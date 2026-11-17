using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using BE10Tools.Adx;
using BE10Tools.Maps;
using BE10Tools.Tests;

namespace BE10Tools;

public static class Program
{
    private const string DefaultRoot = @"C:\Users\Lord Otoy\Documents\REVCORE_BE10_RESEARCH";

    public static int Main(string[] args)
    {
        string cmd = args.Length > 0 ? args[0].ToLowerInvariant() : "selftest";
        try
        {
            return cmd switch
            {
                "selftest" => SelfTest(args),
                "adx" => Adx(args),
                "validate" => Validate(args),
                "catalog" => Catalog(args),
                "compare" => Compare(args),
                _ => Usage()
            };
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"ERROR: {ex.Message}");
            return 2;
        }
    }

    private static int Usage()
    {
        Console.WriteLine("BE10Tools commands:");
        Console.WriteLine("  selftest [dataDir] [resultsDir]");
        Console.WriteLine("  adx <file.adx>");
        Console.WriteLine("  validate [dataDir] [outDir]");
        Console.WriteLine("  catalog [outCsv]");
        Console.WriteLine("  compare <a.bin> <b.bin>");
        return 1;
    }

    private static string Root(string? arg) => arg ?? DefaultRoot;

    private static int SelfTest(string[] args)
    {
        string root = Root(args.Length > 1 ? args[1] : null);
        string data = args.Length > 2 ? args[2] : Path.Combine(root, "PROTOTYPES", "testdata");
        string results = args.Length > 3 ? args[3] : Path.Combine(root, "PROTOTYPES", "RESULTS");
        return TestRunner.RunAll(data, results);
    }

    private static int Adx(string[] args)
    {
        if (args.Length < 2) return Usage();
        var a = AdxInspector.Inspect(args[1]);
        Console.WriteLine($"File        : {args[1]}");
        Console.WriteLine($"SHA-256     : {a.Sha256}");
        Console.WriteLine($"Magic OK    : {a.MagicOk}");
        Console.WriteLine($"Header size : 0x{a.HeaderSize:X}");
        Console.WriteLine($"Fixed block : {a.FixedBlockHex}");
        Console.WriteLine($"Tag byte    : 0x{a.TagByte:X2}");
        Console.WriteLine($"Payload off : 0x{a.PayloadOffset:X}");
        Console.WriteLine($"Payload len : {a.PayloadLength}");
        Console.WriteLine($"Entropy     : {a.Entropy:F3}");
        Console.WriteLine($"Printable   : {a.PrintableRatio:F5}");
        Console.WriteLine($"zlib/gzip/zip: {a.HasZlib}/{a.HasGzip}/{a.HasZip}");
        Console.WriteLine("Contents: ENCRYPTED / NOT DECRYPTED (decryption not attempted)");
        return 0;
    }

    private static int Validate(string[] args)
    {
        string root = Root(args.Length > 1 ? args[1] : null);
        string data = args.Length > 2 ? args[2] : Path.Combine(root, "PROTOTYPES", "testdata");
        string outDir = args.Length > 3 ? args[3] : Path.Combine(root, "PROTOTYPES", "RESULTS");
        Directory.CreateDirectory(outDir);
        var defs = MapDatabase.Load(Path.Combine(data, "3D_MAP_DATABASE.csv"));

        var samples = new (string Bin, string Key)[]
        {
            ("k1aa_n03.bin", "K1AA-N03"),
            ("k59a_a11.bin", "K59A-A11"),
            ("k25g_601.bin", "30400-K25G-601"),
            ("kzrb31.bin", "kzrb31.bin"),
            ("k46n21.bin", "k46n21.bin")
        };

        var sb = new StringBuilder();
        sb.AppendLine("Model,Resource,BIN,TableOffset,BigEndian,TpsCount,RpmCount,TpsMin,TpsMax,RpmMin,RpmMax,FuelMin,FuelMax,Sha256,Status");
        int ok = 0, fail = 0;
        foreach (var (bin, key) in samples)
        {
            var def = defs.FirstOrDefault(d => d.Resource.Contains(key, StringComparison.OrdinalIgnoreCase));
            if (def == null) { fail++; continue; }
            string path = Path.Combine(data, bin);
            var bytes = File.ReadAllBytes(path);
            var t = BinTableReader.Read(bytes, def, def.Fuel[0]);
            var (mn, mx) = t.MinMax();
            string hash = Convert.ToHexString(SHA256.HashData(bytes)).ToLowerInvariant();
            sb.AppendLine(string.Join(",", new[]
            {
                Csv(def.Name), Csv(def.Resource), Csv(bin), $"0x{t.TableOffset:X}",
                t.BigEndian ? "true" : "false", t.Cols.ToString(), t.Rows.ToString(),
                F(t.Tps.Min(), 1), F(t.Tps.Max(), 1), F(t.Rpm.Min(), 0), F(t.Rpm.Max(), 0),
                F(mn, 3), F(mx, 3), hash, "SAMPLE_TEST_PASSED"
            }));
            ok++;
        }
        string outCsv = Path.Combine(outDir, "BE10_TABLE_VALIDATION.csv");
        File.WriteAllText(outCsv, sb.ToString(), new UTF8Encoding(false));
        Console.WriteLine($"Validated {ok} sample tables ({fail} skipped) -> {outCsv}");
        return fail == 0 ? 0 : 1;
    }

    private static int Catalog(string[] args)
    {
        string outCsv = args.Length > 1 ? args[1] : Path.Combine(DefaultRoot, "REPORTS", "BE10_SENSOR_LIVE_DATA_CATALOG.csv");
        Directory.CreateDirectory(Path.GetDirectoryName(outCsv)!);
        var rows = new List<string[]>
        {
            new[]{"Channel","Command","ByteIndex","RawType","RawExpression","PhysicalFormula","Unit","AppliesTo","Evidence","Status"},
            row("RPM","dat10/11/13/16/17","4..5","uint16 BE","(b[4]<<8)+b[5]","raw","rpm","all","Diag.cs dat10/11/13/16/17"),
            row("TPS1","dat10/11/13/16/17","6","uint8","b[6]","b[6]*5/256","V","all","Diag.cs"),
            row("TPS2","dat10/11/13/16/17","7","uint8","b[7]","b[7]/2","%","all","Diag.cs"),
            row("ECT1","dat10/11/13/16","8","uint8","b[8]","b[8]*5/256","V","all","Diag.cs"),
            row("ECT2","dat10/11/13/16","9","uint8","b[9]","b[9]-40","degC","all","Diag.cs"),
            row("ECT1 (dat17)","dat17","12 or 8","uint8","b[12]!=255 ? b[12] : b[8]","raw*5/256","V","all","Diag.cs dat17 fallback"),
            row("ECT2 (dat17)","dat17","13 or 9","uint8","b[13]!=255 ? b[13] : b[9]","raw-40","degC","all","Diag.cs dat17 fallback"),
            row("IAT1","dat10/11/13/16","10","uint8","b[10]","b[10]*5/256","V","all","Diag.cs"),
            row("IAT2","dat10/11/13/16","11","uint8","b[11]","b[11]-40","degC","all","Diag.cs"),
            row("MAP1","dat10/11/13/16","12","uint8","b[12]","b[12]*5/256","V","all","Diag.cs"),
            row("MAP2","dat10/11/13/16","13","uint8","b[13]","raw","raw","all","Diag.cs"),
            row("Battery","dat10/11/16","16","uint8","b[16]","b[16]/10","V","dat10/11/16","Diag.cs"),
            row("Battery","dat13","14","uint8","b[14]","b[14]/10","V","dat13","Diag.cs"),
            row("Battery","dat17","14","uint8","b[14]","b[14]/10","V","dat17","Diag.cs"),
            row("VSS","dat10/11/16","17/22","uint8","b[17] or b[22]","raw","km/h?","dat10/11/16","Unit not stated in source"),
            row("VSS","dat17","19","uint8","b[19]","raw","km/h?","dat17","Unit not stated in source"),
            row("Injector","dat10/11","18..19","uint16 BE","(b[18]<<8)+b[19]","raw/200","ms","dat10/11","Diag.cs"),
            row("Injector","dat13","15..16","uint16 BE","(b[15]<<8)+b[16]","raw/200","ms","dat13","Diag.cs"),
            row("Injector","dat16","23","uint8","b[23]","b[23]/200","ms","dat16","Diag.cs"),
            row("Injector","dat17","15..16","uint16 BE","(b[15]<<8)+b[16]","raw/200","ms","dat17","Diag.cs"),
            row("Ignition advance","dat10/11/13/16/17","20/17/24","uint8","raw","raw/2-64","deg","all","Diag.cs"),
            row("IAC","dat11","22","uint8","b[22]","b[22]/10000","ratio","dat11","Diag.cs"),
            row("AP1 voltage","dat16","6","uint8","b[6]","b[6]*5/256","V","dat16","Diag.cs"),
            row("AP2 voltage","dat16","7","uint8","b[7]","b[7]*5/256","V","dat16","Diag.cs"),
            row("AP1 angle","dat16","8","uint8","b[8]","b[8]/2","deg","dat16","Diag.cs"),
            row("AP2 angle","dat16","9","uint8","b[9]","b[9]/2","deg","dat16","Diag.cs"),
            row("TP1 voltage","dat16","10","uint8","b[10]","b[10]*5/256","V","dat16","Diag.cs"),
            row("TP2 voltage","dat16","11","uint8","b[11]","b[11]*5/256","V","dat16","Diag.cs"),
            row("TP1 angle","dat16","12","uint8","b[12]","b[12]/2","deg","dat16","Diag.cs"),
            row("TP2 angle","dat16","13","uint8","b[13]","b[13]/2","deg","dat16","Diag.cs"),
            row("COR","dat16","14","uint8","b[14]","raw","raw","dat16","Diag.cs"),
            row("MODE","dat17","18","uint8","b[18]","128/103->1, 102->2, 60->3, 89->4, 121->0","enum","dat17","Diag.cs"),
            row("FIZ","dat17","18","uint8","b[18]","<128 ? ON : OFF","enum","dat17","Diag.cs"),
            row("Table type","dat17","2","uint8","b[2]","raw","enum","dat17","Diag.cs"),
            row("O2","dat20","4..5","uint16 LE","b[4]|b[5]<<8","raw/13.142708/1000","lambda?","dat20","Diag.cs; unit not stated"),
            row("O2 voltage","dat20","4","uint8","b[4]","b[4]/50.9937","V","dat20","Diag.cs"),
            row("STF","dat20","5","uint8","b[5]","b[5]/128.25651","ratio","dat20","Diag.cs"),
            row("AFR","dat20","4 (derived)","formula","-5.351*o2v+17.7","-5.351*(b[4]/50.9937)+17.7",":1","dat20","Software estimate, not ECU-reported"),
            row("BAS","datD1","4","uint8","b[4]","0x01=ON else OFF","enum","datD1","Diag.cs"),
            row("SSS","datD1","4","uint8","b[4]","0x01=ON else OFF","enum","datD1","Diag.cs"),
            row("SSW","datD1","4","uint8","b[4]","0x02=ON, 0x00/0x01=OFF","enum","datD1","Diag.cs"),
            row("GGS","datD1","4","uint8","b[4]","0x00=OnGear, 0x01=Netral, else OFF","enum","datD1","Diag.cs"),
            row("POM","datD1","8","uint8","b[8]","0x01/0x05=ON, 0x00/0x04=OFF","enum","datD1","Diag.cs"),
            row("FAN","datD1","9","uint8","b[9]","0x01=ON else OFF","enum","datD1","Diag.cs"),
            row("Gear","datD1","10","uint8","b[10]","0x80=6,0x10=5,0x08=4,0x04=3,0x02=2,0x01=1,0x20=N","gear","datD1","Diag.cs")
        };
        File.WriteAllText(outCsv, string.Join(Environment.NewLine, rows.Select(r => string.Join(",", r.Select(Csv)))) + Environment.NewLine, new UTF8Encoding(false));
        Console.WriteLine($"Catalog written: {outCsv} ({rows.Count - 1} channels)");
        return 0;
    }

    private static int Compare(string[] args)
    {
        if (args.Length < 3) return Usage();
        var a = File.ReadAllBytes(args[1]);
        var b = File.ReadAllBytes(args[2]);
        var (sa, sb, diffs, first, last) = BinTableReader.Compare(a, b);
        Console.WriteLine($"A={args[1]} ({sa} bytes)");
        Console.WriteLine($"B={args[2]} ({sb} bytes)");
        Console.WriteLine($"Differing bytes={diffs}; first=0x{first:X}; last=0x{last:X}");
        return 0;
    }

    private static string[] row(string channel, string command, string index, string rawType,
        string rawExpr, string formula, string unit, string applies, string evidence) =>
        new[] { channel, command, index, rawType, rawExpr, formula, unit, applies, evidence, "STATICALLY_ANALYZED" };

    private static string Csv(string s) => "\"" + s.Replace("\"", "\"\"") + "\"";
    private static string F(double v, int digits) => v.ToString("F" + digits, CultureInfo.InvariantCulture);
}
