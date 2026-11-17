$ErrorActionPreference='Stop'
. 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\tp_lib.ps1'
$srcBin='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\DATASET_COPY\BIN & XDF\SUPRA - SONIC\SUPRA X 125 38770-K41-NC1\SUPRA X 125 38770-K41-NC1.bin'
$srcXdf='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\DATASET_COPY\BIN & XDF\SUPRA - SONIC\SUPRA X 125 38770-K41-NC1\SUPRA X 125 38770-K41-NC1.xdf'
$work='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\SUPRA-K41NC1'
New-Item -ItemType Directory -Force -Path $work | Out-Null
$bin=Join-Path $work 'SUPRA-K41NC1_corrupt.bin'
$xdf=Join-Path $work 'SUPRA-K41NC1.xdf'
$out=Join-Path $work 'SUPRA-K41NC1_resaved.bin'
Copy-Item $srcBin $bin -Force
Copy-Item $srcXdf $xdf -Force
$b=[IO.File]::ReadAllBytes($bin)
$b[0xFFF1]=0
[IO.File]::WriteAllBytes($bin,$b)
if(Test-Path $out){ Remove-Item $out }
$exe='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$p=$null
try{
  $r=StartTpPair $exe $bin $xdf
  $p=$r.Process
  [void][TP]::PostMessage($r.Main,0x0111,[IntPtr]32775,[IntPtr]::Zero)
  $dlg=WaitDlg $p.Id 6
  Write-Output ("SAVE_DLG=0x{0:X}" -f $dlg.ToInt64())
  if($dlg -eq [IntPtr]::Zero){ throw 'SAVE_DIALOG_NOT_FOUND' }
  SetDialogPath $dlg $out
  Start-Sleep -Seconds 4
  if(Test-Path $out){ Write-Output ("SAVED_BYTES={0}" -f (Get-Item $out).Length) } else { throw 'SAVE_MISSING' }
} finally { StopTp $p }
$a=[IO.File]::ReadAllBytes($bin); $b2=[IO.File]::ReadAllBytes($out)
$diff=@()
for($i=0;$i -lt [Math]::Min($a.Length,$b2.Length);$i++){ if($a[$i] -ne $b2[$i]){ $diff += ('{0:X4}: {1:X2}->{2:X2}' -f $i,$a[$i],$b2[$i]) } }
Write-Output ("DIFF_COUNT={0}" -f $diff.Count)
$diff | Select-Object -First 20 | ForEach-Object { Write-Output $_ }
Write-Output ("B_FFF1_INPUT={0} OUTPUT={1}" -f $a[0xFFF1],$b2[0xFFF1])
