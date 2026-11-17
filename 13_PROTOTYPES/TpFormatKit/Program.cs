using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;
using System.Xml.Linq;

namespace TpFormatKit;

internal static class Program
{
    private static string _root = "";
    private static string _out = "";
    private static readonly StringBuilder Log = new();
    private static int _pass, _fail;

    private static int Main(string[] args)
    {
        _root = args.Length > 0 ? Path.GetFullPath(args[0]) : Directory.GetCurrentDirectory();
        _out = args.Length > 1 ? Path.GetFullPath(args[1]) : Path.Combine(_root, "13_PROTOTYPES", "OUT");
        Directory.CreateDirectory(_out);

        var xdfPath = Path.Combine(_root, "04_BIN_AUTOPSY", "WORK", "K1AA-N03", "30400-k1aa-n03.xdf");
        var binPath = Path.Combine(_root, "04_BIN_AUTOPSY", "WORK", "K1AA-N03", "beat_k1aa_n03.bin");
        var exportPath = Path.Combine(_root, "05_XDF_AUTOPSY", "export_tps_rpm.csv");

        try
        {
            Section("XDF PARSE");
            var doc = XdfDocument.Load(xdfPath);
            Check("XDF is plaintext XML", doc.IsPlaintext, "magic=" + doc.MagicHex);
            Check("20 XDFTABLE objects", doc.Tables.Count == 20, "count=" + doc.Tables.Count);
            Check("header title", doc.Title == "BEAT 110 ESP K1AA-N03", doc.Title ?? "<null>");
            Check("base offset 0", doc.BaseOffset == 0, "base=" + doc.BaseOffset);
            Check("9 categories", doc.Categories.Count == 9, "count=" + doc.Categories.Count);
            Check("no constants", doc.Constants.Count == 0, "count=" + doc.Constants.Count);
            var t0 = doc.Tables.First(t => t.Title == "TPS vs RPM Fast Idle #1");
            Check("table1 z offset 0x3815E", t0.Z.Embedded.Address == 0x3815E, "0x" + t0.Z.Embedded.Address.ToString("X"));
            Check("table1 35 rows x 29 cols", t0.Z.Embedded.RowCount == 35 && t0.Z.Embedded.ColCount == 29, $"{t0.Z.Embedded.RowCount}x{t0.Z.Embedded.ColCount}");
            Check("table1 16-bit cells", t0.Z.Embedded.ElementBits == 16, t0.Z.Embedded.ElementBits.ToString());

            Section("BIN READ / AXIS");
            var bin = File.ReadAllBytes(binPath);
            Check("BIN is 262144 bytes", bin.Length == 262144, "len=" + bin.Length);
            var xAxis = doc.ResolveAxis(t0.X, bin);
            var yAxis = doc.ResolveAxis(t0.Y, bin);
            Check("x axis count 29", xAxis.Values.Count == 29, "count=" + xAxis.Values.Count);
            Check("x axis first 0.0 / last 74.3", Near(xAxis.Values[0], 0.0) && Near(xAxis.Values[^1], 74.3),
                $"{xAxis.Values[0]}..{xAxis.Values[^1]}");
            Check("y axis count 35", yAxis.Values.Count == 35, "count=" + yAxis.Values.Count);
            Check("y axis first 900 / last 9200", Near(yAxis.Values[0], 900) && Near(yAxis.Values[^1], 9200),
                $"{yAxis.Values[0]}..{yAxis.Values[^1]}");
            var grid = t0.ReadGrid(bin);
            Check("grid is 35x29", grid.GetLength(0) == 35 && grid.GetLength(1) == 29,
                $"{grid.GetLength(0)}x{grid.GetLength(1)}");
            Check("stored row0 first cell 3880", Near(grid[0, 0], 3880), grid[0, 0].ToString(CultureInfo.InvariantCulture));
            Check("stored row34 first cell 464", Near(grid[34, 0], 464), grid[34, 0].ToString(CultureInfo.InvariantCulture));

            var sw = doc.Tables.First(t => t.Title == "SW Version");
            var ecm = doc.Tables.First(t => t.Title == "ECM ID");
            Check("SW Version is text table", sw.Z.OutputType == 4 && sw.Z.Embedded.Address == 0x577C,
                $"outputtype={sw.Z.OutputType} addr=0x{sw.Z.Embedded.Address:X}");
            var swText = Encoding.ASCII.GetString(bin, 0x577C, 17);
            Check("SW Version decodes SH850T01R100_PV10", swText == "SH850T01R100_PV10", swText);
            Check("ECM ID is hex table", ecm.Z.OutputType == 3 && ecm.Z.Embedded.Address == 0x800,
                $"outputtype={ecm.Z.OutputType} addr=0x{ecm.Z.Embedded.Address:X}");
            var ecmHex = string.Join(' ', bin.Skip(0x800).Take(5).Select(x => x.ToString("X2")));
            Check("ECM ID decodes 01 03 7A 00 AC", ecmHex == "01 03 7A 00 AC", ecmHex);

            Section("CROSS-CHECK VS TUNERPRO EXPORT");
            var blocks = ExportCsv.Parse(exportPath);
            Check("export contains 20 table blocks", blocks.Count == 20, "count=" + blocks.Count);
            var named = doc.Tables.ToDictionary(t => t.Title, StringComparer.OrdinalIgnoreCase);
            int comparedCells = 0, mismatchedCells = 0, comparedTables = 0, skippedTables = 0;
            foreach (var b in blocks)
            {
                if (b.Title.Trim() is "SW Version" or "ECM ID") { skippedTables++; continue; }
                if (!named.TryGetValue(b.Title.Trim(), out var table)) { skippedTables++; continue; }
                var display = ExportCsv.ToDisplayGrid(doc, table, bin);
                if (display == null) { skippedTables++; continue; }
                comparedTables++;
                var (cells, diffs) = ExportCsv.Compare(b, display);
                comparedCells += cells;
                mismatchedCells += diffs;
                Log.AppendLine($"  {b.Title.Trim(),-28} cells={cells,5} mismatch={diffs}");
            }
            Check("all 18 numeric tables compared", comparedTables == 18, $"compared={comparedTables} skipped={skippedTables}");
            Check("all exported cells reproduced", mismatchedCells == 0, $"cells={comparedCells} mismatch={mismatchedCells}");

            Section("CHECKSUM (XDFCHECKSUM, calculationmethod=0)");
            var supraXdf = XdfDocument.Load(Path.Combine(_root, "04_BIN_AUTOPSY", "WORK", "SUPRA-K41NC1", "SUPRA-K41NC1.xdf"));
            Check("checksum definition present", supraXdf.Checksums.Count == 1, "count=" + supraXdf.Checksums.Count);
            if (supraXdf.Checksums.Count > 0)
            {
                var cs = supraXdf.Checksums[0];
                Check("checksum region FFF0..FFF0", cs.DataStart == 0xFFF0 && cs.DataEnd == 0xFFF0 && cs.StoreAddress == 0xFFF1,
                    $"start=0x{cs.DataStart:X} end=0x{cs.DataEnd:X} store=0x{cs.StoreAddress:X}");
                var supraOrig = File.ReadAllBytes(Path.Combine(_root, "04_BIN_AUTOPSY", "WORK", "SUPRA-K41NC1", "SUPRA-K41NC1.bin"));
                var supraRe = File.ReadAllBytes(Path.Combine(_root, "04_BIN_AUTOPSY", "WORK", "SUPRA-K41NC1", "SUPRA-K41NC1_resaved.bin"));
                Check("original store byte 0xFF", supraOrig[0xFFF1] == 0xFF, "0x" + supraOrig[0xFFF1].ToString("X2"));
                Check("resaved store byte 0xFF", supraRe[0xFFF1] == 0xFF, "0x" + supraRe[0xFFF1].ToString("X2"));
                var supraCorrupt = File.ReadAllBytes(Path.Combine(_root, "04_BIN_AUTOPSY", "WORK", "SUPRA-K41NC1", "SUPRA-K41NC1_corrupt.bin"));
                Check("corrupt input store byte 0x00", supraCorrupt[0xFFF1] == 0x00, "0x" + supraCorrupt[0xFFF1].ToString("X2"));
                Check("original store byte 0xFF", supraOrig[0xFFF1] == 0xFF, "0x" + supraOrig[0xFFF1].ToString("X2"));
                Check("resaved store byte 0xFF", supraRe[0xFFF1] == 0xFF, "0x" + supraRe[0xFFF1].ToString("X2"));
                byte calc = Checksum.Sum8(CalcRegionSum(supraOrig, cs.DataStart, cs.DataEnd));
                Check("method-0 sum over FFF0..FFF0 = 0xFF", calc == 0xFF, "0x" + calc.ToString("X2"));
                int diff = BinaryDiff.Count(supraCorrupt, supraRe);
                Check("Save As normalized store 0x00 -> 0xFF, 1 byte", diff == 1 && supraRe[0xFFF1] == 0xFF, "diff=" + diff);
                var deltaIn = File.ReadAllBytes(Path.Combine(_root, "04_BIN_AUTOPSY", "WORK", "SUPRA-K41NC1", "CHECKSUM_DELTA_TEST.bin"));
                var deltaOut = File.ReadAllBytes(Path.Combine(_root, "04_BIN_AUTOPSY", "WORK", "SUPRA-K41NC1", "CHECKSUM_DELTA_TEST_out.bin"));
                Check("data-byte change at 0x1000 preserved", deltaIn[0x1000] == deltaOut[0x1000] && deltaOut[0x1000] == 0x7E,
                    $"in=0x{deltaIn[0x1000]:X2} out=0x{deltaOut[0x1000]:X2}");
                Check("data-byte change did not alter store byte", deltaIn[0xFFF1] == deltaOut[0xFFF1],
                    $"in=0x{deltaIn[0xFFF1]:X2} out=0x{deltaOut[0xFFF1]:X2}");
                Check("data-byte delta produced no other change", BinaryDiff.Count(deltaIn, deltaOut) == 0,
                    "diff=" + BinaryDiff.Count(deltaIn, deltaOut));

                var cbrXdf = XdfDocument.Load(Path.Combine(_root, "04_BIN_AUTOPSY", "WORK", "CBR1000RR-MGP-A01", "CBR1000RR.xdf"));
                var cbrCs = cbrXdf.Checksums[0];
                Check("CBR checksum region 0..0x3FFFF, store 0x3FFF8", cbrCs.DataStart == 0 && cbrCs.DataEnd == 0x3FFFF && cbrCs.StoreAddress == 0x3FFF8,
                    $"start=0x{cbrCs.DataStart:X} end=0x{cbrCs.DataEnd:X} store=0x{cbrCs.StoreAddress:X}");
                Check("CBR checksum requires plugin IRON-PONY-RK", cbrCs.PluginModuleId == "49524f4e-504f-4e59-524b-000000000000",
                    cbrCs.PluginModuleId);
                var cbrBin = File.ReadAllBytes(Path.Combine(_root, "00_SOURCE_INVENTORY", "DATASET_COPY", "BIN & XDF", "CB -CBR", "CBR500R 38770 MGZ-C02", "CBR1000RR 38770-MGP-A01", "28= CBR1000RR 38770-MGP-A01.bin"));
                int sumOther = 0;
                for (int i = 0; i < cbrBin.Length; i++) if (i != 0x3FFF8) sumOther = (sumOther + cbrBin[i]) & 0xFF;
                int stored = (0x100 - sumOther) & 0xFF;
                Check("CBR stored 0xEF = two's complement of other bytes", cbrBin[0x3FFF8] == 0xEF && stored == 0xEF,
                    $"stored=0x{cbrBin[0x3FFF8]:X2} calc=0x{stored:X2}");
            }

            Section("BIN DIFF");
            var ed = File.ReadAllBytes(Path.Combine(_root, "04_BIN_AUTOPSY", "WORK", "K1AA-N03", "edited_9999.bin"));
            var ranges = BinaryDiff.Ranges(bin, ed);
            Check("edited K1AA differs in one contiguous range", ranges.Count == 1, "ranges=" + ranges.Count);
            if (ranges.Count > 0)
            {
                Check("edited range is 2 bytes", ranges[0].Length == 2, "len=" + ranges[0].Length);
                Check("edited bytes encode 9999 (0x270F LE)", ed[ranges[0].Start] == 0x0F && ed[ranges[0].Start + 1] == 0x27,
                    $"0x{ed[ranges[0].Start]:X2} 0x{ed[ranges[0].Start + 1]:X2} at 0x{ranges[0].Start:X}");
            }

            Section("ENCRYPTED CONTAINER HEADER");
            var encXdf = FindEncryptedXdf(Path.Combine(_root, "00_SOURCE_INVENTORY", "DATASET_COPY"));
            if (encXdf != null)
            {
                var h = ContainerHeader.Read(encXdf);
                Check("encrypted XDF magic 05 22 97 00", h.MagicHex == "05 22 97 00", h.MagicHex);
                Check("header marker byte[0x83]=0x64", h.Marker == 0x64, "0x" + h.Marker.ToString("X2"));
                Check("ciphertext starts at 0x84", h.CipherOffset == 0x84, "0x" + h.CipherOffset.ToString("X"));
                Check("header has no readable filename/title", h.AsciiHeader.Trim('\0', ' ', '.', '"', '?', '\u0005', '\u0097').Length == 0,
                    "ascii_len=" + h.AsciiHeader.Trim('\0', ' ', '.', '"', '?', '\u0005', '\u0097').Length);
            }
            else Check("encrypted XDF sample found", false, "none");

            Section("ADX CONTAINER");
            var adx = new[]
            {
                Path.Combine(_root, "06_ADX_AUTOPSY", "WORK", "keihin.adx"),
                Path.Combine(_root, "06_ADX_AUTOPSY", "WORK", "shindengen.adx")
            };
            foreach (var p in adx)
            {
                if (!File.Exists(p)) { Check(Path.GetFileName(p) + " present", false, "missing"); continue; }
                var h = ContainerHeader.Read(p);
                Check(Path.GetFileName(p) + " encrypted magic", h.MagicHex == "05 22 97 00", h.MagicHex);
                Check(Path.GetFileName(p) + " marker 0x64", h.Marker == 0x64, "0x" + h.Marker.ToString("X2"));
                Log.AppendLine($"  {Path.GetFileName(p)} size={h.Size} cipher={h.Size - h.CipherOffset} entropy={h.Entropy:F3}");
            }

            Section("DATASET MATRIX");
            var rows = DatasetScan.Run(Path.Combine(_root, "00_SOURCE_INVENTORY", "DATASET_COPY"));
            var matrixPath = Path.Combine(_out, "DATASET_COMPATIBILITY_MATRIX.csv");
            DatasetScan.WriteCsv(matrixPath, rows);
            Check("matrix written", File.Exists(matrixPath), matrixPath);
            Check("matrix has XDF rows", rows.Count(r => r.Kind == "XDF") >= 100, "xdf=" + rows.Count(r => r.Kind == "XDF"));
            Check("plaintext XDF count 13", rows.Count(r => r.Kind == "XDF" && r.Plaintext) == 13,
                "plaintext=" + rows.Count(r => r.Kind == "XDF" && r.Plaintext));
        }
        catch (Exception ex)
        {
            _fail++;
            Log.AppendLine("FATAL: " + ex);
        }

        Section("RESULT");
        Log.AppendLine($"PASS={_pass} FAIL={_fail}");
        var text = Log.ToString();
        File.WriteAllText(Path.Combine(_out, "SELFTEST.txt"), text);
        Console.WriteLine(text);
        return _fail == 0 ? 0 : 1;
    }

