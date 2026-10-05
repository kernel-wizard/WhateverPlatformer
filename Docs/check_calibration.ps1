# check_calibration.ps1 - checks Docs\calibration_ledger.csv against the rules and tables in core.md.
# Run:  powershell -ExecutionPolicy Bypass -File "C:\Users\ontro\Documents\Unreal Projects\WhateverPlatformer\Docs\check_calibration.ps1"
# Exit code = number of FAIL lines (0 = clean). Read-only: it never writes any file.
# Keep this file ASCII-only (Windows PowerShell 5.1 reads BOM-less files as ANSI).

$ErrorActionPreference = 'Stop'
$Inv    = [Globalization.CultureInfo]::InvariantCulture
$Ledger = Join-Path $PSScriptRoot 'calibration_ledger.csv'
$Core   = Join-Path (Split-Path $PSScriptRoot -Parent) 'core.md'

# core.md 1.3 / 1.6 / 1.7 [LOCKED]
$Budget     = @{ 1 = 1030; 2 = 1340; 3 = 1740; 4 = 2260; 5 = 2940 }
$Milestones = @(300, 800, 1500, 2500, 3800, 5500)
$Tolerance  = 0.15   # level max vs budget
$GrowMin    = 0.20   # room-to-room growth
$GrowMax    = 0.30
$AvgShare   = 0.70   # average player share of max

$script:Fails = 0
$script:Warns = 0
function Pass([string]$m) { Write-Host "PASS  $m" -ForegroundColor Green }
function Info([string]$m) { Write-Host "INFO  $m" -ForegroundColor Gray }
function Warn([string]$m) { $script:Warns++; Write-Host "WARN  $m" -ForegroundColor Yellow }
function Fail([string]$m) { $script:Fails++; Write-Host "FAIL  $m" -ForegroundColor Red }
function Num([string]$s)  { [double]::Parse($s.Trim(), $Inv) }
function Pct([double]$x)  { ($x * 100).ToString('+0;-0;0', $Inv) + '%' }
function DamageMatches([string]$cell, [double]$v) {
    try {
        $rm = [regex]::Match($cell.Trim(), '^([\d.]+)\s*[\u2013-]\s*([\d.]+)$')
        if ($rm.Success) { return ($v -ge (Num $rm.Groups[1].Value) -and $v -le (Num $rm.Groups[2].Value)) }
        return ([math]::Abs((Num $cell) - $v) -lt 0.05)
    } catch { return $false }
}

$rows = @(Import-Csv $Ledger | ForEach-Object {
    [pscustomobject]@{
        Level  = [int]$_.Level
        Room   = [int]$_.Room
        Fruit  = (Num $_.Fruit)
        Kills  = (Num $_.Kills)
        Max    = (Num $_.Max)
	Reward = if ($_.PSObject.Properties['Reward'] -and $_.Reward) { Num $_.Reward } else { 0 }
        Time   = (Num $_.Time_s)
        Damage = (Num $_.Damage)
        Deaths = (Num $_.Deaths)
        Status = $_.Status
        Note   = $_.Note
    }
})
$core = @(Get-Content $Core -Encoding UTF8)

# ---------------------------------------------------------------- rooms
Write-Host "`n== Rooms (ledger) =="
foreach ($r in $rows) {
    $id = "L$($r.Level) R$($r.Room)"
    $sum = $r.Fruit + $r.Kills
    if ($sum -eq $r.Max) { Pass "$id fruit $($r.Fruit) + kills $($r.Kills) = max $($r.Max)" }
    else { Fail "$id fruit $($r.Fruit) + kills $($r.Kills) = $sum, but ledger max is $($r.Max)" }

    $dmgBudget = ($r.Room + 1) + ($r.Level - 1)
    if ($r.Damage -le $dmgBudget) { Pass "$id damage $($r.Damage) <= budget $dmgBudget" }
    else { Fail "$id damage $($r.Damage) > budget $dmgBudget" }

    $deathCap = if ($r.Level -le 2) { 1 } else { 2 }
    if ($r.Deaths -le $deathCap) { Pass "$id deaths $($r.Deaths) <= $deathCap" }
    else { Warn "$id deaths $($r.Deaths) > $deathCap" }

    if ($r.Status -ne 'calibrated') { Warn "$id status '$($r.Status)': $($r.Note)" }
}

