using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using BE10Tools.Adx;
using BE10Tools.Formula;
using BE10Tools.Maps;
using BE10Tools.Protocol;

namespace BE10Tools.Tests;

public sealed record TestRecord(
    string Id, string Title, string Input, string Method,
    string Expected, string Actual, bool Pass,
    string HashBefore, string HashAfter, string Output, string Notes);

/// <summary>
/// Runs the BE-10 sample tests. Inputs are read-only copies under PROTOTYPES/testdata;
/// every record carries SHA-256 of its inputs before and after the run.
/// </summary>
public static class TestRunner
{
    private static string N(double v, int digits = 6) => v.ToString("F" + digits, CultureInfo.InvariantCulture);

    public static int RunAll(string dataDir, string resultsDir)
    {
        Directory.CreateDirectory(resultsDir);
        var files = Directory.GetFiles(dataDir).OrderBy(x => x, StringComparer.OrdinalIgnoreCase).ToArray();
        var before = HashFiles(files);
        var tests = new List<TestRecord>();
        string P(string name) => Path.Combine(dataDir, name);

        var mapDefs = MapDatabase.Load(P("3D_MAP_DATABASE.csv"));
        var keihinAdx = AdxInspector.Inspect(P("ADX KEIHIN BE.adx"));
        var shinAdx = AdxInspector.Inspect(P("ADX SHINDENGEN BE.adx"));
        var k1Bytes = File.ReadAllBytes(P("k1aa_n03.bin"));
        var k59Bytes = File.ReadAllBytes(P("k59a_a11.bin"));
        var k25Bytes = File.ReadAllBytes(P("k25g_601.bin"));
        var kzrBytes = File.ReadAllBytes(P("kzrb31.bin"));
        var k46Bytes = File.ReadAllBytes(P("k46n21.bin"));

        void Add(string id, string title, string input, string method, string expected,
                 Func<(bool pass, string actual, string output, string notes)> body, params string[] used)
        {
            var (pass, actual, output, notes) = body();
            tests.Add(new TestRecord(id, title, input, method, expected, actual, pass,
                JoinHashes(before, used), "", output, notes));
        }

        // ---------------- ADX ----------------
        Add("ADX-01", "ADX KEIHIN container structure",
            "ADX KEIHIN BE.adx", "Static inspection: magic, header boundary, fixed block, payload tag, entropy, signatures",
            "magic=05 22 97 00; header=0x83; payload=39891 bytes; tag=0x03; no zlib/gzip/zip; entropy>=7.9; printable consistent with random (0.33-0.42); 43-byte prefix equal to SHINDENGEN",
            () =>
            {
                bool magic = keihinAdx.MagicOk && keihinAdx.HeaderSize == 0x83 && keihinAdx.PayloadLength == 39891 && keihinAdx.TagByte == 0x03;
                bool prefix = keihinAdx.FixedBlockHex[..86] == shinAdx.FixedBlockHex[..86];
                bool comp = !keihinAdx.HasZlib && !keihinAdx.HasGzip && !keihinAdx.HasZip;
                bool pass = magic && prefix && comp && keihinAdx.Entropy >= 7.9
                            && keihinAdx.PrintableRatio is > 0.33 and < 0.42;
                string actual = $"magic={keihinAdx.MagicOk}; header=0x{keihinAdx.HeaderSize:X}; payload={keihinAdx.PayloadLength}; tag=0x{keihinAdx.TagByte:X2}; entropy={N(keihinAdx.Entropy, 3)}; printable={N(keihinAdx.PrintableRatio, 4)}; prefix43Equal={prefix}; zlib={keihinAdx.HasZlib}; gzip={keihinAdx.HasGzip}; zip={keihinAdx.HasZip}";
                return (pass, actual, $"SHA256={keihinAdx.Sha256}", "No decryption attempted; container only.");
            }, P("ADX KEIHIN BE.adx"), P("ADX SHINDENGEN BE.adx"));

        Add("ADX-02", "ADX SHINDENGEN container structure",
            "ADX SHINDENGEN BE.adx", "Static inspection of second ADX",
            "magic=true; header=0x83; payload=23472; tag=0x02; entropy>=7.9; no compression signatures",
            () =>
            {
                bool pass = shinAdx.MagicOk && shinAdx.HeaderSize == 0x83 && shinAdx.PayloadLength == 23472
                            && shinAdx.TagByte == 0x02 && shinAdx.Entropy >= 7.9
                            && !shinAdx.HasZlib && !shinAdx.HasGzip && !shinAdx.HasZip;
                string actual = $"magic={shinAdx.MagicOk}; header=0x{shinAdx.HeaderSize:X}; payload={shinAdx.PayloadLength}; tag=0x{shinAdx.TagByte:X2}; entropy={N(shinAdx.Entropy, 3)}";
                return (pass, actual, $"SHA256={shinAdx.Sha256}", "ADX tag byte differs from KEIHIN file.");
            }, P("ADX SHINDENGEN BE.adx"));

        Add("ADX-03", "ADX files are not modified",
            "both ADX files", "Compare SHA-256 recorded before and after all prototype work",
            "hashes identical before/after",
            () =>
            {
                bool pass = before[P("ADX KEIHIN BE.adx")] == Sha(P("ADX KEIHIN BE.adx"))
                         && before[P("ADX SHINDENGEN BE.adx")] == Sha(P("ADX SHINDENGEN BE.adx"));
                return (pass, pass ? "hashes unchanged" : "hash mismatch", "", "Read-only guarantee.");
            }, P("ADX KEIHIN BE.adx"), P("ADX SHINDENGEN BE.adx"));

        // ---------------- Databases ----------------
        Add("DB-01", "Map database parse",
            "3D_MAP_DATABASE.csv", "CSV parse into MapDefinition records",
            "152 models; K1AA-N03: cols=29 rows=35 tpsh=0x39BFE rpmh=0x39C38 feul1=0x3815E ig1=0x39CA1 limit1=0x39858 kon=1.0",
            () =>
            {
                var k = mapDefs.FirstOrDefault(x => x.Resource.Contains("K1AA-N03", StringComparison.OrdinalIgnoreCase));
                bool dims = k is { ColumnCount: 29, RowCount: 35, Tpsh: 0x39BFE, Rpmh: 0x39C38, Kon: 1.0 };
                bool offs = k != null && k.Fuel[0] == 0x3815E && k.Ignition[0] == 0x39CA1 && k.Limit[0] == 0x39858;
                bool pass = mapDefs.Count == 152 && dims && offs;
                string actual = $"count={mapDefs.Count}; K1AA={(k == null ? "missing" : $"cols={k.ColumnCount} rows={k.RowCount} tpsh=0x{k.Tpsh:X} rpmh=0x{k.Rpmh:X} feul1=0x{k.Fuel[0]:X} ig1=0x{k.Ignition[0]:X} limit1=0x{k.Limit[0]:X} kon={k.Kon}")}";
                return (pass, actual, "", "Offsets are file offsets, not ECU addresses.");
            }, P("3D_MAP_DATABASE.csv"));

        Add("DB-02", "ECU ID database parse",
            "3D_ECU_ID_DATABASE.csv", "CSV parse and family count",
            "169 rows: KEIHIN=97, SHINDENGEN=72; first KEIHIN 0101F30F11 / VERZA 150 (K18G-941) start=0x8000 ck=0",
            () =>
            {
                var rows = Csv.Read(P("3D_ECU_ID_DATABASE.csv"));
                var h = rows[0].Select(x => x.Trim().TrimStart('\uFEFF')).ToArray();
                int fam = Array.FindIndex(h, x => x.Equals("Family", StringComparison.OrdinalIgnoreCase));
                int ecm = Array.FindIndex(h, x => x.Equals("EcmId", StringComparison.OrdinalIgnoreCase));
                int part = Array.FindIndex(h, x => x.Equals("PartCode", StringComparison.OrdinalIgnoreCase));
                var data = rows.Skip(1).Where(r => r.Length > ecm).ToArray();
                int k = data.Count(r => r[fam].Equals("KEIHIN", StringComparison.OrdinalIgnoreCase));
                int s = data.Count(r => r[fam].Equals("SHINDENGEN", StringComparison.OrdinalIgnoreCase));
                bool pass = data.Length == 169 && k == 97 && s == 72 && data[0][ecm] == "0101F30F11" && data[0][part].Contains("K18G-941");
                string actual = $"rows={data.Length}; KEIHIN={k}; SHINDENGEN={s}; first={data[0][ecm]}/{data[0][part]}";
                return (pass, actual, "", "Some ChecksumOffset values are literal 'auto' (resolved at runtime by signature scan).");
            }, P("3D_ECU_ID_DATABASE.csv"));

        // ---------------- Table extraction ----------------
        MapTable Table(byte[] bytes, string key)
        {
            var def = mapDefs.First(x => x.Resource.Contains(key, StringComparison.OrdinalIgnoreCase));
            return BinTableReader.Read(bytes, def, def.Fuel[0]);
        }

        void TableTest(string id, string bin, string key, int cols, int rows, bool be,
                       double tps0, double tps1, double tpsN, double rpm0, double rpm1, double rpmN,
                       double first, double last, double min, double max)
        {
            Add(id, $"3D map parse {key}",
                Path.GetFileName(bin), "BinTableReader: TPS /10, RPM /kon, uint16 table /1000, endianness by table offset",
                $"cols={cols} rows={rows} BE={be}; TPS={tps0}/{tps1}/{tpsN}; RPM={rpm0}/{rpm1}/{rpmN}; fuel first={first} last={last} min={min} max={max}",
                () =>
                {
                    var t = Table(File.ReadAllBytes(bin), key);
                    var (mn, mx) = t.MinMax();
                    bool pass = t.Cols == cols && t.Rows == rows && t.BigEndian == be
                        && Math.Abs(t.Tps[0] - tps0) < 1e-9 && Math.Abs(t.Tps[1] - tps1) < 1e-9 && Math.Abs(t.Tps[^1] - tpsN) < 1e-9
                        && Math.Abs(t.Rpm[0] - rpm0) < 1e-9 && Math.Abs(t.Rpm[1] - rpm1) < 1e-9 && Math.Abs(t.Rpm[^1] - rpmN) < 1e-9
                        && Math.Abs(t.Values[0, 0] - first) < 1e-9 && Math.Abs(t.Values[rows - 1, cols - 1] - last) < 1e-9
                        && Math.Abs(mn - min) < 1e-9 && Math.Abs(mx - max) < 1e-9;
                    string actual = $"cols={t.Cols} rows={t.Rows} BE={t.BigEndian}; TPS={N(t.Tps[0], 1)}/{N(t.Tps[1], 1)}/{N(t.Tps[^1], 1)}; RPM={N(t.Rpm[0], 0)}/{N(t.Rpm[1], 0)}/{N(t.Rpm[^1], 0)}; fuel first={N(t.Values[0, 0], 3)} last={N(t.Values[rows - 1, cols - 1], 3)} min={N(mn, 3)} max={N(mx, 3)}";
                    return (pass, actual, $"tableOffset=0x{t.TableOffset:X}", "");
                }, bin);
        }

        TableTest("MAP-01", P("k1aa_n03.bin"), "K1AA-N03", 29, 35, false, 0, 0.4, 74.3, 900, 1200, 9200, 3.880, 10.149, 0.464, 12.584);
        TableTest("MAP-02", P("k59a_a11.bin"), "K59A-A11", 25, 29, false, 0, 0.4, 74.3, 900, 1100, 9600, 0.885, 2.359, 0.174, 3.381);
        TableTest("MAP-03", P("k25g_601.bin"), "30400-K25G-601", 25, 29, false, 0, 0.4, 74.3, 1000, 1200, 9500, 1.261, 3.026, 0.141, 3.821);
        TableTest("MAP-04", P("kzrb31.bin"), "kzrb31.bin", 25, 29, false, 0, 0.5, 74.3, 900, 1100, 9850, 1.261, 2.619, 0.066, 3.587);
        TableTest("MAP-05", P("k46n21.bin"), "k46n21.bin", 25, 29, true, 0, 0.4, 74.3, 1000, 1200, 9500, 3.363, 8.069, 0.376, 10.190);

        // ---------------- Checksums / security ----------------
        Add("CK-01", "Honda frame checksum vectors",
            "synthetic byte vectors", "ChecksumHonda = (sum ^ 0xFF) + 1; BuildFrame; ParseFrames",
            "72 05 71 10 -> 08; 72 05 71 20 -> F8; 7D 06 01 01 03 -> 78; FE 04 72 -> 8C; built frame 72 05 71 10 08",
            () =>
            {
                byte c1 = HondaProtocol.ChecksumHonda(new byte[] { 0x72, 0x05, 0x71, 0x10 });
                byte c2 = HondaProtocol.ChecksumHonda(new byte[] { 0x72, 0x05, 0x71, 0x20 });
                byte c3 = HondaProtocol.ChecksumHonda(new byte[] { 0x7D, 0x06, 0x01, 0x01, 0x03 });
                byte c4 = HondaProtocol.ChecksumHonda(new byte[] { 0xFE, 0x04, 0x72 });
                var frame = HondaProtocol.BuildFrame(0x72, new byte[] { 0x71, 0x10 });
                bool pass = c1 == 0x08 && c2 == 0xF8 && c3 == 0x78 && c4 == 0x8C && Convert.ToHexString(frame) == "7205711008";
                return (pass, $"c1=0x{c1:X2} c2=0x{c2:X2} c3=0x{c3:X2} c4=0x{c4:X2} frame={Convert.ToHexString(frame)}", "", "");
            });

        Add("CK-02", "Keihin 8-bit sum complement",
            "synthetic bytes 01..0A", "KeihinChecksum(offset=0) and (offset=5); verify total sum == 0 mod 256 after write",
            "offset0=CA; offset5=CF; post-write byte sums 0",
            () =>
            {
                var d0 = Enumerable.Range(1, 10).Select(i => (byte)i).ToArray();
                byte c0 = HondaProtocol.KeihinChecksum(d0, 0);
                d0[0] = c0;
                int sum0 = d0.Sum(x => x) & 0xFF;
                var d5 = Enumerable.Range(1, 10).Select(i => (byte)i).ToArray();
                byte c5 = HondaProtocol.KeihinChecksum(d5, 5);
                d5[5] = c5;
                int sum5 = d5.Sum(x => x) & 0xFF;
                bool pass = c0 == 0xCA && c5 == 0xCF && sum0 == 0 && sum5 == 0;
                return (pass, $"offset0=0x{c0:X2} sum={sum0}; offset5=0x{c5:X2} sum={sum5}", "", "Matches Form1.cs KeihinAutoChecksum.");
            });

        Add("CK-03", "Shindengen 32-bit sum complement",
            "synthetic 32-byte buffer, bytes 0..31, checksum field 12..15 zeroed, num=16",
            "ShindengenChecksum + Apply; verify sum32(all 32 bytes)==0",
            "checksum=0x868D949C; post-write sum32=0",
            () =>
            {
                var d = Enumerable.Range(0, 32).Select(i => (byte)i).ToArray();
                Array.Clear(d, 12, 4);
                uint ck = HondaProtocol.ShindengenChecksum(d, 16);
                HondaProtocol.ApplyShindengenChecksum(d, 16);
                uint sum = HondaProtocol.Sum32(d, 0, 32);
                bool pass = ck == 0x868D949C && sum == 0;
                return (pass, $"checksum=0x{ck:X8}; sum32=0x{sum:X8}", "", "num is the D0 07 marker offset; field at num-4.");
            });

        Add("SK-01", "Shindengen seed/key arithmetic",
            "seed=0x1234, c0=0x0102, c1=0x0003, c2=0x0011",
            "key = c1*(seed+c0) + (c2>0 ? seed%c2 : seed), 16-bit truncation",
            "0x39A4 (high 39, low A4)",
            () =>
            {
                ushort key = HondaProtocol.ShindengenKey(0x1234, 0x0102, 0x0003, 0x0011);
                var (hi, lo) = HondaProtocol.ShindengenKeyBytes(key);
                bool pass = key == 0x39A4 && hi == 0x39 && lo == 0xA4;
                return (pass, $"key=0x{key:X4} high=0x{hi:X2} low=0x{lo:X2}", "", "No ECU contacted.");
            });

        // ---------------- Live data ----------------
        byte[] Buf(int size) => new byte[size];
        Add("LD-01", "dat10 live decode",
            "synthetic 21-byte response", "LiveData.DecodeDat10 exact source offsets",
            "RPM=3600; TPS=2.5V/50%; ECT=1.953125V/50C; IAT=1.953125V/0C; MAP=1.953125V/50; BAT=12.0V; VSS=60; INJ=5.0ms; ADV=0deg",
            () =>
            {
                var b = Buf(24);
                b[4] = 0x0E; b[5] = 0x10; b[6] = 128; b[7] = 100; b[8] = 100; b[9] = 90;
                b[10] = 100; b[11] = 40; b[12] = 100; b[13] = 50; b[16] = 120; b[17] = 60;
                b[18] = 0x03; b[19] = 0xE8; b[20] = 128;
                var d = LiveData.DecodeDat10(b);
                bool pass = d.Rpm == 3600 && d.TpsVolt == 2.5 && d.TpsPercent == 50 && d.EctVolt == 1.953125
                    && d.EctC == 50 && d.IatVolt == 1.953125 && d.IatC == 0 && d.MapVolt == 1.953125
                    && d.MapRaw == 50 && d.BatVolt == 12.0 && d.Vss == 60 && d.InjMs == 5.0 && d.AdvDeg == 0;
                return (pass, $"RPM={d.Rpm}; TPS={N(d.TpsVolt)}V/{N(d.TpsPercent)}%; ECT={N(d.EctVolt)}V/{d.EctC}C; IAT={N(d.IatVolt)}V/{d.IatC}C; MAP={N(d.MapVolt)}V/{d.MapRaw}; BAT={N(d.BatVolt)}V; VSS={d.Vss}; INJ={N(d.InjMs)}ms; ADV={N(d.AdvDeg)}", "", "");
            });

        Add("LD-02", "dat13 live decode (compact layout)",
            "synthetic 18-byte response", "LiveData.DecodeDat13: BAT@14, INJ@15-16, ADV@17",
            "BAT=12.0V; INJ=1.0ms; ADV=0deg",
            () =>
            {
                var b = Buf(20);
                b[4] = 0x03; b[5] = 0x84; b[6] = 100; b[7] = 80; b[8] = 100; b[9] = 90;
                b[10] = 100; b[11] = 40; b[12] = 100; b[13] = 50; b[14] = 120;
                b[15] = 0; b[16] = 200; b[17] = 128;
                var d = LiveData.DecodeDat13(b);
                bool pass = d.Rpm == 900 && d.BatVolt == 12.0 && d.InjMs == 1.0 && d.AdvDeg == 0;
                return (pass, $"RPM={d.Rpm}; BAT={N(d.BatVolt)}V; INJ={N(d.InjMs)}ms; ADV={N(d.AdvDeg)}", "", "");
            });

        Add("LD-03", "dat16 live decode (dual sensors)",
            "synthetic 25-byte response", "LiveData.DecodeDat16 exact source offsets",
            "RPM=3600; AP1=5.0V AP2=2.5V; TP1=30deg TP2=20deg; COR=7; ECT=2.5V/50C; IAT=2.5V/0C; MAP=2.5V/99; BAT=12V; VSS=60; INJ=1.0ms; ADV=0",
            () =>
            {
                var b = Buf(28);
                b[4] = 0x0E; b[5] = 0x10; b[6] = 255; b[7] = 128; b[8] = 90; b[9] = 100;
                b[10] = 255; b[11] = 0; b[12] = 60; b[13] = 40; b[14] = 7;
                b[15] = 128; b[16] = 90; b[17] = 128; b[18] = 40; b[19] = 128; b[20] = 99;
                b[21] = 120; b[22] = 60; b[23] = 200; b[24] = 128;
                var d = LiveData.DecodeDat16(b);
                bool pass = d.Rpm == 3600 && Math.Abs(d.Ap1Volt - 4.980469) < 0.001 && d.Ap2Volt == 2.5
                    && d.Tp1Deg == 30 && d.Tp2Deg == 20 && d.Cor == 7 && d.EctVolt == 2.5 && d.EctC == 50
                    && d.IatVolt == 2.5 && d.IatC == 0 && d.MapVolt == 2.5 && d.MapRaw == 99
                    && d.BatVolt == 12 && d.Vss == 60 && d.InjMs == 1.0 && d.AdvDeg == 0;
                return (pass, $"RPM={d.Rpm}; AP1={N(d.Ap1Volt)}V AP2={N(d.Ap2Volt)}V; TP1={N(d.Tp1Deg)} TP2={N(d.Tp2Deg)}; COR={d.Cor}; ECT={N(d.EctVolt)}/{d.EctC}; IAT={N(d.IatVolt)}/{d.IatC}; MAP={N(d.MapVolt)}/{d.MapRaw}; BAT={N(d.BatVolt)}; VSS={d.Vss}; INJ={N(d.InjMs)}; ADV={N(d.AdvDeg)}", "", "");
            });

        Add("LD-04", "dat17 mode/table decode",
            "synthetic 20-byte response", "LiveData.DecodeDat17: ECT fallback when 0xFF, MODE map, FIZ flag",
            "RPM=1500; TPS=2.5V/50%; ECT=2.5V/50C; MODE=1; FIZ=ON; tableType=2; VSS=60",
            () =>
            {
                var b = Buf(22);
                b[2] = 2; b[4] = 0x05; b[5] = 0xDC; b[6] = 128; b[7] = 100;
                b[8] = 128; b[9] = 90; b[12] = 255; b[13] = 90; b[14] = 120;
                b[15] = 0; b[16] = 200; b[17] = 128; b[18] = 103; b[19] = 60;
                var d = LiveData.DecodeDat17(b);
                bool pass = d.Rpm == 1500 && d.TpsVolt == 2.5 && d.EctVolt == 2.5 && d.EctC == 50
                    && d.Mode == 1 && d.FizOn && d.TableType == 2 && d.Vss == 60;
                return (pass, $"RPM={d.Rpm}; TPS={N(d.TpsVolt)}/{N(d.TpsPercent)}; ECT={N(d.EctVolt)}/{d.EctC}; MODE={d.Mode}; FIZ={d.FizOn}; tableType={d.TableType}; VSS={d.Vss}", "", "");
            });

        Add("LD-05", "dat20 AFR formula",
            "b[4]=64, b[5]=128", "LiveData.DecodeDat20: O2, O2V, STF, AFR",
            "O2=2.498115; O2V=1.255057; STF=0.998000; AFR=10.984190",
            () =>
            {
                var b = Buf(8); b[4] = 64; b[5] = 128;
                var d = LiveData.DecodeDat20(b);
                bool pass = Math.Abs(d.O2 - 2.498115) < 1e-5 && Math.Abs(d.O2Volt - 1.255057) < 1e-5
                    && Math.Abs(d.Stf - 0.998000) < 1e-5 && Math.Abs(d.Afr - 10.984190) < 1e-5;
                return (pass, $"O2={N(d.O2)}; O2V={N(d.O2Volt)}; STF={N(d.Stf)}; AFR={N(d.Afr)}", "", "AFR is a software estimate, not an ECU-reported value.");
            });

        Add("LD-06", "datD1 status decode",
            "synthetic 11-byte response", "LiveData.DecodeDatD1 switch mapping",
            "b4=01: BAS=ON, SSS=ON, SSW=OFF, GGS=Netral; b8=05: POM=ON; b9=01: FAN=ON; b10=80: gear 6",
            () =>
            {
                var b = Buf(12); b[4] = 0x01; b[8] = 0x05; b[9] = 0x01; b[10] = 0x80;
                var d = LiveData.DecodeDatD1(b);
                bool pass = d.Bas == "ON" && d.Sss == "ON" && d.Ssw == "OFF" && d.Ggs == "Netral"
                    && d.Pom == "ON" && d.Fan == "ON" && d.Gear == "6";
                return (pass, $"BAS={d.Bas} SSS={d.Sss} SSW={d.Ssw} GGS={d.Ggs} POM={d.Pom} FAN={d.Fan} GEAR={d.Gear}", "", "");
            });

        // ---------------- Formula engine ----------------
        Add("FX-01", "Formula evaluator",
            "expressions x*5/256; -5.351*x+17.7; (a+b)*2", "SimpleFormula shunting-yard evaluator",
            "x=128 -> 2.5; x=1.25505699723691 -> 10.984190; a=1,b=2 -> 6",
            () =>
            {
                double v1 = SimpleFormula.Evaluate("x*5/256", new Dictionary<string, double> { ["x"] = 128 });
                double v2 = SimpleFormula.Evaluate("-5.351*x+17.7", new Dictionary<string, double> { ["x"] = 1.25505699723691 });
                double v3 = SimpleFormula.Evaluate("(a+b)*2", new Dictionary<string, double> { ["a"] = 1, ["b"] = 2 });
                bool pass = v1 == 2.5 && Math.Abs(v2 - 10.984190) < 1e-5 && v3 == 6.0;
                return (pass, $"v1={N(v1)}; v2={N(v2)}; v3={N(v3)}", "", "");
            });

        // ---------------- Interpolation ----------------
        Add("IN-01", "Bilinear interpolation and clamping",
            "xs=[0,10], ys=[0,100], z={{0,10},{20,30}}", "Interpolation.Bilinear + NearestIndex",
            "(5,50)=15; (0,0)=0; (20,200)=30 clamped; nearest x=7 -> index 1",
            () =>
            {
                var xs = new[] { 0.0, 10.0 };
                var ys = new[] { 0.0, 100.0 };
                var z = new double[,] { { 0, 10 }, { 20, 30 } };
                double c = Interpolation.Bilinear(xs, ys, z, 5, 50);
                double corner = Interpolation.Bilinear(xs, ys, z, 0, 0);
                double clamp = Interpolation.Bilinear(xs, ys, z, 20, 200);
                int nearest = Interpolation.NearestIndex(xs, 7);
                bool pass = Math.Abs(c - 15) < 1e-12 && corner == 0 && Math.Abs(clamp - 30) < 1e-12 && nearest == 1;
                return (pass, $"center={N(c)}; corner={N(corner)}; clamped={N(clamp)}; nearestIndex={nearest}", "", "Interpolation is an addition; the source only uses nearest-point pointer logic.");
            });

        // ---------------- Editing / export / compare ----------------
        Add("ED-01", "Table edit round-trip on a copy",
            "k1aa_n03.bin (copied to RESULTS/work_k1aa.bin)", "Copy, WriteRaw(feul1,row0,col0,5000), reload, re-read",
            "reloaded value=5.000; bytes at 0x3815E = 13 88; source SHA-256 unchanged",
            () =>
            {
                string work = Path.Combine(resultsDir, "work_k1aa.bin");
                File.Copy(P("k1aa_n03.bin"), work, overwrite: true);
                var def = mapDefs.First(x => x.Resource.Contains("K1AA-N03"));
                var buf = File.ReadAllBytes(work);
                BinTableReader.WriteRaw(buf, def.Fuel[0], def.ColumnCount, 0, 0, 5000);
                File.WriteAllBytes(work, buf);
                var re = BinTableReader.Read(File.ReadAllBytes(work), def, def.Fuel[0]);
                ushort raw = BinTableReader.ReadRaw(File.ReadAllBytes(work), def.Fuel[0], def.ColumnCount, 0, 0);
                bool little = buf[def.Fuel[0]] == 0x88 && buf[def.Fuel[0] + 1] == 0x13;
                bool pass = raw == 5000 && Math.Abs(re.Values[0, 0] - 5.0) < 1e-12 && little
                    && before[P("k1aa_n03.bin")] == Sha(P("k1aa_n03.bin"));
                return (pass, $"value={N(re.Values[0, 0], 3)}; raw=0x{raw:X4}; bytes={buf[def.Fuel[0]]:X2} {buf[def.Fuel[0] + 1]:X2}; sourceHashUnchanged={before[P("k1aa_n03.bin")] == Sha(P("k1aa_n03.bin"))}", $"work file: {work}", "Only the copy is written.");
            }, P("k1aa_n03.bin"));

        Add("EX-01", "3D graph export and re-import",
            "k1aa_n03.bin", "ExportCsv(fuel map) then ReadExportedCsv",
            "35 data rows x 29 data columns; first=3.880; last=10.149",
            () =>
            {
                var def = mapDefs.First(x => x.Resource.Contains("K1AA-N03"));
                var t = BinTableReader.Read(File.ReadAllBytes(P("k1aa_n03.bin")), def, def.Fuel[0]);
                string path = Path.Combine(resultsDir, "BE10_K1AA_FUEL_GRAPH.csv");
                BinTableReader.ExportCsv(t, path);
                var (rows, cols, first, last) = BinTableReader.ReadExportedCsv(path);
                bool pass = rows == 35 && cols == 29 && Math.Abs(first - 3.880) < 1e-9 && Math.Abs(last - 10.149) < 1e-9;
                return (pass, $"rows={rows} cols={cols} first={N(first, 3)} last={N(last, 3)}", $"export: {path}", "");
            }, P("k1aa_n03.bin"));

        Add("CP-01", "BIN comparison",
            "k59a_a11.bin vs kzrb31.bin", "BinTableReader.Compare byte scan",
            "both 393216 bytes; 131901 differing bytes; first diff 0; last diff 196495",
            () =>
            {
                var (sa, sb, diffs, first, last) = BinTableReader.Compare(File.ReadAllBytes(P("k59a_a11.bin")), File.ReadAllBytes(P("kzrb31.bin")));
                bool pass = sa == 393216 && sb == 393216 && diffs == 131901 && first == 0 && last == 196495;
                return (pass, $"sizes={sa}/{sb}; diffs={diffs}; first={first}; last={last}", "", "");
            }, P("k59a_a11.bin"), P("kzrb31.bin"));

        Add("FR-01", "Frame stream parser",
            "two concatenated frames, second checksum corrupted", "HondaProtocol.ParseFrames",
            "2 frames; first valid; second invalid; format/length preserved",
            () =>
            {
                var f1 = HondaProtocol.BuildFrame(0x72, new byte[] { 0x71, 0x10 });
                var f2 = HondaProtocol.BuildFrame(0x72, new byte[] { 0x71, 0x20 });
                f2[^1] ^= 0xFF;
                var stream = f1.Concat(f2).ToArray();
                var frames = HondaProtocol.ParseFrames(stream);
                bool pass = frames.Count == 2 && frames[0].ChecksumOk && !frames[1].ChecksumOk
                    && frames[0].Format == 0x72 && frames[0].Data.Length == 2 && frames[0].LengthByte == 5;
                return (pass, $"frames={frames.Count}; ok1={frames[0].ChecksumOk}; ok2={frames[1].ChecksumOk}; format=0x{frames[0].Format:X2}; len={frames[0].Data.Length}", "", "");
            });

        // ---------------- finalize ----------------
        var after = HashFiles(files);
        for (int i = 0; i < tests.Count; i++)
            tests[i] = tests[i] with { HashAfter = tests[i].HashAfter.Replace("__AFTER__", "") };

        // Fill per-test after-hashes by recomputing the used files from the record's before string.
        var finalTests = tests.Select(t =>
        {
            var afterHashes = t.HashBefore.Split("; ", StringSplitOptions.RemoveEmptyEntries)
                .Select(part =>
                {
                    int eq = part.IndexOf('=');
                    string name = eq > 0 ? part[..eq] : part;
                    string path = files.FirstOrDefault(f => Path.GetFileName(f) == name) ?? P(name);
                    return $"{name}={Sha(path)}";
                });
            return t with { HashAfter = string.Join("; ", afterHashes) };
        }).ToList();

        WriteCsv(Path.Combine(resultsDir, "BE10_PROTOTYPE_TESTS.csv"), finalTests);
        WriteTxt(Path.Combine(resultsDir, "SELFTEST.txt"), finalTests, before, after);

        int failed = finalTests.Count(t => !t.Pass);
        Console.WriteLine($"SELFTEST: {finalTests.Count - failed}/{finalTests.Count} passed, {failed} failed.");
        Console.WriteLine($"Results: {resultsDir}");
        return failed == 0 ? 0 : 1;
    }

