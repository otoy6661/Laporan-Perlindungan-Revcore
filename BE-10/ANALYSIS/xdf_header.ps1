$p='C:\Users\Lord Otoy\Downloads\Mobile Devices\REMAP TOOLS BE-09 Revisi 3\FILE BIN XDF ADX\BIN & XDF\ADV\30400-K0WA-N01.xdf'
$b=[IO.File]::ReadAllBytes($p)
for($i=0xE0;$i -lt 0x140;$i+=16){
  $end=[Math]::Min($i+15,$b.Length-1)
  '{0:X4}: {1}' -f $i, (($b[$i..$end] | ForEach-Object { $_.ToString('X2') }) -join ' ')
}
$run=0;$start=0
for($i=0;$i -lt $b.Length;$i++){ if($b[$i] -eq 0){ if($run -eq 0){$start=$i}; $run++ } else { if($run -ge 32){ 'zero-run 0x{0:X} len {1}' -f $start,$run }; $run=0 } }
if($run -ge 32){ 'zero-run 0x{0:X} len {1}' -f $start,$run }