    private static int CalcRegionSum(byte[] data, int start, int end)
    {
        int sum = 0;
        for (int i = start; i <= end && i < data.Length; i++) sum += data[i];
        return sum & 0xFF;
    }

    private static string? FindEncryptedXdf(string datasetRoot)
    {
        foreach (var p in Directory.EnumerateFiles(datasetRoot, "*.xdf", SearchOption.AllDirectories))
        {
            try
            {
                using var fs = File.OpenRead(p);
                Span<byte> m = stackalloc byte[4];
                if (fs.Read(m) == 4 && m.SequenceEqual(new byte[] { 0x05, 0x22, 0x97, 0x00 })) return p;
            }
            catch { }
        }
        return null;
    }

    private static void Section(string name) => Log.AppendLine().AppendLine("== " + name);
    private static void Check(string name, bool ok, string detail)
    {
        if (ok) _pass++; else _fail++;
        Log.AppendLine($"  [{(ok ? "PASS" : "FAIL")}] {name} ({detail})");
    }
    private static bool Near(double a, double b, double eps = 1e-6) => Math.Abs(a - b) <= eps;
}

internal static class Checksum
{
    // Observed for XDFCHECKSUM calculationmethod=0 with region FFF0..FFF0:
    // the stored byte equals the additive sum of the region modulo 256.
    public static byte Sum8(int sum) => (byte)(sum & 0xFF);
}

