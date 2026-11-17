using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.Json;

class PeScope
{
    static byte[] data = Array.Empty<byte>();
    static List<Sec> sections = new();

    class Sec { public string Name=""; public uint VA, VSize, RawPtr, RawSize, Flags; }

    static void Main(string[] args)
    {
        if (args.Length < 2) { Console.WriteLine("usage: PeScope <pefile> <outdir>"); return; }
        string path = args[0], outdir = args[1];
        Directory.CreateDirectory(outdir);
        data = File.ReadAllBytes(path);
        int e_lfanew = BitConverter.ToInt32(data, 0x3C);
        if (BitConverter.ToUInt32(data, e_lfanew) != 0x00004550) { Console.WriteLine("NOT_PE"); return; }
        int coff = e_lfanew + 4;
        ushort machine = U16(coff);
        ushort nsec = U16(coff + 2);
        uint ts = U32(coff + 4);
        ushort optSize = U16(coff + 16);
        ushort chars = U16(coff + 18);
        int opt = coff + 20;
        ushort magic = U16(opt);
        bool pe32plus = magic == 0x20B;
        uint entry = U32(opt + 16);
        ulong imageBase = pe32plus ? U64(opt + 24) : U32(opt + 28);
        uint sectAlign = U32(opt + 32), fileAlign = U32(opt + 36);
        uint sizeOfImage = U32(opt + 56), sizeOfHeaders = U32(opt + 60);
        ushort subsystem = U16(opt + 68);
        ushort dllChars = U16(opt + 70);
        int ddOff = opt + (pe32plus ? 112 : 96);
        int ndd = (int)U32(opt + (pe32plus ? 108 : 92));
        var dirs = new (uint rva, uint size)[16];
        for (int i = 0; i < Math.Min(ndd, 16); i++) dirs[i] = (U32(ddOff + i * 8), U32(ddOff + i * 8 + 4));

        int secOff = opt + optSize;
        for (int i = 0; i < nsec; i++)
        {
            int s = secOff + i * 40;
            var sec = new Sec {
                Name = Encoding.ASCII.GetString(data, s, 8).TrimEnd('\0'),
                VSize = U32(s + 8), VA = U32(s + 12), RawSize = U32(s + 16), RawPtr = U32(s + 20), Flags = U32(s + 36)
            };
            sections.Add(sec);
        }

        var result = new Dictionary<string, object?>
        {
            ["File"] = Path.GetFileName(path),
            ["Bytes"] = data.Length,
            ["Machine"] = $"0x{machine:X4}",
            ["MachineName"] = machine switch { 0x14c => "x86", 0x8664 => "x64", 0x1c0 => "ARM", _ => "other" },
            ["PE32Plus"] = pe32plus,
            ["Sections"] = nsec,
            ["TimeDateStamp"] = ts,
            ["TimeDateStampUtc"] = DateTimeOffset.FromUnixTimeSeconds(ts).UtcDateTime.ToString("yyyy-MM-dd HH:mm:ss"),
            ["Characteristics"] = $"0x{chars:X4}",
            ["DllCharacteristics"] = $"0x{dllChars:X4}",
            ["Subsystem"] = subsystem switch { 2 => "GUI", 3 => "CUI", _ => subsystem.ToString() },
            ["EntryPointRVA"] = $"0x{entry:X8}",
            ["ImageBase"] = $"0x{imageBase:X}",
            ["SectionAlignment"] = sectAlign,
            ["FileAlignment"] = fileAlign,
            ["SizeOfImage"] = sizeOfImage,
            ["SizeOfHeaders"] = sizeOfHeaders,
            ["OverlayBytes"] = OverlaySize(),
            ["HasCLR"] = dirs[14].rva != 0,
            ["AuthenticodeDir"] = new { Offset = dirs[4].rva, Size = dirs[4].size },
            ["DataDirectories"] = dirs.Select((d, i) => new { Index = i, RVA = $"0x{d.rva:X8}", Size = d.size }).ToArray(),
        };

        var secList = new List<object>();
        foreach (var s in sections)
        {
            secList.Add(new {
                s.Name, VA = $"0x{s.VA:X8}", VirtualSize = s.VSize,
                RawPointer = $"0x{s.RawPtr:X8}", RawSize = s.RawSize,
                Flags = $"0x{s.Flags:X8}",
                Entropy = Math.Round(Entropy(s.RawPtr, s.RawSize), 4)
            });
        }
        result["SectionTable"] = secList;

        try { result["Imports"] = ReadImports(dirs[1].rva); } catch (Exception ex) { result["ImportsError"] = ex.Message; }
        try { result["DelayImports"] = ReadDelayImports(dirs[13].rva); } catch (Exception ex) { result["DelayImportsError"] = ex.Message; }
        try { result["Exports"] = ReadExports(dirs[0].rva); } catch (Exception ex) { result["ExportsError"] = ex.Message; }
        try { result["Resources"] = ReadResources(dirs[2].rva); } catch (Exception ex) { result["ResourcesError"] = ex.Message; }

        string json = JsonSerializer.Serialize(result, new JsonSerializerOptions { WriteIndented = true });
        File.WriteAllText(Path.Combine(outdir, "PE_" + Path.GetFileName(path) + ".json"), json);

        var strings = ExtractStrings();
        using (var w = new StreamWriter(Path.Combine(outdir, "STRINGS_" + Path.GetFileName(path) + ".txt"), false, new UTF8Encoding(false)))
        {
            foreach (var s in strings) w.WriteLine($"0x{s.Offset:X8}\t{s.Kind}\t{s.Text}");
        }
        Console.WriteLine($"{Path.GetFileName(path)}: sections={nsec} imports={((List<object>)result["Imports"]!).Count} strings={strings.Count}");
    }

