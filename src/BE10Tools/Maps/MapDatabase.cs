using System.Globalization;
using System.Text;

namespace BE10Tools.Maps;

/// <summary>
/// One row of the model/map database extracted from the 3D Chart Graph
/// combo-box handler (Form1.cs). Offsets are file offsets inside the BIN.
/// </summary>
public sealed class MapDefinition
{
    public string Index { get; init; } = "";
    public string Name { get; init; } = "";
    public string Resource { get; init; } = "";
    public int ColumnCount { get; init; }
    public int RowCount { get; init; }
    public int Tpsh { get; init; }
    public int Rpmh { get; init; }
    public int Iap { get; init; }
    public int[] Fuel { get; init; } = new int[3];
    public int[] Ignition { get; init; } = new int[5];
    public int[] Limit { get; init; } = new int[7];
    public int Lambda { get; init; }
    public int O2 { get; init; }
    public int O2c { get; init; }
    public int Immo { get; init; }
    public int[] Mode { get; init; } = new int[5];
    public double Kon { get; init; } = 1.0;

    public override string ToString() => $"{Index} {Name} cols={ColumnCount} rows={RowCount} fuel1=0x{Fuel[0]:X}";
}

public static class MapDatabase
{
    public static List<MapDefinition> Load(string csvPath)
    {
        var rows = Csv.Read(csvPath);
        if (rows.Count < 2) throw new InvalidDataException("Map database CSV is empty.");
        var h = rows[0];
        int Col(string name) => Array.FindIndex(h, x => string.Equals(x?.Trim(), name, StringComparison.OrdinalIgnoreCase));

        int iIndex = Col("Index"), iName = Col("Name"), iRes = Col("Resource");
        int iCols = Col("columnCount"), iRows = Col("rowCount");
        int iTpsh = Col("tpsh"), iRpmh = Col("rpmh"), iIap = Col("iaph");
        int iLm = Col("lm"), iO2 = Col("o2"), iO2c = Col("o2c"), iImmo = Col("IMMO"), iKon = Col("kon");

        var list = new List<MapDefinition>(rows.Count - 1);
        foreach (var r in rows.Skip(1))
        {
            if (r.Length < 3 || string.IsNullOrWhiteSpace(r[iName])) continue;
            var def = new MapDefinition
            {
                Index = Field(r, iIndex),
                Name = Field(r, iName),
                Resource = Field(r, iRes),
                ColumnCount = ParseInt(Field(r, iCols)),
                RowCount = ParseInt(Field(r, iRows)),
                Tpsh = ParseOffset(Field(r, iTpsh)),
                Rpmh = ParseOffset(Field(r, iRpmh)),
                Iap = ParseOffset(Field(r, iIap)),
                Lambda = ParseOffset(Field(r, iLm)),
                O2 = ParseOffset(Field(r, iO2)),
                O2c = ParseOffset(Field(r, iO2c)),
                Immo = ParseOffset(Field(r, iImmo)),
                Kon = ParseDouble(Field(r, iKon), 1.0)
            };
            for (int k = 0; k < 3; k++) def.Fuel[k] = ParseOffset(Field(r, Col("feul" + (k + 1))));
            for (int k = 0; k < 5; k++) def.Ignition[k] = ParseOffset(Field(r, Col("ig" + (k + 1))));
            for (int k = 0; k < 7; k++) def.Limit[k] = ParseOffset(Field(r, Col("limit" + (k + 1))));
            for (int k = 0; k < 5; k++) def.Mode[k] = ParseOffset(Field(r, Col("MODE" + k)));
            list.Add(def);
        }
        return list;
    }

    private static string Field(string[] row, int i) => i >= 0 && i < row.Length ? row[i].Trim() : "";

    public static int ParseOffset(string s)
    {
        s = s.Trim().Trim('"');
        if (s.Length == 0) return 0;
        if (s.StartsWith("0x", StringComparison.OrdinalIgnoreCase))
            return int.Parse(s[2..], NumberStyles.HexNumber, CultureInfo.InvariantCulture);
        return int.TryParse(s, NumberStyles.Integer, CultureInfo.InvariantCulture, out var v) ? v : 0;
    }

    private static int ParseInt(string s) =>
        int.TryParse(s, NumberStyles.Integer, CultureInfo.InvariantCulture, out var v) ? v : 0;

    private static double ParseDouble(string s, double fallback)
    {
        s = s.Trim().TrimEnd('f', 'F');
        return double.TryParse(s, NumberStyles.Float, CultureInfo.InvariantCulture, out var v) ? v : fallback;
    }
}

public static class Csv
{
    public static List<string[]> Read(string path)
    {
        var text = File.ReadAllText(path, Encoding.UTF8).TrimStart('\uFEFF');
        var rows = new List<string[]>();
        var field = new StringBuilder();
        var row = new List<string>();
        bool quoted = false;
        for (int i = 0; i < text.Length; i++)
        {
            char c = text[i];
            if (quoted)
            {
                if (c == '"')
                {
                    if (i + 1 < text.Length && text[i + 1] == '"') { field.Append('"'); i++; }
                    else quoted = false;
                }
                else field.Append(c);
            }
            else if (c == '"') quoted = true;
            else if (c == ',') { row.Add(field.ToString()); field.Clear(); }
            else if (c == '\n')
            {
                row.Add(field.ToString().TrimEnd('\r'));
                field.Clear();
                rows.Add(row.ToArray());
                row.Clear();
            }
            else field.Append(c);
        }
        if (field.Length > 0 || row.Count > 0)
        {
            row.Add(field.ToString().TrimEnd('\r'));
            rows.Add(row.ToArray());
        }
        return rows;
    }
}
