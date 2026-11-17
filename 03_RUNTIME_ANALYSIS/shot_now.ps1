Add-Type -AssemblyName System.Drawing
Add-Type @"
using System; using System.Runtime.InteropServices;
public class S {
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out R r);
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 public struct R { public int L,T,Ri,B; }
}
"@
$p=Get-Process TunerPro -ErrorAction Stop | Select-Object -First 1
$h=$p.MainWindowHandle
[void][S]::SetForegroundWindow($h)
Start-Sleep -Milliseconds 500
$r=New-Object S+R
[void][S]::GetWindowRect($h,[ref]$r)
$b=New-Object System.Drawing.Bitmap ($r.Ri-$r.L),($r.B-$r.T)
$g=[System.Drawing.Graphics]::FromImage($b)
$g.CopyFromScreen($r.L,$r.T,0,0,$b.Size)
$b.Save('C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\dblclick_state.png')
$g.Dispose(); $b.Dispose()
'SAVED'