    private static string Sha(string path)
    {
        using var sha = SHA256.Create();
        return Convert.ToHexString(sha.ComputeHash(File.ReadAllBytes(path))).ToLowerInvariant();
    }

    private static Dictionary<string, string> HashFiles(IEnumerable<string> files) =>
        files.ToDictionary(f => f, Sha);

    private static string JoinHashes(IReadOnlyDictionary<string, string> hashes, IEnumerable<string> files) =>
        string.Join("; ", files.Select(f => $"{Path.GetFileName(f)}={hashes[f]}"));

    private static string Q(string s) => "\"" + s.Replace("\"", "\"\"") + "\"";

    private static void WriteCsv(string path, List<TestRecord> tests)
    {
        var sb = new StringBuilder();
        sb.AppendLine("ID,Title,Input,Method,Expected,Actual,Status,HashBefore,HashAfter,Output,Notes");
        foreach (var t in tests)
        {
            sb.AppendLine(string.Join(",", new[]
            {
                Q(t.Id), Q(t.Title), Q(t.Input), Q(t.Method), Q(t.Expected), Q(t.Actual),
                Q(t.Pass ? "SAMPLE_TEST_PASSED" : "SAMPLE_TEST_FAILED"),
                Q(t.HashBefore), Q(t.HashAfter), Q(t.Output), Q(t.Notes)
            }));
        }
        File.WriteAllText(path, sb.ToString(), new UTF8Encoding(false));
    }

