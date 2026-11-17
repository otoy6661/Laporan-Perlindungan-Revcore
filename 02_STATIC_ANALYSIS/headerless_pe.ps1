param([string]$Path, [int]$PeOffset)
$b = [System.IO.File]::ReadAllBytes($Path)
function U16([int]$o) { [BitConverter]::ToUInt16($b, $o) }
function U32([int]$o) { [BitConverter]::ToUInt32($b, $o) }
function Ent([int]$off, [int]$len) {
    if ($off -lt 0 -or $len -le 0 -or $off + $len -gt $b.Length) { return -1 }
    $c = New-Object int[] 256
    for ($i = 0; $i -lt $len; $i++) { $c[$b[$off + $i]]++ }
    $e = 0.0; for ($i = 0; $i -lt 256; $i++) { if ($c[$i] -gt 0) { $p = $c[$i] / $len; $e -= $p * [Math]::Log($p, 2) } }
    [Math]::Round($e, 4)
}
$sig = [Text.Encoding]::ASCII.GetString($b, $PeOffset, 4)
"pe_offset=0x{0:X} sig={1}" -f $PeOffset, (($b[$PeOffset..($PeOffset+3)] | % { $_.ToString('X2') }) -join ' ')
if ($sig -ne "PE`0`0") { exit 1 }
$coff = $PeOffset + 4
$machine = U16 $coff; $nsec = U16 ($coff + 2); $ts = U32 ($coff + 4); $optSize = U16 ($coff + 16)
$opt = $coff + 20; $magic = U16 $opt
"machine=0x{0:X4} sections={1} timestamp=0x{2:X8}" -f $machine, $nsec, $ts
$secOff = $opt + $optSize
for ($i = 0; $i -lt $nsec; $i++) {
    $s = $secOff + $i * 40
    $name = [Text.Encoding]::ASCII.GetString($b, $s, 8).TrimEnd([char]0)
    $vs = U32 ($s + 8); $va = U32 ($s + 12); $rs = U32 ($s + 16); $rp = U32 ($s + 20); $fl = U32 ($s + 36)
    "sec[{0}] name='{1}' va=0x{2:X} vsize=0x{3:X} raw=0x{4:X} rawsize=0x{5:X} flags=0x{6:X8} entropy={7}" -f $i,$name,$va,$vs,$rp,$rs,$fl,(Ent $rp ([Math]::Min($rs, 1048576)))
}
