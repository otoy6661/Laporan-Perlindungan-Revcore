param(
  [string]$Bin='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\K1AA-N03\edited_9999.bin',
  [string]$Out='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\05_XDF_AUTOPSY\export_edited.csv'
)
$ErrorActionPreference='Stop'
. 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\tp_lib.ps1'
$exe='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$xdf='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\K1AA-N03\30400-k1aa-n03.xdf'
$p=$null
try {
  $r=StartTpPair $exe $Bin $xdf
  $p=$r.Process
  Write-Output ("TITLE={0}" -f $p.MainWindowTitle)
  [void][TP]::PostMessage($r.Main,0x0111,[IntPtr]32847,[IntPtr]::Zero)
  $dlg=WaitDlg $p.Id 6
  if($dlg -eq [IntPtr]::Zero){ throw 'EXPORT_DIALOG_NOT_FOUND' }
  SetDialogPath $dlg $Out
  Start-Sleep -Seconds 5
  if(Test-Path $Out){ Write-Output ("EXPORT_BYTES={0}" -f (Get-Item $Out).Length) } else { Write-Output 'EXPORT_MISSING' }
} finally { StopTp $p }
