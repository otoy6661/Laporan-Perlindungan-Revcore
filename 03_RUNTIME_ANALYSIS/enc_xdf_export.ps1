$ErrorActionPreference='Stop'
. 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\tp_lib.ps1'
$exe='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$bin='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\DATASET_COPY\BIN & XDF\ADV\30400-K0WA-N01.bin'
$xdf='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\DATASET_COPY\BIN & XDF\ADV\ADV 150  K0WA - N01 (fix)\standar\ADV 150 -- 30400-K0WA-N01.xdf'
$out='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\05_XDF_AUTOPSY\enc_xdf_k0wa_export.txt'
$p=$null
try {
  $r=StartTpPair $exe $bin $xdf
  $p=$r.Process
  Write-Output ("TITLE={0}" -f $p.MainWindowTitle)
  $tv=FindChildClass $r.Main 'SysTreeView32'
  if($tv -ne [IntPtr]::Zero){
    $items=[TP]::Dump($tv,$p.Id,6)
    Write-Output ("TREE_ITEMS={0}" -f $items.Count)
    foreach($it in $items){ Write-Output ("T|"+$it) }
  }
  [void][TP]::PostMessage($r.Main,0x0111,[IntPtr]32847,[IntPtr]::Zero)
  $dlg=WaitDlg $p.Id 6
  Write-Output ("EXPORT_DLG=0x{0:X}" -f $dlg.ToInt64())
  if($dlg -ne [IntPtr]::Zero){
    SetDialogPath $dlg $out
    Start-Sleep -Seconds 5
  }
  if(Test-Path $out){ Write-Output ("EXPORT_BYTES={0}" -f (Get-Item $out).Length) } else { Write-Output 'EXPORT_MISSING' }
} finally { StopTp $p }
