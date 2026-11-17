$ErrorActionPreference='Stop'
. 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\tp_lib.ps1'
Add-Type @"
using System; using System.Text; using System.Runtime.InteropServices;
public class PT {
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder sb, int n);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder sb, int n);
 [DllImport("user32.dll")] public static extern int GetDlgCtrlID(IntPtr h);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")] public static extern void mouse_event(uint f,uint dx,uint dy,uint d,IntPtr e);
 [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref P p);
 public struct P { public int X,Y; }
}
"@
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
  Write-Output ("DLG=0x{0:X} TAB=0x{1:X}" -f $dlg.ToInt64(),$tab.ToInt64())
  $n=[TP]::SendMessage($tab,0x1304,[IntPtr]::Zero,[IntPtr]::Zero).ToInt32()
  Write-Output ("TABS={0}" -f $n)
  $proc=[TP]::OpenProcess(0x1F0FFF,$false,$p.Id)
  $remote=[TP]::VirtualAllocEx($proc,[IntPtr]::Zero,[IntPtr]256,0x3000,0x04)
  $tabTexts=@()
  for($i=0;$i -lt $n;$i++){
    $buf=New-Object byte[] 16
    $w=[IntPtr]::Zero; [void][TP]::WriteProcessMemory($proc,$remote,$buf,[IntPtr]16,[ref]$w)
    [void][TP]::SendMessage($tab,0x130A,[IntPtr]$i,$remote)
    $rb=New-Object byte[] 16; $rr=[IntPtr]::Zero; [void][TP]::ReadProcessMemory($proc,$remote,$rb,[IntPtr]16,[ref]$rr)
    $l=[BitConverter]::ToInt32($rb,0); $t=[BitConverter]::ToInt32($rb,4); $ri=[BitConverter]::ToInt32($rb,8); $b=[BitConverter]::ToInt32($rb,12)
    $pt=New-Object PT+P; $pt.X=[int](($l+$ri)/2); $pt.Y=[int](($t+$b)/2)
    [void][PT]::ClientToScreen($tab,[ref]$pt)
    Write-Output ("TAB {0} rect=({1},{2})-({3},{4}) screen=({5},{6})" -f $i,$l,$t,$ri,$b,$pt.X,$pt.Y)
    $tabTexts += ,@($pt.X,$pt.Y)
  }
  # click last tab (Data Acq./Emulation)
  $last=$tabTexts[$n-1]
  [void][PT]::SetCursorPos($last[0],$last[1]); Start-Sleep -Milliseconds 200
  [PT]::mouse_event(0x0002,0,0,0,[IntPtr]::Zero); [PT]::mouse_event(0x0004,0,0,0,[IntPtr]::Zero)
  Start-Sleep -Seconds 2
  Shot $dlg 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\preferences_dataacq.png'
  $script:kids=New-Object System.Collections.ArrayList
  $cb=[TP+EnumProc]{ param($h,$l) [void]$script:kids.Add($h); return $true }
  [void][TP]::EnumChildWindows($dlg,$cb,[IntPtr]::Zero)
  foreach($k in $script:kids){
    if(-not [PT]::IsWindowVisible($k)){ continue }
    $c=New-Object System.Text.StringBuilder 64; [void][PT]::GetClassNameW($k,$c,64)
    $t=New-Object System.Text.StringBuilder 512; [void][PT]::GetWindowTextW($k,$t,512)
    Write-Output ("{0} id={1} text='{2}'" -f $c.ToString(),[PT]::GetDlgCtrlID($k),$t.ToString())
    if($c.ToString() -eq 'ComboBox'){
      $v=[TP]::SendMessage($k,0x0146,[IntPtr]::Zero,[IntPtr]::Zero).ToInt64(); if($v -gt 2147483647){ $v-=4294967296 }
      $cnt=[int]$v
      $v2=[TP]::SendMessage($k,0x0147,[IntPtr]::Zero,[IntPtr]::Zero).ToInt64(); if($v2 -gt 2147483647){ $v2-=4294967296 }
      $sel=[int]$v2
      Write-Output ("  COMBO id={0} items={1} sel={2}" -f [PT]::GetDlgCtrlID($k),$cnt,$sel)
      for($ci=0;$ci -lt $cnt;$ci++){
        $len=[int][TP]::SendMessage($k,0x0149,[IntPtr]$ci,[IntPtr]::Zero).ToInt64()
        [void][TP]::SendMessage($k,0x0148,[IntPtr]$ci,$remote)
        $tb=New-Object byte[] 1024; $rr=[IntPtr]::Zero
        [void][TP]::ReadProcessMemory($proc,$remote,$tb,[IntPtr]1024,[ref]$rr)
        $s=[Text.Encoding]::Default.GetString($tb,0,[Math]::Max(1,$len))
        $s=[regex]::Replace($s,'[^\x20-\x7E]','.')
        Write-Output ("    CI {0}| {1}" -f $ci,$s)
      }
    }
  }
  [void][TP]::VirtualFreeEx($proc,$remote,[IntPtr]::Zero,0x8000)
} finally { StopTp $p }
