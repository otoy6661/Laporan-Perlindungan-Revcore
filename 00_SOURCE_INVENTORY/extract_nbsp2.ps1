$ErrorActionPreference = 'Stop'
$src = '\\?\C:\Program Files (x86)\FLASHPRO.inc\flashpro.exe' + [char]0x00A0
$dst = 'C:\Users\<USER>\Documents\REVCORE_BE12_FLASHPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\flashpro_nbsp.exe'
$fi = [System.IO.FileInfo]::new($src)
"exists=$($fi.Exists) size=$($fi.Length)"
$sha = [System.Security.Cryptography.SHA256]::Create()
$in = [System.IO.File]::Open($src, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
try {
    $out = [System.IO.File]::Create($dst)
    try { $in.CopyTo($out) } finally { $out.Dispose() }
    $in.Position = 0
    $hash = [BitConverter]::ToString($sha.ComputeHash($in)).Replace('-', '').ToLower()
} finally { $in.Dispose(); $sha.Dispose() }
$di = [System.IO.FileInfo]::new($dst)
$vi = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($dst)
"copy_size=$($di.Length) sha256=$hash"
"file_version=$($vi.FileVersion) product_version=$($vi.ProductVersion) product=$($vi.ProductName) company=$($vi.CompanyName) original=$($vi.OriginalFilename)"