internal sealed class XdfDocument
{
    public string? Title { get; private set; }
    public int BaseOffset { get; private set; }
    public bool IsPlaintext { get; private set; }
    public string MagicHex { get; private set; } = "";
    public List<string> Categories { get; } = new();
    public List<XdfTable> Tables { get; } = new();
    public List<XdfConstant> Constants { get; } = new();
    public List<XdfChecksum> Checksums { get; } = new();
    private readonly Dictionary<uint, XdfTable> _byId = new();

    public static XdfDocument Load(string path)
    {
        var d = new XdfDocument();
        var head = File.ReadAllBytes(path).Take(8).ToArray();
        d.MagicHex = string.Join(' ', head.Take(4).Select(b => b.ToString("X2")));
        d.IsPlaintext = head.Length > 0 && (head[0] == (byte)'<' || Encoding.ASCII.GetString(head).TrimStart().StartsWith("<"));
        if (!d.IsPlaintext)
        {
            var h = ContainerHeader.Read(path);
            throw new InvalidDataException($"XDF is encrypted (magic {h.MagicHex}, marker 0x{h.Marker:X2}); export via TunerPro first.");
        }
        var x = XDocument.Load(path);
        var root = x.Root!;
        var header = root.Element("XDFHEADER");
        d.Title = header?.Element("deftitle")?.Value;
        var bo = header?.Element("BASEOFFSET");
        d.BaseOffset = ParseInt(bo?.Attribute("offset")?.Value);
        foreach (var c in header?.Elements("CATEGORY") ?? Enumerable.Empty<XElement>())
            d.Categories.Add(c.Attribute("name")?.Value ?? "");
        foreach (var t in root.Elements("XDFTABLE")) d.Tables.Add(XdfTable.Parse(t));
        foreach (var c in root.Elements("XDFCONSTANT")) d.Constants.Add(XdfConstant.Parse(c));
        foreach (var c in root.Elements("XDFCHECKSUM")) d.Checksums.Add(XdfChecksum.Parse(c));
        foreach (var t in d.Tables) d._byId[t.UniqueId] = t;
        return d;
    }

