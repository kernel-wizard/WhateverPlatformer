# check_calibration.ps1 v2 (2026-10-07) - checks Docs\calibration_ledger.csv against core.md (1.2, 1.3, 1.6-1.8).
# Run:  powershell -ExecutionPolicy Bypass -File "C:\Users\ontro\Documents\Unreal Projects\WhateverPlatformer\Docs\check_calibration.ps1"
# Exit code = number of FAIL lines (0 = clean). Read-only: it never writes any file.
# Keep this file ASCII-only (Windows PowerShell 5.1 reads BOM-less files as ANSI).
# Milestones (1.7) and the 12-level plan (1.8) are PARSED from core.md, so core.md stays the single source.

$ErrorActionPreference = 'Stop'
$Inv    = [Globalization.CultureInfo]::InvariantCulture
$Ledger = Join-Path $PSScriptRoot 'calibration_ledger.csv'
$Core   = Join-Path (Split-Path $PSScriptRoot -Parent) 'core.md'

# core.md 1.3 / 1.6 / 1.7 [LOCKED]
$BudgetOverride = @{ 1 = 1030 }   # 1.6: L1 budget 1030 (the 1.8 table shows the actual 970)
$TimeNominal    = @{ '2-1' = 43.6; '2-2' = 51.4; '3-2' = 52.3 } # 1.3: L2 R1 + R2, L3 R2 time exceptions (user-approved 2026-10-07 / 2026-10-08 / 2026-10-25)
$ThreatGrowthExempt = @(1)          # 1.3: L1 calibrated before the threat definition -> threat growth = INFO
$Tolerance  = 0.15   # level max vs budget, time/density vs plan
$ScoreSplitFrom = 4                    # 1.6 room score split applies from this level
$ScoreSplit     = @(1, 1.25, 1.5625)   # R0 : R1 : R2 (max excl. reward)
$RewardPerLevel = 100                  # mini-boss reward excluded from the split
$GrowMin    = 0.20   # room-to-room growth
$GrowMax    = 0.30
$AvgShare   = 0.70   # average player share of max
$RoomCap    = 60     # s per room
$RoomDmgCap = 4
$LevelDmgCap = 12
$HpCap      = 14
$DensityCap = 6.0    # threats per 10 s

$script:Fails = 0
$script:Warns = 0
function Pass([string]$m) { Write-Host "PASS  $m" -ForegroundColor Green }
function Info([string]$m) { Write-Host "INFO  $m" -ForegroundColor Gray }
function Warn([string]$m) { $script:Warns++; Write-Host "WARN  $m" -ForegroundColor Yellow }
function Fail([string]$m) { $script:Fails++; Write-Host "FAIL  $m" -ForegroundColor Red }
function Num([string]$s)  { [double]::Parse($s.Trim(), $Inv) }
function Pct([double]$x)  { ($x * 100).ToString('+0;-0;0', $Inv) + '%' }
function R1([double]$x)   { [math]::Round($x, 1).ToString($Inv) }
function DamageMatches([string]$cell, [double]$v) {
    try {
        $rm = [regex]::Match($cell.Trim(), '^([\d.]+)\s*[\u2013-]\s*([\d.]+)$')
        if ($rm.Success) { return ($v -ge (Num $rm.Groups[1].Value) -and $v -le (Num $rm.Groups[2].Value)) }
        return ([math]::Abs((Num $cell) - $v) -lt 0.05)
    } catch { return $false }
}

$rows = @(Import-Csv $Ledger | ForEach-Object {
    [pscustomobject]@{
        Level   = [int]$_.Level
        Room    = [int]$_.Room
        Fruit   = (Num $_.Fruit)
        Kills   = (Num $_.Kills)
        Max     = (Num $_.Max)
        Reward  = if ($_.PSObject.Properties['Reward'] -and $_.Reward) { Num $_.Reward } else { 0 }
        Time    = (Num $_.Time_s)
        Damage  = (Num $_.Damage)
        Deaths  = (Num $_.Deaths)
        Threats = if ($_.PSObject.Properties['Threats'] -and $_.Threats) { Num $_.Threats } else { $null }
        Status  = $_.Status
        Note    = $_.Note
    }
})
$core = @(Get-Content $Core -Encoding UTF8)

