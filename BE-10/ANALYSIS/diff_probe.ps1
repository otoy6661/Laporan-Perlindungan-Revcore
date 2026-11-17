$a=[IO.File]::ReadAllBytes('C:\Users\Lord Otoy\Documents\REVCORE_BE10_RESEARCH\PROTOTYPES\testdata\k59a_a11.bin')
$b=[IO.File]::ReadAllBytes('C:\Users\Lord Otoy\Documents\REVCORE_BE10_RESEARCH\PROTOTYPES\testdata\kzrb31.bin')
$n=[Math]::Min($a.Length,$b.Length);$c=0;$first=-1;$last=-1
for($i=0;$i -lt $n;$i++){if($a[$i] -ne $b[$i]){$c++;if($first -lt 0){$first=$i};$last=$i}}
"SIZEA=$($a.Length) SIZEB=$($b.Length) DIFFS=$c FIRST=$first LAST=$last"
