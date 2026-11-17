$ErrorActionPreference='Stop'
. 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\tp_lib.ps1'
$work='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\CBR1000RR-MGP-A01'
$bin=Join-Path $work 'CBR1000RR_checksum_test.bin'
$xdf=Join-Path $work 'CBR1000RR.xdf'
$exe='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$p=$null
try{
  $r=StartTpPair $exe $bin $xdf
  $p=$r.Process
  Start-Sleep -Seconds 3
  Shot $r.Main 'CBR_load_state.png'
  Write-Output ('MAIN_TITLE='+$r.Main.Title)
  foreach($w in [System.Windows.Automation.AutomationElement]::RootElement.FindAll([System.Windows.Automation.TreeScope]::Children,[System.Windows.Automation.Condition]::TrueCondition)){
    try{ if($w.Current.ProcessId -eq $p.Id){ Write-Output ('WIN class='+$w.Current.ClassName+' name='+$w.Current.Name) } }catch{}
  }
  [void][TP]::PostMessage($r.Main,0x0111,[IntPtr]32775,[IntPtr]::Zero)
  Start-Sleep -Seconds 2
  $dlg=WaitDlg $p.Id 4
  Write-Output ('SAVE_DLG=0x{0:X}' -f $dlg.ToInt64())
  if($dlg -ne [IntPtr]::Zero){ DumpChildren $dlg }
} finally { StopTp $p }
