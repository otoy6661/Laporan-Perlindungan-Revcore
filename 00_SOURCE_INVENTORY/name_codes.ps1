$root = 'C:\Program Files (x86)\FLASHPRO.inc'
foreach ($f in [System.IO.Directory]::GetFiles($root)) {
    $n = [System.IO.Path]::GetFileName($f)
    $codes = ($n.ToCharArray() | ForEach-Object { '{0:X4}' -f [int]$_ }) -join ' '
    "[$n] len=$($n.Length) codes=$codes"
}
