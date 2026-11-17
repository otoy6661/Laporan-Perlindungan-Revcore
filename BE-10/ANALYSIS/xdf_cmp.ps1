$x='C:\Users\Lord Otoy\Downloads\Mobile Devices\REMAP TOOLS BE-09 Revisi 3\FILE BIN XDF ADX\BIN & XDF\ADV\30400-K0WA-N01.xdf'
$b=[IO.File]::ReadAllBytes($x)
foreach($o in @(0x100,0x108,0x120,0x130,0x133,0x134,0x135)){ $hex=($b[$o..($o+15)] | ForEach-Object { $_.ToString('X2') }) -join ' '; "0x{0:X3}: {1}" -f $o,$hex }
# find first nonzero after 0x108
for($i=0x108;$i -lt $b.Length;$i++){ if($b[$i] -ne 0){ "FIRST_NONZERO_AFTER_108=0x{0:X}" -f $i; break } }