# ---------------------------------------------------------------- parse core.md 1.7 + 1.8
$Milestones = @()
foreach ($line in $core) {
    $m = [regex]::Match($line, '^\|\s*M(\d+)\s*\|\s*(\d+)\s*\|')
    if ($m.Success) { $Milestones += [int]$m.Groups[2].Value }
}
$Plan = @{}
$planRx = '^\|\s*(\d+)\s*\|\s*([\d.]+)/([\d.]+)/([\d.]+)\s*\|\s*(\d+)\s*\|\s*(\d+)/(\d+)/(\d+)\s*\((\d+)\)\s*\|\s*([\d.]+)\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|\s*([^|]*?)\s*\|'
foreach ($line in $core) {
    $m = [regex]::Match($line, $planRx)
    if (-not $m.Success) { continue }
    $g = $m.Groups
    $Plan[[int]$g[1].Value] = @{
        T = @((Num $g[2].Value), (Num $g[3].Value), (Num $g[4].Value))
        HP = [int]$g[5].Value
        D = @([int]$g[6].Value, [int]$g[7].Value, [int]$g[8].Value)
        DL = [int]$g[9].Value
        Dens = (Num $g[10].Value)
        Max = [int]$g[11].Value
        Avg = [int]$g[12].Value
        Prize = @([regex]::Matches($g[13].Value, 'M(\d+)') | ForEach-Object { [int]$_.Groups[1].Value })
    }
}
Write-Host "`n== core.md parse =="
if ($Milestones.Count -eq 12) { Pass "1.7 milestones M1-M12 parsed" } else { Fail "1.7: parsed $($Milestones.Count) milestones, expected 12" }
if ($Plan.Count -eq 12) { Pass "1.8 plan rows L1-L12 parsed" } else { Fail "1.8: parsed $($Plan.Count) plan rows, expected 12" }
function Budget([int]$lv) { if ($BudgetOverride.ContainsKey($lv)) { $BudgetOverride[$lv] } else { $Plan[$lv].Max } }

# ---------------------------------------------------------------- core.md 1.8 self-consistency
Write-Host "`n== core.md 1.8 plan self-consistency =="
$cum = 0
for ($lv = 1; $lv -le 12; $lv++) {
    if (-not $Plan.ContainsKey($lv)) { continue }
    $p = $Plan[$lv]; $id = "Plan L$lv"
    $sumD = ($p.D | Measure-Object -Sum).Sum
    if ($sumD -eq $p.DL) { Pass "$id damage $($p.D -join '/') = level $($p.DL)" } else { Fail "$id damage rooms sum $sumD vs level $($p.DL)" }
    if (@($p.D | Where-Object { $_ -gt $RoomDmgCap }).Count) { Fail "$id room damage > $RoomDmgCap" }
    if ($lv -ge 3) {
        $want = [math]::Min($p.HP - 2, $LevelDmgCap)
        if ($p.DL -eq $want) { Pass "$id level damage $($p.DL) = min(HP $($p.HP) - 2, $LevelDmgCap)" } else { Fail "$id level damage $($p.DL) vs min(HP-2, $LevelDmgCap) = $want" }
    }
    if ($p.HP -gt $HpCap) { Fail "$id start HP $($p.HP) > cap $HpCap" }
    if (@($p.T | Where-Object { $_ -gt $RoomCap }).Count) { Fail "$id room time > $RoomCap s" }
    if ($p.Dens -gt $DensityCap) { Fail "$id density $($p.Dens) > cap $DensityCap" }
    $prev = $cum
    $cum += (Budget $lv) * $AvgShare
    if ([math]::Abs($cum - $p.Avg) / $p.Avg -le 0.01) { Pass "$id avg cum $($p.Avg) (computed $([math]::Round($cum)))" } else { Warn "$id avg cum $($p.Avg) vs computed $([math]::Round($cum))" }
    $crossed = @()
    for ($i = 0; $i -lt $Milestones.Count; $i++) { if ($Milestones[$i] -gt $prev -and $Milestones[$i] -le $cum) { $crossed += ($i + 1) } }
    if (($crossed -join ',') -eq ($p.Prize -join ',')) { Pass "$id prizes reached: $(if ($crossed.Count) { 'M' + ($crossed -join ', M') } else { 'none' })" }
    else { Warn "$id prize column M$($p.Prize -join ', M') vs computed M$($crossed -join ', M')" }
}

