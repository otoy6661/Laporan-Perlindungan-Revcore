param([switch]$KeepOpen)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
$exe='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$p=Start-Process -FilePath $exe -PassThru -WorkingDirectory (Split-Path $exe)
for($i=0;$i -lt 60;$i++){ Start-Sleep -Milliseconds 400; $p.Refresh(); if($p.MainWindowHandle -ne 0){break} }
Start-Sleep -Seconds 2
$root=[System.Windows.Automation.AutomationElement]::RootElement
$cond=New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty,$p.Id)
$win=$root.FindFirst([System.Windows.Automation.TreeScope]::Children,$cond)
if($null -eq $win){ Write-Output "NO_UIA_WINDOW"; $p.Kill(); exit 1 }
Write-Output ("WINDOW: {0} | class={1}" -f $win.Current.Name,$win.Current.ClassName)
$all=$win.FindAll([System.Windows.Automation.TreeScope]::Descendants,[System.Windows.Automation.Condition]::TrueCondition)
Write-Output ("DESCENDANTS={0}" -f $all.Count)
$i=0
foreach($e in $all){
  $ct=$e.Current.ControlType.ProgrammaticName -replace 'ControlType\.',''
  $nm=$e.Current.Name; $aid=$e.Current.AutomationId; $cls=$e.Current.ClassName
  if($ct -in @('MenuBar','MenuItem','Tree','TreeItem','StatusBar','Edit','Pane','ToolBar','Button','ComboBox','Text') -and ($nm -or $aid)){
    Write-Output ("[{0}] {1} | name='{2}' | id='{3}' | class='{4}'" -f $i,$ct,$nm,$aid,$cls)
  }
  $i++
  if($i -gt 400){break}
}
Write-Output "--- TOP MENUS ---"
$menuBar=$win.FindFirst([System.Windows.Automation.TreeScope]::Descendants,(New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty,[System.Windows.Automation.ControlType]::MenuBar)))
if($menuBar){
  $items=$menuBar.FindAll([System.Windows.Automation.TreeScope]::Children,[System.Windows.Automation.Condition]::TrueCondition)
  foreach($m in $items){ Write-Output ("MENU: {0}" -f $m.Current.Name) }
} else { Write-Output "NO_MENUBAR" }
if(-not $KeepOpen){ $p.CloseMainWindow() | Out-Null; for($i=0;$i -lt 20;$i++){Start-Sleep -Milliseconds 300; if($p.HasExited){break}}; if(-not $p.HasExited){$p.Kill()} }
else { Write-Output ("PID={0}" -f $p.Id) }
