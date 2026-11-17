$ErrorActionPreference='Stop'
. 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\tp_lib.ps1'
Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
using System; using System.Text; using System.Runtime.InteropServices;
public class SD {
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder sb, int n);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder sb, int n);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
}
"@
$exe='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$p=Start-Process -FilePath $exe -PassThru -WorkingDirectory (Split-Path $exe)
for($i=0;$i -lt 40;$i++){ Start-Sleep -Milliseconds 400; $p.Refresh(); if($p.MainWindowHandle -ne 0){break} }
Start-Sleep -Seconds 3; $p.Refresh()
Write-Output ("TITLE={0}" -f $p.MainWindowTitle)
$script:rows=New-Object System.Collections.ArrayList
$cb=[TP+EnumProc]{ param($h,$l)
  $wp=0; [void][SD]::GetWindowThreadProcessId($h,[ref]$wp)
  if($wp -ne $p.Id){ return $true }
  if(-not [SD]::IsWindowVisible($h)){ return $true }
  $c=New-Object System.Text.StringBuilder 64; [void][SD]::GetClassNameW($h,$c,64)
  $t=New-Object System.Text.StringBuilder 512; [void][SD]::GetWindowTextW($h,$t,512)
  [void]$script:rows.Add(("{0} {1} '{2}'" -f $h.ToInt64(),$c.ToString(),$t.ToString()))
  return $true
}
[void][TP]::EnumWindows($cb,[IntPtr]::Zero)
$script:rows | ForEach-Object { Write-Output $_ }
# dump texts inside each dialog
$script:dt=New-Object System.Collections.ArrayList
$cb3=[TP+EnumProc]{ param($h,$l)
  $wp=0; [void][SD]::GetWindowThreadProcessId($h,[ref]$wp)
  if($wp -ne $p.Id){ return $true }
  $c=New-Object System.Text.StringBuilder 64; [void][SD]::GetClassNameW($h,$c,64)
  if($c.ToString() -eq '#32770'){
    $script:kids=New-Object System.Collections.ArrayList
    $cb2=[TP+EnumProc]{ param($k,$l) [void]$script:kids.Add($k); return $true }
    [void][TP]::EnumChildWindows($h,$cb2,[IntPtr]::Zero)
    foreach($k in $script:kids){
      $ck=New-Object System.Text.StringBuilder 64; [void][SD]::GetClassNameW($k,$ck,64)
      $tk=New-Object System.Text.StringBuilder 256; [void][SD]::GetWindowTextW($k,$tk,256)
      if($tk.Length -gt 0 -and [SD]::IsWindowVisible($k)){ [void]$script:dt.Add(("D {0}: {1}" -f $ck.ToString(),$tk.ToString())) }
    }
  }
  return $true
}
[void][TP]::EnumWindows($cb3,[IntPtr]::Zero)
$script:dt | Select-Object -Unique | ForEach-Object { Write-Output $_ }
$vs=[System.Windows.Forms.SystemInformation]::VirtualScreen
$bmp=New-Object System.Drawing.Bitmap $vs.Width,$vs.Height
$g=[System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($vs.Left,$vs.Top,0,0,$bmp.Size)
$bmp.Save('C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\startup_corrupt.png',[System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
StopTp $p
