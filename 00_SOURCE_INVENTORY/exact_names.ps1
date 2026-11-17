$root = 'C:\Program Files (x86)\FLASHPRO.inc'
$files = [System.IO.Directory]::GetFiles($root)
foreach ($f in $files) {
    $fi = [System.IO.FileInfo]::new($f)
    $h = (Get-FileHash -LiteralPath $f -Algorithm SHA256).Hash.ToLower()
    $vi = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($f)
    $sig = Get-AuthenticodeSignature -LiteralPath $f
    '{0}|{1}|{2}|{3}|{4}|{5}|{6}' -f $fi.Name, $fi.Length, $h, $vi.FileVersion, $vi.ProductName, $vi.CompanyName, $sig.Status
}
