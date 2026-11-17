# BE-12 - Verifier for the VB6 wrapper format found in FLASHPRO.inc executables
# Read-only. Operates on copies in APP_COPY only. Produces CSV + text summary.
#
# Layout established by BE-12 static analysis:
#   [0 .. 0x1E000)      VB6 stub PE image (headers + 3 sections, 122880 B)
#   [stub .. H)         filler = one 256-byte random block repeated, H = MZ-25
#   [H .. H+25)         25-byte header: uint16 fillerLen at +0, 0x0000 at +2, 0x0E10 at +4
#   [H+25 .. EOF-25)    original executable, byte-identical to installer payload
#   [EOF-25 .. EOF)     25-byte trailer: uint32 originalSize at +0, 0x0E10 at +4
param(
    [string]$CopyDir = "$PSScriptRoot\APP_COPY",
    [string]$OutCsv  = "$PSScriptRoot\WRAPPER_LAYOUT_VERIFIED.csv",
    [string]$OriginalDir = "C:\Users\<USER>\Documents\Qoder\flashpro_analysis\embedded_2026\{app}"
)

function Get-Sha256([byte[]]$bytes, [int]$offset, [int]$count) {
    $sha = [Security.Cryptography.SHA256]::Create()
    $sha.ComputeHash($bytes, $offset, $count)
}

$stubLen = 0x1E000   # 122880, overlay start = end of PE image (headers + 3 sections)
$rows = @()

$targets = @(
    @{ Name = 'FLASHPRO.exe';       Original = 'FLASHPRO.exe' },
    @{ Name = 'AUTO UPDATE.exe';    Original = 'AUTO UPDATE.exe' },
    @{ Name = 'unins000.exe';       Original = $null }
)

foreach ($t in $targets) {
    $path = Join-Path $CopyDir $t.Name
    if (-not (Test-Path -LiteralPath $path)) { continue }
    $b = [IO.File]::ReadAllBytes($path)

    # Locate the payload MZ: candidate whose e_lfanew points to a PE signature
    $mz = -1
    for ($i = $stubLen; $i -lt [Math]::Min($stubLen + 0x8000, $b.Length - 0x100); $i++) {
        if ($b[$i] -eq 0x4D -and $b[$i+1] -eq 0x5A) {
            $lf = [BitConverter]::ToInt32($b, $i + 0x3C)
            if ($lf -gt 0 -and $lf -lt 0x400 -and ($i + $lf + 3) -lt $b.Length) {
                if ($b[$i+$lf] -eq 0x50 -and $b[$i+$lf+1] -eq 0x45 -and $b[$i+$lf+2] -eq 0 -and $b[$i+$lf+3] -eq 0) { $mz = $i; break }
            }
        }
    }

    $hdrOff = $mz - 25
    $n = [BitConverter]::ToUInt16($b, $hdrOff)
    $tag = [BitConverter]::ToUInt16($b, $hdrOff + 4)
    $hdr = $b[$hdrOff..($hdrOff + 24)]
    $payOff = $mz
    $trOff = $b.Length - 25
    $tr = $b[$trOff..($b.Length - 1)]
    $claimedSize = [BitConverter]::ToUInt32($b, $trOff)
    $trTag = [BitConverter]::ToUInt16($b, $trOff + 4)
    $payLen = $trOff - $payOff

    # filler periodicity: 256-byte block repeated up to the header
    $blk = New-Object byte[] 256
    [Array]::Copy($b, $stubLen, $blk, 0, 256)
    $break = -1
    for ($i = $stubLen; $i -lt $hdrOff; $i++) {
        if ($b[$i] -ne $blk[($i - $stubLen) % 256]) { $break = $i; break }
    }

    $paySha = (Get-Sha256 $b $payOff $payLen)
    $blkSha = (Get-Sha256 $blk 0 256)
    $payShaHex = ([BitConverter]::ToString($paySha).Replace('-','').ToLower())

    $origSha = ''
    $origMatch = 'N/A (no installer original available)'
    if ($t.Original) {
        $op = Join-Path $OriginalDir $t.Original
        if (Test-Path -LiteralPath $op) {
            $origSha = (Get-FileHash -LiteralPath $op -Algorithm SHA256).Hash.ToLower()
            if ($origSha -eq $payShaHex) { $origMatch = 'EXACT MATCH' } else { $origMatch = 'MISMATCH' }
        }
    }

    $rows += [pscustomobject]@{
        File               = $t.Name
        Bytes              = $b.Length
        PayloadMzOffset    = $mz
        FillerLenField     = $n
        FillerActualLen    = ($hdrOff - $stubLen)
        FillerLenMatches   = ($n -eq ($hdrOff - $stubLen))
        FillerBreak        = $break
        FillerPeriodic     = ($break -eq -1)
        HeaderTagAtPlus4   = ('0x{0:X4}' -f $tag)
        Header25Hex        = ([BitConverter]::ToString($hdr).Replace('-','').ToLower())
        PayloadLen         = $payLen
        TrailerSizeField   = $claimedSize
        SizeFieldMatches   = ($claimedSize -eq $payLen)
        TrailerTagAtPlus4  = ('0x{0:X4}' -f $trTag)
        SizeEquationHolds  = (($stubLen + ($hdrOff - $stubLen) + 25 + $payLen + 25) -eq $b.Length)
        PayloadSha256      = $payShaHex
        FillerBlock256Sha  = ([BitConverter]::ToString($blkSha).Replace('-','').ToLower())
        InstallerOriginalSha256 = $origSha
        PayloadVsOriginal  = $origMatch
    }
}

$rows | Export-Csv -LiteralPath $OutCsv -NoTypeInformation -Encoding UTF8
$rows | Format-List | Out-String -Width 250
