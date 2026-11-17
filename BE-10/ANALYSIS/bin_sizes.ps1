$b=Get-ChildItem 'C:\Users\Lord Otoy\Documents\REVCORE_BE10_RESEARCH\SOURCES\3D_CHART_GRAPH\PROJECT\3D Chart Graph\*.bin'
"COUNT=$($b.Count)"
$b | Group-Object Length | Sort-Object Name | ForEach-Object { "$($_.Count) x $($_.Name) bytes" }
