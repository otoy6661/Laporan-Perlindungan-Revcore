$id=[int]$env:TPPID
$mods=Get-Process -Id $id -Module -ErrorAction SilentlyContinue
Write-Output ("MODULE_COUNT={0}" -f ($mods | Measure-Object).Count)
$mods | ForEach-Object { Write-Output ('MOD {0}' -f $_.FileName) }
