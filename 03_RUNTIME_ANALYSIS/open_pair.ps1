$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System; using System.Text; using System.Runtime.InteropServices;
public class W {
 public delegate bool EnumProc(IntPtr h, IntPtr l);
 [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr p, EnumProc cb, IntPtr l);
 [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder sb, int n);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder sb, int n);
 [DllImport("user32.dll")] public static extern int GetDlgCtrlID(IntPtr h);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
 [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h,uint m,IntPtr w,IntPtr l);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern IntPtr SendMessageW(IntPtr h,uint m,IntPtr w,string l);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
 public struct RECT { public int Left,Top,Right,Bottom; }
}
"@
function Shot($h,$path){
  $r=New-Object W+RECT; [W]::GetWindowRect($h,[ref]$r)|Out-Null
  $bmp=New-Object System.Drawing.Bitmap ($r.Right-$r.Left),($r.Bottom-$r.Top)
  $g=[System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($r.Left,$r.Top,0,0,$bmp.Size)
  $bmp.Save($path,[System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
}
function FindDlg($procId){
  $script:found=[IntPtr]::Zero
  $cb=[W+EnumProc]{ param($h,$l)
    $wp=0; [void][W]::GetWindowThreadProcessId($h,[ref]$wp)
    if($wp -ne $procId){ return $true }
    $c=New-Object System.Text.StringBuilder 64; [void][W]::GetClassNameW($h,$c,64)
    if($c.ToString() -ne '#32770'){ return $true }
    if(-not [W]::IsWindowVisible($h)){ return $true }
    $t=New-Object System.Text.StringBuilder 128; [void][W]::GetWindowTextW($h,$t,128)
    if($t.ToString() -ne 'TunerPro Initialization Error'){ $script:found=$h; return $false }
    return $true
  }
  [void][W]::EnumWindows($cb,[IntPtr]::Zero)
  return $script:found
}
function WaitDlg($procId,$seconds){
  for($i=0;$i -lt ($seconds*4);$i++){ $d=FindDlg $procId; if($d -ne [IntPtr]::Zero){ return $d }; Start-Sleep -Milliseconds 250 }
  return [IntPtr]::Zero
}
function SetDialogPath($dlg,$path){
  $script:edit=[IntPtr]::Zero
  $cb=[W+EnumProc]{ param($h,$l)
    $c=New-Object System.Text.StringBuilder 64; [void][W]::GetClassNameW($h,$c,64)
    if($c.ToString() -eq 'Edit'){ $id=[W]::GetDlgCtrlID($h); if($id -eq 1148 -or $script:edit -eq [IntPtr]::Zero){ $script:edit=$h } }
    return $true
  }
  [void][W]::EnumChildWindows($dlg,$cb,[IntPtr]::Zero)
  if($script:edit -eq [IntPtr]::Zero){ throw 'NO_EDIT' }
  [void][W]::SendMessageW($script:edit,0x000C,[IntPtr]::Zero,$path)
  Start-Sleep -Milliseconds 300
  [void][W]::PostMessage($dlg,0x0111,[IntPtr]1,[IntPtr]::Zero)
}
$exe='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$bin='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\K1AA-N03\beat_k1aa_n03.bin'
$xdf='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\K1AA-N03\30400-k1aa-n03.xdf'
$p=$null
try {
  $p=Start-Process -FilePath $exe -PassThru -WorkingDirectory (Split-Path $exe)
  for($i=0;$i -lt 60;$i++){ Start-Sleep -Milliseconds 400; $p.Refresh(); if($p.MainWindowHandle -ne 0){break} }
  Start-Sleep -Seconds 2
  $p.Refresh()
  $main=$p.MainWindowHandle
  if($p.MainWindowTitle -like '*Initialization Error*'){ throw 'APP_INIT_ERROR' }
  Write-Output ("MAIN_TITLE={0}" -f $p.MainWindowTitle)
  [void][W]::PostMessage($main,0x0111,[IntPtr]32773,[IntPtr]::Zero)
  $dlg=WaitDlg $p.Id 6
  Write-Output ("BIN_DLG=0x{0:X}" -f $dlg.ToInt64())
  if($dlg -eq [IntPtr]::Zero){ throw 'BIN_DIALOG_NOT_FOUND' }
  SetDialogPath $dlg $bin
  Start-Sleep -Seconds 3
  $p.Refresh(); Write-Output ("AFTER_BIN_TITLE={0}" -f $p.MainWindowTitle)
  [void][W]::PostMessage($main,0x0111,[IntPtr]32776,[IntPtr]::Zero)
  $dlg=WaitDlg $p.Id 6
  Write-Output ("XDF_DLG=0x{0:X}" -f $dlg.ToInt64())
  if($dlg -eq [IntPtr]::Zero){ throw 'XDF_DIALOG_NOT_FOUND' }
  SetDialogPath $dlg $xdf
  Start-Sleep -Seconds 4
  $p.Refresh(); Write-Output ("AFTER_XDF_TITLE={0}" -f $p.MainWindowTitle)
  Shot $main 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\loaded_pair.png'
  Write-Output "SHOT_SAVED"
  Write-Output ("PID={0}" -f $p.Id)
} finally {
  if($p -and -not $p.HasExited){ $p.CloseMainWindow() | Out-Null; Start-Sleep -Seconds 2; if(-not $p.HasExited){ $p.Kill() } }
}