    static uint OverlaySize()
    {
        if (sections.Count == 0) return 0;
        uint end = 0;
        foreach (var s in sections) end = Math.Max(end, s.RawPtr + s.RawSize);
        return (uint)Math.Max(0, data.Length - end);
    }

    static double Entropy(uint off, uint len)
    {
        if (off == 0 || len == 0 || off >= data.Length) return 0;
        int n = (int)Math.Min(len, data.Length - off);
        var counts = new int[256];
        for (int i = 0; i < n; i++) counts[data[off + i]]++;
        double e = 0;
        for (int i = 0; i < 256; i++) if (counts[i] > 0) { double p = (double)counts[i] / n; e -= p * Math.Log2(p); }
        return e;
    }

    static int RvaToOff(uint rva)
    {
        foreach (var s in sections)
            if (rva >= s.VA && rva < s.VA + Math.Max(s.VSize, s.RawSize))
                return (int)(s.RawPtr + (rva - s.VA));
        return rva < data.Length ? (int)rva : -1;
    }

    static string CString(int off)
    {
        if (off < 0 || off >= data.Length) return "";
        int e = off; while (e < data.Length && data[e] != 0) e++;
        return Encoding.ASCII.GetString(data, off, e - off);
    }

    static List<object> ReadImports(uint rva)
    {
        var list = new List<object>();
        if (rva == 0) return list;
        int off = RvaToOff(rva);
        for (int i = 0; i < 512; i++)
        {
            int d = off + i * 20;
            uint oft = U32(d), nameRva = U32(d + 12), ft = U32(d + 16);
            if (oft == 0 && nameRva == 0 && ft == 0) break;
            string dll = CString(RvaToOff(nameRva));
            var fns = new List<string>();
            uint thunk = oft != 0 ? oft : ft;
            int to = RvaToOff(thunk);
            if (to >= 0)
            {
                for (int k = 0; k < 4096; k++)
                {
                    uint v = U32(to + k * 4);
                    if (v == 0) break;
                    if ((v & 0x80000000) != 0) fns.Add("#" + (v & 0xFFFF));
                    else
                    {
                        int hn = RvaToOff(v & 0x7FFFFFFF);
                        fns.Add(CString(hn + 2));
                    }
                }
            }
            list.Add(new { DLL = dll, Functions = fns });
        }
        return list;
    }

