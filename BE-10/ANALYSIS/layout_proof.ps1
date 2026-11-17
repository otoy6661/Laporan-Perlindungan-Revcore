$ErrorActionPreference='Stop'
$out = New-Object System.Collections.Generic.List[string]

function Hex($b,$o,$n){ ($b[$o..($o+$n-1)] | ForEach-Object { $_.ToString('X2') }) -join ' ' }

$adxDir='C:\Users\Lord Otoy\Documents\REVCORE_BE10_RESEARCH\SOURCES\ADX_D2_TECH'
foreach($f in Get-ChildItem $adxDir -Filter *.adx){
  $b=[IO.File]::ReadAllBytes($f.FullName)
  $out.Add("FILE=$($f.Name) SIZE=$($b.Length)")
  foreach($o in @(0x000,0x080,0x0FC,0x100,0x104,0x108,0x128,0x130,0x133,0x134,0x140)){
    $out.Add(("0x{0:X3}: {1}" -f $o,(Hex $b $o 16)))
  }
  # boundary proof: index of last zero before payload vs tag
  $out.Add(("TAG_0x133=0x{0:X2} PAYLOAD_0x134=0x{1:X2}" -f $b[0x133],$b[0x134]))
  $out.Add("")
}

$xdf='C:\Users\Lord Otoy\Downloads\Mobile Devices\REMAP TOOLS BE-09 Revisi 3\FILE BIN XDF ADX\BIN & XDF\ADV\30400-K0WA-N01.xdf'
$b=[IO.File]::ReadAllBytes($xdf)
$out.Add("LOCKED_XDF=$xdf SIZE=$($b.Length)")
foreach($o in @(0x000,0x080,0x0FC,0x100,0x104,0x108,0x120,0x130,0x133,0x134,0x140)){
  $out.Add(("0x{0:X3}: {1}" -f $o,(Hex $b $o 16)))
}
# compare preamble against ADX KEIHIN
$a=[IO.File]::ReadAllBytes((Join-Path $adxDir 'ADX KEIHIN BE.adx'))
$same=0
for($i=0;$i -lt 0x108;$i++){ if($a[$i] -eq $b[$i]){ $same++ } else { break } }
$out.Add("PREAMBLE_IDENTICAL_UP_TO_0x{0:X}" -f $same)
$out | Set-Content -Path 'C:\Users\Lord Otoy\Documents\REVCORE_BE10_RESEARCH\ANALYSIS\ADX_XDF_LAYOUT_PROOF.txt' -Encoding UTF8
Write-Output 'written'