# ---------------------------------------------------------------- growth
Write-Host "`n== Room-to-room growth (target +20..+30 %) =="
foreach ($lv in @($rows | Select-Object -ExpandProperty Level -Unique)) {
    $lr = @($rows | Where-Object Level -eq $lv | Sort-Object Room)
    for ($i = 1; $i -lt $lr.Count; $i++) {
        $a = $lr[$i - 1]; $b = $lr[$i]
	foreach ($k in 'Time', 'Max') {
            $va = $a.$k; $vb = $b.$k; $lbl = $k
            if ($k -eq 'Max') { $va -= $a.Reward; $vb -= $b.Reward; $lbl = 'Max excl. reward' }
            $g = ($vb - $va) / $va
            $msg = "L$lv R$($a.Room)->R$($b.Room) $lbl $(Pct $g) ($va -> $vb)"
            if ($g -ge $GrowMin -and $g -le $GrowMax) { Pass $msg } else { Warn $msg }
        }
    }
}

# ---------------------------------------------------------------- levels
Write-Host "`n== Level budgets (x1.3, tolerance +-15 %) + 70 % average vs milestones =="
$cum = 0
foreach ($lv in 1..5) {
    $cum += $Budget[$lv] * $AvgShare
    $got = @($Milestones | Where-Object { $_ -le $cum })
    $ms = if ($got.Count) { "M1-M$($got.Count)" } else { 'none' }
    $lr = @($rows | Where-Object Level -eq $lv)
    if ($lr.Count -eq 0) { Info "L$lv no rooms yet; budget $($Budget[$lv]), cumulative avg ~$([math]::Round($cum)) ($ms)"; continue }
    $sum = ($lr | Measure-Object Max -Sum).Sum
    if ($lr.Count -lt 3) { Info "L$lv $($lr.Count)/3 rooms, max so far $sum of budget $($Budget[$lv]); cumulative avg ~$([math]::Round($cum)) ($ms)"; continue }
    $drift = ($sum - $Budget[$lv]) / $Budget[$lv]
    $msg = "L$lv max $sum vs budget $($Budget[$lv]) ($(Pct $drift)); cumulative avg ~$([math]::Round($cum)) ($ms)"
    if ([math]::Abs($drift) -le $Tolerance) { Pass $msg } else { Fail "$msg -> change FRUIT, never milestones" }
}

# ---------------------------------------------------------------- core.md: kill values 1.6 vs enemy table 2.7
Write-Host "`n== core.md: kill values (1.6) vs enemy Score column (2.7) =="
$kill = @{}
$killLine = @($core | Where-Object { $_ -match 'Kill values:' })[0]
if ($killLine) {
    $text = (($killLine -split 'Kill values:\*\*')[1] -split '\.\s')[0]
    foreach ($m in [regex]::Matches($text, '([A-Z][A-Za-z ]*?)\s+(\d+)')) { $kill[$m.Groups[1].Value.Trim()] = [int]$m.Groups[2].Value }
} else { Warn 'core.md: "Kill values:" line not found' }

