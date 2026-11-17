param([string]$Path,[int]$Min=5)
$bytes=[IO.File]::ReadAllBytes($Path)
$sb=New-Object System.Text.StringBuilder
for($i=0;$i -lt $bytes.Length;$i++){
  $b=$bytes[$i]
  if($b -ge 32 -and $b -lt 127){ [void]$sb.Append([char]$b) }
  else { if($sb.Length -ge $Min){ '{0:X4}: {1}' -f ($i-$sb.Length),$sb.ToString() }; [void]$sb.Clear() }
}
