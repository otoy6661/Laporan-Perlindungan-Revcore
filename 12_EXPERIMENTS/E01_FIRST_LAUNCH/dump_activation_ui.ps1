param(
    [int]$ProcId = 53624,
    [string]$OutDir = 'C:\Users\<USER>\Documents\REVCORE_BE12_FLASHPRO_AUTOPSY\12_EXPERIMENTS\E01_FIRST_LAUNCH\OBSERVATION'
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

$p = Get-Process -Id $ProcId -ErrorAction Stop
$h = $p.MainWindowHandle
if ($h -eq 0) { throw 'NO_MAIN_WINDOW' }
$root = [System.Windows.Automation.AutomationElement]::FromHandle($h)
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('UIA_TREE root=' + $root.Current.Name + ' class=' + $root.Current.ClassName + ' type=' + $root.Current.ControlType.ProgrammaticName + ' rect=' + $root.Current.BoundingRectangle)

function Walk($el, $depth) {
    if ($depth -gt 6) { return }
    $walker = [System.Windows.Automation.TreeWalker]::ControlViewWalker
    $child = $walker.GetFirstChild($el)
    while ($child -ne $null) {
        try {
            $c = $child.Current
            $pad = '  ' * $depth
            $line = '{0}[{1}] name="{2}" auto="{3}" class="{4}" enabled={5} offscreen={6} rect={7}' -f $pad, $c.ControlType.ProgrammaticName.Replace('ControlType.',''), $c.Name, $c.AutomationId, $c.ClassName, $c.IsEnabled, $c.IsOffscreen, $c.BoundingRectangle
            $patterns = @()
            foreach ($pt in @([System.Windows.Automation.ValuePattern]::Pattern, [System.Windows.Automation.InvokePattern]::Pattern, [System.Windows.Automation.SelectionItemPattern]::Pattern, [System.Windows.Automation.TextPattern]::Pattern)) {
                $obj = $null
                if ($child.TryGetCurrentPattern($pt, [ref]$obj)) { $patterns += $pt.ProgrammaticName.Replace('PatternIdentifiers.Pattern','') }
            }
            if ($patterns.Count -gt 0) { $line += ' patterns=' + ($patterns -join ',') }
            $lines.Add($line)
            Walk $child ($depth + 1)
        } catch {}
        $child = $walker.GetNextSibling($child)
    }
}
Walk $root 1
$out = Join-Path $OutDir 'E01_ACTIVATION_UI_TREE.txt'
$lines | Set-Content -LiteralPath $out -Encoding UTF8
$lines
