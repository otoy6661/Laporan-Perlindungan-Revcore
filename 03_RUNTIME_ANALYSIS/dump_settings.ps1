param([string]$Path)
$bytes = [IO.File]::ReadAllBytes($Path)
# UTF-16LE runs
$sb = New-Object System.Text.StringBuilder
$runs = New-Object System.Collections.ArrayList
for($i=0;$i -lt $bytes.Length-1;$i+=2){
  $c = $bytes[$i] + ($bytes[$i+1] -shl 8)
  if($c -ge 32 -and $c -lt 127){ [void]$sb.Append([char]$c) }
  else { if($sb.Length -ge 4){ [void]$runs.Add(("{0:X4}: {1}" -f ($i-$sb.Length*2), $sb.ToString())) }; [void]$sb.Clear() }
}
if($sb.Length -ge 4){ [void]$runs.Add(("{0:X4}: {1}" -f ($bytes.Length-$sb.Length*2), $sb.ToString())) }
Write-Output "=== UTF16LE strings: $($runs.Count) ==="
$runs | Select-Object -First 60
