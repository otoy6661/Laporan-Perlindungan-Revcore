$ErrorActionPreference='Stop'
$root='C:\Users\Lord Otoy\Documents\REVCORE_BE10_RESEARCH'
$src=Join-Path $root 'SOURCES\3D_CHART_GRAPH\PROJECT\3D Chart Graph\Form1.cs'
$t=[IO.File]::ReadAllText($src)
$rx=[regex]'(?s)if \(selectedItem == "(?<name>[^"]+)"\)\s*\{(?<body>.*?)\n\s*resourceName = "(?<res>[^"]+)";'
$ms=$rx.Matches($t)
"blocks: $($ms.Count)"
$fields='columnCount','rowCount','tpsh','rpmh','iaph','feul1','feul2','feul3','ig1','ig2','ig3','ig4','ig5','limit1','limit2','limit3','limit4','limit5','limit6','limit7','lm','o2','o2c','IMMO','MODE0','MODE1','MODE2','MODE3','MODE4','kon'
$rows=@()
foreach($m in $ms){
  $o=[ordered]@{ Index=$m.Groups['name'].Value; Name=$m.Groups['name'].Value; Resource=$m.Groups['res'].Value }
  foreach($f in $fields){
    $mm=[regex]::Match($m.Groups['body'].Value, '(?m)\b'+[regex]::Escape($f)+'\s*=\s*(0[xX][0-9A-Fa-f]+|\d+(?:\.\d+)?[fF]?)\s*;')
    $o[$f]= if($mm.Success){$mm.Groups[1].Value}else{''}
  }
  $rows += [pscustomobject]$o
}
$rows | Export-Csv -LiteralPath (Join-Path $root 'ANALYSIS\3D_MAP_DATABASE.csv') -NoTypeInformation -Encoding UTF8
"rows: $($rows.Count)"
$rows | Select-Object -First 3 | Format-List
"unique names: $((($rows | Select-Object -ExpandProperty Name) | Sort-Object -Unique).Count)"
"missing feul1: $(($rows | Where-Object {$_.feul1 -eq ''}).Count)"
