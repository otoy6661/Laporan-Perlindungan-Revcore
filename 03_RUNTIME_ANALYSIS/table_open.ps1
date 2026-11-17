param([string]$Table='TPS vs RPM')
$ErrorActionPreference='Stop'
. 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\tp_lib.ps1'
$exe='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$bin='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\K1AA-N03\beat_k1aa_n03.bin'
$xdf='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\K1AA-N03\30400-k1aa-n03.xdf'
$p=$null
try {
  $r=StartTpPair $exe $bin $xdf
  $p=$r.Process
  Write-Output ("TITLE={0}" -f $p.MainWindowTitle)
  $tv=FindChildClass $r.Main 'SysTreeView32'
  $item=[TP]::FindByText($tv,$p.Id,$Table)
  Write-Output ("ITEM=0x{0:X}" -f $item.ToInt64())
  if($item -eq [IntPtr]::Zero){ throw 'ITEM_NOT_FOUND' }
  [void][TP]::SelectItem($tv,$item)
  Start-Sleep -Seconds 1
  [void][TP]::RealDoubleClick($tv,$item,$p.Id)
  Start-Sleep -Seconds 3
  $p.Refresh()
  Write-Output ("TITLE_AFTER_SELECT={0}" -f $p.MainWindowTitle)
  # list MDI children
  $mdi=FindChildClass $r.Main 'MDIClient'
  $script:kids=New-Object System.Collections.ArrayList
  $cb=[TP+EnumProc]{ param($h,$l)
    $c=New-Object System.Text.StringBuilder 64; [void][TP]::GetClassNameW($h,$c,64)
    $t=New-Object System.Text.StringBuilder 256; [void][TP]::GetWindowTextW($h,$t,256)
    [void]$script:kids.Add(("0x{0:X} class={1} text='{2}'" -f $h.ToInt64(),$c.ToString(),$t.ToString()))
    return $true
  }
  [void][TP]::EnumChildWindows($mdi,$cb,[IntPtr]::Zero)
  $script:kids | ForEach-Object { Write-Output $_ }
  Shot $r.Main 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\table_open.png'
  Write-Output 'SHOT_SAVED'
} finally { StopTp $p }
