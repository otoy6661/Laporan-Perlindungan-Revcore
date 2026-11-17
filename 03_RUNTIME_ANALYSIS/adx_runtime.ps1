param([string]$Mode='editor')
$ErrorActionPreference='Stop'
. 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\tp_lib.ps1'
Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
using System; using System.Text; using System.Runtime.InteropServices;
public class TPX {
 public delegate bool EnumProc2(IntPtr h, IntPtr l);
 [DllImport("user32.dll",EntryPoint="EnumChildWindows")] public static extern bool EnumChildWindows2(IntPtr p, EnumProc2 cb, IntPtr l);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder sb, int n);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder sb, int n);
 [DllImport("user32.dll")] public static extern int GetDlgCtrlID(IntPtr h);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")] public static extern bool IsWindowEnabled(IntPtr h);
 [DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr h,int i);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern IntPtr SendMessageW(IntPtr h,uint m,IntPtr w,string l);
 [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr h,uint m,IntPtr w,IntPtr l);
 [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h,uint m,IntPtr w,IntPtr l);
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
}
"@
$outDir='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS'
$exe='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$adx='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\06_ADX_AUTOPSY\WORK\keihin.adx'
$log=New-Object System.Collections.ArrayList
function L($s){ [void]$log.Add($s); Write-Output $s }
function ShotScreen($path){
  $vs=[System.Windows.Forms.SystemInformation]::VirtualScreen
  $bmp=New-Object System.Drawing.Bitmap $vs.Width,$vs.Height
  $g=[System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($vs.Left,$vs.Top,0,0,$bmp.Size)
  $bmp.Save($path,[System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
}
function DumpChildren($parent,$depth,$maxDepth){
  $kids=New-Object System.Collections.ArrayList
  $cb=[TP+EnumProc]{ param($h,$l)
    [void]$kids.Add($h); return $true
  }
  [void][TP]::EnumChildWindows($parent,$cb,[IntPtr]::Zero)
  foreach($k in $kids){
    $c=New-Object System.Text.StringBuilder 128; [void][TPX]::GetClassNameW($k,$c,128)
    $t=New-Object System.Text.StringBuilder 512; [void][TPX]::GetWindowTextW($k,$t,512)
    $id=[TPX]::GetDlgCtrlID($k)
    $vis=[TPX]::IsWindowVisible($k)
    $en=[TPX]::IsWindowEnabled($k)
    $st=[TPX]::GetWindowLong($k,-16)
    L(("  [{0}] hwnd={1} id={2} vis={3} en={4} style=0x{5:X8} text='{6}'" -f $c.ToString(),$k.ToInt64(),$id,$vis,$en,$st,$t.ToString()))
  }
}
function DumpTop($procId,$includeHidden){
  $script:tops=New-Object System.Collections.ArrayList
  $cb=[TP+EnumProc]{ param($h,$l)
    $wp=0; [void][TPX]::GetWindowThreadProcessId($h,[ref]$wp)
    if($wp -ne $procId){ return $true }
    if(-not $includeHidden -and -not [TPX]::IsWindowVisible($h)){ return $true }
    [void]$script:tops.Add($h); return $true
  }
  [void][TP]::EnumWindows($cb,[IntPtr]::Zero)
  foreach($h in $script:tops){
    $c=New-Object System.Text.StringBuilder 128; [void][TPX]::GetClassNameW($h,$c,128)
    $t=New-Object System.Text.StringBuilder 512; [void][TPX]::GetWindowTextW($h,$t,512)
    L(("TOP {0} class={1} text='{2}'" -f $h.ToInt64(),$c.ToString(),$t.ToString()))
    DumpChildren $h 1 2
  }
}
$p=$null
try {
  $p=Start-Process -FilePath $exe -PassThru -WorkingDirectory (Split-Path $exe)
  for($i=0;$i -lt 60;$i++){ Start-Sleep -Milliseconds 400; $p.Refresh(); if($p.MainWindowHandle -ne 0){break} }
  Start-Sleep -Seconds 2; $p.Refresh()
  $main=$p.MainWindowHandle
  if($p.MainWindowTitle -like '*Initialization Error*'){ throw 'APP_INIT_ERROR' }
  L(("START TITLE={0}" -f $p.MainWindowTitle))
  [void][TP]::PostMessage($main,0x0111,[IntPtr]33052,[IntPtr]::Zero)
  $dlg=WaitDlg $p.Id 6
  if($dlg -eq [IntPtr]::Zero){ throw 'LOAD_DIALOG_NOT_FOUND' }
  SetDialogPath $dlg $adx
  Start-Sleep -Seconds 3
  $p.Refresh(); L(("AFTER ADX LOAD TITLE={0}" -f $p.MainWindowTitle))
  $cmd=@{ editor=33071; scan=33068; lists=33047; dash=33048; monitors=33050; history=33049 }[$Mode]
  if($null -eq $cmd){ throw "UNKNOWN_MODE $Mode" }
  L(("COMMAND={0}" -f $cmd))
  [void][TP]::PostMessage($main,0x0111,[IntPtr]$cmd,[IntPtr]::Zero)
  if($Mode -eq 'scan'){
    for($i=0;$i -lt 24;$i++){ Start-Sleep -Milliseconds 500; $d=FindDlg $p.Id; if($d -ne [IntPtr]::Zero){ L(("DIALOG_APPEARED 0x{0:X}" -f $d.ToInt64())); break } }
  } else { Start-Sleep -Seconds 3 }
  $p.Refresh(); L(("POST TITLE={0}" -f $p.MainWindowTitle))
  DumpTop $p.Id $true
  if($Mode -eq 'editor'){
    # enumerate deeper inside the ADX Editor dialog
    $ed=FindDlg $p.Id
    if($ed -ne [IntPtr]::Zero){
      $t=New-Object System.Text.StringBuilder 512; [void][TPX]::GetWindowTextW($ed,$t,512)
      L(("EDITOR DIALOG 0x{0:X} text='{1}'" -f $ed.ToInt64(),$t.ToString()))
      DumpChildren $ed 0 4
      $tv=FindChildClass $ed 'SysTreeView32'
      if($tv -ne [IntPtr]::Zero){
        L(("ADX_EDITOR_TREE hwnd=0x{0:X}" -f $tv.ToInt64()))
        $items=[TP]::Dump($tv,$p.Id,8)
        foreach($it in $items){ L(("  T|"+$it)) }
      }
    }
  }
  ShotScreen (Join-Path $outDir ("adx_{0}_runtime.png" -f $Mode))
  L('SCREENSHOT_SAVED')
} finally {
  if($p -and -not $p.HasExited){ StopTp $p }
  $log | Set-Content -Path (Join-Path $outDir ("adx_{0}_runtime.txt" -f $Mode)) -Encoding UTF8
}