    public Axis ResolveAxis(XdfAxis axis, byte[] bin)
    {
        if (axis.LinkedObjectId != 0 && _byId.TryGetValue(axis.LinkedObjectId, out var linked))
        {
            var g = linked.ReadGrid(bin);
            var vals = new List<double>();
            for (int i = 0; i < g.GetLength(0); i++) vals.Add(g[i, 0]);
            if (vals.Count == 0) for (int i = 0; i < g.GetLength(1); i++) vals.Add(g[0, i]);
            return new Axis(vals);
        }
        if (axis.Labels.Count > 0)
            return new Axis(axis.Labels.Select(s => double.TryParse(s, NumberStyles.Float, CultureInfo.InvariantCulture, out var v) ? v : 0).ToList());
        if (axis.Embedded.Address > 0 && axis.IndexCount > 0)
        {
            var vals = new List<double>();
            int stride = axis.Embedded.MajorStrideBits != 0 ? Math.Abs(axis.Embedded.MajorStrideBits) / 8 : 1;
            for (int i = 0; i < axis.IndexCount; i++)
                vals.Add(axis.Math.Apply(ReadCell(bin, axis.Embedded.Address + i * stride, axis.Embedded.ElementBits, false)));
            return new Axis(vals);
        }
        return new Axis(Enumerable.Range(0, axis.IndexCount).Select(i => (double)i).ToList());
    }

