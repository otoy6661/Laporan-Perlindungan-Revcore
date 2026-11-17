using System.Security.Cryptography;

namespace BE10Tools.Adx;

public sealed record AdxInspection(
    bool MagicOk,
    int HeaderSize,
    int PayloadOffset,
    int PayloadLength,
    string FixedBlockHex,
    byte TagByte,
    double Entropy,
    double PrintableRatio,
    bool HasZlib,
    bool HasGzip,
    bool HasZip,
    string Sha256);

/// <summary>
/// Static, non-decrypting inspector for TunerPro-style locked ADX containers.
/// It validates the container layout observed in BE-10 and never attempts
/// decryption or key recovery.
/// </summary>
public static class AdxInspector
{
    public static AdxInspection Inspect(string path)
    {
        var b = File.ReadAllBytes(path);
        if (b.Length < 0x140) throw new InvalidDataException("File too small for ADX container header.");

        bool magic = b[0] == 0x05 && b[1] == 0x22 && b[2] == 0x97 && b[3] == 0x00;

        // Observed header: magic + 128 zero bytes => first non-zero payload byte at 0x83.
        int header = 0x83;
        for (int i = 4; i < Math.Min(0x200, b.Length); i++)
        {
            if (b[i] != 0) { header = i; break; }
        }

        // Observed layout (both ADX files): 44-byte fixed block at 0x108..0x133,
        // family tag byte at 0x133 (0x03 KEIHIN, 0x02 SHINDENGEN), payload at 0x134.
        const int fixedOffset = 0x108;
        const int fixedLen = 44;
        string fixedHex = Convert.ToHexString(b, fixedOffset, fixedLen);
        byte tag = b[0x133];

        const int payloadOffset = 0x134;
        int payloadLen = b.Length - payloadOffset;

        return new AdxInspection(
            magic,
            header,
            payloadOffset,
            payloadLen,
            fixedHex,
            tag,
            Entropy(b, payloadOffset, payloadLen),
            PrintableRatio(b, payloadOffset, payloadLen),
            StartsWith(b, payloadOffset, 0x78, 0x9C) || StartsWith(b, payloadOffset, 0x78, 0xDA) || StartsWith(b, payloadOffset, 0x78, 0x01),
            StartsWith(b, payloadOffset, 0x1F, 0x8B),
            StartsWith(b, payloadOffset, 0x50, 0x4B, 0x03, 0x04),
            Convert.ToHexString(SHA256.HashData(b)).ToLowerInvariant());
    }

    public static double Entropy(byte[] data, int offset, int len)
    {
        if (len <= 0) return 0;
        var counts = new long[256];
        for (int i = offset; i < offset + len; i++) counts[data[i]]++;
        double e = 0;
        for (int i = 0; i < 256; i++)
        {
            if (counts[i] == 0) continue;
            double p = (double)counts[i] / len;
            e -= p * Math.Log2(p);
        }
        return e;
    }

    public static double PrintableRatio(byte[] data, int offset, int len)
    {
        if (len <= 0) return 0;
        int printable = 0;
        for (int i = offset; i < offset + len; i++)
        {
            byte c = data[i];
            if (c >= 0x20 && c <= 0x7E) printable++;
        }
        return (double)printable / len;
    }

    private static bool StartsWith(byte[] data, int offset, params byte[] pattern)
    {
        if (offset + pattern.Length > data.Length) return false;
        for (int j = 0; j < pattern.Length; j++)
            if (data[offset + j] != pattern[j]) return false;
        return true;
    }
}
