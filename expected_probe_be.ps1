$ErrorActionPreference='Stop'
$p='C:\Users\Lord Otoy\Documents\REVCORE_BE10_RESEARCH\PROTOTYPES\testdata\k46n21.bin'
$b=[IO.File]::ReadAllBytes($p)
function U16BE($b,$o){ return ([int]$b[$o] -shl 8) -bor [int]$b[$o+1] }
$tpsh=0x390AC;$rpmh=0x390E0;$feul=0x3911C;$rows=29;$cols=25
"SIZE=$($b.Length)"
"TPS raw0=$(U16BE $b $tpsh) raw1=$(U16BE $b ($tpsh+2)) rawN=$(U16BE $b ($tpsh+($cols-1)*2))  vals=$((U16BE $b $tpsh)/10),$((U16BE $b ($tpsh+2))/10),$((U16BE $b ($tpsh+($cols-1)*2))/10)"
"RPM raw0=$(U16BE $b $rpmh) raw1=$(U16BE $b ($rpmh+2)) rawN=$(U16BE $b ($rpmh+($rows-1)*2))  vals=$(U16BE $b $rpmh),$(U16BE $b ($rpmh+2)),$(U16BE $b ($rpmh+($rows-1)*2))"
$min=65535;$max=0
for($r=0;$r -lt $rows;$r++){for($c=0;$c -lt $cols;$c++){$v=U16BE $b ($feul+($r*$cols+$c)*2); if($v -lt $min){$min=$v};if($v -gt $max){$max=$v}}}
"FUEL first=$(U16BE $b $feul) last=$(U16BE $b ($feul+($rows*$cols-1)*2)) min=$min max=$max vals=$((U16BE $b $feul)/1000),$((U16BE $b ($feul+($rows*$cols-1)*2))/1000),$($min/1000),$($max/1000)"
