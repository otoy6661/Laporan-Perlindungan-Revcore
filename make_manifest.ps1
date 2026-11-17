$ErrorActionPreference = 'Stop'
$root = 'C:\Users\Lord Otoy\Documents\REVCORE_BE10_RESEARCH'
$rows = New-Object System.Collections.Generic.List[object]
function Add-Tree([string]$base, [string]$category, [string]$provenance) {
    Get-ChildItem -LiteralPath $base -Recurse -File | ForEach-Object {
        $h = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
        $rows.Add([pscustomobject]@{
            Category   = $category
            Provenance = $provenance
            SizeBytes  = $_.Length
            RelPath    = $_.FullName.Substring($root.Length + 1).Replace('\','/')
            SHA256     = $h.Hash.ToLower()
        })
    }
}
Add-Tree (Join-Path $root 'SOURCES\ADX_D2_TECH') 'ADX_SOURCE' 'Copied unmodified from Downloads REMAP TOOLS BE-09 Revisi 3\FILE BIN XDF ADX\ADX-D2 TECH'
Add-Tree (Join-Path $root 'SOURCES\3D_CHART_GRAPH\PROJECT') '3D_SOURCE' 'Copied from Downloads 3D Chart Graph remap kline (excluded .vs/bin/obj/packages)'
Add-Tree (Join-Path $root 'SOURCES\3D_CHART_GRAPH') '3D_SOLUTION_ZIP' 'Solution/archives copied from Downloads 3D Chart Graph remap kline'
Add-Tree (Join-Path $root 'EXTRACTED_ZIPS') 'EXTRACTED_ZIP' 'Extracted from SOURCES/3D_CHART_GRAPH/ZIPS (no overwrite, original paths preserved)'
$rows | Sort-Object RelPath | Export-Csv -LiteralPath (Join-Path $root 'REPORTS\BE10_SHA256_MANIFEST.csv') -NoTypeInformation -Encoding UTF8
"Rows: $($rows.Count)"
$rows | Group-Object Category | ForEach-Object { "$($_.Name): $($_.Count)" }
