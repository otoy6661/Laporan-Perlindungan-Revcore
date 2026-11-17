$ErrorActionPreference='Stop'
. 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\tp_lib.ps1'
Add-Type @"
using System; using System.Text; using System.Runtime.InteropServices;
public class UC {
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder sb, int n);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder sb, int n);
 [DllImport("user32.dll")] public static extern int GetDlgCtrlID(IntPtr h);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
 [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h,uint m,IntPtr w,IntPtr l);
}
"@
$exe='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$bin='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\SUPRA-K41NC1\SUPRA-K41NC1_resaved.bin'
$xdf='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\SUPRA-K41NC1\SUPRA-K41NC1.xdf'
function Dialogs($procId){
  $script:out=New-Object System.Collections.ArrayList
  $cb=[TP+EnumProc]{ param($h,$l)
    $wp=0; [void][UC]::GetWindowThreadProcessId($h,[ref]$wp)
    if($wp -ne $procId){ return $true }
    if(-not [UC]::IsWindowVisible($h)){ return $true }
    $c=New-Object System.Text.StringBuilder 64; [void][UC]::GetClassNameW($h,$c,64)
    if($c.ToString() -ne '#32770'){ return $true }
    $t=New-Object System.Text.StringBuilder 512; [void][UC]::GetWindowTextW($h,$t,512)
    [void]$script:out.Add(("DLG 0x{0:X} '{1}'" -f $h.ToInt64(),$t.ToString()))
    $script:kids=New-Object System.Collections.ArrayList
    $cb2=[TP+EnumProc]{ param($k,$l) [void]$script:kids.Add($k); return $true }
    [void][TP]::EnumChildWindows($h,$cb2,[IntPtr]::Zero)
    foreach($k in $script:kids){
      $ck=New-Object System.Text.StringBuilder 64; [void][UC]::GetClassNameW($k,$ck,64)
      $tk=New-Object System.Text.StringBuilder 512; [void][UC]::GetWindowTextW($k,$tk,512)
      if($tk.Length -gt 0){ [void]$script:out.Add(("  {0} id={1} '{2}'" -f $ck.ToString(),[UC]::GetDlgCtrlID($k),$tk.ToString())) }
    }
    return $true
  }
  [void][TP]::EnumWindows($cb,[IntPtr]::Zero)
  return $script:out
}
function CloseDialogs($procId){
  $script:dl=New-Object System.Collections.ArrayList
  $cb=[TP+EnumProc]{ param($h,$l)
    $wp=0; [void][UC]::GetWindowThreadProcessId($h,[ref]$wp)
    if($wp -ne $procId){ return $true }
    if(-not [UC]::IsWindowVisible($h)){ return $true }
    $c=New-Object System.Text.StringBuilder 64; [void][UC]::GetClassNameW($h,$c,64)
    if($c.ToString() -eq '#32770'){ [void]$script:dl.Add($h) }
    return $true
  }
  [void][TP]::EnumWindows($cb,[IntPtr]::Zero)
  foreach($h in $script:dl){ [void][UC]::PostMessage($h,0x0010,[IntPtr]::Zero,[IntPtr]::Zero) }
}
$cmds=@(
  @{id=33127; name='Plug-ins'},
  @{id=32991; name='System Check'},
  @{id=32854; name='Initialize Hardware'},
  @{id=32897; name='Emulation Upload'},
  @{id=32904; name='Emulation Download'},
  @{id=32899; name='Emulation Verify'},
  @{id=32900; name='Enable Live Tuning'},
  @{id=33104; name='Release Hardware'}
)
$p=$null
try{
  $r=StartTpPair $exe $bin $xdf
  $p=$r.Process
  $tv=FindChildClass $r.Main 'SysTreeView32'
  $sb=FindChildClass $r.Main 'msctls_statusbar32'
  foreach($c in $cmds){
    Write-Output ("==== {0} ({1}) ====" -f $c.name,$c.id)
    [void][TP]::PostMessage($r.Main,0x0111,[IntPtr]$c.id,[IntPtr]::Zero)
    Start-Sleep -Seconds 3
    Dialogs $p.Id | ForEach-Object { Write-Output $_ }
    if($sb -ne [IntPtr]::Zero){ $st=[TP]::Status($sb,$p.Id); Write-Output ("STATUS=" + ($st -join ' | ')) }
    $p.Refresh(); Write-Output ("TITLE=" + $p.MainWindowTitle)
    CloseDialogs $p.Id
    Start-Sleep -Seconds 1
  }
} finally { StopTp $p }
