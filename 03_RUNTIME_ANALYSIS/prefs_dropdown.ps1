$ErrorActionPreference='Stop'
. 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\tp_lib.ps1'
Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
using System; using System.Text; using System.Runtime.InteropServices;
public class DD {
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out R r);
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")] public static extern void mouse_event(uint f,uint dx,uint dy,uint d,IntPtr e);
 [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref P p);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder sb, int n);
 public struct R { public int L,T,Ri,B; }
 public struct P { public int X,Y; }
}
"@
function ShotScreen($path){
  $vs=[System.Windows.Forms.SystemInformation]::VirtualScreen
  $bmp=New-Object System.Drawing.Bitmap $vs.Width,$vs.Height
  $g=[System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($vs.Left,$vs.Top,0,0,$bmp.Size)
  $bmp.Save($path,[System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
}
$exe='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$bin='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\SUPRA-K41NC1\SUPRA-K41NC1_resaved.bin'
$xdf='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\SUPRA-K41NC1\SUPRA-K41NC1.xdf'
$p=$null
try{
  $r=StartTpPair $exe $bin $xdf
  $p=$r.Process
  [void][TP]::PostMessage($r.Main,0x0111,[IntPtr]32778,[IntPtr]::Zero)
  Start-Sleep -Seconds 3
  $dlg=FindDlg $p.Id
  $tab=FindChildClass $dlg 'SysTabControl32'
  # click last tab
  $proc=[TP]::OpenProcess(0x1F0FFF,$false,$p.Id)
  $remote=[TP]::VirtualAllocEx($proc,[IntPtr]::Zero,[IntPtr]256,0x3000,0x04)
  $n=[TP]::SendMessage($tab,0x1304,[IntPtr]::Zero,[IntPtr]::Zero).ToInt32()
  $buf=New-Object byte[] 16; $w=[IntPtr]::Zero; [void][TP]::WriteProcessMemory($proc,$remote,$buf,[IntPtr]16,[ref]$w)
  [void][TP]::SendMessage($tab,0x130A,[IntPtr]($n-1),$remote)
  $rb=New-Object byte[] 16; $rr=[IntPtr]::Zero; [void][TP]::ReadProcessMemory($proc,$remote,$rb,[IntPtr]16,[ref]$rr)
  $l=[BitConverter]::ToInt32($rb,0); $t=[BitConverter]::ToInt32($rb,4); $ri=[BitConverter]::ToInt32($rb,8); $b=[BitConverter]::ToInt32($rb,12)
  $pt=New-Object DD+P; $pt.X=[int](($l+$ri)/2); $pt.Y=[int](($t+$b)/2)
  [void][DD]::ClientToScreen($tab,[ref]$pt)
  [void][DD]::SetCursorPos($pt.X,$pt.Y); [DD]::mouse_event(0x0002,0,0,0,[IntPtr]::Zero); [DD]::mouse_event(0x0004,0,0,0,[IntPtr]::Zero)
  Start-Sleep -Seconds 1
  # click combo 2672
  $cb1=$null
  $script:kids=New-Object System.Collections.ArrayList
  $cbx=[TP+EnumProc]{ param($h,$l) [void]$script:kids.Add($h); return $true }
  [void][TP]::EnumChildWindows($dlg,$cbx,[IntPtr]::Zero)
  foreach($k in $script:kids){ if([TP]::GetDlgCtrlID($k) -eq 2672){ $cb1=$k } }
  if($cb1 -ne $null){
    $rect=New-Object DD+R; [void][DD]::GetWindowRect($cb1,[ref]$rect)
    [void][DD]::SetCursorPos(($rect.Ri-10),(([int](($rect.T+$rect.B)/2)))); Start-Sleep -Milliseconds 300
    [DD]::mouse_event(0x0002,0,0,0,[IntPtr]::Zero); [DD]::mouse_event(0x0004,0,0,0,[IntPtr]::Zero)
    Start-Sleep -Seconds 1
    ShotScreen 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\prefs_interface_dropdown.png'
    [System.Windows.Forms.SendKeys]::SendWait('{ESC}')
  }
  [void][TP]::VirtualFreeEx($proc,$remote,[IntPtr]::Zero,0x8000)
} finally { StopTp $p }
