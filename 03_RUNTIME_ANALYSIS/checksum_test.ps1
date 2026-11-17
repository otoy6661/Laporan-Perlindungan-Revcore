$ErrorActionPreference='Stop'
. 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\tp_lib.ps1'
Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
using System; using System.Runtime.InteropServices;
public class M2 {
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out R r);
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")] public static extern void mouse_event(uint f,uint dx,uint dy,uint d,IntPtr e);
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern IntPtr SetFocus(IntPtr h);
 [DllImport("user32.dll")] public static extern IntPtr GetFocus();
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
 [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
 [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint a,uint b,bool f);
 public struct R { public int L,T,Ri,B; }
}
"@
function ForceFocus($main,$ctrl){
  $tid=0; [void][M2]::GetWindowThreadProcessId($main,[ref]$tid)
  $ctid=[M2]::GetCurrentThreadId()
  [void][M2]::AttachThreadInput($ctid,$tid,$true)
  [void][M2]::SetForegroundWindow($main)
  [void][M2]::SetFocus($ctrl)
  [void][M2]::AttachThreadInput($ctid,$tid,$false)
  Start-Sleep -Milliseconds 300
}
function RealClick($h){
  $r=New-Object M2+R; [void][M2]::GetWindowRect($h,[ref]$r)
  $x=[int](($r.L+$r.Ri)/2); $y=[int](($r.T+$r.B)/2)
  [void][M2]::SetCursorPos($x,$y); Start-Sleep -Milliseconds 200
  [M2]::mouse_event(0x0002,0,0,0,[IntPtr]::Zero); [M2]::mouse_event(0x0004,0,0,0,[IntPtr]::Zero)
}
function Stats($path){
  $b=[IO.File]::ReadAllBytes($path)
  $sum=0; for($i=0;$i -lt $b.Length;$i++){ $sum=($sum+$b[$i]) -band 0xFFFF }
  $sum2=0; for($i=0;$i -lt 0xFFF0;$i++){ $sum2=($sum2+$b[$i]) -band 0xFFFF }
  $sum4=0; for($i=0;$i -lt 0x10000;$i++){ $sum4=($sum4+$b[$i]) -band 0xFFFF }
  [pscustomobject]@{ Size=$b.Length; B_FFF0=$b[0xFFF0]; B_FFF1=$b[0xFFF1]; SumAll16=$sum; SumPreFFF0=$sum2; Sum64K=$sum4 }
}
$srcBin='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\DATASET_COPY\BIN & XDF\SUPRA - SONIC\SUPRA X 125 38770-K41-NC1\SUPRA X 125 38770-K41-NC1.bin'
$srcXdf='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\DATASET_COPY\BIN & XDF\SUPRA - SONIC\SUPRA X 125 38770-K41-NC1\SUPRA X 125 38770-K41-NC1.xdf'
$work='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\SUPRA-K41NC1'
New-Item -ItemType Directory -Force -Path $work | Out-Null
$bin=Join-Path $work 'SUPRA-K41NC1.bin'
$xdf=Join-Path $work 'SUPRA-K41NC1.xdf'
Copy-Item $srcBin $bin -Force
Copy-Item $srcXdf $xdf -Force
$out=Join-Path $work 'SUPRA-K41NC1_edited.bin'
if(Test-Path $out){ Remove-Item $out }
Write-Output '--- PRE ---'
Stats $bin | Format-List | Out-String | Write-Output
$exe='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$p=$null
try {
  $r=StartTpPair $exe $bin $xdf
  $p=$r.Process
  $tv=FindChildClass $r.Main 'SysTreeView32'
  $item=[TP]::FindByText($tv,$p.Id,'Ignition - (1 - 4)')
  Write-Output ("ITEM=0x{0:X}" -f $item.ToInt64())
  if($item -eq [IntPtr]::Zero){ throw 'TABLE_NOT_FOUND' }
  [void][TP]::SelectItem($tv,$item); Start-Sleep -Seconds 1
  [void][TP]::RealDoubleClick($tv,$item,$p.Id); Start-Sleep -Seconds 3
  $grid=FindChildClass $r.Main 'MMGRIDCONTROL'
  Write-Output ("GRID=0x{0:X}" -f $grid.ToInt64())
  if($grid -eq [IntPtr]::Zero){ throw 'NO_GRID' }
  RealClick $grid; Start-Sleep -Milliseconds 300
  ForceFocus $r.Main $grid
  $rct=New-Object M2+R; [void][M2]::GetWindowRect($grid,[ref]$rct)
  [void][M2]::SetCursorPos(($rct.L+90),($rct.T+70)); Start-Sleep -Milliseconds 200
  [M2]::mouse_event(0x0002,0,0,0,[IntPtr]::Zero); [M2]::mouse_event(0x0004,0,0,0,[IntPtr]::Zero)
  Start-Sleep -Milliseconds 500
  [System.Windows.Forms.SendKeys]::SendWait('20'); Start-Sleep -Milliseconds 400
  Shot $r.Main 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\checksum_typing.png'
  [System.Windows.Forms.SendKeys]::SendWait('{ENTER}'); Start-Sleep -Seconds 1
  Shot $r.Main 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\checksum_after_edit.png'
  [void][TP]::PostMessage($r.Main,0x0111,[IntPtr]32775,[IntPtr]::Zero)
  $dlg=WaitDlg $p.Id 6
  Write-Output ("SAVE_DLG=0x{0:X}" -f $dlg.ToInt64())
  if($dlg -eq [IntPtr]::Zero){ throw 'SAVE_DIALOG_NOT_FOUND' }
  SetDialogPath $dlg $out
  Start-Sleep -Seconds 4
  if(Test-Path $out){ Write-Output ("SAVED_BYTES={0}" -f (Get-Item $out).Length) } else { throw 'SAVE_MISSING' }
} finally { StopTp $p }
Write-Output '--- POST ---'
Stats $out | Format-List | Out-String | Write-Output
$a=[IO.File]::ReadAllBytes($bin); $b=[IO.File]::ReadAllBytes($out)
$diff=@()
for($i=0;$i -lt [Math]::Min($a.Length,$b.Length);$i++){ if($a[$i] -ne $b[$i]){ $diff += ('{0:X4}: {1:X2}->{2:X2}' -f $i,$a[$i],$b[$i]) } }
Write-Output ("DIFF_COUNT={0}" -f $diff.Count)
$diff | Select-Object -First 40 | ForEach-Object { Write-Output $_ }
