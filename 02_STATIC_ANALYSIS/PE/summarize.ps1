$ErrorActionPreference='Stop'
Get-ChildItem -Path $PSScriptRoot -Filter 'PE_*.json' | ForEach-Object {
  $d = Get-Content $_.FullName -Raw | ConvertFrom-Json
  Write-Output ("="*70)
  Write-Output ("FILE {0}  machine={1} bytes={2} dll={3} sections={4}" -f $_.Name,$d.MachineName,$d.Bytes,$d.IsDll,$d.Sections)
  foreach($k in @('Exports','Imports','DelayImports')){
    $v = $d.$k
    if($null -eq $v){ Write-Output (" {0}: none" -f $k); continue }
    if($v -is [System.Array]){
      Write-Output (" {0}: {1}" -f $k,$v.Count)
      if($k -eq 'Exports'){ $v | ForEach-Object { Write-Output ("   EXP {0}" -f $_) } }
    } else {
      $names = ($v.PSObject.Properties.Name) -join ','
      Write-Output (" {0}: {1}" -f $k,$names)
    }
  }
  if($d.Resources){ Write-Output (" resources: {0}" -f (($d.Resources | ForEach-Object { $_.Type }) -join ',')) }
}