    static List<object> ReadDelayImports(uint rva)
    {
        var list = new List<object>();
        if (rva == 0) return list;
        int off = RvaToOff(rva);
        for (int i = 0; i < 256; i++)
        {
            int d = off + i * 32;
            uint attrs = U32(d), nameRva = U32(d + 4), mod = U32(d + 8), iat = U32(d + 12), intRva = U32(d + 16);
            if (nameRva == 0 && mod == 0) break;
            string dll = CString(RvaToOff(nameRva));
            var fns = new List<string>();
            uint thunk = intRva != 0 ? intRva : iat;
            int to = RvaToOff(thunk);
            if (to >= 0)
            {
                for (int k = 0; k < 4096; k++)
                {
                    uint v = U32(to + k * 4); if (v == 0) break;
                    if ((v & 0x80000000) != 0) fns.Add("#" + (v & 0xFFFF));
                    else fns.Add(CString(RvaToOff(v & 0x7FFFFFFF) + 2));
                }
            }
            list.Add(new { DLL = dll, Functions = fns });
        }
        return list;
    }

    static List<object> ReadExports(uint rva)
    {
        var list = new List<object>();
        if (rva == 0) return list;
        int off = RvaToOff(rva);
        string dllName = CString(RvaToOff(U32(off + 12)));
        uint numNames = U32(off + 24), namesRva = U32(off + 32);
        for (int i = 0; i < numNames && i < 4096; i++)
        {
            uint nr = U32(RvaToOff(namesRva) + i * 4);
            list.Add(new { DLL = dllName, Name = CString(RvaToOff(nr)) });
        }
        return list;
    }

    static List<object> ReadResources(uint rva)
    {
        var list = new List<object>();
        if (rva == 0) return list;
        int baseOff = RvaToOff(rva);
        WalkRes(baseOff, baseOff, 0, "", list);
        return list;
    }

    static void WalkRes(int baseOff, int dirOff, int level, string path, List<object> list)
    {
        if (level > 3 || dirOff + 16 > data.Length) return;
        int named = U16(dirOff + 12), ids = U16(dirOff + 14);
        for (int i = 0; i < named + ids && i < 512; i++)
        {
            int e = dirOff + 16 + i * 8;
            uint nameField = U32(e), dataField = U32(e + 4);
            string name;
            if ((nameField & 0x80000000) != 0)
            {
                int so = baseOff + (int)(nameField & 0x7FFFFFFF);
                int len = U16(so);
                name = Encoding.Unicode.GetString(data, so + 2, len * 2);
            }
            else
            {
                uint id = nameField;
                name = id switch { 1=>"CURSOR",2=>"BITMAP",3=>"ICON",4=>"MENU",5=>"DIALOG",6=>"STRING",9=>"ACCELERATOR",10=>"RCDATA",12=>"GROUP_CURSOR",14=>"GROUP_ICON",16=>"VERSION",24=>"MANIFEST", _=>"ID_"+id };
            }
            string p = level == 0 ? name : path + "/" + name;
            if ((dataField & 0x80000000) != 0)
                WalkRes(baseOff, baseOff + (int)(dataField & 0x7FFFFFFF), level + 1, p, list);
            else
            {
                int de = baseOff + (int)dataField;
                list.Add(new { Path = p, RVA = $"0x{U32(de):X8}", Size = U32(de + 4) });
            }
        }
    }

    static List<(int Offset, string Kind, string Text)> ExtractStrings()
    {
        var res = new List<(int, string, string)>();
        int n = data.Length;
        int i = 0;
        while (i < n - 5)
        {
            byte b = data[i];
            if (b >= 0x20 && b < 0x7F)
            {
                int j = i;
                while (j < n && data[j] >= 0x20 && data[j] < 0x7F) j++;
                if (j - i >= 5) res.Add((i, "A", Encoding.ASCII.GetString(data, i, j - i)));
                i = j;
            }
            else i++;
        }
        i = 0;
        while (i < n - 8)
        {
            if (data[i] >= 0x20 && data[i] < 0x7F && data[i + 1] == 0)
            {
                int j = i; var sb = new StringBuilder();
                while (j + 1 < n && data[j] >= 0x20 && data[j] < 0x7F && data[j + 1] == 0) { sb.Append((char)data[j]); j += 2; }
                if (sb.Length >= 4) res.Add((i, "W", sb.ToString()));
                i = j;
            }
            else i++;
        }
        return res;
    }

    static ushort U16(int o) => BitConverter.ToUInt16(data, o);
    static uint U32(int o) => BitConverter.ToUInt32(data, o);
    static ulong U64(int o) => BitConverter.ToUInt64(data, o);
}
