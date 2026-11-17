$ErrorActionPreference = 'Stop'
$root = 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY'
$out  = Join-Path $root '15_EVIDENCE\EVIDENCE_MANIFEST.csv'

$dirs = @(
  '14_FINAL_REPORTS',
  '13_PROTOTYPES\PeScope',
  '13_PROTOTYPES\TpFormatKit',
  '13_PROTOTYPES\OUT',
  '02_STATIC_ANALYSIS\PE',
  '03_RUNTIME_ANALYSIS',
  '05_XDF_AUTOPSY',
  '06_ADX_AUTOPSY',
  '11_EXPERIMENTS',
  '00_SOURCE_INVENTORY'
)

$skipDir = @('obj','bin','APP_COPY','DATASET_COPY')
$rows = New-Object System.Collections.Generic.List[object]

foreach ($d in $dirs) {
  $base = Join-Path $root $d
  if (-not (Test-Path $base)) { continue }
  Get-ChildItem -Path $base -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($root.Length + 1)
    $parts = $rel -split '\\'
    $skip = $false
    foreach ($p in $parts) { if ($skipDir -contains $p) { $skip = $true } }
    if ($skip) { return }
    if ($_.Name -eq 'EVIDENCE_MANIFEST.csv') { return }
    $h = (Get-FileHash -Algorithm SHA256 -Path $_.FullName).Hash.ToLower()
    $rows.Add([pscustomobject]@{
      path = $rel
      bytes = $_.Length
      sha256 = $h
    })
  }
}

$rows | Sort-Object path | Export-Csv -Path $out -NoTypeInformation -Encoding UTF8
"WROTE=$out"
"FILES=$($rows.Count)"
"TOTAL_BYTES=$(($rows | Measure-Object bytes -Sum).Sum)"
