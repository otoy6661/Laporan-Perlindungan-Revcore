$ErrorActionPreference='Stop'
function S32($d,$s,$l){ [uint32]$sum=0; $e=$s+$l; while($s+4 -le $e){ $sum=[uint32]($sum + [BitConverter]::ToUInt32($d,$s)); $s+=4 }; return $sum }
$d=New-Object byte[] 32
for($i=0;$i -lt 32;$i++){ $d[$i]=[byte]$i }
for($i=12;$i -le 15;$i++){ $d[$i]=0 }
$tot=[uint32]((S32 $d 0 12) + (S32 $d 16 16))
$ck=[uint32](0x100000000 - [uint64]$tot)
"TOTAL_SUM=$tot CK=$ck HEX=" + ('{0:X8}' -f $ck)
$k=New-Object byte[] 10
for($i=0;$i -lt 10;$i++){ $k[$i]=[byte]($i+1) }
$s0=0; for($i=1;$i -lt 10;$i++){ $s0+=$k[$i] }
"KEIHIN_OFF0=" + ('{0:X2}' -f [byte](0-$s0))
$s5=0; for($i=0;$i -lt 5;$i++){ $s5+=$k[$i] }; for($i=6;$i -lt 10;$i++){ $s5+=$k[$i] }
"KEIHIN_OFF5=" + ('{0:X2}' -f [byte](0-$s5))
