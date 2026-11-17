$root=(Get-Location).Path
Get-ChildItem -Recurse -Filter *.xdf | Where-Object { $_.Length -gt 0 } | ForEach-Object {
  $fs=[IO.File]::OpenRead($_.FullName)
  $b=New-Object byte[] 16
  $n=$fs.Read($b,0,16)
  $fs.Close()
  if($b[0] -ne 0x05){
    $t=[IO.File]::ReadAllText($_.FullName)
    $v=([regex]::Match($t,'XDFFORMAT version="([^"]+)"')).Groups[1].Value
    $ck=([regex]::Matches($t,'<XDFCHECKSUM')).Count
    $tb=([regex]::Matches($t,'<XDFTABLE')).Count
    $cn=([regex]::Matches($t,'<XDFCONSTANT')).Count
    $fl=([regex]::Matches($t,'<XDFFLAG')).Count
    '{0}`t{1}`tver={2}`tck={3}`ttables={4}`tconst={5}`tflags={6}' -f $_.FullName.Substring($root.Length+1),$_.Length,$v,$ck,$tb,$cn,$fl
  }
}
