using System.Globalization;
using System.Text;

namespace BE10Tools.Maps;

public sealed class MapTable
{
    public required MapDefinition Definition { get; init; }
    public required int TableOffset { get; init; }
    public required bool BigEndian { get; init; }
    public required double[] Tps { get; init; }
    public required double[] Rpm { get; init; }
    public required ushort[,] Raw { get; init; }
    public required double[,] Values { get; init; }

    public int Rows => Definition.RowCount;
    public int Cols => Definition.ColumnCount;

    public (double Min, double Max) MinMax()
    {
        double min = double.MaxValue, max = double.MinValue;
        foreach (var v in Values) { if (v < min) min = v; if (v > max) max = v; }
        return (min, max);
    }
}

/// <summary>
/// Reads fuel/ignition map tables exactly the way the researched application
/// does: TPS axis at tpsh (÷10), RPM axis at rpmh (÷kon), table at the map
/// offset, row-major, uint16, default little-endian. Four table offsets use
/// big-endian words (Form1.cs: 0x3A804, 0x3A258, 0x3911C, 0x396C8).
/// </summary>
public static class BinTableReader
{
    public static bool BigEndianForTable(int tableOffset) =>
        tableOffset is 0x3A804 or 0x3A258 or 0x3911C or 0x396C8;

    public static ushort U16(byte[] data, int offset, bool bigEndian)
    {
        if (offset < 0 || offset + 1 >= data.Length)
            throw new ArgumentOutOfRangeException(nameof(offset), $"0x{offset:X} outside BIN (size 0x{data.Length:X}).");
        return bigEndian
            ? (ushort)((data[offset] << 8) | data[offset + 1])
            : (ushort)(data[offset] | (data[offset + 1] << 8));
    }

    public static MapTable Read(byte[] data, MapDefinition def, int tableOffset)
    {
        bool be = BigEndianForTable(tableOffset);
        int rows = def.RowCount, cols = def.ColumnCount;
        if (rows <= 0 || cols <= 0) throw new InvalidDataException("Map definition has invalid dimensions.");

        var tps = new double[cols];
        for (int c = 0; c < cols; c++) tps[c] = U16(data, def.Tpsh + c * 2, be) / 10.0;

        var rpm = new double[rows];
        for (int r = 0; r < rows; r++) rpm[r] = U16(data, def.Rpmh + r * 2, be) / (def.Kon == 0 ? 1.0 : def.Kon);

        var raw = new ushort[rows, cols];
        var vals = new double[rows, cols];
        for (int r = 0; r < rows; r++)
        {
            for (int c = 0; c < cols; c++)
            {
                ushort v = U16(data, tableOffset + (r * cols + c) * 2, be);
                raw[r, c] = v;
                vals[r, c] = v / 1000.0;
            }
        }

        return new MapTable
        {
            Definition = def,
            TableOffset = tableOffset,
            BigEndian = be,
            Tps = tps,
            Rpm = rpm,
            Raw = raw,
            Values = vals
        };
    }

    public static double GetValue(MapTable table, int row, int col) => table.Values[row, col];

    public static void WriteRaw(byte[] data, int tableOffset, int cols, int row, int col, ushort value)
    {
        bool be = BigEndianForTable(tableOffset);
        int off = tableOffset + (row * cols + col) * 2;
        if (off + 1 >= data.Length) throw new ArgumentOutOfRangeException(nameof(row));
        if (be)
        {
            data[off] = (byte)(value >> 8);
            data[off + 1] = (byte)value;
        }
        else
        {
            data[off] = (byte)value;
            data[off + 1] = (byte)(value >> 8);
        }
    }

    public static ushort ReadRaw(byte[] data, int tableOffset, int cols, int row, int col)
    {
        bool be = BigEndianForTable(tableOffset);
        return U16(data, tableOffset + (row * cols + col) * 2, be);
    }

    /// <summary>Exports a table as a CSV grid: first column RPM, header row TPS.</summary>
    public static void ExportCsv(MapTable table, string path)
    {
        var sb = new StringBuilder();
        sb.Append("RPM\\TPS");
        foreach (var t in table.Tps) sb.Append(',').Append(t.ToString("F3", CultureInfo.InvariantCulture));
        sb.AppendLine();
        for (int r = 0; r < table.Rows; r++)
        {
            sb.Append(table.Rpm[r].ToString("F3", CultureInfo.InvariantCulture));
            for (int c = 0; c < table.Cols; c++)
                sb.Append(',').Append(table.Values[r, c].ToString("F3", CultureInfo.InvariantCulture));
            sb.AppendLine();
        }
        File.WriteAllText(path, sb.ToString(), new UTF8Encoding(false));
    }

    public static (int DataRows, int DataCols, double First, double Last) ReadExportedCsv(string path)
    {
        var lines = File.ReadAllLines(path);
        int dataRows = lines.Length - 1;
        int dataCols = lines[0].Split(',').Length - 1;
        var firstRow = lines[1].Split(',');
        var lastRow = lines[^1].Split(',');
        double first = double.Parse(firstRow[1], CultureInfo.InvariantCulture);
        double last = double.Parse(lastRow[^1], CultureInfo.InvariantCulture);
        return (dataRows, dataCols, first, last);
    }

    /// <summary>Byte-level BIN comparison summary, little-endian agnostic.</summary>
    public static (int SizeA, int SizeB, long DiffBytes, int FirstDiff, int LastDiff) Compare(byte[] a, byte[] b)
    {
        int n = Math.Min(a.Length, b.Length);
        long diffs = 0;
        int first = -1, last = -1;
        for (int i = 0; i < n; i++)
        {
            if (a[i] != b[i])
            {
                diffs++;
                if (first < 0) first = i;
                last = i;
            }
        }
        diffs += Math.Abs(a.Length - b.Length);
        return (a.Length, b.Length, diffs, first, last);
    }
}
