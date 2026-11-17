$m = Import-Csv 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\13_PROTOTYPES\OUT\DATASET_COMPATIBILITY_MATRIX.csv'
'== kind/plaintext =='
$m | Group-Object kind,plaintext | Sort-Object Name | ForEach-Object { '{0,5}  {1}' -f $_.Count, $_.Name }
'== pair_state =='
$m | Group-Object pair_state | Sort-Object Count -Descending | ForEach-Object { '{0,5}  {1}' -f $_.Count, $_.Name }
'== directory top =='
$m | Group-Object directory | Sort-Object Count -Descending | Select-Object -First 15 | ForEach-Object { '{0,5}  {1}' -f $_.Count, $_.Name }
'== tables distribution =='
$m | Where-Object { $_.kind -eq 'XDF' -and $_.plaintext -eq 'True' } | ForEach-Object { '{0} tables={1} checksums={2} pair={3} file={4}' -f $_.directory, $_.tables, $_.checksums, $_.pair_state, $_.file }
