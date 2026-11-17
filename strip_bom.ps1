$ErrorActionPreference='Stop'
$root='C:\Users\Lord Otoy\Documents\REVCORE_BE10_RESEARCH'
$enc=New-Object System.Text.UTF8Encoding($false)
foreach($n in @('README.md','BE10_ARTIFACT_INDEX.md')){
  $p=Join-Path $root $n
  $t=[IO.File]::ReadAllText($p)
  [IO.File]::WriteAllText($p,$t,$enc)
  Write-Output ("REWROTE_NO_BOM " + $n + " " + $t.Length)
}
