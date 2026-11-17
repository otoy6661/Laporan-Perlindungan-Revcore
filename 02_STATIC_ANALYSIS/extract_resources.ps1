# BE-12 - Minimal PE resource extractor (read-only).
# Dumps every resource leaf under a directory tree, plus a CSV index.
param(
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter(Mandatory=$true)][string]$OutDir
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

function U16([byte[]]$b,[int]$o){ [BitConverter]::ToUInt16($b,$o) }
function U32([byte[]]$b,[int]$o){ [BitConverter]::ToUInt32($b,$o) }

$b = [IO.File]::ReadAllBytes($Path)
$pe = U32 $b 0x3C
$opt = $pe + 24
$magic = U16 $b $opt
if ($magic -eq 0x20b) { $dd = $opt + 112 } else { $dd = $opt + 96 }
$rsrcRva = U32 $b ($dd + 16)
$rsrcSize = U32 $b ($dd + 20)
if ($rsrcRva -eq 0) { throw 'No resource directory' }

$nsec = U16 $b ($pe + 6)
$secTab = $opt + (U16 $b ($pe + 20))
$sections = @()
for ($i=0; $i -lt $nsec; $i++) {
    $o = $secTab + $i*40
    $sections += [pscustomobject]@{
        Va = (U32 $b ($o+12)); VSize = (U32 $b ($o+8)); Raw = (U32 $b ($o+20)); RawSize = (U32 $b ($o+16))
    }
}
function RvaToOff([uint32]$rva) {
    foreach ($s in $sections) {
        if ($rva -ge $s.Va -and $rva -lt ($s.Va + [Math]::Max($s.VSize, $s.RawSize))) { return [int]($rva - $s.Va + $s.Raw) }
    }
    return -1
}

$base = RvaToOff $rsrcRva
$typeNames = @{ 1='CURSOR'; 2='BITMAP'; 3='ICON'; 4='MENU'; 5='DIALOG'; 6='STRING'; 9='ACCELERATOR'; 10='RCDATA'; 11='MESSAGETABLE'; 12='GROUP_CURSOR'; 14='GROUP_ICON'; 16='VERSION'; 24='MANIFEST' }

$index = @()
function Walk([int]$dirOff, [string]$typeName, [string]$idName, [int]$depth) {
    $named = U16 $b ($base + $dirOff + 12); $ids = U16 $b ($base + $dirOff + 14)
    $count = $named + $ids
    for ($i=0; $i -lt $count; $i++) {
        $e = $base + $dirOff + 16 + $i*8
        $nameField = U32 $b $e; $offField = U32 $b ($e+4)
        $isNamed = ($nameField -band 0x80000000) -ne 0
        $childOff = $offField -band 0x7FFFFFFF
        $isDir = ($offField -band 0x80000000) -ne 0
        $label = if ($isNamed) { $no = $base + ($nameField -band 0x7FFFFFFF); $len = U16 $b $no; [Text.Encoding]::Unicode.GetString($b, $no+2, $len*2) }
                 else { [string]$nameField }
        switch ($depth) {
            0 { $tn = if ($typeNames.ContainsKey([int]$nameField) -and -not $isNamed) { $typeNames[[int]$nameField] } else { $label }; Walk $childOff $tn '' 1 }
            1 { Walk $childOff $typeName $label 2 }
            2 {
                $dataOff = $base + $childOff
                $rva = U32 $b $dataOff; $size = U32 $b ($dataOff+4); $cp = U32 $b ($dataOff+8)
                $fo = RvaToOff $rva
                $fn = ($typeName + '_' + $idName + '_' + $label + '.bin') -replace '[^A-Za-z0-9_.\-]','_'
                $out = Join-Path $OutDir $fn
                if ($fo -ge 0 -and $size -gt 0 -and ($fo + $size) -le $b.Length) {
                    $chunk = New-Object byte[] $size
                    [Array]::Copy($b, $fo, $chunk, 0, $size)
                    [IO.File]::WriteAllBytes($out, $chunk)
                }
                $script:index += [pscustomobject]@{ Type=$typeName; Id=$idName; Lang=$label; RVA=('0x{0:X}' -f $rva); Size=$size; FileOffset=$fo; Output=$fn }
            }
        }
    }
}
Walk 0 '' '' 0
$index | Export-Csv -LiteralPath (Join-Path $OutDir 'RESOURCE_INDEX.csv') -NoTypeInformation -Encoding UTF8
$index | Format-Table -AutoSize | Out-String -Width 200
