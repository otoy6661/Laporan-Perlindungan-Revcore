using System.Buffers.Binary;

namespace BE10Tools.Protocol;

public sealed record Frame(byte Format, byte[] Data, byte Checksum, bool ChecksumOk)
{
    /// <summary>Length byte observed in K-Line frames: total frame size including format, length and checksum.</summary>
    public byte LengthByte => (byte)(Data.Length + 3);

    public string Hex => Convert.ToHexString(new[] { Format, LengthByte }.Concat(Data).Concat(new[] { Checksum }).ToArray());
}

/// <summary>
/// K-Line framing and checksums reconstructed statically from Diag.cs and
/// Form1.cs. No physical ECU is contacted; functions operate on byte buffers.
/// </summary>
public static class HondaProtocol
{
    /// <summary>Honda frame checksum: (sum ^ 0xFF) + 1, truncated to 8 bits.</summary>
    public static byte ChecksumHonda(ReadOnlySpan<byte> data)
    {
        int sum = 0;
        foreach (byte b in data) sum += b;
        return (byte)(((sum ^ 0xFF) + 1) & 0xFF);
    }

    /// <summary>
    /// Builds [format][total_length][data...][checksum]. The length byte counts
    /// the whole frame (format + length + data + checksum), matching observed
    /// requests such as 72 05 71 10 08.
    /// </summary>
    public static byte[] BuildFrame(byte format, ReadOnlySpan<byte> data)
    {
        int total = data.Length + 3;
        if (total > 0xFF) throw new ArgumentException("Frame too long.");
        var frame = new byte[total];
        frame[0] = format;
        frame[1] = (byte)total;
        data.CopyTo(frame.AsSpan(2));
        frame[^1] = ChecksumHonda(frame.AsSpan(0, frame.Length - 1));
        return frame;
    }

    /// <summary>Parses a concatenated stream of frames. Returns valid and invalid frames.</summary>
    public static List<Frame> ParseFrames(ReadOnlySpan<byte> stream)
    {
        var result = new List<Frame>();
        int i = 0;
        while (i + 3 <= stream.Length)
        {
            byte fmt = stream[i];
            int total = stream[i + 1];
            if (total < 3 || i + total > stream.Length) break;
            var data = stream.Slice(i + 2, total - 3).ToArray();
            byte ck = stream[i + total - 1];
            bool ok = ChecksumHonda(stream.Slice(i, total - 1)) == ck;
            result.Add(new Frame(fmt, data, ck, ok));
            i += total;
        }
        return result;
    }

    /// <summary>
    /// Keihin 8-bit sum complement. Writes 0 - sum at checksumOffset.
    /// checksumOffset == 0 means "sum bytes 1..end" (Form1.cs KeihinAutoChecksum).
    /// </summary>
    public static byte KeihinChecksum(byte[] data, int checksumOffset)
    {
        int sum = 0;
        if (checksumOffset == 0)
        {
            for (int i = 1; i < data.Length; i++) sum += data[i];
        }
        else
        {
            for (int i = 0; i < checksumOffset; i++) sum += data[i];
            for (int i = checksumOffset + 1; i < data.Length; i++) sum += data[i];
        }
        return (byte)(0 - (byte)sum);
    }

    public static void ApplyKeihinChecksum(byte[] data, int checksumOffset)
        => data[checksumOffset] = KeihinChecksum(data, checksumOffset);

    /// <summary>Sum of little-endian uint32 words; uint arithmetic wraps.</summary>
    public static uint Sum32(byte[] data, int start, int length)
    {
        uint sum = 0;
        int end = start + length;
        while (start + 4 <= end)
        {
            sum = unchecked(sum + BinaryPrimitives.ReadUInt32LittleEndian(data.AsSpan(start, 4)));
            start += 4;
        }
        return sum;
    }

    /// <summary>
    /// Shindengen 32-bit sum complement. The 4-byte checksum field sits at
    /// [num-4, num-1]; the sum covers [0, num-4) plus [num, end).
    /// Form1.cs ShindengenAutoChecksum; num is the D0 07 marker position.
    /// </summary>
    public static uint ShindengenChecksum(byte[] data, int num)
    {
        uint total = unchecked(Sum32(data, 0, num - 4) + Sum32(data, num, data.Length - num));
        return unchecked(0u - total);
    }

    public static void ApplyShindengenChecksum(byte[] data, int num)
    {
        uint value = ShindengenChecksum(data, num);
        BinaryPrimitives.WriteUInt32LittleEndian(data.AsSpan(num - 4, 4), value);
    }

    /// <summary>
    /// Shindengen seed/key. Signature scan yields three little-endian words:
    /// c0 = [i], c1 = [i+2], c2 = [i+4]; key = c1*(seed+c0) + (c2>0 ? seed % c2 : seed).
    /// </summary>
    public static ushort ShindengenKey(ushort seed, ushort c0, ushort c1, ushort c2)
    {
        ushort num5 = unchecked((ushort)(c1 * (seed + c0)));
        int add = c2 > 0 ? seed % c2 : seed;
        return unchecked((ushort)(num5 + add));
    }

    public static (byte High, byte Low) ShindengenKeyBytes(ushort key) => ((byte)(key >> 8), (byte)key);
}
