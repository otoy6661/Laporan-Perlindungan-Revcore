$ErrorActionPreference='SilentlyContinue'
$cut=(Get-Date).AddMinutes(-15)
Write-Output '--- RECENT FILES ---'
Get-ChildItem "$env:APPDATA","$env:LOCALAPPDATA" -Recurse -Depth 3 -File -ErrorAction SilentlyContinue |
  Where-Object { $_.LastWriteTime -gt $cut } |
  Select-Object LastWriteTime,Length,FullName | Sort-Object LastWriteTime | Format-Table -AutoSize | Out-String -Width 240
Write-Output '--- REGISTRY KEYS ---'
Get-ChildItem 'HKCU:\Software' -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match 'Tuner|Creational|Mark|Mansur' } | ForEach-Object { $_.Name }
Get-ChildItem 'HKCU:\Software' -Recurse -Depth 2 -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -match 'Tuner|Creational|Mark|Mansur' } | ForEach-Object { $_.Name }
Write-Output '--- INSTALL COPY CHANGED ---'
Get-ChildItem 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY' -Recurse -File |
  Where-Object { $_.LastWriteTime -gt $cut } | Select-Object LastWriteTime,Length,FullName | Format-Table -AutoSize | Out-String -Width 240
