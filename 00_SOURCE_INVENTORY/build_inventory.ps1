# BE-12 authoritative file inventory for C:\Program Files (x86)\FLASHPRO.inc (read-only)
# Regenerates FLASHPRO_FILE_INVENTORY.csv/.json with per-file error isolation.
param(
    [string]$Root   = 'C:\Program Files (x86)\FLASHPRO.inc',
    [string]$OutDir = 'C:\Users\<USER>\Documents\REVCORE_BE12_FLASHPRO_AUTOPSY\00_SOURCE_INVENTORY'
)
$ErrorActionPreference = 'Continue'

function Get-PeInfo([string]$Path) {
    $r = [ordered]@{ dos_magic=''; pe_offset=''; machine=''; sections=''; timestamp_utc=''; optional_magic=''; subsystem=''; entry_rva=''; image_base=''; overlay_bytes=''; clr_present=''; error='' }
    try {
        $fs = [IO.File]::Open($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
        try {
            $br = New-Object IO.BinaryReader($fs)
            $b = $br.ReadBytes([int]$fs.Length)
        } finally { $fs.Dispose() }
        if ($b.Length -lt 0x40 -or $b[0] -ne 0x4D -or $b[1] -ne 0x5A) { $r.dos_magic='NOT_MZ'; return [pscustomobject]$r }
        $r.dos_magic='MZ'
        $pe = [BitConverter]::ToInt32($b,0x3C); $r.pe_offset = '0x{0:X}' -f $pe
        if ($pe -lt 0 -or $pe + 24 -gt $b.Length) { $r.error='PE_OFFSET_OUT_OF_RANGE'; return [pscustomobject]$r }
        if (-not ($b[$pe] -eq 0x50 -and $b[$pe+1] -eq 0x45 -and $b[$pe+2] -eq 0 -and $b[$pe+3] -eq 0)) { $r.error='NO_PE_SIGNATURE'; return [pscustomobject]$r }
        $m = [BitConverter]::ToUInt16($b,$pe+4); $r.machine = switch ($m) { 0x14c {'x86'} 0x8664 {'x64'} default { '0x{0:X4}' -f $m } }
        $r.sections = [BitConverter]::ToUInt16($b,$pe+6)
        $r.timestamp_utc = [DateTimeOffset]::FromUnixTimeSeconds([BitConverter]::ToUInt32($b,$pe+8)).UtcDateTime.ToString('yyyy-MM-dd HH:mm:ss')
        $opt = $pe+24; $magic = [BitConverter]::ToUInt16($b,$opt)
        $r.optional_magic = switch ($magic) { 0x10b {'PE32'} 0x20b {'PE32+'} default { '0x{0:X4}' -f $magic } }
        $r.entry_rva = '0x{0:X}' -f [BitConverter]::ToUInt32($b,$opt+16)
        if ($magic -eq 0x10b) { $r.image_base='0x{0:X}' -f [BitConverter]::ToUInt32($b,$opt+28); $dd=$opt+96; $soi=[BitConverter]::ToUInt32($b,$opt+56) }
        else { $r.image_base='0x{0:X}' -f [BitConverter]::ToUInt64($b,$opt+24); $dd=$opt+112; $soi=[BitConverter]::ToUInt32($b,$opt+56) }
        $r.subsystem = [BitConverter]::ToUInt16($b,$opt+68)
        # overlay = file size - end of last raw section
        $nsec = [BitConverter]::ToUInt16($b,$pe+6); $secTab = $opt + ([BitConverter]::ToUInt16($b,$pe+20))
        $end = 0
        for ($i=0; $i -lt $nsec; $i++) {
            $o = $secTab + $i*40
            $rawSize = [BitConverter]::ToUInt32($b,$o+16); $rawPtr = [BitConverter]::ToUInt32($b,$o+20)
            if (($rawPtr + $rawSize) -gt $end) { $end = $rawPtr + $rawSize }
        }
        if ($b.Length -gt $end) { $r.overlay_bytes = $b.Length - $end }
        if ($dd + 15*8 + 8 -le $b.Length) {
            $clrRva = [BitConverter]::ToUInt32($b,$dd+14*8); $clrSize = [BitConverter]::ToUInt32($b,$dd+14*8+4)
            $r.clr_present = ($clrRva -ne 0 -and $clrSize -ne 0)
        }
    } catch { $r.error = $_.Exception.Message }
    [pscustomobject]$r
}

$notes = @{
    'AUTO UPDATE.exe' = 'VB6 wrapper (TJprojMain 1.00). Embeds original 9,671,680 B Enigma x64 payload (EXACT MATCH to installer copy).'
    'FLASHPRO.exe'    = 'VB6 wrapper (TJprojMain 1.00). Embeds original 33,321,984 B Enigma x64 payload (EXACT MATCH to installer copy).'
    'unins000.exe'    = 'VB6 wrapper (TJprojMain 1.00). Embeds 3,693,285 B Inno Setup uninstaller payload.'
    ('flashpro.exe' + [char]0x00A0) = 'Installed name is "flashpro.exe" + U+00A0 (NBSP). Byte-identical copy of the FLASHPRO.exe embedded payload / installer original.'
    'DotNetZip.dll'   = 'MSIL .NET library (Ionic DotNetZip 1.16.0), unsigned.'
    'lastimage.txt'   = 'Plain text, 67 B, refers to a PNG path under C:\Users\Home\Downloads (not present on this machine).'
    'unins000.dat'    = 'Inno Setup uninstaller data (5,537 B).'
}

$rows = @()
foreach ($f in (Get-ChildItem -LiteralPath $Root -Force -File | Sort-Object Name)) {
    $path = $f.FullName
    $vi = $null; $asm = $null; $sig = $null
    try { $vi = [Diagnostics.FileVersionInfo]::GetVersionInfo($path) } catch {}
    try { $asm = [Reflection.AssemblyName]::GetAssemblyName($path) } catch {}
    try { $sig = Get-AuthenticodeSignature -LiteralPath $path } catch {}

    # Win32 path normalization mishandles the trailing U+00A0 name: reading through the
    # installed path silently resolves to FLASHPRO.exe. Use the byte-verified copy instead.
    $readPath = $path
    if ($f.Name -eq ('flashpro.exe' + [char]0x00A0)) {
        $readPath = Join-Path $OutDir 'APP_COPY\flashpro_nbsp.exe'
    }

    $sha = ''
    try {
        $fs = [IO.File]::Open($readPath, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
        try { $sha = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($fs)).Replace('-','').ToLower() } finally { $fs.Dispose() }
    } catch { $sha = 'ERROR: ' + $_.Exception.Message }

    $pe = $null
    $extNorm = ($f.Extension.TrimEnd([char]0x00A0, [char]0x20))
    if ($extNorm -match '^\.(exe|dll|ocx|sys)$') { $pe = Get-PeInfo $readPath }

    $rows += [pscustomobject]@{
        filename        = $f.Name
        name_codepoints = (([int[]][char[]]$f.Name) -join ',')
        extension       = $f.Extension
        bytes           = $f.Length
        sha256          = $sha
        creation_utc    = $f.CreationTimeUtc.ToString('yyyy-MM-dd HH:mm:ss')
        last_write_utc  = $f.LastWriteTimeUtc.ToString('yyyy-MM-dd HH:mm:ss')
        role            = if ($notes.ContainsKey($f.Name)) { 'see notes' } else { '' }
        pe_machine      = if ($pe) { $pe.machine } else { '' }
        pe_subsystem    = if ($pe) { $pe.subsystem } else { '' }
        pe_build_utc    = if ($pe) { $pe.timestamp_utc } else { '' }
        pe_overlay_bytes= if ($pe) { $pe.overlay_bytes } else { '' }
        clr_present     = if ($pe) { $pe.clr_present } else { '' }
        file_version    = if ($vi) { $vi.FileVersion } else { '' }
        product_version = if ($vi) { $vi.ProductVersion } else { '' }
        product_name    = if ($vi) { $vi.ProductName } else { '' }
        company_name    = if ($vi) { $vi.CompanyName } else { '' }
        original_name   = if ($vi) { $vi.OriginalFilename } else { '' }
        description     = if ($vi) { $vi.FileDescription } else { '' }
        assembly_name   = if ($asm) { $asm.FullName } else { '' }
        signature       = if ($sig) { $sig.Status.ToString() } else { '' }
        notes           = if ($notes.ContainsKey($f.Name)) { $notes[$f.Name] } else { '' }
        pe_error        = if ($pe) { $pe.error } else { '' }
    }
}

$rows | Export-Csv -LiteralPath (Join-Path $OutDir 'FLASHPRO_FILE_INVENTORY.csv') -NoTypeInformation -Encoding UTF8
$rows | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $OutDir 'FLASHPRO_FILE_INVENTORY.json') -Encoding UTF8
$rows | Format-Table filename, bytes, pe_machine, file_version, signature -AutoSize | Out-String -Width 200
'FILES=' + $rows.Count
