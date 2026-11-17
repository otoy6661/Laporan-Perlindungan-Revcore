$ErrorActionPreference='Stop'
$root='C:\Users\Lord Otoy\Documents\REVCORE_BE10_RESEARCH'
$manifest=Join-Path $root 'REPORTS\BE10_SHA256_MANIFEST.csv'
$rows=Import-Csv $manifest
$lines=New-Object System.Collections.Generic.List[string]
$lines.Add('"Category","Provenance","SizeBytes","RelPath","SHA256"')
$missing=0
foreach($r in $rows){
  $p=Join-Path $root $r.RelPath
  if(Test-Path -LiteralPath $p -PathType Leaf){
    $item=Get-Item -LiteralPath $p
    $h=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash.ToLower()
    $lines.Add(('"{0}","{1}",{2},"{3}","{4}"' -f $r.Category,$r.Provenance,$item.Length,$r.RelPath,$h))
  } else {
    $missing++
    $lines.Add(('"{0}","{1}",{2},"{3}","{4}"' -f $r.Category,$r.Provenance,$r.SizeBytes,$r.RelPath,$r.SHA256))
  }
}
$lines | Set-Content -LiteralPath $manifest -Encoding UTF8
Write-Output ("REFRESHED=" + ($rows.Count - $missing) + " MISSING=" + $missing + " TOTAL=" + $rows.Count)
