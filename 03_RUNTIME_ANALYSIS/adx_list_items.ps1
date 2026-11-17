param([string]$Out='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\06_ADX_AUTOPSY\KEIHIN_DATA_LISTS.txt')
$ErrorActionPreference='Stop'
. 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\tp_lib.ps1'
$exe='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$adx='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\06_ADX_AUTOPSY\WORK\keihin.adx'
$lines=New-Object System.Collections.ArrayList
function L($s){ [void]$lines.Add($s); Write-Output $s }
function GetTextRemote($hwnd,$msg,$wParam,$procId,$count){
  $proc=[TP]::OpenProcess(0x1F0FFF,$false,$procId)
  $remote=[TP]::VirtualAllocEx($proc,[IntPtr]::Zero,[IntPtr]4096,0x3000,0x04)
  try{
    [void][TP]::SendMessage($hwnd,$msg,$wParam,$remote)
    $tb=New-Object byte[] ($count*2)
    $r=[IntPtr]::Zero; [void][TP]::ReadProcessMemory($proc,$remote,$tb,[IntPtr]$tb.Length,[ref]$r)
    $s=[System.Text.Encoding]::Unicode.GetString($tb); $z=$s.IndexOf([char]0); if($z -ge 0){ $s=$s.Substring(0,$z) }
    return $s
  } finally { [void][TP]::VirtualFreeEx($proc,$remote,[IntPtr]::Zero,0x8000) }
}
function DumpLV($lv,$procId,$maxCols){
  $proc=[TP]::OpenProcess(0x1F0FFF,$false,$procId)
  if($proc -eq [IntPtr]::Zero){ L('LV_OPENPROCESS_FAIL'); return }
  $remote=[TP]::VirtualAllocEx($proc,[IntPtr]::Zero,[IntPtr]8192,0x3000,0x04)
  try{
    $count=[TP]::SendMessage($lv,0x1004,[IntPtr]::Zero,[IntPtr]::Zero).ToInt32()
    $hdr=[TP]::SendMessage($lv,0x101F,[IntPtr]::Zero,[IntPtr]::Zero)
    $cols=0
    if($hdr -ne [IntPtr]::Zero){ $cols=[TP]::SendMessage($hdr,0x1200,[IntPtr]::Zero,[IntPtr]::Zero).ToInt32() }
    L(("LV_ITEMS={0} LV_COLS={1}" -f $count,$cols))
    if($cols -le 0 -or $cols -gt $maxCols){ $cols=$maxCols }
    $textAddr=[IntPtr]($remote.ToInt64()+256)
    for($i=0;$i -lt $count;$i++){
      $row=New-Object System.Collections.ArrayList
      for($c=0;$c -lt $cols;$c++){
        $buf=New-Object byte[] 64
        [BitConverter]::GetBytes([uint32]1).CopyTo($buf,0)      # LVIF_TEXT
        [BitConverter]::GetBytes([int]$i).CopyTo($buf,4)        # iItem
        [BitConverter]::GetBytes([int]$c).CopyTo($buf,8)        # iSubItem
        [BitConverter]::GetBytes([int]$textAddr.ToInt64()).CopyTo($buf,20)  # pszText (x86 pointer)
        [BitConverter]::GetBytes([int]512).CopyTo($buf,24)      # cchTextMax
        $w=[IntPtr]::Zero; [void][TP]::WriteProcessMemory($proc,$remote,$buf,[IntPtr]64,[ref]$w)
        [void][TP]::SendMessage($lv,0x1073,[IntPtr]$i,$remote)
        $tb=New-Object byte[] 1024
        $r=[IntPtr]::Zero; [void][TP]::ReadProcessMemory($proc,$textAddr,$tb,[IntPtr]1024,[ref]$r)
        $s=[System.Text.Encoding]::Unicode.GetString($tb); $z=$s.IndexOf([char]0); if($z -ge 0){ $s=$s.Substring(0,$z) }
        [void]$row.Add($s)
      }
      L(("ROW {0}| {1}" -f $i,($row -join ' | ')))
    }
  } finally { [void][TP]::VirtualFreeEx($proc,$remote,[IntPtr]::Zero,0x8000) }
}
function DumpCombo($cb,$procId){
  $n=[TP]::SendMessage($cb,0x0146,[IntPtr]::Zero,[IntPtr]::Zero).ToInt32()
  L(("COMBO_ITEMS={0}" -f $n))
  for($i=0;$i -lt $n;$i++){
    $s=GetTextRemote $cb 0x0148 ([IntPtr]$i) $procId 256
    L(("COMBO {0}| {1}" -f $i,$s))
  }
}
$p=$null
try{
  $p=Start-Process -FilePath $exe -PassThru -WorkingDirectory (Split-Path $exe)
  for($i=0;$i -lt 60;$i++){ Start-Sleep -Milliseconds 400; $p.Refresh(); if($p.MainWindowHandle -ne 0){break} }
  Start-Sleep -Seconds 2; $p.Refresh()
  $main=$p.MainWindowHandle
  if($p.MainWindowTitle -like '*Initialization Error*'){ throw 'APP_INIT_ERROR' }
  [void][TP]::PostMessage($main,0x0111,[IntPtr]33052,[IntPtr]::Zero)
  $dlg=WaitDlg $p.Id 6; if($dlg -eq [IntPtr]::Zero){ throw 'LOAD_DIALOG_NOT_FOUND' }
  SetDialogPath $dlg $adx; Start-Sleep -Seconds 3
  [void][TP]::PostMessage($main,0x0111,[IntPtr]33047,[IntPtr]::Zero)
  Start-Sleep -Seconds 3
  # find Lists tab sheet and its listview
  $script:found=New-Object System.Collections.ArrayList
  $cb=[TP+EnumProc]{ param($h,$l)
    $wp=0; [void][TP]::GetWindowThreadProcessId($h,[ref]$wp)
    if($wp -ne $p.Id){ return $true }
    $c=New-Object System.Text.StringBuilder 64; [void][TP]::GetClassNameW($h,$c,64)
    $id=[TP]::GetDlgCtrlID($h)
    $t=New-Object System.Text.StringBuilder 128; [void][TP]::GetWindowTextW($h,$t,128)
    if($c.ToString() -eq 'SysListView32' -or $c.ToString() -eq 'ComboBox'){
      [void]$script:found.Add(("CLASS={0} ID={1} TEXT='{2}' HWND={3}" -f $c.ToString(),$id,$t.ToString(),$h.ToInt64()))
      if($c.ToString() -eq 'SysListView32'){ L(("--- LISTVIEW id={0}" -f $id)); DumpLV $h $p.Id 8 }
      else { L(("--- COMBOBOX id={0}" -f $id)); DumpCombo $h $p.Id }
    }
    return $true
  }
  [void][TP]::EnumWindows([TP+EnumProc]{ param($h,$l)
    $wp=0; [void][TP]::GetWindowThreadProcessId($h,[ref]$wp)
    if($wp -eq $p.Id){ [void][TP]::EnumChildWindows($h,$cb,[IntPtr]::Zero) }
    return $true
  },[IntPtr]::Zero)
  L('--- FOUND CONTROLS ---')
  $script:found | ForEach-Object { L($_) }
} finally {
  if($p -and -not $p.HasExited){ StopTp $p }
  $lines | Set-Content -Path $Out -Encoding UTF8
}
