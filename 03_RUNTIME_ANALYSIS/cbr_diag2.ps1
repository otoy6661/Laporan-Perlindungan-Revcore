$ErrorActionPreference='Stop'
. 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\tp_lib.ps1'
$work='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\CBR1000RR-MGP-A01'
$exe='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$p=Start-Process -FilePath $exe -PassThru -WorkingDirectory (Split-Path $exe)
for($i=0;$i -lt 40;$i++){ Start-Sleep -Milliseconds 500; $p.Refresh(); if($p.MainWindowHandle -ne 0){break} }
Start-Sleep -Seconds 2; $p.Refresh()
Write-Output ('PID={0} EXITED={1} MAIN=0x{2:X} TITLE={3}' -f $p.Id,$p.HasExited,$p.MainWindowHandle.ToInt64(),$p.MainWindowTitle)
if($p.MainWindowHandle -ne 0){
  [void][TP]::PostMessage($p.MainWindowHandle,0x0111,[IntPtr]32773,[IntPtr]::Zero)
  $d=WaitDlg $p.Id 6; Write-Output ('BIN_DLG=0x{0:X}' -f $d.ToInt64())
  if($d -ne [IntPtr]::Zero){ SetDialogPath $d (Join-Path $work 'CBR1000RR_checksum_test.bin'); Start-Sleep -Seconds 3 }
  [void][TP]::PostMessage($p.MainWindowHandle,0x0111,[IntPtr]32776,[IntPtr]::Zero)
  $d2=WaitDlg $p.Id 5; Write-Output ('XDF_DLG=0x{0:X}' -f $d2.ToInt64())
  if($d2 -ne [IntPtr]::Zero){ SetDialogPath $d2 (Join-Path $work 'CBR1000RR.xdf'); Start-Sleep -Seconds 3 }
  Start-Sleep -Seconds 2
  Shot $p.MainWindowHandle 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\cbr_loaded.png'
  $d3=FindDlg $p.Id; Write-Output ('LATE_DLG=0x{0:X}' -f $d3.ToInt64())
  if($d3 -ne [IntPtr]::Zero){ DumpChildren $d3 }
}
StopTp $p
