$ErrorActionPreference='Stop'
. 'C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\03_RUNTIME_ANALYSIS\tp_lib.ps1'
$exe='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\00_SOURCE_INVENTORY\APP_COPY\TunerPro.exe'
$bin='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\K1AA-N03\beat_k1aa_n03.bin'
$xdf='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\04_BIN_AUTOPSY\WORK\K1AA-N03\30400-k1aa-n03.xdf'
$csv='C:\Users\Lord Otoy\Documents\REVCORE_BE11_TUNERPRO_AUTOPSY\05_XDF_AUTOPSY\K1AA-N03_TABLE_STATUS.csv'
$p=$null
try {
  $r=StartTpPair $exe $bin $xdf
  $p=$r.Process
  $tv=FindChildClass $r.Main 'SysTreeView32'
  $sb=FindChildClass $r.Main 'msctls_statusbar32'
  $lines=[TP]::Dump($tv,$p.Id,2)
  $tables=@()
  foreach($l in $lines){ if($l -match '^  (.+)$'){ $tables += $Matches[1] } }
  Write-Output ("TABLES={0}" -f $tables.Count)
  $rows=New-Object System.Collections.ArrayList
  foreach($t in $tables){
    $item=[TP]::FindByText($tv,$p.Id,$t)
    if($item -eq [IntPtr]::Zero){ continue }
    [void][TP]::SelectItem($tv,$item)
    Start-Sleep -Milliseconds 350
    $parts=[TP]::Status($sb,$p.Id)
    [void]$rows.Add([pscustomobject]@{Table=$t; Status=($parts -join ' | ')})
    Write-Output ("{0} => {1}" -f $t,($parts -join ' | '))
  }
  $rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
} finally { StopTp $p }
