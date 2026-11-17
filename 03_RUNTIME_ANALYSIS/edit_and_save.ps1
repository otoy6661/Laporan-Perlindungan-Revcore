$ErrorActionPreference='Stop'
. 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\tp_lib.ps1'
Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
using System; using System.Runtime.InteropServices;
public class M {
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out R r);
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")] public static extern void mouse_event(uint f,uint dx,uint dy,uint d,IntPtr e);
 public struct R { public int L,T,Ri,B; }
}
"@
function RealClick($h){
  $r=New-Object M+R; [void][M]::GetWindowRect($h,[ref]$r)
  $x=[int](($r.L+$r.Ri)/2); $y=[int](($r.T+$r.B)/2)
  [void][M]::SetCursorPos($x,$y); Start-Sleep -Milliseconds 200
  [M]::mouse_event(0x0002,0,0,0,[IntPtr]::Zero); [M]::mouse_event(0x0004,0,0,0,[IntPtr]::Zero)
}
$exe='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$bin='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\K1AA-N03\beat_k1aa_n03.bin'
$xdf='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\K1AA-N03\30400-k1aa-n03.xdf'
$out='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\K1AA-N03\edited_9999.bin'
$p=$null
try {
  $r=StartTpPair $exe $bin $xdf
  $p=$r.Process
  $tv=FindChildClass $r.Main 'SysTreeView32'
  $item=[TP]::FindByText($tv,$p.Id,'TPS vs RPM')
  [void][TP]::SelectItem($tv,$item); Start-Sleep -Seconds 1
  [void][TP]::RealDoubleClick($tv,$item,$p.Id); Start-Sleep -Seconds 3
  $grid=FindChildClass $r.Main 'MMGRIDCONTROL'
  Write-Output ("GRID=0x{0:X}" -f $grid.ToInt64())
  if($grid -eq [IntPtr]::Zero){ throw 'NO_GRID' }
  RealClick $grid
  Start-Sleep -Milliseconds 500
  [System.Windows.Forms.SendKeys]::SendWait('^{HOME}')
  Start-Sleep -Milliseconds 300
  [System.Windows.Forms.SendKeys]::SendWait('9999')
  Start-Sleep -Milliseconds 300
  [System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
  Start-Sleep -Seconds 1
  Shot $r.Main 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\after_edit.png'
  [void][TP]::PostMessage($r.Main,0x0111,[IntPtr]32775,[IntPtr]::Zero)
  $dlg=WaitDlg $p.Id 6
  Write-Output ("SAVE_DLG=0x{0:X}" -f $dlg.ToInt64())
  if($dlg -eq [IntPtr]::Zero){ throw 'SAVE_DIALOG_NOT_FOUND' }
  SetDialogPath $dlg $out
  Start-Sleep -Seconds 4
  if(Test-Path $out){ Write-Output ("SAVED_BYTES={0}" -f (Get-Item $out).Length) } else { Write-Output 'SAVE_MISSING' }
} finally { StopTp $p }
