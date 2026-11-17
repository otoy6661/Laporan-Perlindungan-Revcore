$root='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\DATASET_COPY'
Get-ChildItem -Path $root -Recurse -Filter '*.xdf' | Where-Object { $_.Name -match 'MGP|K41' } | Select-Object -First 20 -ExpandProperty FullName
