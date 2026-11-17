namespace BE10Tools.Maps;

/// <summary>
/// Bilinear interpolation over an RPM × TPS grid with input clamping.
/// Axis arrays must be ascending; this mirrors the lookup behaviour needed by
/// a map editor (the researched application uses nearest-point pointer logic
/// only, so the interpolation engine is a BE-10 addition, not a reconstruction).
/// </summary>
public static class Interpolation
{
    public static double Bilinear(double[] xs, double[] ys, double[,] z, double x, double y)
    {
        if (xs.Length < 2 || ys.Length < 2) throw new ArgumentException("Grid needs at least 2x2 points.");
        if (z.GetLength(0) != ys.Length || z.GetLength(1) != xs.Length)
            throw new ArgumentException("Grid dimensions do not match axes.");

        x = Math.Clamp(x, xs[0], xs[^1]);
        y = Math.Clamp(y, ys[0], ys[^1]);

        int i = Bracket(xs, x);
        int j = Bracket(ys, y);
        double tx = (x - xs[i]) / (xs[i + 1] - xs[i]);
        double ty = (y - ys[j]) / (ys[j + 1] - ys[j]);

        double z00 = z[j, i], z01 = z[j, i + 1], z10 = z[j + 1, i], z11 = z[j + 1, i + 1];
        return z00 * (1 - tx) * (1 - ty)
             + z01 * tx * (1 - ty)
             + z10 * (1 - tx) * ty
             + z11 * tx * ty;
    }

    private static int Bracket(double[] axis, double v)
    {
        for (int k = 0; k < axis.Length - 1; k++)
            if (v <= axis[k + 1]) return k;
        return axis.Length - 2;
    }

    /// <summary>Nearest breakpoint index, the behaviour used to position the live pointer.</summary>
    public static int NearestIndex(double[] axis, double v)
    {
        int best = 0;
        double bestDelta = double.MaxValue;
        for (int i = 0; i < axis.Length; i++)
        {
            double d = Math.Abs(axis[i] - v);
            if (d < bestDelta) { bestDelta = d; best = i; }
        }
        return best;
    }

    public static (double MaxAbs, long Changed, double ChangedPercent) Compare(double[,] a, double[,] b)
    {
        if (a.GetLength(0) != b.GetLength(0) || a.GetLength(1) != b.GetLength(1))
            throw new ArgumentException("Tables have different dimensions.");
        double max = 0;
        long changed = 0;
        int total = a.Length;
        for (int r = 0; r < a.GetLength(0); r++)
            for (int c = 0; c < a.GetLength(1); c++)
            {
                double d = Math.Abs(a[r, c] - b[r, c]);
                if (d > max) max = d;
                if (d > 1e-12) changed++;
            }
        return (max, changed, total == 0 ? 0 : 100.0 * changed / total);
    }
}
