$root='C:\Users\Lord Otoy\Downloads\Mobile Devices\REMAP TOOLS BE-09 Revisi 3\FILE BIN XDF ADX'
$i=0
Get-ChildItem -Path $root -Recurse -Filter *.xdf | ForEach-Object {
  $b=New-Object byte[] 4
  $fs=[IO.File]::OpenRead($_.FullName)
  [void]$fs.Read($b,0,4)
  $fs.Close()
  if($b[0] -eq 5 -and $b[1] -eq 0x22 -and $b[2] -eq 0x97 -and $b[3] -eq 0){
    $i++
    if($i -le 6){ Write-Output ('{0}|{1}' -f $_.Length,$_.FullName) }
  }
}
Write-Output ('TOTAL='+$i)