    internal static double ReadCell(byte[] bin, int addr, int bits, bool signed)
    {
        if (addr < 0 || addr >= bin.Length) return double.NaN;
        if (bits == 8)
        {
            byte b = bin[addr];
            return signed ? (sbyte)b : b;
        }
        if (bits == 16 && addr + 1 < bin.Length)
        {
            ushort v = (ushort)(bin[addr] | (bin[addr + 1] << 8));
            return signed ? (short)v : v;
        }
        return double.NaN;
    }

    internal static int ParseInt(string? s)
    {
        if (string.IsNullOrWhiteSpace(s)) return 0;
        s = s.Trim();
        if (s.StartsWith("0x", StringComparison.OrdinalIgnoreCase))
            return int.Parse(s[2..], NumberStyles.HexNumber, CultureInfo.InvariantCulture);
        return int.Parse(s, CultureInfo.InvariantCulture);
    }
}

internal sealed class Axis
{
    public List<double> Values { get; }
    public Axis(List<double> v) { Values = v; }
}

internal sealed class XdfTable
{
    public uint UniqueId { get; private set; }
    public string Title { get; private set; } = "";
    public XdfAxis X { get; private set; } = new();
    public XdfAxis Y { get; private set; } = new();
    public XdfAxis Z { get; private set; } = new();

    public static XdfTable Parse(XElement e)
    {
        var t = new XdfTable
        {
            UniqueId = (uint)XdfDocument.ParseInt(e.Attribute("uniqueid")?.Value),
            Title = e.Element("title")?.Value ?? ""
        };
        foreach (var a in e.Elements("XDFAXIS"))
        {
            var id = a.Attribute("id")?.Value;
            var ax = XdfAxis.Parse(a);
            if (id == "x") t.X = ax; else if (id == "y") t.Y = ax; else if (id == "z") t.Z = ax;
        }
        return t;
    }

    public double[,] ReadGrid(byte[] bin)
    {
        int rows = Math.Max(1, Z.Embedded.RowCount);
        int cols = Math.Max(1, Z.Embedded.ColCount);
        int elem = Math.Max(1, Z.Embedded.ElementBits / 8);
        int rowStride = Z.Embedded.MajorStrideBits != 0 ? Math.Abs(Z.Embedded.MajorStrideBits) / 8 : cols * elem;
        int colStride = Z.Embedded.MinorStrideBits != 0 ? Math.Abs(Z.Embedded.MinorStrideBits) / 8 : elem;
        var g = new double[rows, cols];
        for (int r = 0; r < rows; r++)
            for (int c = 0; c < cols; c++)
            {
                int addr = Z.Embedded.Address + r * rowStride + c * colStride;
                g[r, c] = Z.Math.Apply(XdfDocument.ReadCell(bin, addr, Z.Embedded.ElementBits, Z.Embedded.Signed));
            }
        return g;
    }
}

internal sealed class XdfConstant
{
    public string Title { get; private set; } = "";
    public static XdfConstant Parse(XElement e) => new() { Title = e.Element("title")?.Value ?? "" };
}

internal sealed class XdfChecksum
{
    public int DataStart { get; private set; }
    public int DataEnd { get; private set; }
    public int StoreAddress { get; private set; }
    public int StoreSizeBits { get; private set; }
    public int Method { get; private set; }
    public string PluginModuleId { get; private set; } = "";
    public static XdfChecksum Parse(XElement e)
    {
        // Fields live inside a nested <REGION> in XDF 1.70 files.
        string? Val(string name) => e.Descendants(name).FirstOrDefault()?.Value;
        return new XdfChecksum
        {
            DataStart = XdfDocument.ParseInt(Val("datastart")),
            DataEnd = XdfDocument.ParseInt(Val("dataend")),
            StoreAddress = XdfDocument.ParseInt(Val("storeaddress")),
            StoreSizeBits = XdfDocument.ParseInt(Val("storesizebits")),
            Method = XdfDocument.ParseInt(Val("calculationmethod")),
            PluginModuleId = Val("pluginmoduleid") ?? ""
        };
    }
}

