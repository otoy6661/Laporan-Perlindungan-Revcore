$ErrorActionPreference='Stop'
$app='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY'
$exe=Join-Path $app 'TunerPro.exe'
$target=Join-Path $app 'TPChecksumPlugin.dll'
$off=Join-Path $app 'TPChecksumPlugin.dll.off'
if(Test-Path $off){ Remove-Item $off -Force }
Rename-Item $target $off
$p=$null
try{
  $p=Start-Process -FilePath $exe -PassThru -WorkingDirectory $app
  for($i=0;$i -lt 40;$i++){ Start-Sleep -Milliseconds 400; $p.Refresh(); if($p.MainWindowHandle -ne 0){break} }
  Start-Sleep -Seconds 5; $p.Refresh()
  Write-Output ("TITLE={0}" -f $p.MainWindowTitle)
  $env:TPPID="$($p.Id)"
  & "$env:WINDIR\SysWOW64\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\modules32.ps1'
} finally {
  if($p -and -not $p.HasExited){ $p.CloseMainWindow() | Out-Null; Start-Sleep -Seconds 2; if(-not $p.HasExited){ $p.Kill() } }
  if(Test-Path $off){ Rename-Item $off $target -Force }
}
Write-Output ("RESTORED={0}" -f (Test-Path $target))
