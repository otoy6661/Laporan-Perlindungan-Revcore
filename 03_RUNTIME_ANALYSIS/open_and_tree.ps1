$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System; using System.Text; using System.Collections.Generic; using System.Runtime.InteropServices;
public class T {
 public delegate bool EnumProc(IntPtr h, IntPtr l);
 [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr p, EnumProc cb, IntPtr l);
 [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder sb, int n);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder sb, int n);
 [DllImport("user32.dll")] public static extern int GetDlgCtrlID(IntPtr h);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
 [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h,uint m,IntPtr w,IntPtr l);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern IntPtr SendMessageW(IntPtr h,uint m,IntPtr w,string l);
 [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr h,uint m,IntPtr w,IntPtr l);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
 [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool i, int pid);
 [DllImport("kernel32.dll")] public static extern IntPtr VirtualAllocEx(IntPtr p, IntPtr a, IntPtr s, int t, int pr);
 [DllImport("kernel32.dll")] public static extern bool VirtualFreeEx(IntPtr p, IntPtr a, IntPtr s, int t);
 [DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr p, IntPtr a, byte[] b, IntPtr s, out IntPtr w);
 [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr p, IntPtr a, byte[] b, IntPtr s, out IntPtr r);
 public struct RECT { public int Left,Top,Right,Bottom; }
 const uint TVM_GETNEXTITEM=0x110A, TVM_GETITEMW=0x113E, TVM_EXPAND=0x1102;
 const int TVGN_ROOT=0, TVGN_NEXT=1, TVGN_CHILD=4, TVE_EXPAND=2;
 public static List<string> Dump(IntPtr hTV, int pid, int maxDepth){
   var outp=new List<string>();
   IntPtr proc=OpenProcess(0x1F0FFF,false,pid);
   if(proc==IntPtr.Zero) { outp.Add("OPENPROCESS_FAIL"); return outp; }
   IntPtr remote=VirtualAllocEx(proc,IntPtr.Zero,(IntPtr)4096,0x3000,0x04);
   if(remote==IntPtr.Zero){ outp.Add("VALLOC_FAIL"); return outp; }
   try {
     IntPtr root=SendMessage(hTV,TVM_GETNEXTITEM,(IntPtr)TVGN_ROOT,IntPtr.Zero);
     if(root!=IntPtr.Zero){ Walk(hTV,proc,remote,root,0,maxDepth,outp); }
   } finally { VirtualFreeEx(proc,remote,IntPtr.Zero,0x8000); }
   return outp;
 }
 static void Walk(IntPtr hTV, IntPtr proc, IntPtr remote, IntPtr item, int depth, int maxDepth, List<string> outp){
   string text=GetText(hTV,proc,remote,item);
   outp.Add(new string(' ',depth*2)+text);
   if(depth>=maxDepth) return;
   SendMessage(hTV,TVM_EXPAND,(IntPtr)TVE_EXPAND,item);
   IntPtr ch=SendMessage(hTV,TVM_GETNEXTITEM,(IntPtr)TVGN_CHILD,item);
   while(ch!=IntPtr.Zero){
     Walk(hTV,proc,remote,ch,depth+1,maxDepth,outp);
     ch=SendMessage(hTV,TVM_GETNEXTITEM,(IntPtr)TVGN_NEXT,ch);
   }
 }
 static string GetText(IntPtr hTV, IntPtr proc, IntPtr remote, IntPtr item){
   byte[] st=new byte[40];
   IntPtr textBuf=(IntPtr)(remote.ToInt64()+64);
   BitConverter.GetBytes((uint)0x0001).CopyTo(st,0);
   BitConverter.GetBytes(item.ToInt64()).CopyTo(st,4);
   BitConverter.GetBytes(textBuf.ToInt64()).CopyTo(st,16);
   BitConverter.GetBytes(512).CopyTo(st,20);
   IntPtr w; WriteProcessMemory(proc,remote,st,(IntPtr)40,out w);
   SendMessage(hTV,TVM_GETITEMW,IntPtr.Zero,remote);
   byte[] tb=new byte[512];
   IntPtr r; ReadProcessMemory(proc,textBuf,tb,(IntPtr)512,out r);
   string s=Encoding.Unicode.GetString(tb);
   int z=s.IndexOf((char)0); if(z>=0) s=s.Substring(0,z);
   return s;
 }
}
"@
function Shot($h,$path){
  $r=New-Object T+RECT; [T]::GetWindowRect($h,[ref]$r)|Out-Null
  $bmp=New-Object System.Drawing.Bitmap ($r.Right-$r.Left),($r.Bottom-$r.Top)
  $g=[System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($r.Left,$r.Top,0,0,$bmp.Size)
  $bmp.Save($path,[System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
}
function FindDlg($procId){
  $script:found=[IntPtr]::Zero
  $cb=[T+EnumProc]{ param($h,$l)
    $wp=0; [void][T]::GetWindowThreadProcessId($h,[ref]$wp)
    if($wp -ne $procId){ return $true }
    $c=New-Object System.Text.StringBuilder 64; [void][T]::GetClassNameW($h,$c,64)
    if($c.ToString() -ne '#32770'){ return $true }
    if(-not [T]::IsWindowVisible($h)){ return $true }
    $t=New-Object System.Text.StringBuilder 128; [void][T]::GetWindowTextW($h,$t,128)
    if($t.ToString() -ne 'TunerPro Initialization Error'){ $script:found=$h; return $false }
    return $true
  }
  [void][T]::EnumWindows($cb,[IntPtr]::Zero)
  return $script:found
}
function WaitDlg($procId,$seconds){
  for($i=0;$i -lt ($seconds*4);$i++){ $d=FindDlg $procId; if($d -ne [IntPtr]::Zero){ return $d }; Start-Sleep -Milliseconds 250 }
  return [IntPtr]::Zero
}
function SetDialogPath($dlg,$path){
  $script:edit=[IntPtr]::Zero
  $cb=[T+EnumProc]{ param($h,$l)
    $c=New-Object System.Text.StringBuilder 64; [void][T]::GetClassNameW($h,$c,64)
    if($c.ToString() -eq 'Edit'){ $id=[T]::GetDlgCtrlID($h); if($id -eq 1148 -or $script:edit -eq [IntPtr]::Zero){ $script:edit=$h } }
    return $true
  }
  [void][T]::EnumChildWindows($dlg,$cb,[IntPtr]::Zero)
  if($script:edit -eq [IntPtr]::Zero){ throw 'NO_EDIT' }
  [void][T]::SendMessageW($script:edit,0x000C,[IntPtr]::Zero,$path)
  Start-Sleep -Milliseconds 300
  [void][T]::PostMessage($dlg,0x0111,[IntPtr]1,[IntPtr]::Zero)
}
function FindChildClass($parent,$cls){
  $script:hit=[IntPtr]::Zero
  $cb=[T+EnumProc]{ param($h,$l)
    $c=New-Object System.Text.StringBuilder 64; [void][T]::GetClassNameW($h,$c,64)
    if($c.ToString() -eq $cls){ $script:hit=$h; return $false }
    return $true
  }
  [void][T]::EnumChildWindows($parent,$cb,[IntPtr]::Zero)
  return $script:hit
}
$exe='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$bin='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\K1AA-N03\beat_k1aa_n03.bin'
$xdf='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\K1AA-N03\30400-k1aa-n03.xdf'
$outTree='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\05_XDF_AUTOPSY\K1AA-N03_TREE.txt'
$p=$null
try {
  $p=Start-Process -FilePath $exe -PassThru -WorkingDirectory (Split-Path $exe)
  for($i=0;$i -lt 60;$i++){ Start-Sleep -Milliseconds 400; $p.Refresh(); if($p.MainWindowHandle -ne 0){break} }
  Start-Sleep -Seconds 2; $p.Refresh()
  $main=$p.MainWindowHandle
  if($p.MainWindowTitle -like '*Initialization Error*'){ throw 'APP_INIT_ERROR' }
  [void][T]::PostMessage($main,0x0111,[IntPtr]32773,[IntPtr]::Zero)
  $dlg=WaitDlg $p.Id 6; if($dlg -eq [IntPtr]::Zero){ throw 'BIN_DIALOG_NOT_FOUND' }
  SetDialogPath $dlg $bin; Start-Sleep -Seconds 3
  [void][T]::PostMessage($main,0x0111,[IntPtr]32776,[IntPtr]::Zero)
  $dlg=WaitDlg $p.Id 6; if($dlg -eq [IntPtr]::Zero){ throw 'XDF_DIALOG_NOT_FOUND' }
  SetDialogPath $dlg $xdf; Start-Sleep -Seconds 4
  $p.Refresh(); Write-Output ("TITLE={0}" -f $p.MainWindowTitle)
  $tv=FindChildClass $main 'SysTreeView32'
  Write-Output ("TREE_HANDLE=0x{0:X}" -f $tv.ToInt64())
  if($tv -eq [IntPtr]::Zero){ throw 'NO_TREE' }
  $lines=[T]::Dump($tv,$p.Id,3)
  Write-Output ("TREE_LINES={0}" -f $lines.Count)
  $lines | Set-Content -Path $outTree -Encoding UTF8
  $lines | Select-Object -First 60
  Shot $main 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\tree_expanded.png'
} finally {
  if($p -and -not $p.HasExited){ $p.CloseMainWindow() | Out-Null; Start-Sleep -Seconds 2; if(-not $p.HasExited){ $p.Kill() } }
}
