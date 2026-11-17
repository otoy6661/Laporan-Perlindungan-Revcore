$ErrorActionPreference='Stop'
. 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\tp_lib.ps1'
Add-Type @"
using System; using System.Text; using System.Runtime.InteropServices;
public class DP {
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder sb, int n);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder sb, int n);
 [DllImport("user32.dll")] public static extern int GetDlgCtrlID(IntPtr h);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
}
"@
$bin='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\SUPRA-K41NC1\SUPRA-K41NC1_corrupt.bin'
$xdf='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\SUPRA-K41NC1\SUPRA-K41NC1.xdf'
$exe='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$p=$null
try{
  $r=StartTpPair $exe $bin $xdf
  $p=$r.Process
  [void][TP]::PostMessage($r.Main,0x0111,[IntPtr]32775,[IntPtr]::Zero)
  Start-Sleep -Seconds 3
  $script:rows=New-Object System.Collections.ArrayList
  $cb=[TP+EnumProc]{ param($h,$l)
    $wp=0; [void][DP]::GetWindowThreadProcessId($h,[ref]$wp)
    if($wp -ne $p.Id){ return $true }
    $c=New-Object System.Text.StringBuilder 64; [void][DP]::GetClassNameW($h,$c,64)
    $t=New-Object System.Text.StringBuilder 256; [void][DP]::GetWindowTextW($h,$t,256)
    [void]$script:rows.Add(("TOP {0} {1} vis={2} text='{3}'" -f $h.ToInt64(),$c.ToString(),[DP]::IsWindowVisible($h),$t.ToString()))
    return $true
  }
  [void][TP]::EnumWindows($cb,[IntPtr]::Zero)
  $script:rows | ForEach-Object { Write-Output $_ }
  $dlg=FindDlg $p.Id
  Write-Output ("FINDDLG=0x{0:X}" -f $dlg.ToInt64())
  if($dlg -ne [IntPtr]::Zero){
    $script:kids=New-Object System.Collections.ArrayList
    $cb2=[TP+EnumProc]{ param($h,$l) [void]$script:kids.Add($h); return $true }
    [void][TP]::EnumChildWindows($dlg,$cb2,[IntPtr]::Zero)
    foreach($k in $script:kids){
      $c=New-Object System.Text.StringBuilder 64; [void][DP]::GetClassNameW($k,$c,64)
      $id=[DP]::GetDlgCtrlID($k)
      $t=New-Object System.Text.StringBuilder 128; [void][DP]::GetWindowTextW($k,$t,128)
      Write-Output ("  {0} id={1} vis={2} text='{3}'" -f $c.ToString(),$id,[DP]::IsWindowVisible($k),$t.ToString())
    }
  }
} finally { StopTp $p }