# ---------------------------------------------------------------- rooms
Write-Host "`n== Rooms (ledger vs 1.8 plan) =="
foreach ($r in $rows) {
    $id = "L$($r.Level) R$($r.Room)"
    $p = $Plan[$r.Level]
    $sum = $r.Fruit + $r.Kills
    if ($sum -eq $r.Max) { Pass "$id fruit $($r.Fruit) + kills $($r.Kills) = max $($r.Max)" }
    else { Fail "$id fruit $($r.Fruit) + kills $($r.Kills) = $sum, but ledger max is $($r.Max)" }

    $dmgBudget = if ($p) { $p.D[$r.Room] } else { $RoomDmgCap }
    if ($r.Damage -le $dmgBudget) { Pass "$id damage $($r.Damage) <= budget $dmgBudget" }
    else { Fail "$id damage $($r.Damage) > budget $dmgBudget" }

    $deathCap = if ($r.Level -le 2) { 1 } else { 2 }
    if ($r.Deaths -le $deathCap) { Pass "$id deaths $($r.Deaths) <= $deathCap" }
    else { Warn "$id deaths $($r.Deaths) > $deathCap" }

    if ($r.Time -le $RoomCap) { Pass "$id time $($r.Time) s <= cap $RoomCap s" } else { Fail "$id time $($r.Time) s > room cap $RoomCap s" }
    if ($p) {
        $tt = $p.T[$r.Room]; $d = ($r.Time - $tt) / $tt
        $msg = "$id time $($r.Time) s vs plan $tt s ($(Pct $d))"
        if ([math]::Abs($d) -le $Tolerance) { Pass $msg } else { Warn $msg }
    }

    if ($null -eq $r.Threats) { Info "$id threats not logged (density unchecked)" }
    else {
        $dens = $r.Threats / $r.Time * 10
        $msg = "$id density $(R1 $dens)/10 s ($($r.Threats) threats)"
        if ($dens -gt $DensityCap) { Fail "$msg > cap $DensityCap" }
        else { Info "$msg (checked per level)" }
    }

    if ($r.Status -ne 'calibrated') { Warn "$id status '$($r.Status)': $($r.Note)" }
}

# ---------------------------------------------------------------- growth
Write-Host "`n== Room-to-room growth (target +20..+30 %) =="
foreach ($lv in @($rows | Select-Object -ExpandProperty Level -Unique)) {
    $lr = @($rows | Where-Object Level -eq $lv | Sort-Object Room)
    for ($i = 1; $i -lt $lr.Count; $i++) {
        $a = $lr[$i - 1]; $b = $lr[$i]
        foreach ($k in 'Time', 'Max', 'Threats') {
            $va = $a.$k; $vb = $b.$k; $lbl = $k
            if ($k -eq 'Threats' -and ($null -eq $va -or $null -eq $vb)) { continue }
            if ($k -eq 'Max') { $va -= $a.Reward; $vb -= $b.Reward; $lbl = 'Max excl. reward' }
            $exB = $TimeNominal.ContainsKey("$lv-$($b.Room)")
            if ($k -eq 'Time' -and $TimeNominal.ContainsKey("$lv-$($a.Room)")) { $va = $TimeNominal["$lv-$($a.Room)"]; $lbl = 'Time (nominal prev)' }
            $g = ($vb - $va) / $va
            $msg = "L$lv R$($a.Room)->R$($b.Room) $lbl $(Pct $g) ($va -> $vb)"
            if ($k -eq 'Time' -and $exB) { Info "$msg = approved time exception (1.3)" }
            elseif ($k -eq 'Threats' -and $ThreatGrowthExempt -contains $lv) { Info "$msg = approved threat-growth exception (1.3)" }
            elseif ($g -ge $GrowMin -and $g -le $GrowMax) { Pass $msg } else { Warn $msg }
        }
    }
}

