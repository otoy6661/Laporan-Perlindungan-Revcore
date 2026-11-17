using System.Linq;
﻿using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection.Metadata;
using System.Text;
using Microsoft.Diagnostics.Runtime;

class Program
{
    static int Main(string[] args)
    {
        if (args[0] == "il")
        {
            int ilPid = int.Parse(args[1]);
            string typeName = args[2];
            string outFile = args[3];
            using DataTarget dt2 = DataTarget.AttachToProcess(ilPid, false);
            ClrRuntime rt2 = dt2.ClrVersions[0].CreateRuntime();
            var sb = new StringBuilder();
            int count = 0, withIl = 0;
            foreach (ClrModule mod in rt2.EnumerateModules())
            {
                ClrType? t = null;
                try { t = mod.GetTypeByName(typeName); } catch { }
                if (t == null) continue;
                foreach (ClrMethod m in t.Methods)
                {
                    count++;
                    ILInfo info;
                    try { info = m.GetILInfo(); } catch { continue; }
                    if (info.Address == 0 || info.Length <= 0) continue;
                    withIl++;
                    byte[] il = new byte[info.Length];
                    int r = dt2.DataReader.Read(info.Address, il.AsSpan());
                    sb.AppendLine($"== {typeName}.{m.Name} len={info.Length} read={r} addr=0x{info.Address:X} flags=0x{info.Flags:X} ==");
                    sb.AppendLine(BitConverter.ToString(il).Replace("-", " "));
                }
            }
            File.WriteAllText(outFile, sb.ToString());
            Console.WriteLine($"methods={count} with_il={withIl} -> {outFile}");
            return 0;
        }
        if (args.Length < 2)
        {
            Console.Error.WriteLine("usage: ClrProbe <pid|metadata.bin> <outDir>");
            return 2;
        }
        if (args[0].EndsWith(".bin", StringComparison.OrdinalIgnoreCase))
        {
            byte[] raw = File.ReadAllBytes(args[0]);
            Directory.CreateDirectory(args[1]);
            File.WriteAllText(Path.Combine(args[1], "US_ONLY.txt"), ExtractUserStrings(raw));
            DumpMetadata(raw, args[1], 1);
            Console.WriteLine("parsed " + raw.Length + " bytes");
            return 0;
        }
        int pid = int.Parse(args[0]);
        string outDir = args[1];
        Directory.CreateDirectory(outDir);

        using DataTarget dt = DataTarget.AttachToProcess(pid, false);
        Console.WriteLine($"modules_in_target={dt.EnumerateModules().Count()}");
        foreach (ClrInfo info in dt.ClrVersions)
            Console.WriteLine($"clr_info version={info.Version} flavor={info.Flavor}");

        if (dt.ClrVersions.Length == 0) { Console.WriteLine("NO_CLR"); return 1; }
        ClrRuntime rt = dt.ClrVersions[0].CreateRuntime();
        Console.WriteLine($"appdomains={rt.AppDomains.Length}");

        var summary = new StringBuilder();
        int modIdx = 0;
        foreach (ClrAppDomain ad in rt.AppDomains)
        {
            summary.AppendLine($"AD id={ad.Id} name={ad.Name}");
            foreach (ClrModule m in ad.Modules)
            {
                summary.AppendLine($"  MOD[{modIdx}] name={m.Name} asm={m.AssemblyName} meta=0x{m.MetadataAddress:X} len={m.MetadataLength} imagebase=0x{m.ImageBase:X}");
                if (m.MetadataAddress != 0 && m.MetadataLength > 64)
                {
                    byte[] buf = new byte[m.MetadataLength];
                    int read = dt.DataReader.Read(m.MetadataAddress, buf.AsSpan());
                    summary.AppendLine($"    meta_read={read} sig={(buf.Length >= 4 ? Encoding.ASCII.GetString(buf, 0, 4) : "?")}");
                    if (read == buf.Length && buf[0] == (byte)'B' && buf[1] == (byte)'S' && buf[2] == (byte)'J' && buf[3] == (byte)'B')
                    {
                        string raw = Path.Combine(outDir, $"MOD_{modIdx}_metadata.bin");
                        File.WriteAllBytes(raw, buf);
                        try { DumpMetadata(buf, outDir, modIdx); }
                        catch (Exception ex) { summary.AppendLine("    meta_parse_error=" + ex.Message); }
                    }
                }
                modIdx++;
            }
        }
        File.WriteAllText(Path.Combine(outDir, "MODULES.txt"), summary.ToString());
        Console.WriteLine(summary.ToString());
        return 0;
    }

