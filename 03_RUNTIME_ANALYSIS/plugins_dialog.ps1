$ErrorActionPreference='Stop'
. 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\tp_lib.ps1'
Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
using System; using System.Text; using System.Runtime.InteropServices;
public class PD {
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder sb, int n);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder sb, int n);
 [DllImport("user32.dll")] public static extern int GetDlgCtrlID(IntPtr h);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
 [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr h,uint m,IntPtr w,IntPtr l);
}
"@
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
  Write-Output ("DLG=0x{0:X}" -f $dlg.ToInt64())
  if($dlg -ne [IntPtr]::Zero){
    Shot $dlg 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\about_plugins.png'
    $script:kids=New-Object System.Collections.ArrayList
    $cb=[TP+EnumProc]{ param($h,$l) [void]$script:kids.Add($h); return $true }
    [void][TP]::EnumChildWindows($dlg,$cb,[IntPtr]::Zero)
    foreach($k in $script:kids){
      $c=New-Object System.Text.StringBuilder 64; [void][PD]::GetClassNameW($k,$c,64)
      $t=New-Object System.Text.StringBuilder 512; [void][PD]::GetWindowTextW($k,$t,512)
      Write-Output ("CHILD {0} id={1} vis={2} text='{3}'" -f $c.ToString(),[PD]::GetDlgCtrlID($k),[PD]::IsWindowVisible($k),$t.ToString())
      if($c.ToString() -eq 'ListBox'){
        $n=[PD]::SendMessage($k,0x018B,[IntPtr]::Zero,[IntPtr]::Zero).ToInt32()
        Write-Output ("LISTBOX_ITEMS={0}" -f $n)
        $proc=[TP]::OpenProcess(0x1F0FFF,$false,$p.Id)
        $remote=[TP]::VirtualAllocEx($proc,[IntPtr]::Zero,[IntPtr]4096,0x3000,0x04)
        for($i=0;$i -lt $n;$i++){
          [void][PD]::SendMessage($k,0x0189,[IntPtr]$i,$remote)
          $tb=New-Object byte[] 1024; $rr=[IntPtr]::Zero
          [void][TP]::ReadProcessMemory($proc,$remote,$tb,[IntPtr]1024,[ref]$rr)
          $s=[Text.Encoding]::Unicode.GetString($tb); $z=$s.IndexOf([char]0); if($z -ge 0){ $s=$s.Substring(0,$z) }
          Write-Output ("LB {0}| {1}" -f $i,$s)
        }
        [void][TP]::VirtualFreeEx($proc,$remote,[IntPtr]::Zero,0x8000)
      }
    }
  }
} finally { StopTp $p }
