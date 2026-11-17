$ErrorActionPreference='Stop'
. 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\tp_lib.ps1'
Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
using System; using System.Text; using System.Runtime.InteropServices;
public class PR {
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder sb, int n);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder sb, int n);
 [DllImport("user32.dll")] public static extern int GetDlgCtrlID(IntPtr h);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
}
"@
$exe='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$bin='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\SUPRA-K41NC1\SUPRA-K41NC1_resaved.bin'
$xdf='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\SUPRA-K41NC1\SUPRA-K41NC1.xdf'
$p=$null
try{
  $r=StartTpPair $exe $bin $xdf
  $p=$r.Process
  [void][TP]::PostMessage($r.Main,0x0111,[IntPtr]32778,[IntPtr]::Zero)
  Start-Sleep -Seconds 3
  $dlg=FindDlg $p.Id
  Write-Output ("DLG=0x{0:X}" -f $dlg.ToInt64())
  if($dlg -eq [IntPtr]::Zero){ throw 'NO_PREFS' }
  Shot $dlg 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\preferences.png'
  $script:kids=New-Object System.Collections.ArrayList
  $cb=[TP+EnumProc]{ param($h,$l) [void]$script:kids.Add($h); return $true }
  [void][TP]::EnumChildWindows($dlg,$cb,[IntPtr]::Zero)
  foreach($k in $script:kids){
    $c=New-Object System.Text.StringBuilder 64; [void][PR]::GetClassNameW($k,$c,64)
    $t=New-Object System.Text.StringBuilder 512; [void][PR]::GetWindowTextW($k,$t,512)
    Write-Output ("{0} id={1} vis={2} text='{3}'" -f $c.ToString(),[PR]::GetDlgCtrlID($k),[PR]::IsWindowVisible($k),$t.ToString())
  }
} finally { StopTp $p }
