# BE-12 - dump UTF-16LE runs from resource templates (read-only)
param([string]$Dir)
Get-ChildItem -LiteralPath $Dir -Filter *.bin | Where-Object { $_.Name -match '^(ICON_[456]|VERSION|MANIFEST)' } | ForEach-Object {
    $b = [IO.File]::ReadAllBytes($_.FullName)
    Write-Output ('===== ' + $_.Name + ' (' + $b.Length + ' B)')
    if ($_.Name -like 'MANIFEST*') {
        Write-Output ([Text.Encoding]::UTF8.GetString($b))
        return
    }
    $s = [Text.Encoding]::Unicode.GetString($b)
    $parts = $s.Split([char]0)
    foreach ($p in $parts) {
        $t = $p.Trim()
        if ($t.Length -ge 2 -and ($t.ToCharArray() | Where-Object { [int]$_ -ge 32 -and [int]$_ -lt 0x3000 }).Count -ge [Math]::Max(2, [int]($t.Length*0.8))) {
            Write-Output ('  ' + $t)
        }
    }
}
