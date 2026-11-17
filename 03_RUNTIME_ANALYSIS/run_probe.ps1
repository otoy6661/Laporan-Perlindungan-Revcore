$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32Probe {
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
}
"@
$root='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY'
$exe=Join-Path $root '00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$out=Join-Path $root '03_RUNTIME_ANALYSIS'
$p=Start-Process -FilePath $exe -WorkingDirectory (Split-Path $exe) -PassThru
Write-Output ("PID=" + $p.Id)
$deadline=(Get-Date).AddSeconds(25)
while((Get-Date) -lt $deadline){
  Start-Sleep -Milliseconds 500
  $p.Refresh()
  if($p.MainWindowHandle -ne 0){ break }
  if($p.HasExited){ break }
}
$p.Refresh()
Write-Output ("HAS_EXITED=" + $p.HasExited)
if(-not $p.HasExited){
  Write-Output ("MAIN_WINDOW=" + $p.MainWindowHandle)
  Write-Output ("TITLE=" + $p.MainWindowTitle)
  Write-Output ("WORKING_SET_MB=" + [math]::Round($p.WorkingSet64/1MB,1))
  Write-Output ("THREADS=" + $p.Threads.Count)
  $mods=$p.Modules | ForEach-Object { $_.FileName }
  $mods | Set-Content -LiteralPath (Join-Path $out 'modules_at_startup.txt') -Encoding UTF8
  if($p.MainWindowHandle -ne 0){
    [Win32Probe]::SetForegroundWindow($p.MainWindowHandle) | Out-Null
    Start-Sleep -Milliseconds 800
    $r=New-Object Win32Probe+RECT
    [Win32Probe]::GetWindowRect($p.MainWindowHandle,[ref]$r) | Out-Null
    $w=$r.Right-$r.Left; $h=$r.Bottom-$r.Top
    Write-Output ("RECT=" + $r.Left + "," + $r.Top + "," + $w + "," + $h)
    if($w -gt 0 -and $h -gt 0){
      $bmp=New-Object System.Drawing.Bitmap $w,$h
      $g=[System.Drawing.Graphics]::FromImage($bmp)
      $g.CopyFromScreen($r.Left,$r.Top,0,0,$bmp.Size)
      $bmp.Save((Join-Path $out 'startup_window.png'),[System.Drawing.Imaging.ImageFormat]::Png)
      $g.Dispose(); $bmp.Dispose()
      Write-Output 'SCREENSHOT=startup_window.png'
    }
  }
  Start-Sleep -Seconds 1
  $p.CloseMainWindow() | Out-Null
  if(-not $p.WaitForExit(5000)){ $p.Kill(); Write-Output 'FORCE_KILLED' } else { Write-Output ("EXIT_CODE=" + $p.ExitCode) }
} else {
  Write-Output ("EXIT_CODE=" + $p.ExitCode)
}