internal sealed class XdfAxis
{
    public int IndexCount { get; private set; }
    public int OutputType { get; private set; }
    public uint LinkedObjectId { get; private set; }
    public List<string> Labels { get; } = new();
    public Embed Embedded { get; private set; } = new();
    public MathExpr Math { get; private set; } = MathExpr.Identity;

    public static XdfAxis Parse(XElement e)
    {
        var a = new XdfAxis { IndexCount = XdfDocument.ParseInt(e.Element("indexcount")?.Value) };
        var ot = e.Element("outputtype")?.Value;
        if (!string.IsNullOrWhiteSpace(ot)) a.OutputType = XdfDocument.ParseInt(ot);
        var ed = e.Element("EMBEDDEDDATA");
        if (ed != null)
        {
            a.Embedded = new Embed
            {
                Address = XdfDocument.ParseInt(ed.Attribute("mmedaddress")?.Value),
                ElementBits = XdfDocument.ParseInt(ed.Attribute("mmedelementsizebits")?.Value),
                RowCount = XdfDocument.ParseInt(ed.Attribute("mmedrowcount")?.Value),
                ColCount = XdfDocument.ParseInt(ed.Attribute("mmedcolcount")?.Value),
                MajorStrideBits = XdfDocument.ParseInt(ed.Attribute("mmedmajorstridebits")?.Value),
                MinorStrideBits = XdfDocument.ParseInt(ed.Attribute("mmedminorstridebits")?.Value),
                Signed = (XdfDocument.ParseInt(ed.Attribute("mmedtypeflags")?.Value) & 0x01) != 0
            };
        }
        var link = e.Element("embedinfo")?.Attribute("linkobjid")?.Value;
        if (!string.IsNullOrWhiteSpace(link)) a.LinkedObjectId = (uint)XdfDocument.ParseInt(link);
        foreach (var l in e.Elements("LABEL")) a.Labels.Add(l.Attribute("value")?.Value ?? "");
        var math = e.Element("MATH")?.Attribute("equation")?.Value;
        if (!string.IsNullOrWhiteSpace(math)) a.Math = MathExpr.Parse(math);
        return a;
    }
}

internal sealed class Embed
{
    public int Address { get; init; }
    public int ElementBits { get; init; }
    public int RowCount { get; init; }
    public int ColCount { get; init; }
    public int MajorStrideBits { get; init; }
    public int MinorStrideBits { get; init; }
    public bool Signed { get; init; }
}

internal sealed class MathExpr
{
    public static readonly MathExpr Identity = Parse("X");
    private readonly string _src;
    private int _pos;

    private MathExpr(string src) { _src = src; }
    public static MathExpr Parse(string s) => new(s);

    public double Apply(double x)
    {
        _pos = 0;
        var v = Expr(x);
        return double.IsNaN(v) ? double.NaN : v;
    }

    private double Expr(double x)
    {
        double v = Term(x);
        while (_pos < _src.Length && (_src[_pos] == '+' || _src[_pos] == '-'))
        {
            char op = _src[_pos++];
            double r = Term(x);
            v = op == '+' ? v + r : v - r;
        }
        return v;
    }

    private double Term(double x)
    {
        double v = Factor(x);
        while (_pos < _src.Length && (_src[_pos] == '*' || _src[_pos] == '/'))
        {
            char op = _src[_pos++];
            double r = Factor(x);
            v = op == '*' ? v * r : (r == 0 ? double.NaN : v / r);
        }
        return v;
    }

    private double Factor(double x)
    {
        Skip();
        if (_pos < _src.Length && _src[_pos] == '(')
        {
            _pos++;
            double v = Expr(x);
            Skip();
            if (_pos < _src.Length && _src[_pos] == ')') _pos++;
            return v;
        }
        if (_pos < _src.Length && (_src[_pos] == 'X' || _src[_pos] == 'x')) { _pos++; return x; }
        int start = _pos;
        while (_pos < _src.Length && (char.IsDigit(_src[_pos]) || _src[_pos] == '.' || _src[_pos] == 'E' || _src[_pos] == 'e' ||
               ((_src[_pos] == '+' || _src[_pos] == '-') && _pos > start && (_src[_pos - 1] == 'E' || _src[_pos - 1] == 'e'))))
            _pos++;
        if (start == _pos) { _pos++; return double.NaN; }
        return double.TryParse(_src[start.._pos], NumberStyles.Float, CultureInfo.InvariantCulture, out var parsed) ? parsed : double.NaN;
    }

