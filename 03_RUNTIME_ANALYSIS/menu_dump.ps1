$ErrorActionPreference='Stop'
Add-Type @"
using System; using System.Text; using System.Runtime.InteropServices;
public class MenuApi {
 [DllImport("user32.dll")] public static extern IntPtr GetMenu(IntPtr hWnd);
 [DllImport("user32.dll")] public static extern int GetMenuItemCount(IntPtr hMenu);
 [DllImport("user32.dll")] public static extern IntPtr GetSubMenu(IntPtr hMenu,int pos);
 [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int GetMenuStringW(IntPtr hMenu,uint id,StringBuilder sb,int max,uint flags);
 [DllImport("user32.dll")] public static extern uint GetMenuItemID(IntPtr hMenu,int pos);
 [DllImport("user32.dll")] public static extern uint GetMenuState(IntPtr hMenu,uint id,uint flags);
}
"@
$exe='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$p=Start-Process -FilePath $exe -PassThru -WorkingDirectory (Split-Path $exe)
for($i=0;$i -lt 60;$i++){ Start-Sleep -Milliseconds 400; $p.Refresh(); if($p.MainWindowHandle -ne 0){break} }
Start-Sleep -Seconds 2
$h=$p.MainWindowHandle
$menu=[MenuApi]::GetMenu($h)
function DumpMenu($hm,$indent){
  $n=[MenuApi]::GetMenuItemCount($hm)
  for($i=0;$i -lt $n;$i++){
    $sb=New-Object System.Text.StringBuilder 256
    [void][MenuApi]::GetMenuStringW($hm,[uint32]$i,$sb,256,0x400)
    $txt=$sb.ToString() -replace "`t.*$",''
    $id=[MenuApi]::GetMenuItemID($hm,$i)
    $sub=[MenuApi]::GetSubMenu($hm,$i)
    Write-Output ("{0}{1}  [id={2}]" -f $indent,$txt,$id)
    if($sub -ne [IntPtr]::Zero){ DumpMenu $sub ($indent+'  ') }
  }
}
Write-Output ("MENU_HANDLE={0}" -f $menu)
DumpMenu $menu ''
$p.CloseMainWindow() | Out-Null
for($i=0;$i -lt 20;$i++){Start-Sleep -Milliseconds 300; if($p.HasExited){break}}
if(-not $p.HasExited){$p.Kill()}
