param(
    [string]$Src = 'C:\Users\<USER>\Documents\REVCORE_BE12_FLASHPRO_AUTOPSY\12_EXPERIMENTS\E01_FIRST_LAUNCH\OBSERVATION\CLR_DUMP\US_ONLY.txt',
    [string]$Out = 'C:\Users\<USER>\Documents\REVCORE_BE12_FLASHPRO_AUTOPSY\05_ECU_IDENTIFICATION\extract'
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path $Out | Out-Null
$lines = Get-Content -LiteralPath $Src

# BIN catalog: strings starting FLASHPRO. and ending .bin
$bins = $lines | Where-Object { $_ -match '^FLASHPRO\..+\.bin$' } | Sort-Object -Unique
$binRows = foreach ($b in $bins) {
    $name = $b -replace '^FLASHPRO\.', '' -replace '\.bin$', ''
    $model = ($name -split '[- ]')[0]
    [pscustomobject]@{ resource_file = $b; stripped_name = $name; first_token = $model }
}
$binRows | Export-Csv -LiteralPath (Join-Path $Out 'BIN_CATALOG.csv') -NoTypeInformation -Encoding UTF8

# DTC pairs: code line like 1-1, then description line
$dtc = New-Object System.Collections.Generic.List[object]
for ($i = 0; $i -lt $lines.Count - 1; $i++) {
    if ($lines[$i] -match '^\d{1,2}-\d$' -and $lines[$i+1] -match '^[A-Za-z0-9].{3,}$') {
        $dtc.Add([pscustomobject]@{ code = $lines[$i]; description = $lines[$i+1] })
    }
}
$dtc | Export-Csv -LiteralPath (Join-Path $Out 'DTC_CODES.csv') -NoTypeInformation -Encoding UTF8

# Part codes appearing in strings
$pc = New-Object System.Collections.Generic.List[object]
foreach ($l in $lines) {
    foreach ($m in [regex]::Matches($l, '\b(?:30400|38770)-[A-Z0-9]{2,5}-[A-Z0-9]{2,4}\b')) {
        $pc.Add([pscustomobject]@{ part_code = $m.Value; source_string = $l })
    }
}
$pc | Sort-Object part_code, source_string -Unique | Export-Csv -LiteralPath (Join-Path $Out 'PART_CODES.csv') -NoTypeInformation -Encoding UTF8

'BIN=' + $binRows.Count
'DTC=' + $dtc.Count
'PART_CODES=' + ($pc | Sort-Object part_code -Unique).Count
