param([string]$Mode='edit')
$ErrorActionPreference='Stop'
. 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\tp_lib.ps1'
$exe='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$adx='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\06_ADX_AUTOPSY\WORK\keihin.adx'
$p=$null
try {
  $p=Start-Process -FilePath $exe -PassThru -WorkingDirectory (Split-Path $exe)
  for($i=0;$i -lt 60;$i++){ Start-Sleep -Milliseconds 400; $p.Refresh(); if($p.MainWindowHandle -ne 0){break} }
  Start-Sleep -Seconds 2; $p.Refresh()
  $main=$p.MainWindowHandle
  if($p.MainWindowTitle -like '*Initialization Error*'){ throw 'APP_INIT_ERROR' }
  [void][TP]::PostMessage($main,0x0111,[IntPtr]33052,[IntPtr]::Zero)
  $dlg=WaitDlg $p.Id 6; if($dlg -eq [IntPtr]::Zero){ throw 'LOAD_DIALOG_NOT_FOUND' }
  SetDialogPath $dlg $adx
  Start-Sleep -Seconds 2
  $cmd = 33071
  if($Mode -eq 'scan'){ $cmd = 33068 }
  [void][TP]::PostMessage($main,0x0111,[IntPtr]$cmd,[IntPtr]::Zero)
  Start-Sleep -Seconds 3
  $p.Refresh(); Write-Output ("TITLE={0}" -f $p.MainWindowTitle)
  $script:rows=New-Object System.Collections.ArrayList
  $cb=[TP+EnumProc]{ param($h,$l)
    $wp=0; [void][TP]::GetWindowThreadProcessId($h,[ref]$wp)
    if($wp -ne $p.Id){ return $true }
    if(-not [TP]::IsWindowVisible($h)){ return $true }
    $c=New-Object System.Text.StringBuilder 64; [void][TP]::GetClassNameW($h,$c,64)
    $t=New-Object System.Text.StringBuilder 256; [void][TP]::GetWindowTextW($h,$t,256)
    [void]$script:rows.Add(("class={0} text='{1}'" -f $c.ToString(),$t.ToString()))
    return $true
  }
  [void][TP]::EnumWindows($cb,[IntPtr]::Zero)
  $script:rows | ForEach-Object { Write-Output $_ }
  $script:all=New-Object System.Collections.ArrayList
  $cb2=[TP+EnumProc]{ param($h,$l)
    $c=New-Object System.Text.StringBuilder 64; [void][TP]::GetClassNameW($h,$c,64)
    if($c.ToString() -eq 'Static' -or $c.ToString() -eq 'Button'){
      $t=New-Object System.Text.StringBuilder 512; [void][TP]::GetWindowTextW($h,$t,512)
      if($t.Length -gt 0){ [void]$script:all.Add(("ST {0}: {1}" -f $c.ToString(),$t.ToString())) }
    }
    return $true
  }
  $cbTop=[TP+EnumProc]{ param($h,$l)
    $wp=0; [void][TP]::GetWindowThreadProcessId($h,[ref]$wp)
    if($wp -ne $p.Id){ return $true }
    if([TP]::IsWindowVisible($h)){ [void][TP]::EnumChildWindows($h,$cb2,[IntPtr]::Zero) }
    return $true
  }
  [void][TP]::EnumWindows($cbTop,[IntPtr]::Zero)
  Write-Output '--- TEXTS ---'
  $script:all | Select-Object -Unique | ForEach-Object { Write-Output $_ }
  Shot $main ("C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\adx_{0}.png" -f $Mode)
  Write-Output 'SHOT_SAVED'
} finally { StopTp $p }
