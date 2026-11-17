$ErrorActionPreference='Stop'
$root='C:\Users\Lord Otoy\Documents\REVCORE_BE10_RESEARCH'
$src=Join-Path $root 'SOURCES\3D_CHART_GRAPH\PROJECT\3D Chart Graph\Form1.cs'
$t=[IO.File]::ReadAllText($src)
function Get-Arr([string]$name){
  $m=[regex]::Match($t,'(?s)private static readonly string\[\] '+[regex]::Escape($name)+'\s*=\s*new string\[\]\s*\{(?<body>.*?)\};')
  if(-not $m.Success){ throw "array not found: $name" }
  $vals=[regex]::Matches($m.Groups['body'].Value,'"([^"]*)"') | ForEach-Object { $_.Groups[1].Value }
  ,$vals
}
$khId=Get-Arr 'khEcmId'; $khPart=Get-Arr 'khPartCode'; $khStart=Get-Arr 'khStartOffset'; $khCk=Get-Arr 'khCksumOffset'
$shId=Get-Arr 'shEcmId'; $shPart=Get-Arr 'shPartCode'
"kh counts: id=$($khId.Count) part=$($khPart.Count) start=$($khStart.Count) ck=$($khCk.Count)"
"sh counts: id=$($shId.Count) part=$($shPart.Count)"
$rows=@()
for($i=0;$i -lt [Math]::Max($khId.Count,$khPart.Count);$i++){
  $rows += [pscustomobject]@{ Family='KEIHIN'; Index=$i; EcmId=$(if($i -lt $khId.Count){$khId[$i]}else{''}); PartCode=$(if($i -lt $khPart.Count){$khPart[$i]}else{''}); StartOffset=$(if($i -lt $khStart.Count){$khStart[$i]}else{''}); ChecksumOffset=$(if($i -lt $khCk.Count){$khCk[$i]}else{''}) }
}
for($i=0;$i -lt [Math]::Max($shId.Count,$shPart.Count);$i++){
  $rows += [pscustomobject]@{ Family='SHINDENGEN'; Index=$i; EcmId=$(if($i -lt $shId.Count){$shId[$i]}else{''}); PartCode=$(if($i -lt $shPart.Count){$shPart[$i]}else{''}); StartOffset='auto'; ChecksumOffset='auto' }
}
$rows | Export-Csv -LiteralPath (Join-Path $root 'ANALYSIS\3D_ECU_ID_DATABASE.csv') -NoTypeInformation -Encoding UTF8
"total rows: $($rows.Count)"
$rows | Group-Object Family | ForEach-Object { "$($_.Name): $($_.Count)" }
