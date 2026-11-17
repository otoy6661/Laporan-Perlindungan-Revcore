$ErrorActionPreference = 'Stop'
$src = '\\?\C:\Program Files (x86)\FLASHPRO.inc\flashpro.exe '
$dst = 'C:\Users\<USER>\Documents\REVCORE_BE12_FLASHPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\flashpro_v0016.exe'
$sha = [System.Security.Cryptography.SHA256]::Create()
$in = [System.IO.File]::Open($src, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
try {
    $out = [System.IO.File]::Create($dst)
    try { $in.CopyTo($out) } finally { $out.Dispose() }
    $in.Position = 0
    $hash = [BitConverter]::ToString($sha.ComputeHash($in)).Replace('-', '').ToLower()
} finally { $in.Dispose(); $sha.Dispose() }
$fi = [System.IO.FileInfo]::new($dst)
$vi = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($dst)
"src_size=$($fi.Length) sha256=$hash"
"file_version=$($vi.FileVersion) product_version=$($vi.ProductVersion) product=$($vi.ProductName) company=$($vi.CompanyName) desc=$($vi.FileDescription) original=$($vi.OriginalFilename)"
