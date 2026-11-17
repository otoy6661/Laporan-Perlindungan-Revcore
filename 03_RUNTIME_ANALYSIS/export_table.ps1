$ErrorActionPreference='Stop'
. 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\tp_lib.ps1'
$exe='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$bin='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\K1AA-N03\beat_k1aa_n03.bin'
$xdf='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\K1AA-N03\30400-k1aa-n03.xdf'
$out='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\05_XDF_AUTOPSY\export_tps_rpm.csv'
$p=$null
try {
  $r=StartTpPair $exe $bin $xdf
  $p=$r.Process
  $tv=FindChildClass $r.Main 'SysTreeView32'
  $item=[TP]::FindByText($tv,$p.Id,'TPS vs RPM')
  [void][TP]::SelectItem($tv,$item); Start-Sleep -Seconds 1
  [void][TP]::RealDoubleClick($tv,$item,$p.Id); Start-Sleep -Seconds 3
  [void][TP]::PostMessage($r.Main,0x0111,[IntPtr]32847,[IntPtr]::Zero)
  $dlg=WaitDlg $p.Id 6
  Write-Output ("EXPORT_DLG=0x{0:X}" -f $dlg.ToInt64())
  if($dlg -eq [IntPtr]::Zero){ throw 'EXPORT_DIALOG_NOT_FOUND' }
  SetDialogPath $dlg $out
  Start-Sleep -Seconds 4
  if(Test-Path $out){ Write-Output ("EXPORT_BYTES={0}" -f (Get-Item $out).Length) } else { Write-Output 'EXPORT_MISSING' }
} finally { StopTp $p }