    static void DumpMetadata(byte[] buf, string outDir, int idx)
    {
        using var ms = new MemoryStream(buf, false);
        using var provider = MetadataReaderProvider.FromMetadataStream(ms, MetadataStreamOptions.LeaveOpen);
        MetadataReader r = provider.GetMetadataReader();

        var types = new StringBuilder();
        foreach (TypeDefinitionHandle h in r.TypeDefinitions)
        {
            TypeDefinition t = r.GetTypeDefinition(h);
            string ns = r.GetString(t.Namespace);
            string name = r.GetString(t.Name);
            types.AppendLine($"{ns}.{name}".TrimStart('.') + $"\tmethods={t.GetMethods().Count} fields={t.GetFields().Count}");
        }
        File.WriteAllText(Path.Combine(outDir, $"MOD_{idx}_types.txt"), types.ToString());

        var methods = new StringBuilder();
        foreach (MethodDefinitionHandle h in r.MethodDefinitions)
        {
            MethodDefinition md = r.GetMethodDefinition(h);
            methods.AppendLine(r.GetString(md.Name));
        }
        File.WriteAllText(Path.Combine(outDir, $"MOD_{idx}_methods.txt"), methods.ToString());

        var refs = new StringBuilder();
        foreach (MemberReferenceHandle h in r.MemberReferences)
        {
            MemberReference mr = r.GetMemberReference(h);
            string parent = "";
            switch (mr.Parent.Kind)
            {
                case HandleKind.TypeReference:
                    TypeReference tr = r.GetTypeReference((TypeReferenceHandle)mr.Parent);
                    parent = r.GetString(tr.Namespace) + "." + r.GetString(tr.Name);
                    break;
                case HandleKind.TypeDefinition:
                    TypeDefinition td = r.GetTypeDefinition((TypeDefinitionHandle)mr.Parent);
                    parent = r.GetString(td.Namespace) + "." + r.GetString(td.Name);
                    break;
                default: parent = mr.Parent.Kind.ToString(); break;
            }
            refs.AppendLine(parent + "::" + r.GetString(mr.Name));
        }
        File.WriteAllText(Path.Combine(outDir, $"MOD_{idx}_memberrefs.txt"), refs.ToString());

        var tyr = new StringBuilder();
        foreach (TypeReferenceHandle h in r.TypeReferences)
        {
            TypeReference tr = r.GetTypeReference(h);
            tyr.AppendLine(r.GetString(tr.Namespace) + "." + r.GetString(tr.Name));
        }
        File.WriteAllText(Path.Combine(outDir, $"MOD_{idx}_typerefs.txt"), tyr.ToString());

        File.WriteAllText(Path.Combine(outDir, $"MOD_{idx}_userstrings.txt"), ExtractUserStrings(buf));

        // methods grouped by type + literal constants
        var mt = new StringBuilder();
        var consts = new StringBuilder();
        foreach (TypeDefinitionHandle th in r.TypeDefinitions)
        {
            TypeDefinition t = r.GetTypeDefinition(th);
            string tn = (r.GetString(t.Namespace) + "." + r.GetString(t.Name)).TrimStart('.');
            foreach (MethodDefinitionHandle mh in t.GetMethods())
            {
                MethodDefinition md = r.GetMethodDefinition(mh);
                mt.AppendLine($"{tn}\t{r.GetString(md.Name)}\tparams={md.GetParameters().Count}");
            }
            foreach (FieldDefinitionHandle fh in t.GetFields())
            {
                FieldDefinition fd = r.GetFieldDefinition(fh);
                if ((fd.Attributes & System.Reflection.FieldAttributes.Literal) != 0)
                {
                    string val = "";
                    try
                    {
                        ConstantHandle ch = fd.GetDefaultValue();
                        if (!ch.IsNil)
                        {
                            Constant c = r.GetConstant(ch);
                            val = c.TypeCode + ":" + (c.Value.IsNil ? "" : r.GetBlobBytes(c.Value).Length <= 8
                                ? BitConverter.ToString(r.GetBlobBytes(c.Value)).Replace("-", "")
                                : "<blob>");
                        }
                    }
                    catch { }
                    consts.AppendLine($"{tn}\t{r.GetString(fd.Name)}\t{val}");
                }
            }
        }
        File.WriteAllText(Path.Combine(outDir, $"MOD_{idx}_methods_by_type.txt"), mt.ToString());
        File.WriteAllText(Path.Combine(outDir, $"MOD_{idx}_consts.txt"), consts.ToString());

        // fields with types
        var fields = new StringBuilder();
        foreach (TypeDefinitionHandle th in r.TypeDefinitions)
        {
            TypeDefinition t = r.GetTypeDefinition(th);
            string tn = (r.GetString(t.Namespace) + "." + r.GetString(t.Name)).TrimStart('.');
            foreach (FieldDefinitionHandle fh in t.GetFields())
            {
                FieldDefinition fd = r.GetFieldDefinition(fh);
                string sig = "";
                try { sig = fd.DecodeSignature(new SigProvider(), null); } catch { }
                fields.AppendLine($"{tn}\t{r.GetString(fd.Name)}\t{sig}");
            }
        }
        File.WriteAllText(Path.Combine(outDir, $"MOD_{idx}_fields.txt"), fields.ToString());

        // P/Invoke imports
        var pins = new StringBuilder();
        foreach (MethodDefinitionHandle mh in r.MethodDefinitions)
        {
            MethodDefinition md = r.GetMethodDefinition(mh);
            MethodImport imp = md.GetImport();
            if (imp.Module.IsNil) continue;
            string mod = r.GetString(r.GetModuleReference(imp.Module).Name);
            pins.AppendLine($"{mod}\t{r.GetString(imp.Name)}");
        }
        if (pins.Length == 0) pins.AppendLine("NO_PINVOKE");
        File.WriteAllText(Path.Combine(outDir, $"MOD_{idx}_pinvoke.txt"), pins.ToString());

        // manifest resources
        var res = new StringBuilder();
        foreach (ManifestResourceHandle rh in r.ManifestResources)
        {
            ManifestResource mr = r.GetManifestResource(rh);
            res.AppendLine($"{r.GetString(mr.Name)}\timplementation={(mr.Implementation.IsNil ? "embedded" : "linked")}");
        }
        if (res.Length == 0) res.AppendLine("NO_MANIFEST_RESOURCES");
        File.WriteAllText(Path.Combine(outDir, $"MOD_{idx}_resources.txt"), res.ToString());

        // assembly identity
        try
        {
            AssemblyDefinition ad = r.GetAssemblyDefinition();
            var sb = new StringBuilder();
            sb.AppendLine("name=" + r.GetString(ad.Name));
            sb.AppendLine("version=" + ad.Version);
            sb.AppendLine("culture=" + (ad.Culture.IsNil ? "" : r.GetString(ad.Culture)));
            sb.AppendLine("flags=" + ad.Flags);
            sb.AppendLine("hashalg=" + ad.HashAlgorithm);
            File.WriteAllText(Path.Combine(outDir, $"MOD_{idx}_assembly.txt"), sb.ToString());
        }
        catch { }
    }

