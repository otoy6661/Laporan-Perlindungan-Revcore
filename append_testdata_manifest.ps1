$ErrorActionPreference='Stop'
$root='C:\Users\Lord Otoy\Documents\REVCORE_BE10_RESEARCH'
$man=Join-Path $root 'REPORTS\BE10_SHA256_MANIFEST.csv'
$existing=Get-Content $man | ForEach-Object { $_ }
$paths=Get-ChildItem (Join-Path $root 'PROTOTYPES\testdata') -File | Sort-Object Name
$lines=@()
foreach($f in $paths){
  $rel='PROTOTYPES/testdata/'+$f.Name
  $h=(Get-FileHash $f.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
  $lines += ('"PROTOTYPE_TESTDATA","Read-only test copy; origin documented in BE10_ARTIFACT_INDEX.md","{0}","{1}","{2}"' -f $f.Length,$rel,$h)
}
$existing + $lines | Set-Content $man -Encoding UTF8
"appended=$($lines.Count) total=$((Get-Content $man).Count)"
