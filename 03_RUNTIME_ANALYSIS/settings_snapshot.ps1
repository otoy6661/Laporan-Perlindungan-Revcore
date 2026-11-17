$dir = Join-Path $env:USERPROFILE 'Documents\TunerPro Files'
Get-ChildItem $dir -File | ForEach-Object {
  '{0,-28} {1,8} {2:yyyy-MM-dd HH:mm:ss}' -f $_.Name, $_.Length, $_.LastWriteTime
}
'--- ASCII/UTF16 paths in TunerProSettings.dat ---'
$b = [IO.File]::ReadAllBytes((Join-Path $dir 'TunerProSettings.dat'))
$ascii = [Text.Encoding]::ASCII.GetString($b)
[regex]::Matches($ascii, '[\x20-\x7E]{4,}\.(bin|xdf|adx)') | Select-Object -First 20 | ForEach-Object { $_.Value }
$uni = [Text.Encoding]::Unicode.GetString($b)
'--- utf16 ---'
[regex]::Matches($uni, '[\x20-\x7E]{4,}\.(bin|xdf|adx)') | Select-Object -First 20 | ForEach-Object { $_.Value }
'--- TPSPMSettings.dat strings ---'
$s = [IO.File]::ReadAllBytes((Join-Path $dir 'TPSPMSettings.dat'))
[Text.Encoding]::ASCII.GetString($s) -replace "[\x00-\x1F]", ' '
'--- TPEmuPlugin.dat ---'
$e = [IO.File]::ReadAllBytes((Join-Path $dir 'TPEmuPlugin.dat'))
($e | ForEach-Object { $_.ToString('X2') }) -join ' '
