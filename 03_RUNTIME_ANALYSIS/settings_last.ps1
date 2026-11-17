$path=Join-Path $env:USERPROFILE 'Documents\TunerPro Files\TunerProSettings.dat'
$b=[IO.File]::ReadAllBytes($path)
$s=[Text.Encoding]::ASCII.GetString($b)
$idx=$s.IndexOf('SUPRA')
Write-Output ('IDX='+$idx)
if($idx -ge 0){ Write-Output $s.Substring([Math]::Max(0,$idx-120),360) }
Write-Output '--- strings with .bin ---'
$m=[regex]::Matches($s,'[\x20-\x7E]{6,}\.bin')
foreach($x in $m){ Write-Output $x.Value }
