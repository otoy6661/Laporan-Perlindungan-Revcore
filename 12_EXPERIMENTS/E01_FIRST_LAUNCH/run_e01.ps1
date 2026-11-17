# BE-12 - E01 controlled first launch of the ORIGINAL payload (asInvoker), non-elevated session.
# Copies only. No ECU. Captures process/window/network/file observations and a window image.
$ErrorActionPreference = 'Continue'
$base = Split-Path -Parent $MyInvocation.MyCommand.Path
$app  = Join-Path $base 'APP'
$exe  = Join-Path $app 'FLASHPRO_original.exe'
$out  = Join-Path $base 'OBSERVATION'
New-Item -ItemType Directory -Force -Path $out | Out-Null

$t0 = (Get-Date).ToUniversalTime()
$p = Start-Process -FilePath $exe -WorkingDirectory $app -PassThru
Start-Sleep -Seconds 6
$p.Refresh()

$lines = @()
$lines += 'E01 FIRST LAUNCH (payload direct, non-elevated)'
$lines += ('start_utc=' + $t0.ToString('yyyy-MM-dd HH:mm:ss'))
$lines += ('pid=' + $p.Id + ' has_exited=' + $p.HasExited)
if (-not $p.HasExited) {
    $lines += ('main_window_handle=' + $p.MainWindowHandle)
    $lines += ('main_window_title=' + $p.MainWindowTitle)
    $lines += ('path=' + $p.Path)
    $mods = $p.Modules | ForEach-Object { $_.ModuleName }
    $lines += ('modules_count=' + ($mods | Measure-Object).Count)
    $lines += ('modules=' + (($mods | Sort-Object) -join '; '))
    $children = Get-CimInstance Win32_Process -Filter ("ParentProcessId=" + $p.Id) | Select-Object ProcessId,Name,ExecutablePath,CommandLine
    foreach ($c in $children) { $lines += ('child=' + $c.ProcessId + ' | ' + $c.Name + ' | ' + $c.CommandLine) }
    $conns = Get-NetTCPConnection -OwningProcess $p.Id -ErrorAction SilentlyContinue | Select-Object LocalAddress,LocalPort,RemoteAddress,RemotePort,State
    foreach ($c in $conns) { $lines += ('tcp=' + $c.LocalAddress + ':' + $c.LocalPort + ' -> ' + $c.RemoteAddress + ':' + $c.RemotePort + ' ' + $c.State) }

    # window rectangle + image via PrintWindow
    Add-Type -AssemblyName System.Drawing
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32Shot {
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, uint nFlags);
  public struct RECT { public int Left, Top, Right, Bottom; }
}
"@
    $h = $p.MainWindowHandle
    if ($h -ne 0) {
        $r = New-Object Win32Shot+RECT
        [void][Win32Shot]::GetWindowRect($h, [ref]$r)
        $w = $r.Right - $r.Left; $hh = $r.Bottom - $r.Top
        $lines += ('window_rect=' + $w + 'x' + $hh)
        if ($w -gt 0 -and $hh -gt 0) {
            $bmp = New-Object System.Drawing.Bitmap $w, $hh
            $g = [System.Drawing.Graphics]::FromImage($bmp)
            $hdc = $g.GetHdc()
            [void][Win32Shot]::PrintWindow($h, $hdc, 2)
            $g.ReleaseHdc($hdc); $g.Dispose()
            $img = Join-Path $out 'E01_WINDOW.png'
            $bmp.Save($img, [System.Drawing.Imaging.ImageFormat]::Png)
            $bmp.Dispose()
            $lines += ('screenshot=' + $img)
        }
    }
}

# file deltas: APP, TEMP, APPDATA, LOCALAPPDATA (last 3 minutes)
$since = $t0.AddMinutes(-1)
foreach ($dir in @($app, $env:TEMP, $env:APPDATA, $env:LOCALAPPDATA)) {
    if (-not $dir -or -not (Test-Path -LiteralPath $dir)) { continue }
    $lines += ('--- changed_under=' + $dir)
    Get-ChildItem -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTimeUtc -ge $since -and -not $_.PSIsContainer } |
        Select-Object -First 60 |
        ForEach-Object { $lines += ('file=' + $_.FullName + ' | ' + $_.Length + ' B | ' + $_.LastWriteTimeUtc.ToString('yyyy-MM-dd HH:mm:ss')) }
}

$lines += ('observation_end_utc=' + (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss'))
$lines | Set-Content -LiteralPath (Join-Path $out 'E01_OBSERVATION.txt') -Encoding UTF8
$lines
