$ErrorActionPreference='Stop'
function Map($p){
 $b=[IO.File]::ReadAllBytes($p)
 "FILE=$([IO.Path]::GetFileName($p)) SIZE=$($b.Length)"
 $runs=@(); $inRun=$false; $start=0
 for($i=0;$i -lt 0x108;$i++){
   $nz=($b[$i] -ne 0)
   if($nz -and -not $inRun){$start=$i;$inRun=$true}
   if((-not $nz) -and $inRun){$runs += ("0x{0:X3}-0x{1:X3}" -f $start,($i-1));$inRun=$false}
 }
 if($inRun){$runs += ("0x{0:X3}-0x{1:X3}" -f $start,0x107)}
 "NONZERO: " + ($runs -join ', ')
 for($i=0;$i -lt 0x108;$i++){ if($b[$i] -ne 0){ "0x{0:X3}=0x{1:X2}" -f $i,$b[$i] } }
}
Map 'C:\Users\Lord Otoy\Documents\REVCORE_BE10_RESEARCH\PROTOTYPES\testdata\ADX KEIHIN BE.adx'
Map 'C:\Users\Lord Otoy\Documents\REVCORE_BE10_RESEARCH\PROTOTYPES\testdata\ADX SHINDENGEN BE.adx'
# first difference between the two files
$a=[IO.File]::ReadAllBytes('C:\Users\Lord Otoy\Documents\REVCORE_BE10_RESEARCH\PROTOTYPES\testdata\ADX KEIHIN BE.adx')
$c=[IO.File]::ReadAllBytes('C:\Users\Lord Otoy\Documents\REVCORE_BE10_RESEARCH\PROTOTYPES\testdata\ADX SHINDENGEN BE.adx')
for($i=0;$i -lt [Math]::Min($a.Length,$c.Length);$i++){ if($a[$i] -ne $c[$i]){ "FIRST_DIFF=0x{0:X}" -f $i; break } }
# locked XDF preamble comparison sample
$x='C:\Users\Lord Otoy\Downloads\Mobile Devices\REMAP TOOLS BE-09 Revisi 3\FILE BIN XDF ADX\BIN & XDF\ADV\30400-K0WA-N01.xdf'
if(Test-Path $x){ Map $x }
