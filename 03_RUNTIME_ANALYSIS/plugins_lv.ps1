$ErrorActionPreference='Stop'
. 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\tp_lib.ps1'
$exe='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$bin='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\SUPRA-K41NC1\SUPRA-K41NC1_resaved.bin'
$xdf='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\SUPRA-K41NC1\SUPRA-K41NC1.xdf'
$p=$null
try{
  $r=StartTpPair $exe $bin $xdf
  $p=$r.Process
  [void][TP]::PostMessage($r.Main,0x0111,[IntPtr]33127,[IntPtr]::Zero)
  Start-Sleep -Seconds 3
  $dlg=FindDlg $p.Id
  $lv=FindChildClass $dlg 'SysListView32'
  Write-Output ("DLG=0x{0:X} LV=0x{1:X}" -f $dlg.ToInt64(),$lv.ToInt64())
  $proc=[TP]::OpenProcess(0x1F0FFF,$false,$p.Id)
  $remote=[TP]::VirtualAllocEx($proc,[IntPtr]::Zero,[IntPtr]8192,0x3000,0x04)
  $count=[TP]::SendMessage($lv,0x1004,[IntPtr]::Zero,[IntPtr]::Zero).ToInt32()
  $hdr=[TP]::SendMessage($lv,0x101F,[IntPtr]::Zero,[IntPtr]::Zero)
  $cols=[TP]::SendMessage($hdr,0x1200,[IntPtr]::Zero,[IntPtr]::Zero).ToInt32()
  Write-Output ("ITEMS={0} COLS={1}" -f $count,$cols)
  $textAddr=[IntPtr]($remote.ToInt64()+256)
  for($i=0;$i -lt $count;$i++){
    $row=New-Object System.Collections.ArrayList
    for($c=0;$c -lt $cols;$c++){
      $buf=New-Object byte[] 64
      [BitConverter]::GetBytes([uint32]1).CopyTo($buf,0)
      [BitConverter]::GetBytes([int]$i).CopyTo($buf,4)
      [BitConverter]::GetBytes([int]$c).CopyTo($buf,8)
      [BitConverter]::GetBytes([int]$textAddr.ToInt64()).CopyTo($buf,20)
      [BitConverter]::GetBytes([int]512).CopyTo($buf,24)
      $w=[IntPtr]::Zero; [void][TP]::WriteProcessMemory($proc,$remote,$buf,[IntPtr]64,[ref]$w)
      [void][TP]::SendMessage($lv,0x1073,[IntPtr]$i,$remote)
      $tb=New-Object byte[] 1024; $rr=[IntPtr]::Zero
      [void][TP]::ReadProcessMemory($proc,$textAddr,$tb,[IntPtr]1024,[ref]$rr)
      $s=[Text.Encoding]::Unicode.GetString($tb); $z=$s.IndexOf([char]0); if($z -ge 0){ $s=$s.Substring(0,$z) }
      [void]$row.Add($s)
    }
    Write-Output ("ROW {0}| {1}" -f $i,($row -join ' | '))
  }
  [void][TP]::VirtualFreeEx($proc,$remote,[IntPtr]::Zero,0x8000)
} finally { StopTp $p }
