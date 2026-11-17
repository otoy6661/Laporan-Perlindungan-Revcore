$ErrorActionPreference='Stop'
. 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\tp_lib.ps1'
$work='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\CBR1000RR-MGP-A01'
$bin=Join-Path $work 'CBR1000RR_checksum_test.bin'
$xdf=Join-Path $work 'CBR1000RR.xdf'
$out=Join-Path $work 'CBR1000RR_checksum_test_out.bin'
if(Test-Path $out){ Remove-Item $out -Force }
$exe='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$p=$null
try{
  $r=StartTpPair $exe $bin $xdf
  $p=$r.Process
  [void][TP]::PostMessage($r.Main,0x0111,[IntPtr]32775,[IntPtr]::Zero)
  $d=WaitDlg $p.Id 8
  Write-Output ('SAVE_DLG=0x{0:X}' -f $d.ToInt64())
  if($d -eq [IntPtr]::Zero){ throw 'NO_SAVE_DLG' }

  SetDialogPath $d $out
  Start-Sleep -Seconds 10
  $d2=FindDlg $p.Id
  Write-Output ('POST_DLG=0x{0:X}' -f $d2.ToInt64())
  if($d2 -ne [IntPtr]::Zero){ [void][TP]::PostMessage($d2,0x0111,[IntPtr]1,[IntPtr]::Zero); Start-Sleep -Seconds 3 }
  Write-Output ('EXISTS='+(Test-Path $out))
} finally { StopTp $p }
