$ErrorActionPreference='Stop'
$root='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY'
$appSrc='C:\Program Files (x86)\TunerPro RT'
$appCopy=Join-Path $root 'APP_COPY'
$dsSrc='C:\Users\Lord Otoy\Downloads\Mobile Devices\REMAP TOOLS BE-09 Revisi 3\FILE BIN XDF ADX'
$dsCopy=Join-Path $root 'DATASET_COPY'
$enc=New-Object System.Text.UTF8Encoding($false)

function Rel($base,$f){ $f.FullName.Substring($base.Length+1).Replace('\','/') }

$rows=@()
Get-ChildItem -LiteralPath $appCopy -Recurse -File | Sort-Object FullName | ForEach-Object {
  $v=$_.VersionInfo
  $rows += [pscustomobject]@{
    RelPath=(Rel $appCopy $_); Bytes=$_.Length; FileVersion=$v.FileVersion; ProductVersion=$v.ProductVersion;
    Company=$v.CompanyName; Product=$v.ProductName; SHA256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLower()
  }
}
$lines=New-Object System.Collections.Generic.List[string]
$lines.Add('"RelPath","Bytes","FileVersion","ProductVersion","Company","Product","SHA256"')
foreach($r in $rows){ $lines.Add(('"{0}",{1},"{2}","{3}","{4}","{5}","{6}"' -f $r.RelPath,$r.Bytes,$r.FileVersion,$r.ProductVersion,$r.Company,$r.Product,$r.SHA256)) }
[IO.File]::WriteAllLines((Join-Path $root 'APP_INVENTORY.csv'),$lines,$enc)
Write-Output ("APP_FILES=" + $rows.Count)

$drows=@()
Get-ChildItem -LiteralPath $dsCopy -Recurse -File | Sort-Object FullName | ForEach-Object {
  $drows += [pscustomobject]@{
    RelPath=(Rel $dsCopy $_); Bytes=$_.Length; Ext=$_.Extension.ToLower();
    SHA256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLower()
  }
}
$dlines=New-Object System.Collections.Generic.List[string]
$dlines.Add('"RelPath","Bytes","Extension","SHA256"')
foreach($r in $drows){ $dlines.Add(('"{0}",{1},"{2}","{3}"' -f $r.RelPath,$r.Bytes,$r.Ext,$r.SHA256)) }
[IO.File]::WriteAllLines((Join-Path $root 'DATASET_INVENTORY.csv'),$dlines,$enc)
Write-Output ("DATASET_FILES=" + $drows.Count)

# verify copies vs originals
$bad=0
foreach($f in (Get-ChildItem -LiteralPath $appCopy -Recurse -File)){
  $rel=$f.FullName.Substring($appCopy.Length+1)
  $src=Join-Path $appSrc $rel
  if(-not (Test-Path -LiteralPath $src)){ $bad++; continue }
  if((Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash){ $bad++ }
}
Write-Output ("APP_COPY_MISMATCH=" + $bad)
$bad2=0
foreach($f in (Get-ChildItem -LiteralPath $dsCopy -Recurse -File)){
  $rel=$f.FullName.Substring($dsCopy.Length+1)
  $src=Join-Path $dsSrc $rel
  if(-not (Test-Path -LiteralPath $src)){ $bad2++; continue }
  if((Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash){ $bad2++ }
}
Write-Output ("DATASET_COPY_MISMATCH=" + $bad2)

$envLines=@()
$envLines += 'BE-11 ENVIRONMENT'
$envLines += ('Captured: ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
$envLines += ('OS: ' + (Get-CimInstance Win32_OperatingSystem).Caption + ' ' + [Environment]::OSVersion.VersionString)
$envLines += ('CPU: ' + (Get-CimInstance Win32_Processor | Select-Object -First 1).Name)
$envLines += ('RAM_GB: ' + [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,1))
$envLines += ('PowerShell: ' + $PSVersionTable.PSVersion.ToString())
$envLines += ('DotNet: ' + (dotnet --version 2>$null))
$envLines += ('User: ' + [Environment]::UserName)
$envLines += ('AppPath: ' + $appSrc)
$envLines += ('DatasetPath: ' + $dsSrc)
[IO.File]::WriteAllLines((Join-Path $root 'ENVIRONMENT.txt'),$envLines,$enc)
Write-Output 'ENV_WRITTEN'
