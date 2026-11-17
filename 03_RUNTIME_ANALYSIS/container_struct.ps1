param([string]$File,[string]$Out)
$b=[IO.File]::ReadAllBytes($File)
$sb=New-Object System.Text.StringBuilder
function W($s){ [void]$sb.AppendLine($s); Write-Output $s }
W ("FILE={0}" -f $File)
W ("SIZE={0}" -f $b.Length)
W '--- FIRST 256 BYTES ---'
for($i=0;$i -lt [Math]::Min(256,$b.Length);$i+=16){
  $chunk=$b[$i..([Math]::Min($i+15,$b.Length-1))]
  $h=($chunk | ForEach-Object { $_.ToString('X2') }) -join ' '
  $a=($chunk | ForEach-Object { if($_ -ge 32 -and $_ -lt 127){[char]$_}else{'.'} }) -join ''
  W ('{0:X4}  {1,-48}  {2}' -f $i,$h,$a)
}
W '--- LAST 64 BYTES ---'
$start=[Math]::Max(0,$b.Length-64)
for($i=$start;$i -lt $b.Length;$i+=16){
  $chunk=$b[$i..([Math]::Min($i+15,$b.Length-1))]
  $h=($chunk | ForEach-Object { $_.ToString('X2') }) -join ' '
  $a=($chunk | ForEach-Object { if($_ -ge 32 -and $_ -lt 127){[char]$_}else{'.'} }) -join ''
  W ('{0:X4}  {1,-48}  {2}' -f $i,$h,$a)
}
W '--- ENTROPY ---'
function Ent($arr,$s,$e){
  $freq=New-Object int[] 256
  for($i=$s;$i -lt $e;$i++){ $freq[$arr[$i]]++ }
  $n=$e-$s; $h=0.0
  for($k=0;$k -lt 256;$k++){ if($freq[$k] -gt 0){ $p=$freq[$k]/$n; $h -= $p*[Math]::Log($p,2) } }
  return $h
}
W ("ENTROPY_ALL={0:F4}" -f (Ent $b 0 $b.Length))
W ("ENTROPY_AFTER_132={0:F4}" -f (Ent $b 132 $b.Length))
W '--- ASCII STRINGS >= 5 ---'
$s=[Text.Encoding]::ASCII.GetString($b)
$m=[regex]::Matches($s,'[\x20-\x7E]{5,}')
$count=0
foreach($x in $m){ $count++; if($count -le 60){ W ('STR 0x{0:X5} {1}' -f $x.Index,$x.Value) } }
W ("ASCII_STRING_COUNT={0}" -f $m.Count)
W '--- 16-BYTE BLOCK DUPLICATES ---'
$seen=@{}
$dups=0
for($i=0;$i+16 -le $b.Length;$i+=16){
  $key=[BitConverter]::ToString($b,$i,16)
  if($seen.ContainsKey($key)){ $dups++ } else { $seen[$key]=$i }
}
W ("BLOCK_COUNT={0} DUPLICATE_BLOCKS={1}" -f [Math]::Floor($b.Length/16),$dups)
W '--- VARIABLE HEADER BYTES (first 132) ---'
$hdr=($b[0..131] | ForEach-Object { $_.ToString('X2') }) -join ' '
W $hdr
$sb.ToString() | Set-Content -Path $Out -Encoding UTF8
