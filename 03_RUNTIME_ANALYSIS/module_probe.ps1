$ErrorActionPreference='Stop'
$exe='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$p=Start-Process -FilePath $exe -PassThru -WorkingDirectory (Split-Path $exe)
for($i=0;$i -lt 40;$i++){ Start-Sleep -Milliseconds 400; $p.Refresh(); if($p.MainWindowHandle -ne 0){break} }
Start-Sleep -Seconds 5; $p.Refresh()
Write-Output ("TITLE={0}" -f $p.MainWindowTitle)
$env:TPPID="$($p.Id)"
& "$env:WINDIR\SysWOW64\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\modules32.ps1'
$p.CloseMainWindow() | Out-Null
Start-Sleep -Seconds 2
if(-not $p.HasExited){ $p.Kill() }
