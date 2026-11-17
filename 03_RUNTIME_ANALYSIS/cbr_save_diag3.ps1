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
  SetDialogPath $d $out
  Start-Sleep -Seconds 6
  $d2=FindDlg $p.Id
  if($d2 -ne [IntPtr]::Zero){
    $t=New-Object System.Text.StringBuilder 256
    [void][TP]::GetWindowTextW($d2,$t,256)
    Write-Output ('POST_TITLE='+$t.ToString())
    Shot $d2 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\cbr_save_error.png'
    $cb=[TP+EnumProc]{ param($h,$l)
      $c=New-Object System.Text.StringBuilder 64; [void][TP]::GetClassNameW($h,$c,64)
      $x=New-Object System.Text.StringBuilder 512; [void][TP]::GetWindowTextW($h,$x,512)
      $id=[TP]::GetDlgCtrlID($h)
      Write-Output ('  CHILD class={0} id={1} text={2}' -f $c.ToString(),$id,$x.ToString())
      return $true
    }
    [void][TP]::EnumChildWindows($d2,$cb,[IntPtr]::Zero)
  } else { Write-Output 'NO_POST_DLG' }
  Write-Output ('EXISTS='+(Test-Path $out))
} finally { StopTp $p }
