$ErrorActionPreference='Stop'
$td='C:\Users\Lord Otoy\Documents\REVCORE_BE10_RESEARCH\PROTOTYPES\testdata'
function U16LE($b,$o){ return [int]$b[$o] -bor ([int]$b[$o+1] -shl 8) }
function U16BE($b,$o){ return ([int]$b[$o] -shl 8) -bor [int]$b[$o+1] }
$cases=@(
 @{f='k1aa_n03.bin';tpsh=0x39BFE;rpmh=0x39C38;feul=0x3815E;rows=35;cols=29;kon=1.0},
 @{f='k59a_a11.bin';tpsh=0x1A58C;rpmh=0x1A5BE;feul=0x190EC;rows=29;cols=25;kon=1.0},
 @{f='k25g_601.bin';tpsh=0x1A5D4;rpmh=0x1A606;feul=0x19130;rows=29;cols=25;kon=1.0},
 @{f='kzrb31.bin';tpsh=0x1A860;rpmh=0x1A892;feul=0x194C0;rows=29;cols=25;kon=1.0}
)
foreach($c in $cases){
  $p=Join-Path $td $c.f
  $b=[IO.File]::ReadAllBytes($p)
  "FILE=$($c.f) SIZE=$($b.Length)"
  $tps0=U16LE $b $c.tpsh; $tps1=U16LE $b ($c.tpsh+2); $tpsN=U16LE $b ($c.tpsh+($c.cols-1)*2)
  $rpm0=U16LE $b $c.rpmh; $rpm1=U16LE $b ($c.rpmh+2); $rpmN=U16LE $b ($c.rpmh+($c.rows-1)*2)
  "TPS raw0=$tps0 raw1=$tps1 rawN=$tpsN  vals=$($tps0/10),$($tps1/10),$($tpsN/10)"
  "RPM raw0=$rpm0 raw1=$rpm1 rawN=$rpmN  vals=$($rpm0/$c.kon),$($rpm1/$c.kon),$($rpmN/$c.kon)"
  $min=65535;$max=0;$first=0;$last=0
  for($r=0;$r -lt $c.rows;$r++){ for($col=0;$col -lt $c.cols;$col++){
    $v=U16LE $b ($c.feul+($r*$c.cols+$col)*2)
    if($r -eq 0 -and $col -eq 0){$first=$v}
    if($r -eq $c.rows-1 -and $col -eq $c.cols-1){$last=$v}
    if($v -lt $min){$min=$v}; if($v -gt $max){$max=$v}
  }}
  "FUEL first=$first last=$last min=$min max=$max  vals=$($first/1000),$($last/1000),$($min/1000),$($max/1000)"
}