    private void Skip() { while (_pos < _src.Length && _src[_pos] == ' ') _pos++; }
}

internal sealed class ExportCsv
{
    public string Title { get; init; } = "";
    public List<double> XHeader { get; init; } = new();
    public List<double> YLabels { get; init; } = new();
    public List<List<double>> Rows { get; init; } = new();

    private static readonly Regex Num = new(@"-?\d+(?:\.\d+)?", RegexOptions.Compiled);

    public static List<ExportCsv> Parse(string path)
    {
        var blocks = new List<ExportCsv>();
        var lines = new List<string>();
        using (var fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
        using (var sr = new StreamReader(fs, Encoding.UTF8))
        {
            string? ln;
            while ((ln = sr.ReadLine()) != null) lines.Add(ln);
        }
        int i = 0;
        while (i < lines.Count)
        {
            if (!lines[i].StartsWith("TABLE:", StringComparison.Ordinal)) { i++; continue; }
            string title = lines[i][6..].Trim();
            i++;
            while (i < lines.Count && !lines[i].Contains("Cell Units")) i++;
            i++;
            while (i < lines.Count && string.IsNullOrWhiteSpace(lines[i])) i++;
            var cand = i < lines.Count ? Num.Matches(lines[i]).Select(m => double.Parse(m.Value, CultureInfo.InvariantCulture)).ToList() : new List<double>();
            int j = i + 1;
            while (j < lines.Count && string.IsNullOrWhiteSpace(lines[j])) j++;
            var next = j < lines.Count ? Num.Matches(lines[j]).Select(m => double.Parse(m.Value, CultureInfo.InvariantCulture)).ToList() : new List<double>();
            List<double> header;
            if (cand.Count >= 1 && cand.Count + 1 == next.Count)
            {
                header = cand;
                i++;
            }
            else header = new List<double>();
            var rows = new List<List<double>>();
            var ylabels = new List<double>();
            while (i < lines.Count && !lines[i].StartsWith("TABLE:", StringComparison.Ordinal))
            {
                var ln = lines[i];
                if (string.IsNullOrWhiteSpace(ln)) { i++; if (rows.Count > 0) break; else continue; }
                var ms = Num.Matches(ln).Select(m => double.Parse(m.Value, CultureInfo.InvariantCulture)).ToList();
                if (ms.Count >= 2) { ylabels.Add(ms[0]); rows.Add(ms.Skip(1).ToList()); }
                i++;
            }
            if (rows.Count > 0) blocks.Add(new ExportCsv { Title = title, XHeader = header, YLabels = ylabels, Rows = rows });
        }
        return blocks;
    }

    public static List<List<double>>? ToDisplayGrid(XdfDocument doc, XdfTable t, byte[] bin)
    {
        var g = t.ReadGrid(bin);
        int rows = g.GetLength(0), cols = g.GetLength(1);
        var y = doc.ResolveAxis(t.Y, bin);
        bool flip = rows > 1 && y.Values.Count > 1 && y.Values[0] < y.Values[^1];
        var outp = new List<List<double>>();
        for (int dr = 0; dr < rows; dr++)
        {
            int r = flip ? rows - 1 - dr : dr;
            var line = new List<double>();
            for (int c = 0; c < cols; c++) line.Add(g[r, c]);
            outp.Add(line);
        }
        return outp;
    }

    public static (int cells, int diffs) Compare(ExportCsv b, List<List<double>> display)
    {
        int cells = 0, diffs = 0;
        int rows = Math.Min(b.Rows.Count, display.Count);
        for (int r = 0; r < rows; r++)
        {
            int cols = Math.Min(b.Rows[r].Count, display[r].Count);
            for (int c = 0; c < cols; c++)
            {
                cells++;
                if (Math.Abs(b.Rows[r][c] - display[r][c]) > 0.055) diffs++;
            }
            cells += Math.Abs(b.Rows[r].Count - display[r].Count);
            diffs += Math.Abs(b.Rows[r].Count - display[r].Count);
        }
        cells += Math.Abs(b.Rows.Count - display.Count) * Math.Max(1, b.XHeader.Count);
        diffs += Math.Abs(b.Rows.Count - display.Count) * Math.Max(1, b.XHeader.Count);
        return (cells, diffs);
    }
}

internal sealed class ContainerHeader
{
    public string MagicHex { get; private set; } = "";
    public byte Marker { get; private set; }
    public int CipherOffset { get; private set; }
    public string AsciiHeader { get; private set; } = "";
    public long Size { get; private set; }
    public double Entropy { get; private set; }

