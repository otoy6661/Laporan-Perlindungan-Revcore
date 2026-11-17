$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System; using System.Runtime.InteropServices;
public class W32L {
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h,int c);
 public struct RECT { public int Left,Top,Right,Bottom; }
}
"@
$exe = 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$bin = 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\K1AA-N03\beat_k1aa_n03.bin'
$xdf = 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\K1AA-N03\30400-k1aa-n03.xdf'
$p = Start-Process -FilePath $exe -ArgumentList @("`"$bin`"","`"$xdf`"") -PassThru -WorkingDirectory (Split-Path $exe)
$ok=$false
for($i=0;$i -lt 60;$i++){ Start-Sleep -Milliseconds 500; $p.Refresh(); if($p.MainWindowHandle -ne 0){ $ok=$true; break } }
if(-not $ok){ Write-Output "NO_WINDOW"; exit 1 }
Start-Sleep -Seconds 3
$p.Refresh()
Write-Output ("PID={0}" -f $p.Id)
Write-Output ("TITLE={0}" -f $p.MainWindowTitle)
Write-Output ("MEM_MB={0:N1}" -f ($p.WorkingSet64/1MB))
$h=$p.MainWindowHandle
[W32L]::ShowWindow($h,9) | Out-Null
[W32L]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 700
$r=New-Object W32L+RECT
[W32L]::GetWindowRect($h,[ref]$r) | Out-Null
$w=$r.Right-$r.Left; $ht=$r.Bottom-$r.Top
$bmp=New-Object System.Drawing.Bitmap $w,$ht
$g=[System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($r.Left,$r.Top,0,0,$bmp.Size)
$out='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\loadargs.png'
$bmp.Save($out,[System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Output ("SHOT={0}" -f $out)
$p.CloseMainWindow() | Out-Null
for($i=0;$i -lt 20;$i++){ Start-Sleep -Milliseconds 300; if($p.HasExited){break} }
if(-not $p.HasExited){ $p.Kill() }
Write-Output "EXITED"
