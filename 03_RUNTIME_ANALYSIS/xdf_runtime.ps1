param([string]$Xdf, [string]$Mode='load', [string]$Tag='encxdf')
$ErrorActionPreference='Stop'
. 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\tp_lib.ps1'
Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
using System; using System.Text; using System.Runtime.InteropServices;
public class TPX2 {
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder sb, int n);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder sb, int n);
 [DllImport("user32.dll")] public static extern int GetDlgCtrlID(IntPtr h);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")] public static extern bool IsWindowEnabled(IntPtr h);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
}
"@
$outDir='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS'
$exe='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$log=New-Object System.Collections.ArrayList
function L($s){ [void]$log.Add($s); Write-Output $s }
function ShotScreen($path){
  $vs=[System.Windows.Forms.SystemInformation]::VirtualScreen
  $bmp=New-Object System.Drawing.Bitmap $vs.Width,$vs.Height
  $g=[System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($vs.Left,$vs.Top,0,0,$bmp.Size)
  $bmp.Save($path,[System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
}
function DumpTop($procId){
  $script:tops=New-Object System.Collections.ArrayList
  $cb=[TP+EnumProc]{ param($h,$l)
    $wp=0; [void][TPX2]::GetWindowThreadProcessId($h,[ref]$wp)
    if($wp -ne $procId){ return $true }
    if(-not [TPX2]::IsWindowVisible($h)){ return $true }
    [void]$script:tops.Add($h); return $true
  }
  [void][TP]::EnumWindows($cb,[IntPtr]::Zero)
  foreach($h in $script:tops){
    $c=New-Object System.Text.StringBuilder 128; [void][TPX2]::GetClassNameW($h,$c,128)
    $t=New-Object System.Text.StringBuilder 512; [void][TPX2]::GetWindowTextW($h,$t,512)
    L(("TOP {0} class={1} text='{2}'" -f $h.ToInt64(),$c.ToString(),$t.ToString()))
    $script:kids=New-Object System.Collections.ArrayList
    $cb2=[TP+EnumProc]{ param($k,$l)
      [void]$script:kids.Add($k); return $true
    }
    [void][TP]::EnumChildWindows($h,$cb2,[IntPtr]::Zero)
    foreach($k in $script:kids){
      $ck=New-Object System.Text.StringBuilder 128; [void][TPX2]::GetClassNameW($k,$ck,128)
      $tk=New-Object System.Text.StringBuilder 512; [void][TPX2]::GetWindowTextW($k,$tk,512)
      $id=[TPX2]::GetDlgCtrlID($k)
      if(-not [TPX2]::IsWindowVisible($k)){ continue }
      L(("  [{0}] id={1} en={2} text='{3}'" -f $ck.ToString(),$id,[TPX2]::IsWindowEnabled($k),$tk.ToString()))
    }
  }
}
$p=$null
try{
  $p=Start-Process -FilePath $exe -PassThru -WorkingDirectory (Split-Path $exe)
  for($i=0;$i -lt 60;$i++){ Start-Sleep -Milliseconds 400; $p.Refresh(); if($p.MainWindowHandle -ne 0){break} }
  Start-Sleep -Seconds 2; $p.Refresh()
  $main=$p.MainWindowHandle
  if($p.MainWindowTitle -like '*Initialization Error*'){ throw 'APP_INIT_ERROR' }
  L(("START TITLE={0}" -f $p.MainWindowTitle))
  [void][TP]::PostMessage($main,0x0111,[IntPtr]32776,[IntPtr]::Zero)
  $dlg=WaitDlg $p.Id 6; if($dlg -eq [IntPtr]::Zero){ throw 'XDF_DIALOG_NOT_FOUND' }
  SetDialogPath $dlg $Xdf
  Start-Sleep -Seconds 4
  $p.Refresh(); L(("AFTER XDF TITLE={0}" -f $p.MainWindowTitle))
  # detect password or error dialogs
  $script:dialogs=New-Object System.Collections.ArrayList
  $cb=[TP+EnumProc]{ param($h,$l)
    $wp=0; [void][TPX2]::GetWindowThreadProcessId($h,[ref]$wp)
    if($wp -ne $p.Id){ return $true }
    if(-not [TPX2]::IsWindowVisible($h)){ return $true }
    $c=New-Object System.Text.StringBuilder 64; [void][TPX2]::GetClassNameW($h,$c,64)
    if($c.ToString() -eq '#32770'){
      $t=New-Object System.Text.StringBuilder 256; [void][TPX2]::GetWindowTextW($h,$t,256)
      [void]$script:dialogs.Add(("DLG 0x{0:X} text='{1}'" -f $h.ToInt64(),$t.ToString()))
    }
    return $true
  }
  [void][TP]::EnumWindows($cb,[IntPtr]::Zero)
  L('--- DIALOGS ---'); $script:dialogs | ForEach-Object { L($_) }
  if($Mode -eq 'header'){
    [void][TP]::PostMessage($main,0x0111,[IntPtr]32923,[IntPtr]::Zero)
    Start-Sleep -Seconds 3
  }
  DumpTop $p.Id
  # dump parameter tree if present
  $tv=FindChildClass $main 'SysTreeView32'
  if($tv -ne [IntPtr]::Zero){
    L(("MAIN_TREE hwnd=0x{0:X}" -f $tv.ToInt64()))
    $items=[TP]::Dump($tv,$p.Id,4)
    foreach($it in $items){ L(("  T|"+$it)) }
  } else { L('NO_MAIN_TREE') }
  Shot $main (Join-Path $outDir ("{0}.png" -f $Tag))
  ShotScreen (Join-Path $outDir ("{0}_screen.png" -f $Tag))
  L('SHOT_SAVED')
} finally {
  if($p -and -not $p.HasExited){ StopTp $p }
  $log | Set-Content -Path (Join-Path $outDir ("{0}.txt" -f $Tag)) -Encoding UTF8
}