# ---------------------------------------------------------------- levels
Write-Host "`n== Level budgets (tolerance +-15 %), level damage, avg vs milestones =="
$cum = 0
for ($lv = 1; $lv -le 12; $lv++) {
    if (-not $Plan.ContainsKey($lv)) { continue }
    $b = Budget $lv
    $cum += $b * $AvgShare
    $got = @($Milestones | Where-Object { $_ -le $cum })
    $ms = if ($got.Count) { "M1-M$($got.Count)" } else { 'none' }
    $lr = @($rows | Where-Object Level -eq $lv)
    if ($lr.Count -eq 0) { Info "L$lv no rooms yet; budget $b, cumulative avg ~$([math]::Round($cum)) ($ms)"; continue }
    $sum = ($lr | Measure-Object Max -Sum).Sum
    $dmg = ($lr | Measure-Object Damage -Sum).Sum
    if ($dmg -le $Plan[$lv].DL) { Pass "L$lv damage so far $dmg <= level budget $($Plan[$lv].DL)" } else { Fail "L$lv damage $dmg > level budget $($Plan[$lv].DL)" }
    $tr = @($lr | Where-Object { $null -ne $_.Threats })
    if ($tr.Count -eq 0) { Info "L$lv density unchecked (no threats logged)" }
    else {
        $tSum = ($tr | Measure-Object Threats -Sum).Sum
        $sSum = ($tr | Measure-Object Time -Sum).Sum
        $ld = $tSum / $sSum * 10
        $dd = ($ld - $Plan[$lv].Dens) / $Plan[$lv].Dens
        $dmsg = "L$lv density $(R1 $ld)/10 s ($tSum threats / $(R1 $sSum) s, $($tr.Count) rooms) vs plan $($Plan[$lv].Dens) ($(Pct $dd))"
        if ($ld -gt $DensityCap) { Fail "$dmsg > cap $DensityCap" }
        elseif ([math]::Abs($dd) -le $Tolerance) { Pass $dmsg } else { Warn $dmsg }
    }
    if ($lr.Count -lt 3) { Info "L$lv $($lr.Count)/3 rooms, max so far $sum of budget $b; cumulative avg ~$([math]::Round($cum)) ($ms)"; continue }
    $drift = ($sum - $b) / $b
    $msg = "L$lv max $sum vs budget $b ($(Pct $drift)); cumulative avg ~$([math]::Round($cum)) ($ms)"
    if ([math]::Abs($drift) -le $Tolerance) { Pass $msg } else { Fail "$msg -> change FRUIT, never milestones" }
}

# ---------------------------------------------------------------- 1.6 room score split (L4+)
Write-Host "`n== Room score split (L$ScoreSplitFrom+, (budget - reward) x 1 : 1.25 : 1.5625, +-15 %) =="
$splitSum = ($ScoreSplit | Measure-Object -Sum).Sum
$splitRows = @($rows | Where-Object { $_.Level -ge $ScoreSplitFrom } | Sort-Object Level, Room)
if ($splitRows.Count -eq 0) { Info "no L$ScoreSplitFrom+ rooms in the ledger yet" }
foreach ($r in $splitRows) {
    $t = [math]::Round(((Budget $r.Level) - $RewardPerLevel) * $ScoreSplit[$r.Room] / $splitSum)
    $v = $r.Max - $r.Reward
    $d = ($v - $t) / $t
    $msg = "L$($r.Level) R$($r.Room) max excl. reward $v vs split target $t ($(Pct $d))"
    if ([math]::Abs($d) -le $Tolerance) { Pass $msg } else { Warn $msg }
}

# ---------------------------------------------------------------- 1.3 calibration start score (actual cumulative)
Write-Host "`n== Actual cumulative avg = calibration start score (ledger maxes x $AvgShare, budget for unfinished levels) =="
$cumAct = 0
for ($lv = 1; $lv -le 12; $lv++) {
    if (-not $Plan.ContainsKey($lv)) { continue }
    $lr = @($rows | Where-Object Level -eq $lv)
    $done = $lr.Count -ge 3
    $lvMax = if ($done) { ($lr | Measure-Object Max -Sum).Sum } else { Budget $lv }
    $start = $cumAct
    $cumAct += $lvMax * $AvgShare
    $crossed = @()
    for ($i = 0; $i -lt $Milestones.Count; $i++) { if ($Milestones[$i] -gt $start -and $Milestones[$i] -le $cumAct) { $crossed += ($i + 1) } }
    $src = if ($done) { 'actual' } else { 'budget' }
    $got = if ($crossed.Count) { 'M' + ($crossed -join ', M') } else { 'none' }
    $want = if ($Plan[$lv].Prize.Count) { 'M' + ($Plan[$lv].Prize -join ', M') } else { 'none' }
    $msg = "L$lv start score $([math]::Round($start)) -> end $([math]::Round($cumAct)) ($src max $lvMax); prizes $got"
    if ($got -eq $want) { Pass $msg } else { Warn "$msg vs plan $want" }
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
    $m = [regex]::Match($line, '^\|\s*(?:L(\d+)\s+)?R(\d)\s*\|\s*([\d.]+)\s*s\s*\|\s*([^|]+?)\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|')
    if ($m.Success) {
        $lv = if ($m.Groups[1].Success) { [int]$m.Groups[1].Value } else { 1 }
        $ladder["$lv-$($m.Groups[2].Value)"] = @{ Time = (Num $m.Groups[3].Value); Damage = $m.Groups[4].Value; Deaths = [int]$m.Groups[5].Value; Max = [int]$m.Groups[6].Value }
        continue
    }
    $t = [regex]::Match($line, '^\|\s*\*\*L(\d+) total\*\*\s*\|[^|]*\|\s*([^|]+?)\s*\|\s*(\d+)\s*\|\s*\*\*(\d+)\*\*')
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