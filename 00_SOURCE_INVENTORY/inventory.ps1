param(
    [string]$Root = 'C:\Program Files (x86)\FLASHPRO.inc',
    [string]$OutDir = 'C:\Users\<USER>\Documents\REVCORE_BE12_FLASHPRO_AUTOPSY\00_SOURCE_INVENTORY'
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

function Get-PeInfo {
    param([string]$Path)
    $b = [System.IO.File]::ReadAllBytes($Path)
    $r = [ordered]@{
        dos_magic = ''; pe_offset = $null; pe_signature = ''; machine = ''
        sections = $null; timestamp_utc = ''; characteristics = ''
        optional_magic = ''; subsystem = ''; entry_rva = $null; image_base = $null
        clr_rva = $null; clr_present = $false; error = ''
    }
    try {
        if ($b.Length -lt 0x40 -or $b[0] -ne 0x4D -or $b[1] -ne 0x5A) { $r.dos_magic = 'NOT_MZ'; return [pscustomobject]$r }
        $r.dos_magic = 'MZ'
        $pe = [BitConverter]::ToInt32($b, 0x3C)
        $r.pe_offset = $pe
        if ($pe -lt 0 -or $pe + 24 -gt $b.Length) { $r.error = 'PE_OFFSET_OUT_OF_RANGE'; return [pscustomobject]$r }
        $sig = [Text.Encoding]::ASCII.GetString($b, $pe, 4)
        $r.pe_signature = ($b[$pe..($pe+3)] | ForEach-Object { $_.ToString('X2') }) -join ' '
        if ($sig -ne "PE`0`0") { $r.error = 'NO_PE_SIGNATURE'; return [pscustomobject]$r }
        $machine = [BitConverter]::ToUInt16($b, $pe + 4)
        $r.machine = switch ($machine) { 0x14c {'x86'} 0x8664 {'x64'} 0xaa64 {'ARM64'} default { '0x{0:X4}' -f $machine } }
        $r.sections = [BitConverter]::ToUInt16($b, $pe + 6)
        $ts = [BitConverter]::ToUInt32($b, $pe + 8)
        $r.timestamp_utc = ([DateTimeOffset]::FromUnixTimeSeconds($ts)).UtcDateTime.ToString('yyyy-MM-dd HH:mm:ss')
        $r.characteristics = '0x{0:X4}' -f ([BitConverter]::ToUInt16($b, $pe + 22))
        $opt = $pe + 24
        $magic = [BitConverter]::ToUInt16($b, $opt)
        $r.optional_magic = switch ($magic) { 0x10b {'PE32'} 0x20b {'PE32+'} default { '0x{0:X4}' -f $magic } }
        $r.entry_rva = '0x{0:X}' -f ([BitConverter]::ToUInt32($b, $opt + 16))
        if ($magic -eq 0x10b) {
            $r.image_base = '0x{0:X}' -f ([BitConverter]::ToUInt32($b, $opt + 28))
            $dd = $opt + 96
        } else {
            $r.image_base = '0x{0:X}' -f ([BitConverter]::ToUInt64($b, $opt + 24))
            $dd = $opt + 112
        }
        $r.subsystem = [BitConverter]::ToUInt16($b, $opt + 68)
        if ($dd + 15*8 + 8 -le $b.Length) {
            $clrRva = [BitConverter]::ToUInt32($b, $dd + 14*8)
            $clrSize = [BitConverter]::ToUInt32($b, $dd + 14*8 + 4)
            $r.clr_rva = '0x{0:X}' -f $clrRva
            $r.clr_present = ($clrRva -ne 0 -and $clrSize -ne 0)
        }
    } catch { $r.error = $_.Exception.Message }
    [pscustomobject]$r
}

$rows = foreach ($f in Get-ChildItem -LiteralPath $Root -Recurse -File | Sort-Object FullName) {
    $vi = $null
    try { $vi = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($f.FullName) } catch {}
    $asm = $null
    try { $asm = [System.Reflection.AssemblyName]::GetAssemblyName($f.FullName) } catch {}
    $sig = $null
    try { $sig = Get-AuthenticodeSignature -LiteralPath $f.FullName } catch {}
    $pe = $null
    if ($f.Extension -in '.exe', '.dll', '.ocx', '.sys') { $pe = Get-PeInfo -Path $f.FullName }
    [pscustomobject]@{
        rel_path        = $f.FullName.Substring($Root.Length).TrimStart('\')
        filename        = $f.Name
        extension       = $f.Extension
        bytes           = $f.Length
        sha256          = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash.ToLower()
        last_write_utc  = $f.LastWriteTimeUtc.ToString('yyyy-MM-dd HH:mm:ss')
        pe_machine      = if ($pe) { $pe.machine } else { '' }
        pe_subsystem    = if ($pe) { $pe.subsystem } else { '' }
        pe_build_utc    = if ($pe) { $pe.timestamp_utc } else { '' }
        clr_present     = if ($pe) { $pe.clr_present } else { '' }
        file_version    = if ($vi) { $vi.FileVersion } else { '' }
        product_version = if ($vi) { $vi.ProductVersion } else { '' }
        product_name    = if ($vi) { $vi.ProductName } else { '' }
        company_name    = if ($vi) { $vi.CompanyName } else { '' }
        original_name   = if ($vi) { $vi.OriginalFilename } else { '' }
        description     = if ($vi) { $vi.FileDescription } else { '' }
        assembly_name   = if ($asm) { $asm.FullName } else { '' }
        signature       = if ($sig) { $sig.Status.ToString() } else { '' }
        signer          = if ($sig -and $sig.SignerCertificate) { $sig.SignerCertificate.Subject } else { '' }
        pe_error        = if ($pe) { $pe.error } else { '' }
    }
}
$rows | Export-Csv -LiteralPath (Join-Path $OutDir 'FLASHPRO_FILE_INVENTORY.csv') -NoTypeInformation -Encoding UTF8
$rows | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $OutDir 'FLASHPRO_FILE_INVENTORY.json') -Encoding UTF8
$rows | Format-Table filename, bytes, pe_machine, clr_present, file_version, signature -AutoSize
'FILES=' + $rows.Count
