$ErrorActionPreference='Stop'
$root='C:\Users\Lord Otoy\Documents\REVCORE_BE10_RESEARCH'
$bin=Join-Path $root 'SOURCES\3D_CHART_GRAPH\PROJECT\3D Chart Graph\BEAT -  2020-K1AA-N03.bin'
$b=[IO.File]::ReadAllBytes($bin)
$tpsh=0x39BFE; $rpmh=0x39C38; $feul=0x3815E; $cols=29; $rows=35
"size=$($b.Length)"
"TPS:"
for($c=0;$c -lt $cols;$c++){ $v=[BitConverter]::ToUInt16($b,$tpsh+2*$c); "{0:F1}" -f ($v/10.0) }
"RPM:"
for($r=0;$r -lt $rows;$r++){ $v=[BitConverter]::ToUInt16($b,$rpmh+2*$r); "$v" }
"Fuel first row:"
for($c=0;$c -lt $cols;$c++){ $v=[BitConverter]::ToUInt16($b,$feul+2*$c); "{0:F3}" -f ($v/1000.0) }
"Fuel last row:"
for($c=0;$c -lt $cols;$c++){ $v=[BitConverter]::ToUInt16($b,$feul+2*(($rows-1)*$cols+$c)); "{0:F3}" -f ($v/1000.0) }
