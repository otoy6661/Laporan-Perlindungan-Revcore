$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System; using System.Text; using System.Collections.Generic; using System.Runtime.InteropServices;
public class TP {
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
 [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("kernel32.dll")] public static extern IntPtr OpenProcess(int a, bool i, int pid);
 [DllImport("kernel32.dll")] public static extern IntPtr VirtualAllocEx(IntPtr p, IntPtr a, IntPtr s, int t, int pr);
 [DllImport("kernel32.dll")] public static extern bool VirtualFreeEx(IntPtr p, IntPtr a, IntPtr s, int t);
 [DllImport("kernel32.dll")] public static extern bool WriteProcessMemory(IntPtr p, IntPtr a, byte[] b, IntPtr s, out IntPtr w);
 [DllImport("kernel32.dll")] public static extern bool ReadProcessMemory(IntPtr p, IntPtr a, byte[] b, IntPtr s, out IntPtr r);
 public struct RECT { public int Left,Top,Right,Bottom; }
 const uint TVM_GETNEXTITEM=0x110A, TVM_GETITEMW=0x113E, TVM_EXPAND=0x1102, TVM_SELECTITEM=0x110B;
 const int TVGN_ROOT=0, TVGN_NEXT=1, TVGN_CHILD=4, TVGN_CARET=9, TVE_EXPAND=2;
 public static List<string> Dump(IntPtr hTV, int pid, int maxDepth){
   var outp=new List<string>();
   IntPtr proc=OpenProcess(0x1F0FFF,false,pid);
   if(proc==IntPtr.Zero) { outp.Add("OPENPROCESS_FAIL"); return outp; }
   IntPtr remote=VirtualAllocEx(proc,IntPtr.Zero,(IntPtr)4096,0x3000,0x04);
   if(remote==IntPtr.Zero){ outp.Add("VALLOC_FAIL"); return outp; }
   try {
     IntPtr root=SendMessage(hTV,TVM_GETNEXTITEM,(IntPtr)TVGN_ROOT,IntPtr.Zero);
     while(root!=IntPtr.Zero){
       Walk(hTV,proc,remote,root,0,maxDepth,outp);
       root=SendMessage(hTV,TVM_GETNEXTITEM,(IntPtr)TVGN_NEXT,root);
     }
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
 public static IntPtr FindByText(IntPtr hTV, int pid, string target){
   IntPtr proc=OpenProcess(0x1F0FFF,false,pid);
   if(proc==IntPtr.Zero) return IntPtr.Zero;
   IntPtr remote=VirtualAllocEx(proc,IntPtr.Zero,(IntPtr)4096,0x3000,0x04);
   if(remote==IntPtr.Zero) return IntPtr.Zero;
   try {
     IntPtr root=SendMessage(hTV,TVM_GETNEXTITEM,(IntPtr)TVGN_ROOT,IntPtr.Zero);
     while(root!=IntPtr.Zero){
       IntPtr hit=Find(hTV,proc,remote,root,target,0);
       if(hit!=IntPtr.Zero) return hit;
       root=SendMessage(hTV,TVM_GETNEXTITEM,(IntPtr)TVGN_NEXT,root);
     }
     return IntPtr.Zero;
   } finally { VirtualFreeEx(proc,remote,IntPtr.Zero,0x8000); }
 }
 static IntPtr Find(IntPtr hTV, IntPtr proc, IntPtr remote, IntPtr item, string target, int depth){
   if(item==IntPtr.Zero || depth>8) return IntPtr.Zero;
   if(GetText(hTV,proc,remote,item)==target) return item;
   SendMessage(hTV,TVM_EXPAND,(IntPtr)TVE_EXPAND,item);
   IntPtr ch=SendMessage(hTV,TVM_GETNEXTITEM,(IntPtr)TVGN_CHILD,item);
   while(ch!=IntPtr.Zero){
     IntPtr hit=Find(hTV,proc,remote,ch,target,depth+1);
     if(hit!=IntPtr.Zero) return hit;
     ch=SendMessage(hTV,TVM_GETNEXTITEM,(IntPtr)TVGN_NEXT,ch);
   }
   return IntPtr.Zero;
 }
 public static bool SelectItem(IntPtr hTV, IntPtr item){
   return SendMessage(hTV,TVM_SELECTITEM,(IntPtr)TVGN_CARET,item)!=IntPtr.Zero;
 }
 const uint SB_GETPARTS=0x0406, SB_GETTEXTW=0x040D;
 public static string[] Status(IntPtr hSB, int pid){
   var list=new System.Collections.Generic.List<string>();
   IntPtr n=SendMessage(hSB,SB_GETPARTS,IntPtr.Zero,IntPtr.Zero);
   int count=n.ToInt32(); if(count<=0) return list.ToArray();
   IntPtr proc=OpenProcess(0x1F0FFF,false,pid);
   if(proc==IntPtr.Zero) return list.ToArray();
   IntPtr remote=VirtualAllocEx(proc,IntPtr.Zero,(IntPtr)4096,0x3000,0x04);
   if(remote==IntPtr.Zero) return list.ToArray();
   try {
     for(int i=0;i<count;i++){
       SendMessage(hSB,SB_GETTEXTW,(IntPtr)i,remote);
       byte[] tb=new byte[1024];
       IntPtr r; ReadProcessMemory(proc,remote,tb,(IntPtr)1024,out r);
       string s=Encoding.Unicode.GetString(tb);
       int z=s.IndexOf((char)0); if(z>=0) s=s.Substring(0,z);
       list.Add(s);
     }
   } finally { VirtualFreeEx(proc,remote,IntPtr.Zero,0x8000); }
   return list.ToArray();
 }
 const uint TVM_GETITEMRECT=0x1104;
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
 [DllImport("user32.dll")] public static extern void mouse_event(uint f,uint dx,uint dy,uint d,IntPtr e);
 [DllImport("user32.dll")] public static extern IntPtr GetAncestor(IntPtr h,uint f);
 [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h,int c);
 public struct POINT { public int X,Y; }
 public static bool RealDoubleClick(IntPtr hTV, IntPtr item, int pid){
   IntPtr proc=OpenProcess(0x1F0FFF,false,pid);
   if(proc==IntPtr.Zero) return false;
   IntPtr remote=VirtualAllocEx(proc,IntPtr.Zero,(IntPtr)256,0x3000,0x04);
   if(remote==IntPtr.Zero) return false;
   try {
     byte[] buf=new byte[32];
     BitConverter.GetBytes(item.ToInt64()).CopyTo(buf,0);
     IntPtr w; WriteProcessMemory(proc,remote,buf,(IntPtr)32,out w);
     SendMessage(hTV,TVM_GETITEMRECT,(IntPtr)1,remote);
     byte[] rb=new byte[32]; IntPtr r; ReadProcessMemory(proc,remote,rb,(IntPtr)32,out r);
     int l=BitConverter.ToInt32(rb,0), t=BitConverter.ToInt32(rb,4), rr=BitConverter.ToInt32(rb,8), b=BitConverter.ToInt32(rb,12);
     POINT pt; pt.X=(l+rr)/2; pt.Y=(t+b)/2;
     ClientToScreen(hTV, ref pt);
     IntPtr top=GetAncestor(hTV,2);
     ShowWindow(top,9); SetForegroundWindow(top); System.Threading.Thread.Sleep(300);
     SetCursorPos(pt.X,pt.Y); System.Threading.Thread.Sleep(150);
     mouse_event(0x0002,0,0,0,IntPtr.Zero); mouse_event(0x0004,0,0,0,IntPtr.Zero);
     System.Threading.Thread.Sleep(80);
     mouse_event(0x0002,0,0,0,IntPtr.Zero); mouse_event(0x0004,0,0,0,IntPtr.Zero);
     return true;
   } finally { VirtualFreeEx(proc,remote,IntPtr.Zero,0x8000); }
 }
 public static void PressEnter(IntPtr hWnd){
   PostMessage(hWnd,0x0100,(IntPtr)0x0D,IntPtr.Zero);
   PostMessage(hWnd,0x0101,(IntPtr)0x0D,IntPtr.Zero);
 }
}
"@
function Shot($h,$path){
  $r=New-Object TP+RECT; [TP]::GetWindowRect($h,[ref]$r)|Out-Null
  $bmp=New-Object System.Drawing.Bitmap ($r.Right-$r.Left),($r.Bottom-$r.Top)
  $g=[System.Drawing.Graphics]::FromImage($bmp); $g.CopyFromScreen($r.Left,$r.Top,0,0,$bmp.Size)
  $bmp.Save($path,[System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
}
function FindDlg($procId){
  $script:found=[IntPtr]::Zero
  $cb=[TP+EnumProc]{ param($h,$l)
    $wp=0; [void][TP]::GetWindowThreadProcessId($h,[ref]$wp)
    if($wp -ne $procId){ return $true }
    $c=New-Object System.Text.StringBuilder 64; [void][TP]::GetClassNameW($h,$c,64)
    if($c.ToString() -ne '#32770'){ return $true }
    if(-not [TP]::IsWindowVisible($h)){ return $true }
    $t=New-Object System.Text.StringBuilder 128; [void][TP]::GetWindowTextW($h,$t,128)
    if($t.ToString() -ne 'TunerPro Initialization Error'){ $script:found=$h; return $false }
    return $true
  }
  [void][TP]::EnumWindows($cb,[IntPtr]::Zero)
  return $script:found
}
function WaitDlg($procId,$seconds){
  for($i=0;$i -lt ($seconds*4);$i++){ $d=FindDlg $procId; if($d -ne [IntPtr]::Zero){ return $d }; Start-Sleep -Milliseconds 250 }
  return [IntPtr]::Zero
}
function SetDialogPath($dlg,$path){
  $script:edit=[IntPtr]::Zero
  $cb=[TP+EnumProc]{ param($h,$l)
    $c=New-Object System.Text.StringBuilder 64; [void][TP]::GetClassNameW($h,$c,64)
    if($c.ToString() -eq 'Edit'){ $id=[TP]::GetDlgCtrlID($h); if($id -eq 1148 -or $script:edit -eq [IntPtr]::Zero){ $script:edit=$h } }
    return $true
  }
  [void][TP]::EnumChildWindows($dlg,$cb,[IntPtr]::Zero)
  if($script:edit -eq [IntPtr]::Zero){ throw 'NO_EDIT' }
  [void][TP]::SendMessageW($script:edit,0x000C,[IntPtr]::Zero,$path)
  Start-Sleep -Milliseconds 300
  [void][TP]::PostMessage($dlg,0x0111,[IntPtr]1,[IntPtr]::Zero)
}
function FindChildClass($parent,$cls){
  $script:hit=[IntPtr]::Zero
  $cb=[TP+EnumProc]{ param($h,$l)
    $c=New-Object System.Text.StringBuilder 64; [void][TP]::GetClassNameW($h,$c,64)
    if($c.ToString() -eq $cls){ $script:hit=$h; return $false }
    return $true
  }
  [void][TP]::EnumChildWindows($parent,$cb,[IntPtr]::Zero)
  return $script:hit
}
function StartTpPair($exe,$bin,$xdf){
  # clean only stale instances launched from our isolated copy
  Get-Process TunerPro* -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $exe } | Stop-Process -Force -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 1
  $p=Start-Process -FilePath $exe -PassThru -WorkingDirectory (Split-Path $exe)
  for($i=0;$i -lt 60;$i++){ Start-Sleep -Milliseconds 400; $p.Refresh(); if($p.MainWindowHandle -ne 0){break} }
  Start-Sleep -Seconds 2; $p.Refresh()
  if($p.MainWindowTitle -like '*Initialization Error*'){ throw 'APP_INIT_ERROR' }
  $main=$p.MainWindowHandle
  [void][TP]::PostMessage($main,0x0111,[IntPtr]32773,[IntPtr]::Zero)
  $dlg=WaitDlg $p.Id 6; if($dlg -eq [IntPtr]::Zero){ throw 'BIN_DIALOG_NOT_FOUND' }
  SetDialogPath $dlg $bin; Start-Sleep -Seconds 3
  [void][TP]::PostMessage($main,0x0111,[IntPtr]32776,[IntPtr]::Zero)
  $dlg=WaitDlg $p.Id 6; if($dlg -eq [IntPtr]::Zero){ throw 'XDF_DIALOG_NOT_FOUND' }
  SetDialogPath $dlg $xdf; Start-Sleep -Seconds 4
  $p.Refresh()
  return [pscustomobject]@{ Process=$p; Main=$main }
}
function StopTp($p){
  if($p -and -not $p.HasExited){ $p.CloseMainWindow() | Out-Null; Start-Sleep -Seconds 2; if(-not $p.HasExited){ $p.Kill() } }
}
