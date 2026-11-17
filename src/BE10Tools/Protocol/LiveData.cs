namespace BE10Tools.Protocol;

public sealed record Dat10(
    int Rpm, double TpsVolt, double TpsPercent, double EctVolt, double EctC,
    double IatVolt, double IatC, double MapVolt, int MapRaw,
    double BatVolt, int Vss, double InjMs, double AdvDeg);

public sealed record Dat11(
    int Rpm, double TpsVolt, double TpsPercent, double EctVolt, double EctC,
    double IatVolt, double IatC, double MapVolt, int MapRaw,
    double BatVolt, int Vss, double InjMs, double AdvDeg, double Iac);

public sealed record Dat13(
    int Rpm, double TpsVolt, double TpsPercent, double EctVolt, double EctC,
    double IatVolt, double IatC, double MapVolt, int MapRaw,
    double BatVolt, double InjMs, double AdvDeg);

public sealed record Dat16(
    int Rpm, double Ap1Volt, double Ap2Volt, double Ap1Deg, double Ap2Deg,
    double Tp1Volt, double Tp2Volt, double Tp1Deg, double Tp2Deg,
    int Cor, double EctVolt, double EctC, double IatVolt, double IatC,
    double MapVolt, int MapRaw, double BatVolt, int Vss, double InjMs, double AdvDeg);

public sealed record Dat17(
    int Rpm, double TpsVolt, double TpsPercent, double EctVolt, double EctC,
    double BatVolt, double InjMs, double AdvDeg, int Mode, bool FizOn, int Vss, int TableType);

public sealed record Dat20(double O2, double O2Volt, double Stf, double Afr);

public sealed record DatD1(string Bas, string Sss, string Ssw, string Ggs, string Pom, string Fan, string Gear);

/// <summary>
/// Byte-level live-data decoders copied from Diag.cs. Input is the response
/// buffer as returned by SendCommand (index 0 is the response format byte).
/// Each accessor mirrors the exact offsets and scale factors in the source.
/// </summary>
public static class LiveData
{
    public static Dat10 DecodeDat10(byte[] b) => new(
        Rpm: (b[4] << 8) + b[5],
        TpsVolt: b[6] * 5.0 / 256.0,
        TpsPercent: b[7] / 2.0,
        EctVolt: b[8] * 5.0 / 256.0,
        EctC: b[9] - 40,
        IatVolt: b[10] * 5.0 / 256.0,
        IatC: b[11] - 40,
        MapVolt: b[12] * 5.0 / 256.0,
        MapRaw: b[13],
        BatVolt: b[16] / 10.0,
        Vss: b[17],
        InjMs: ((b[18] << 8) + b[19]) / 200.0,
        AdvDeg: b[20] / 2.0 - 64.0);

    public static Dat11 DecodeDat11(byte[] b) => new(
        (b[4] << 8) + b[5], b[6] * 5.0 / 256.0, b[7] / 2.0, b[8] * 5.0 / 256.0, b[9] - 40,
        b[10] * 5.0 / 256.0, b[11] - 40, b[12] * 5.0 / 256.0, b[13],
        b[16] / 10.0, b[17], ((b[18] << 8) + b[19]) / 200.0, b[20] / 2.0 - 64.0, b[22] / 10000.0);

    public static Dat13 DecodeDat13(byte[] b) => new(
        (b[4] << 8) + b[5], b[6] * 5.0 / 256.0, b[7] / 2.0, b[8] * 5.0 / 256.0, b[9] - 40,
        b[10] * 5.0 / 256.0, b[11] - 40, b[12] * 5.0 / 256.0, b[13],
        b[14] / 10.0, ((b[15] << 8) + b[16]) / 200.0, b[17] / 2.0 - 64.0);

    public static Dat16 DecodeDat16(byte[] b) => new(
        (b[4] << 8) + b[5],
        b[6] * 5.0 / 256.0, b[7] * 5.0 / 256.0, b[8] / 2.0, b[9] / 2.0,
        b[10] * 5.0 / 256.0, b[11] * 5.0 / 256.0, b[12] / 2.0, b[13] / 2.0,
        b[14], b[15] * 5.0 / 256.0, b[16] - 40, b[17] * 5.0 / 256.0, b[18] - 40,
        b[19] * 5.0 / 256.0, b[20], b[21] / 10.0, b[22], b[23] / 200.0, b[24] / 2.0 - 64.0);

    public static Dat17 DecodeDat17(byte[] b)
    {
        int md = b[18];
        int mode = md switch
        {
            128 or 103 => 1,
            102 => 2,
            60 => 3,
            89 => 4,
            121 => 0,
            _ => 0
        };
        return new Dat17(
            (b[4] << 8) + b[5], b[6] * 5.0 / 256.0, b[7] / 2.0,
            b[12] != 255 ? b[12] * 5.0 / 256.0 : b[8] * 5.0 / 256.0,
            b[13] != 255 ? b[13] - 40 : b[9] - 40,
            b[14] / 10.0, ((b[15] << 8) + b[16]) / 200.0, b[17] / 2.0 - 64.0,
            mode, md < 128, b[19], b[2]);
    }

    public static Dat20 DecodeDat20(byte[] b)
    {
        double o2 = BitConverter.ToUInt16(b, 4) / 13.142708 / 1000.0;
        double stf = b[5] / 128.25651;
        double o2v = b[4] / 50.9937;
        double afr = -5.351 * o2v + 17.7;
        return new Dat20(o2, o2v, stf, afr);
    }

    public static DatD1 DecodeDatD1(byte[] b)
    {
        string bas = "OFF", sss = "OFF", ssw = "OFF", ggs = "Netral", pom = "OFF", fan = "OFF", ggv = "OFF";
        switch (b[4])
        {
            case 0x01: bas = "ON"; ggs = "Netral"; ssw = "OFF"; sss = "ON"; break;
            case 0x02: ssw = "ON"; break;
            case 0x00: ggs = "OnGear"; ssw = "OFF"; sss = "OFF"; break;
            default: ssw = "OFF"; break;
        }
        switch (b[8])
        {
            case 0x00: pom = "OFF"; break;
            case 0x01:
            case 0x05: pom = "ON"; break;
            case 0x04: pom = "OFF"; break;
        }
        fan = b[9] == 0x01 ? "ON" : "OFF";
        ggv = b[10] switch
        {
            0x80 => "6",
            0x10 => "5",
            0x08 => "4",
            0x04 => "3",
            0x02 => "2",
            0x01 => "1",
            0x20 => "N",
            _ => "-"
        };
        return new DatD1(bas, sss, ssw, ggs, pom, fan, ggv);
    }
}
