$ErrorActionPreference='Stop'
$root='C:\Users\Lord Otoy\Documents\REVCORE_BE10_RESEARCH'
$files=@('SOURCES\ADX_D2_TECH\ADX KEIHIN BE.adx','SOURCES\ADX_D2_TECH\ADX SHINDENGEN BE.adx')
$const=[byte[]](0x25,0xA5,0x9E,0x70,0xF5,0x74,0x90,0x15,0xB9,0xD0,0x45,0x60,0x38,0xBE,0x47,0xC5,0x29,0x51,0x79,0x36,0xF5,0x89,0x52,0xEB,0x9C,0x85,0xDC,0x0F,0x61,0xA6,0xA5,0x77,0x06,0x43,0xC2,0xC5,0x6F,0xA1,0x75,0x67,0x33,0x70,0x15,0x03)
foreach($f in $files){
  $p=Join-Path $root $f; $b=[IO.File]::ReadAllBytes($p)
  "=== $f size=$($b.Length) ==="
  # find constant
  for($i=0;$i -le $b.Length-$const.Length;$i++){
    $ok=$true; for($j=0;$j -lt $const.Length;$j++){ if($b[$i+$j] -ne $const[$j]){$ok=$false;break} }
    if($ok){ "const45 at 0x{0:X}" -f $i }
  }
  # find all zeros runs >=16
  $run=0; $start=0
  for($i=0;$i -lt $b.Length;$i++){
    if($b[$i] -eq 0){ if($run -eq 0){$start=$i}; $run++ } else { if($run -ge 32){ "zero-run 0x{0:X} len {1}" -f $start,$run }; $run=0 }
  }
  if($run -ge 32){ "zero-run 0x{0:X} len {1}" -f $start,$run }
  # hex 0xE0-0x140
  $s=0xE0; $e=[Math]::Min(0x140,$b.Length-1)
  for($i=$s;$i -lt $e;$i+=16){
    $line=($b[$i..([Math]::Min($i+15,$e))] | ForEach-Object { $_.ToString('X2') }) -join ' '
    "0x{0:X4}: {1}" -f $i,$line
  }
  # tail 32
  $t=[Math]::Max(0,$b.Length-32)
  "tail 0x{0:X}: {1}" -f $t, (($b[$t..($b.Length-1)] | ForEach-Object { $_.ToString('X2') }) -join ' ')
  # ciphertext length after 0x64
  "payload after 0x64 = $($b.Length-0x64) mod16 = $(($b.Length-0x64)%16)"
}