    public static ContainerHeader Read(string path)
    {
        var b = File.ReadAllBytes(path);
        var h = new ContainerHeader
        {
            MagicHex = string.Join(' ', b.Take(4).Select(x => x.ToString("X2"))),
            Marker = b.Length > 0x83 ? b[0x83] : (byte)0,
            CipherOffset = 0x84,
            Size = b.Length
        };
        h.AsciiHeader = Encoding.ASCII.GetString(b, 0, Math.Min(0x83, b.Length))
            .Replace("\0", "").Replace("\r", "").Replace("\n", "");
        var counts = new int[256];
        for (int i = h.CipherOffset; i < b.Length; i++) counts[b[i]]++;
        double e = 0; int n = Math.Max(1, b.Length - h.CipherOffset);
        foreach (var c in counts) if (c > 0) { double p = (double)c / n; e -= p * Math.Log2(p); }
        h.Entropy = e;
        return h;
    }
}

internal static class BinaryDiff
{
    public readonly record struct Range(int Start, int Length);

    public static int Count(byte[] a, byte[] b)
    {
        int n = Math.Min(a.Length, b.Length), c = 0;
        for (int i = 0; i < n; i++) if (a[i] != b[i]) c++;
        return c + Math.Abs(a.Length - b.Length);
    }

    public static List<Range> Ranges(byte[] a, byte[] b)
    {
        var list = new List<Range>();
        int n = Math.Min(a.Length, b.Length);
        int start = -1;
        for (int i = 0; i < n; i++)
        {
            if (a[i] != b[i]) { if (start < 0) start = i; }
            else if (start >= 0) { list.Add(new Range(start, i - start)); start = -1; }
        }
        if (start >= 0) list.Add(new Range(start, n - start));
        return list;
    }
}

internal sealed record MatrixRow(string Kind, string File, long Size, bool Plaintext, string Magic,
    int Tables, int Constants, int Checksums, string PairBin, string PairState, string Directory);

internal static class DatasetScan
{
    public static List<MatrixRow> Run(string root)
    {
        var rows = new List<MatrixRow>();
        foreach (var p in Directory.EnumerateFiles(root, "*.*", SearchOption.AllDirectories)
                     .Where(p => p.EndsWith(".xdf", StringComparison.OrdinalIgnoreCase) || p.EndsWith(".adx", StringComparison.OrdinalIgnoreCase))
                     .OrderBy(p => p, StringComparer.OrdinalIgnoreCase))
        {
            var head = File.ReadAllBytes(p).Take(8).ToArray();
            bool plain = head.Length > 0 && (head[0] == (byte)'<' || Encoding.ASCII.GetString(head).TrimStart().StartsWith("<"));
            string magic = string.Join(' ', head.Take(4).Select(b => b.ToString("X2")));
            int tables = 0, consts = 0, csums = 0;
            if (plain && p.EndsWith(".xdf", StringComparison.OrdinalIgnoreCase))
            {
                try
                {
                    var d = XdfDocument.Load(p);
                    tables = d.Tables.Count; consts = d.Constants.Count; csums = d.Checksums.Count;
                }
                catch { }
            }
            string pairBin = "", pairState = "NO_BIN";
            var dir = Path.GetDirectoryName(p)!;
            var bins = Directory.EnumerateFiles(dir, "*.bin").ToList();
            if (bins.Count > 0)
            {
                var stem = Path.GetFileNameWithoutExtension(p).ToLowerInvariant();
                var best = bins.OrderByDescending(b => TokenOverlap(stem, Path.GetFileNameWithoutExtension(b).ToLowerInvariant())).First();
                pairBin = Path.GetFileName(best);
                pairState = "SAME_DIR";
            }
            rows.Add(new MatrixRow(p.EndsWith(".xdf", StringComparison.OrdinalIgnoreCase) ? "XDF" : "ADX",
                Path.GetFileName(p), new FileInfo(p).Length, plain, magic, tables, consts, csums,
                pairBin, pairState, Path.GetRelativePath(root, dir)));
        }
        return rows;
    }

    private static int TokenOverlap(string a, string b)
    {
        int n = 0;
        foreach (var t in a.Split(new[] { ' ', '-', '_', '.' }, StringSplitOptions.RemoveEmptyEntries))
            if (t.Length >= 4 && b.Contains(t, StringComparison.Ordinal)) n++;
        return n;
    }

    public static void WriteCsv(string path, List<MatrixRow> rows)
    {
        var sb = new StringBuilder();
        sb.AppendLine("kind,file,bytes,plaintext,magic,tables,constants,checksums,nearest_bin,pair_state,directory");
        foreach (var r in rows)
            sb.AppendLine(string.Join(',', Csv(r.Kind), Csv(r.File), r.Size, r.Plaintext, Csv(r.Magic),
                r.Tables, r.Constants, r.Checksums, Csv(r.PairBin), r.PairState, Csv(r.Directory)));
        File.WriteAllText(path, sb.ToString());
    }

    private static string Csv(string s) => s.Contains(',') || s.Contains('"') ? '"' + s.Replace("\"", "\"\"") + '"' : s;
}
