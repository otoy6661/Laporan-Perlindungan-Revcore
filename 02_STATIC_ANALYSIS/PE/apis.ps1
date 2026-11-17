$ErrorActionPreference='Stop'
$pat = 'Reg|CreateFile|WriteFile|ReadFile|CreateDirectory|GetPrivateProfile|WritePrivateProfile|GetModuleFileName|LoadLibrary|GetProcAddress|WinInet|Internet|Http|Socket|connect|send|recv|Comm|SetupComm|PurgeComm|EscapeComm|SetComm|GetComm|CreateThread|Event|Mutex|CriticalSection|FindFirst|FindNext|CopyFile|MoveFile|DeleteFile|SHGetFolder|GetTempPath|GetWindowsDirectory|GetSystemDirectory|ShellExecute|CreateProcess'
Get-ChildItem -Path $PSScriptRoot -Filter 'PE_*.json' | ForEach-Object {
  $d = Get-Content $_.FullName -Raw | ConvertFrom-Json
  Write-Output ("="*78)
  Write-Output ("{0}  imports={1}" -f $_.Name, ($d.Imports | Measure-Object).Count)
  foreach($m in $d.Imports){
    $hits = @($m.Functions | Where-Object { $_ -match $pat })
    if($hits.Count -gt 0){ Write-Output ("  {0}: {1}" -f $m.DLL, ($hits -join ' ')) }
  }
}
