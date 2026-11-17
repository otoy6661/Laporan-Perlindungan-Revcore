$ErrorActionPreference='Stop'
. 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\tp_lib.ps1'
$work='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\SUPRA-K41NC1'
$src=Join-Path $work 'SUPRA-K41NC1.bin'
$xdf=Join-Path $work 'SUPRA-K41NC1.xdf'
$bin=Join-Path $work 'CHECKSUM_DELTA_TEST.bin'
$out=Join-Path $work 'CHECKSUM_DELTA_TEST_out.bin'
Copy-Item $src $bin -Force
$b=[IO.File]::ReadAllBytes($bin)
$off=0x1000
$orig=$b[$off]
$b[$off]=($orig+1) -band 0xFF
[IO.File]::WriteAllBytes($bin,$b)
if(Test-Path $out){ Remove-Item $out -Force }
$exe='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$p=$null
try{
  $r=StartTpPair $exe $bin $xdf
  $p=$r.Process
  [void][TP]::PostMessage($r.Main,0x0111,[IntPtr]32775,[IntPtr]::Zero)
  $dlg=WaitDlg $p.Id 6
  if($dlg -eq [IntPtr]::Zero){ throw 'SAVE_DIALOG_NOT_FOUND' }
  SetDialogPath $dlg $out
  Start-Sleep -Seconds 4
  if(-not (Test-Path $out)){ throw 'SAVE_MISSING' }
} finally { StopTp $p }
$a=[IO.File]::ReadAllBytes($bin); $c=[IO.File]::ReadAllBytes($out)
$diff=@()
for($i=0;$i -lt [Math]::Min($a.Length,$c.Length);$i++){ if($a[$i] -ne $c[$i]){ $diff += ('{0:X4}: {1:X2}->{2:X2}' -f $i,$a[$i],$c[$i]) } }
Write-Output ("INPUT_BYTE_1000=0x{0:X2}->0x{1:X2}" -f $orig,$a[$off])
Write-Output ("DIFF_COUNT={0}" -f $diff.Count)
$diff | Select-Object -First 10 | ForEach-Object { Write-Output $_ }
Write-Output ("FFF1_INPUT=0x{0:X2} OUTPUT=0x{1:X2}" -f $a[0xFFF1],$c[0xFFF1])
$s=0; for($i=0;$i -lt 0x10000;$i++){ $s=($s+$c[$i]) -band 0xFF }
Write-Output ("OUT_SUM_MOD256=0x{0:X2}" -f $s)