    private static void WriteTxt(string path, List<TestRecord> tests,
        IReadOnlyDictionary<string, string> before, IReadOnlyDictionary<string, string> after)
    {
        var sb = new StringBuilder();
        sb.AppendLine("BE-10 PROTOTYPE SELFTEST");
        sb.AppendLine("========================");
        sb.AppendLine($"Timestamp: {DateTime.Now:yyyy-MM-dd HH:mm:ss}");
        sb.AppendLine($"Tests: {tests.Count}; passed: {tests.Count(t => t.Pass)}; failed: {tests.Count(t => !t.Pass)}");
        sb.AppendLine();
        foreach (var t in tests)
        {
            sb.AppendLine($"[{(t.Pass ? "PASS" : "FAIL")}] {t.Id} — {t.Title}");
            sb.AppendLine($"  Input    : {t.Input}");
            sb.AppendLine($"  Method   : {t.Method}");
            sb.AppendLine($"  Expected : {t.Expected}");
            sb.AppendLine($"  Actual   : {t.Actual}");
            sb.AppendLine($"  HashBefore: {t.HashBefore}");
            sb.AppendLine($"  HashAfter : {t.HashAfter}");
            if (t.Output.Length > 0) sb.AppendLine($"  Output   : {t.Output}");
            if (t.Notes.Length > 0) sb.AppendLine($"  Notes    : {t.Notes}");
            sb.AppendLine();
        }
        sb.AppendLine("INPUT HASH STABILITY");
        foreach (var kv in before)
        {
            bool same = after.TryGetValue(kv.Key, out var a) && a == kv.Value;
            sb.AppendLine($"{(same ? "UNCHANGED" : "CHANGED")} {Path.GetFileName(kv.Key)} {kv.Value}");
        }
        File.WriteAllText(path, sb.ToString(), new UTF8Encoding(false));
    }
}
