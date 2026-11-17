$ErrorActionPreference='Stop'
$base='C:\Users\Lord Otoy\Downloads\Mobile Devices\REMAP TOOLS BE-09 Revisi 3\FILE BIN XDF ADX\BIN & XDF'
$files=Get-ChildItem -LiteralPath $base -Recurse -Filter *.xdf | Select-Object -First 8
foreach($f in $files){
  $b=[IO.File]::ReadAllBytes($f.FullName)
  $magic=($b[0..([Math]::Min(7,$b.Length-1))] | ForEach-Object {$_.ToString('X2')}) -join ' '
  $has=$false; $off=-1
  for($i=0;$i -le $b.Length-45;$i++){ if($b[$i] -eq 0x25 -and $b[$i+1] -eq 0xA5 -and $b[$i+2] -eq 0x9E -and $b[$i+3] -eq 0x70){$has=$true;$off=$i;break} }
  "{0}`n  size={1} magic={2} constant={3} at=0x{4:X}" -f $f.FullName,$b.Length,$magic,$has,$off
}
