$ErrorActionPreference='Stop'
foreach($f in @('PROTOTYPES\testdata\ADX KEIHIN BE.adx','PROTOTYPES\testdata\ADX SHINDENGEN BE.adx')){
 $b=[IO.File]::ReadAllBytes((Join-Path 'C:\Users\Lord Otoy\Documents\REVCORE_BE10_RESEARCH' $f))
 "FILE=$f SIZE=$($b.Length)"
 foreach($o in @(0x100,0x104,0x108,0x120,0x130,0x133,0x134,0x135,0x136)){
   $len=16
   $hex=($b[$o..([Math]::Min($o+$len-1,$b.Length-1))] | ForEach-Object { $_.ToString('X2') }) -join ' '
   "0x{0:X3}: {1}" -f $o,$hex
 }
}