    sealed class SigProvider : ISignatureTypeProvider<string, object>
    {
        public string GetArrayType(string e, ArrayShape s) => e + "[]";
        public string GetByReferenceType(string e) => e + "&";
        public string GetFunctionPointerType(MethodSignature<string> s) => "fnptr";
        public string GetGenericInstantiation(string g, System.Collections.Immutable.ImmutableArray<string> a) => g + "<" + string.Join(",", a) + ">";
        public string GetGenericMethodParameter(object c, int i) => "!!" + i;
        public string GetGenericTypeParameter(object c, int i) => "!" + i;
        public string GetModifiedType(string m, string u, bool r) => u;
        public string GetPinnedType(string e) => e;
        public string GetPointerType(string e) => e + "*";
        public string GetPrimitiveType(PrimitiveTypeCode t) => t.ToString();
        public string GetSZArrayType(string e) => e + "[]";
        public string GetTypeFromDefinition(MetadataReader r, TypeDefinitionHandle h, byte k)
        { var t = r.GetTypeDefinition(h); return (r.GetString(t.Namespace) + "." + r.GetString(t.Name)).TrimStart('.'); }
        public string GetTypeFromReference(MetadataReader r, TypeReferenceHandle h, byte k)
        { var t = r.GetTypeReference(h); return (r.GetString(t.Namespace) + "." + r.GetString(t.Name)).TrimStart('.'); }
        public string GetTypeFromSpecification(MetadataReader r, object c, TypeSpecificationHandle h, byte k)
            => r.GetTypeSpecification(h).DecodeSignature(this, c);
    }

    static string ExtractUserStrings(byte[] buf)
    {
        var sb = new StringBuilder();
        try
        {
            int p = 4 + 2 + 2 + 4 + 4; // signature, major, minor, reserved, versionLength
            int verLen = BitConverter.ToInt32(buf, 12);
            p += verLen;
            p += 2 + 2; // flags, stream count
            int streams = BitConverter.ToUInt16(buf, 14 + 4 + verLen + 2);
            int usOff = -1, usSize = 0;
            for (int s = 0; s < streams; s++)
            {
                int off = BitConverter.ToInt32(buf, p); p += 4;
                int size = BitConverter.ToInt32(buf, p); p += 4;
                int nameStart = p;
                while (buf[p] != 0) p++;
                string name = Encoding.ASCII.GetString(buf, nameStart, p - nameStart);
                p++;
                while ((p & 3) != 0) p++;
                if (name == "#US") { usOff = off; usSize = size; }
            }
            if (usOff < 0) return "NO_US_HEAP";
            int q = usOff;
            int end = usOff + usSize;
            while (q < end)
            {
                uint len = ReadCompressedUInt(buf, ref q);
                if (len == 0) continue;
                if (q + (int)len > end) break;
                int chars = (int)(len / 2);
                if (chars > 0)
                {
                    string val = Encoding.Unicode.GetString(buf, q, chars * 2);
                    sb.AppendLine(val);
                }
                q += (int)len;
            }
        }
        catch (Exception ex) { sb.AppendLine("US_PARSE_ERROR: " + ex.Message); }
        return sb.ToString();
    }

    static uint ReadCompressedUInt(byte[] b, ref int p)
    {
        byte b0 = b[p++];
        if ((b0 & 0x80) == 0) return b0;
        if ((b0 & 0x40) == 0) return (uint)(((b0 & 0x3F) << 8) | b[p++]);
        return (uint)(((b0 & 0x1F) << 24) | (b[p++] << 16) | (b[p++] << 8) | b[p++]);
    }
}
