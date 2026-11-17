$ErrorActionPreference='Stop'
$rows = Import-Csv 'C:\Users\Lord Otoy\Documents\REVCORE_BE10_RESEARCH\ANALYSIS\3D_MAP_DATABASE.csv'
"ROWS=$($rows.Count)"
$rows | Group-Object kon | Sort-Object Count -Descending | ForEach-Object { "KON=$($_.Name) COUNT=$($_.Count)" }
"RESOURCES_UNIQUE=$(($rows | Select-Object -ExpandProperty Resource -Unique).Count)"
"COLS=$(($rows | Select-Object -ExpandProperty columnCount -Unique) -join ',')"
"ROWS_AXIS=$(($rows | Select-Object -ExpandProperty rowCount -Unique) -join ',')"
$beOffsets = $rows | Where-Object { $_.feul1 -match '0x3911C|0x3A804|0x3A258|0x396C8' }
"BE_TABLE_ROWS=$($beOffsets.Count)"
$beOffsets | ForEach-Object { "BE: $($_.Name) feul1=$($_.feul1)" }