$hdr = -1
for ($i = 0; $i -lt $core.Count; $i++) { if ($core[$i] -match '^\|\s*Enemy\s*\|') { $hdr = $i; break } }
if ($hdr -lt 0) { Warn 'core.md: enemy table (| Enemy | ...) not found' }
else {
    $cols = @($core[$hdr].Split('|') | ForEach-Object { $_.Trim() })
    $sc = [array]::IndexOf($cols, 'Score')
    $seen = @{}
    for ($i = $hdr + 2; $i -lt $core.Count -and $core[$i].StartsWith('|'); $i++) {
        $c = @($core[$i].Split('|') | ForEach-Object { $_.Trim() })
        $name = $c[1] -replace '\s*\(.*\)\s*$', ''
        $digits = $c[$sc] -replace '[^\d]', ''
        if (-not $digits) { Warn "2.7 ${name}: no Score value"; continue }
        $score = [int]$digits
        $seen[$name] = $true
        if (-not $kill.ContainsKey($name)) { Warn "${name}: Score $score in 2.7 but missing from 1.6 kill values"; continue }
        if ($kill[$name] -eq $score) { Pass "${name}: $score" }
        else { Fail "${name}: 1.6 kill value $($kill[$name]) vs 2.7 table Score $score" }
    }
    foreach ($n in $kill.Keys) { if (-not $seen.ContainsKey($n)) { Warn "${n}: in 1.6 kill values but not in the 2.7 enemy table" } }
}

# ---------------------------------------------------------------- core.md: ladder 1.2 vs ledger
Write-Host "`n== core.md: calibration ladder (1.2) vs ledger =="
$ladder = @{}
$totals = @{}
foreach ($line in $core) {
    $m = [regex]::Match($line, '^\|\s*(?:L(\d)\s+)?R(\d)\s*\|\s*([\d.]+)\s*s\s*\|\s*([^|]+?)\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|')
    if ($m.Success) {
        $lv = if ($m.Groups[1].Success) { [int]$m.Groups[1].Value } else { 1 }
        $ladder["$lv-$($m.Groups[2].Value)"] = @{ Time = (Num $m.Groups[3].Value); Damage = $m.Groups[4].Value; Deaths = [int]$m.Groups[5].Value; Max = [int]$m.Groups[6].Value }
        continue
    }
    $t = [regex]::Match($line, '^\|\s*\*\*L(\d) total\*\*\s*\|[^|]*\|\s*([^|]+?)\s*\|\s*(\d+)\s*\|\s*\*\*(\d+)\*\*')
    if ($t.Success) { $totals[[int]$t.Groups[1].Value] = @{ Damage = $t.Groups[2].Value; Max = [int]$t.Groups[4].Value } }
}
foreach ($r in $rows) {
    $id = "L$($r.Level) R$($r.Room)"
    $key = "$($r.Level)-$($r.Room)"
    if (-not $ladder.ContainsKey($key)) { Warn "$id in ledger but not in the core.md 1.2 ladder"; continue }
    $c = $ladder[$key]
    if ([math]::Abs($c.Time - $r.Time) -le 0.5) { Pass "$id time $($r.Time) s (core $($c.Time) s)" } else { Fail "$id time: ledger $($r.Time) s vs core $($c.Time) s" }
    if (DamageMatches $c.Damage $r.Damage) { Pass "$id damage $($r.Damage) (core $($c.Damage))" } else { Fail "$id damage: ledger $($r.Damage) vs core $($c.Damage)" }
    if ($c.Deaths -eq $r.Deaths) { Pass "$id deaths $($r.Deaths)" } else { Fail "$id deaths: ledger $($r.Deaths) vs core $($c.Deaths)" }
    if ($c.Max -eq $r.Max) { Pass "$id max $($r.Max)" } else { Fail "$id max: ledger $($r.Max) vs core $($c.Max)" }
}
foreach ($lv in $totals.Keys) {
    $lr = @($rows | Where-Object Level -eq $lv)
    $sumMax = ($lr | Measure-Object Max -Sum).Sum
    $sumDmg = ($lr | Measure-Object Damage -Sum).Sum
    if ($totals[$lv].Max -eq $sumMax) { Pass "L$lv total max $sumMax" } else { Fail "L$lv total max: core $($totals[$lv].Max) vs ledger sum $sumMax" }
    if (DamageMatches $totals[$lv].Damage $sumDmg) { Pass "L$lv total damage $sumDmg" } else { Fail "L$lv total damage: core $($totals[$lv].Damage) vs ledger sum $sumDmg" }
}

Write-Host ''
Write-Host ("Result: {0} FAIL, {1} WARN" -f $script:Fails, $script:Warns)
exit $script:Fails