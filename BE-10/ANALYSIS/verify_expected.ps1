$ErrorActionPreference='Stop'
$r=Import-Csv 'C:\Users\Lord Otoy\Documents\REVCORE_BE10_RESEARCH\ANALYSIS\3D_ECU_ID_DATABASE.csv'
"TOTAL=$($r.Count)"
$r | Group-Object Family | ForEach-Object { "$($_.Name)=$($_.Count)" }
"FIRST_K: " + (($r | Select-Object -First 1).EcmId) + " | " + (($r | Select-Object -First 1).PartCode) + " | " + (($r | Select-Object -First 1).StartOffset) + " | " + (($r | Select-Object -First 1).ChecksumOffset)
$sh=$r | Where-Object { $_.Family -eq 'SHINDENGEN' } | Select-Object -First 1
"FIRST_S: " + $sh.EcmId + " | " + $sh.PartCode + " | " + $sh.StartOffset + " | " + $sh.ChecksumOffset
function U16($b,$o){ return ([int]$b[$o]) -bor ((([int]$b[$o+1]) -shl 8)) }
$b=New-Object byte[] 40
$b[4]=64; $b[5]=128
$o2=(U16 $b 4)/13.142708/1000
$stf=128/128.25651
$o2v=64/50.9937
$afr=-5.351*$o2v+17.7
"O2=$o2 O2V=$o2v STF=$stf AFR=$afr"
function S32($d,$s,$l){ [uint32]$sum=0; $e=$s+$l; while($s+4 -le $e){ $sum=[uint32]($sum + [BitConverter]::ToUInt32($d,$s)); $s+=4 }; return $sum }
$d=New-Object byte[] 32
for($i=0;$i -lt 32;$i++){ $d[$i]=[byte]$i }
for($i=12;$i -le 15;$i++){ $d[$i]=0 }
$tot=[uint32]((S32 $d 0 12) + (S32 $d 16 16))
$ck=[uint32](0 - $tot)
"CK=$ck HEX=" + ('{0:X8}' -f $ck)
# keihin synthetic
$k=New-Object byte[] 10
for($i=0;$i -lt 10;$i++){ $k[$i]=[byte]($i+1) }
$s0=0; for($i=1;$i -lt 10;$i++){ $s0+=$k[$i] }
"KEIHIN_OFF0=" + ('{0:X2}' -f [byte](0-$s0))
$s5=0; for($i=0;$i -lt 5;$i++){ $s5+=$k[$i] }; for($i=6;$i -lt 10;$i++){ $s5+=$k[$i] }
"KEIHIN_OFF5=" + ('{0:X2}' -f [byte](0-$s5))
