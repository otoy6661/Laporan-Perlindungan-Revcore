Get-ChildItem -Path $PSScriptRoot -Filter 'PE_*.json' | ForEach-Object {
  $d = Get-Content $_.FullName -Raw | ConvertFrom-Json
  $r = @($d.Resources)
  Write-Output ("="*70)
  Write-Output ("{0}: {1} resource leaves" -f $_.Name, $r.Count)
  $r | ForEach-Object { Write-Output ("  {0}  rva={1} size={2}" -f $_.Path,$_.RVA,$_.Size) }
}
