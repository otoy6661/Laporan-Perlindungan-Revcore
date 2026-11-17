$ErrorActionPreference='Stop'
. 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\tp_lib.ps1'
$srcDir='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\DATASET_COPY\BIN & XDF\CB -CBR\CBR500R 38770 MGZ-C02\CBR1000RR 38770-MGP-A01'
$work='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\CBR1000RR-MGP-A01'
New-Item -ItemType Directory -Force -Path $work | Out-Null
$bin=Join-Path $work 'CBR1000RR_checksum_test.bin'
$xdf=Join-Path $work 'CBR1000RR.xdf'
$out=Join-Path $work 'CBR1000RR_checksum_test_out.bin'
Copy-Item (Join-Path $srcDir '28= CBR1000RR 38770-MGP-A01.bin') $bin -Force
Copy-Item (Join-Path $srcDir '28= CBR1000RR 38770-MGP-A01.xdf') $xdf -Force
$b=[IO.File]::ReadAllBytes($bin)
$store=0x3FFF8
$before=$b[$store]
$b[$store]=0x00
[IO.File]::WriteAllBytes($bin,$b)
if(Test-Path $out){ Remove-Item $out -Force }
$exe='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$p=$null
try{
  $r=StartTpPair $exe $bin $xdf
  $p=$r.Process
  [void][TP]::PostMessage($r.Main,0x0111,[IntPtr]32775,[IntPtr]::Zero)
  $dlg=WaitDlg $p.Id 8
  if($dlg -eq [IntPtr]::Zero){ throw 'SAVE_DIALOG_NOT_FOUND' }
  SetDialogPath $dlg $out
  Start-Sleep -Seconds 5
  if(-not (Test-Path $out)){ throw 'SAVE_MISSING' }
} finally { StopTp $p }
$a=[IO.File]::ReadAllBytes($bin); $c=[IO.File]::ReadAllBytes($out)
$diff=@()
for($i=0;$i -lt [Math]::Min($a.Length,$c.Length);$i++){ if($a[$i] -ne $c[$i]){ $diff += ('{0:X5}: {1:X2}->{2:X2}' -f $i,$a[$i],$c[$i]) } }
Write-Output ("SIZE_IN={0} SIZE_OUT={1}" -f $a.Length,$c.Length)
Write-Output ("STORE_BEFORE_ORIG=0x{0:X2} INPUT=0x{1:X2} OUTPUT=0x{2:X2}" -f $before,$a[$store],$c[$store])
Write-Output ("DIFF_COUNT={0}" -f $diff.Count)
$diff | Select-Object -First 10 | ForEach-Object { Write-Output $_ }
$s=0; for($i=0;$i -lt 0x40000;$i++){ if($i -ne $store){ $s=($s+$c[$i]) -band 0xFF } }
Write-Output ("SUM_EXCL_STORE=0x{0:X2} TWOS_COMP=0x{1:X2}" -f $s,((0x100-$s) -band 0xFF))
$s2=0; for($i=0;$i -lt 0x40000;$i++){ $s2=($s2+$c[$i]) -band 0xFF }
Write-Output ("SUM_ALL=0x{0:X2}" -f $s2)
