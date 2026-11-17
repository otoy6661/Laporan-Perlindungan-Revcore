$ErrorActionPreference='Stop'
Add-Type @"
using System; using System.Text; using System.Runtime.InteropServices;
public class WinTree {
 public delegate bool EnumProc(IntPtr h, IntPtr l);
 [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr parent, EnumProc cb, IntPtr l);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder sb, int n);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder sb, int n);
 [DllImport("user32.dll")] public static extern int GetDlgCtrlID(IntPtr h);
 [DllImport("user32.dll")] public static extern IntPtr GetParent(IntPtr h);
}
"@
$exe='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$p=Start-Process -FilePath $exe -PassThru -WorkingDirectory (Split-Path $exe)
for($i=0;$i -lt 60;$i++){ Start-Sleep -Milliseconds 400; $p.Refresh(); if($p.MainWindowHandle -ne 0){break} }
Start-Sleep -Seconds 2
$main=$p.MainWindowHandle
$script:rows=New-Object System.Collections.ArrayList
$cb=[WinTree+EnumProc]{ param($h,$l)
  $cls=New-Object System.Text.StringBuilder 128; [void][WinTree]::GetClassNameW($h,$cls,128)
  $txt=New-Object System.Text.StringBuilder 256; [void][WinTree]::GetWindowTextW($h,$txt,256)
  $id=[WinTree]::GetDlgCtrlID($h)
  [void]$script:rows.Add([pscustomobject]@{Handle=$h;Class=$cls.ToString();Text=$txt.ToString();Id=$id})
  return $true
}
[void][WinTree]::EnumChildWindows($main,$cb,[IntPtr]::Zero)
Write-Output ("CHILDREN={0}" -f $script:rows.Count)
$script:rows | Sort-Object Class | ForEach-Object { Write-Output ("h=0x{0:X}  id={1,-6} class={2,-28} text='{3}'" -f ($_.Handle.ToInt64()),$_.Id,$_.Class,$_.Text) }
$p.CloseMainWindow() | Out-Null
for($i=0;$i -lt 20;$i++){Start-Sleep -Milliseconds 300; if($p.HasExited){break}}
if(-not $p.HasExited){$p.Kill()}
