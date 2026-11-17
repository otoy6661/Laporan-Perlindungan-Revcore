$inv = Import-Csv 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\DATASET_INVENTORY.csv'
'== extension counts =='
$inv | Group-Object Extension | Sort-Object Count -Descending | ForEach-Object { '{0,5}  {1}' -f $_.Count, $_.Name }
'== total bytes =='
($inv | Measure-Object Bytes -Sum).Sum
'== BIN size distribution =='
$inv | Where-Object { $_.Extension -eq '.bin' } | Group-Object Bytes | Sort-Object Count -Descending | ForEach-Object { '{0,5}  {1} bytes' -f $_.Count, $_.Name }
'== app inventory =='
Import-Csv 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_INVENTORY.csv' | ForEach-Object { '{0,-32} {1,10} {2}' -f $_.RelPath, $_.Bytes, $_.SHA256 }
