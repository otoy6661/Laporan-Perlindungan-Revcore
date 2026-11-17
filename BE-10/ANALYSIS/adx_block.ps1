$a=[IO.File]::ReadAllBytes('C:\Users\Lord Otoy\Documents\REVCORE_BE10_RESEARCH\SOURCES\ADX_D2_TECH\ADX KEIHIN BE.adx')
$s=[IO.File]::ReadAllBytes('C:\Users\Lord Otoy\Documents\REVCORE_BE10_RESEARCH\SOURCES\ADX_D2_TECH\ADX SHINDENGEN BE.adx')
$blk=($a[0x108..0x132] | ForEach-Object { $_.ToString('X2') }) -join ' '
$diff=@()
for($i=0x108;$i -le 0x132;$i++){ if($a[$i] -ne $s[$i]){ $diff += ('0x{0:X3}' -f $i) } }
Write-Output ('KEIHIN_BLOCK43='+$blk)
Write-Output ('BLOCK_DIFF_OFFSETS='+($diff -join ','))
Write-Output ('KEIHIN_TAG=0x{0:X2} SHIND_TAG=0x{1:X2}' -f $a[0x133],$s[0x133])
$p=$a[0x134..($a.Length-1)]
$ent=0.0
$counts=New-Object int[] 256
foreach($x in $p){ $counts[$x]++ }
foreach($c in $counts){ if($c -gt 0){ $pr=$c/$p.Length; $ent -= $pr*[Math]::Log($pr,2) } }
Write-Output ('KEIHIN_PAYLOAD_LEN='+$p.Length+' ENTROPY='+[Math]::Round($ent,4))
