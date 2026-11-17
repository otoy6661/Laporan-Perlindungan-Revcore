$ErrorActionPreference='Stop'
Add-Type @"
using System; using System.Text; using System.Runtime.InteropServices;
public class D {
 public delegate bool EnumProc(IntPtr h, IntPtr l);
 [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
 [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr p, EnumProc cb, IntPtr l);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder sb, int n);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder sb, int n);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
 [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h,uint m,IntPtr w,IntPtr l);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
}
"@
$exe='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$p=Start-Process -FilePath $exe -PassThru -WorkingDirectory (Split-Path $exe)
for($i=0;$i -lt 60;$i++){ Start-Sleep -Milliseconds 400; $p.Refresh(); if($p.MainWindowHandle -ne 0){break} }
Start-Sleep -Seconds 2
$main=$p.MainWindowHandle
Write-Output ("main=0x{0:X} title={1}" -f $main.ToInt64(),$p.MainWindowTitle)
[void][D]::PostMessage($main,0x0111,[IntPtr]32773,[IntPtr]::Zero)
Start-Sleep -Seconds 2
$script:rows=New-Object System.Collections.ArrayList
$cb=[D+EnumProc]{ param($h,$l)
  $wp=0; [void][D]::GetWindowThreadProcessId($h,[ref]$wp)
  if($wp -ne $p.Id){ return $true }
  $c=New-Object System.Text.StringBuilder 64; [void][D]::GetClassNameW($h,$c,64)
  $t=New-Object System.Text.StringBuilder 128; [void][D]::GetWindowTextW($h,$t,128)
  [void]$script:rows.Add(("0x{0:X} vis={1} class={2} text='{3}'" -f $h.ToInt64(),[D]::IsWindowVisible($h),$c.ToString(),$t.ToString()))
  return $true
}
[void][D]::EnumWindows($cb,[IntPtr]::Zero)
$script:rows | ForEach-Object { Write-Output $_ }
$p.CloseMainWindow() | Out-Null
for($i=0;$i -lt 20;$i++){Start-Sleep -Milliseconds 300; if($p.HasExited){break}}
if(-not $p.HasExited){$p.Kill()}
