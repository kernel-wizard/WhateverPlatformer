# WhateverPlatformer: CORE KNOWLEDGE / GUARD RAILS

> Source of truth for how this project is built, calibrated and safely edited.
> Compiled 2026-10-02 from the live project (DefaultEngine.ini, asset CDOs, placed actors in MAP_Level1) and every
> design/calibration decision the user approved so far. Coherence pass 2026-10-05 (Bat score, kill formula, milestone
> label, ladder notes, L2 live knobs, Black Bat row, HUD heart limit, level damage budgets).
> Scaling rework 2026-10-07: 12 levels ≈ 1 h, 60 s room cap, intensity growth between levels, score plateau after L5,
> milestones M7–M12, HP cap 14, damage cap (§1.3, §1.6–1.8). Threat definition + L1 density 2.5 added 2026-10-07.
> If memory is lost: READ THIS FILE FIRST. If a live value differs from this file, the live value wins. Report the
> difference to the user and update this file once the user confirms.
> Status tags: **[LOCKED]** never change without explicit user approval · **[LIVE]** the current value in the project ·
> **[PLAN]** agreed direction, not fully implemented · **[PROPOSAL]** suggested, not yet approved.
> SESSION RULE: in every new session on this project, Claude's FIRST reply starts with "Core settings loaded" and then does the task.

---

## 0. Project identity

| Item | Value |
|---|---|
| Engine | Unreal Engine **5.3** (`EngineAssociation 5.3`), Windows, DX12 SM6 |
| Genre | 2D side-scrolling action platformer (Mega-Man-like shooting + Pixel-Adventure art) |
| 2D stack | **Paper2D** (sprites, flipbooks, tilemaps) + **PaperZD** (player anim BP) |
| Plugins | PaperZD, ClaudeAssistant (MCP editor tools), RootMovement, ModelingToolsEditorMode |
| Game Mode | `/Game/Blueprints/GM_Action` (GlobalDefaultGameMode) |
| Game Instance | `/Game/Blueprints/GI_Platformer` (**must** stay in `DefaultEngine.ini` `[/Script/EngineSettings.GameMapsSettings] GameInstanceClass=` or the score resets in Shipping builds) |
| Maps | `/Game/Maps/MAP_Level1` (GameDefaultMap + EditorStartupMap), `/Game/Maps/MAP_Level2`, `/Game/Maps/MAP_Level3`, `/Game/Maps/MAP_Level4`, `/Game/Maps/MAP_Debug` (safe sandbox) |
| Old names | "MAP_2DStage" in older notes = **MAP_Level1**. "TM_Stage_2" in older notes = the tilemap now named **TM_Stage_1** (`/Game/PaperAssets/Environment/Level_1/TM_Stage_1`, 120x23), used by the actor `TM_Stage_1` in MAP_Level1 |
| Calibration ledger | `Docs/calibration_ledger.csv` (one row per room) + `Docs/check_calibration.ps1` (cross-checks the ledger against this file; exit code = FAIL count) |
| Game length | **12 levels ≈ 1 h** first play (§1.8) |

---

## 1. CALIBRATION FORMULAS, CORE IDEAS AND RULES

### 1.1 Reference point (difficulty 1.0) [LOCKED]
- **Baseline = Level 1, Room 0**, approved by the user 2026-09-30, rated "easy, passable".
- Measured average player: **clear time ~30 s, 1 damage (of 10 HP), 0 deaths**. Threat density ≈ 5 enemies / 30 s.
- Room-0 content: 3 Crabs (1 per corridor section), 1 Bat, 1 Lizard (optional side chamber only), 0 spikes/saws/falling platforms, 1 checkpoint halfway, fruit 160 pts, plus a secret.
- New skills taught in room 0: wall jump (spawn shaft, falling has no penalty), shooting (low corridors with enemies you cannot jump over).

### 1.2 Measured calibration ladder (Level 1, same tester) [LIVE]
| Room | Time | Damage | Deaths | Max score | New mechanic |
|---|---|---|---|---|---|
| R0 | 25 s | 0 | 0 | 230 | wall jump + shooting |
| R1 | 32 s | 1 | 0 | 285 | moving/falling platforms (FallDelay 0.5) |
| R2 | 40 s | 1 | 0 | 455 | saws + Eye + Lizard Warden mini-boss |
| **L1 total** | ~1.6 min | 2 | 0 | **970** | |
Compare rooms **relative to each other**. Absolute times depend on the tester's skill.
- **Calibrated 2026-10-05** with the PIE calibration monitor (`Saved/Logs/calib_runs.csv`, full clear, one run): time growth **+26 % / +26 %**, score growth excluding the Warden reward **+24 % / +25 %**. The §1.1 baseline (30 s, 1 dmg) is the original first-test value; this ladder is the same tester, now faster.
- R1 fixes for the time: Bat_TierC removed; pit pickups and Crab_Pit moved near the drop point; pocket Kiwi + Bananas replaced by 4 main-route Apples; +Cherries_ShaftBat (Option A).

**Level 2 ladder** (same tester, single shots = average L2 player: 11 HP, no Spread):
| Room | Time | Damage | Deaths | Max score | New mechanic |
|---|---|---|---|---|---|
| L2 R0 | 35 s | 0–1 | 0 | 310 | spikes (+ Crystal Bat chaser 3 HP, Crystal Crab walk 150) |
| L2 R1 | 37 s | 1 | 0 | 380 | crumble tiles (3 s stand); 13 threats; TIME EXCEPTION, see §1.3 |
| L2 R2 | 51 s | 0–1 | 0 | 570 | hammer break + floor-drop shortcut (+ Warden mini-boss); 16 threats; TIME EXCEPTION, see §1.3 |

**Level 3 ladder** (same tester, calibration runs with the average start-of-level loadout: 11 HP + Spread + fast charge, monitor start score 1660):
| Room | Time | Damage | Deaths | Max score | New mechanic |
|---|---|---|---|---|---|
| L3 R0 | 39 s | 0–1 | 0 | 380 | Trunk walking shooter (+ Mushroom walker); 15 threats, density 3.9; Grove pickups (Acorn 10 / Clover 20 / Berries 30 / Golden Acorn 50) |
| L3 R1 | 48 s | 1–2 | 0 | 470 | hammer ambush (caged exit warp + run back, ambush 0 pts); 19 threats, density 4.0 |
| L3 R2 | 52 s | 3 | 0 | 680 | Plant turret + combo (hammer floor-drop + caged exit + ambush) + Trunk Warden mini-boss (HP 12, HitStunCooldown 1.5); 24 threats, density 4.6; first room built from microsections (§1.5); TIME EXCEPTION, see §1.3 |

**Level 4 ladder** (same tester, calibration runs with the average start-of-level loadout: 12 HP + Spread + fast charge, monitor start score 2632):
| Room | Time | Damage | Deaths | Max score | New mechanic |
|---|---|---|---|---|---|
| L4 R0 | 45 s | 0–2 | 0 | 580 | Marsh Vent (timed gas launch, no damage) + Slime + Snail; 17 threats, density 3.8; no-prize runs 43.8 s, 2.0 dmg, 0 deaths |

### 1.3 Scaling formulas
- **Game length** (user-approved 2026-10-07): **12 levels ≈ 1 h** first play (real time ≈ tester clean time × 1.5–2.2). Per-level targets in §1.8. [LOCKED]
- **Each room ≈ +20–30 % over the previous room WITHIN a level** (time, threat count, score). Each level's R0 ≈ ×1.1 the previous level's R0 in TIME and THREAT COUNT (sawtooth); R0 SCORE follows the level budget instead (§1.6 room score split). **Room time cap 60 s.** [LOCKED 2026-10-07; score clarification 2026-10-25]
- **Between levels, growth = intensity**, not length: threat density (threats per 10 s, cap ~6), precision (narrower platforms, shorter safe windows), level knobs, mechanic combos. Growth rate shrinks: L1–5 +20–30 %/level, L6–9 +10–15 %, L10–12 +5–8 %. [LOCKED 2026-10-07]
- **Time exception L2 R1** (user-approved 2026-10-07, this room only): crumble tiles reward speed, so R1 is only +6 % over R0 (score +23 %, threats +30 %, damage OK). The next room's TIME target uses a nominal R1 = R0 × 1.25 ≈ 43.6 s → L2 R2 52–57 s. **Time exception L2 R2** (user-approved 2026-10-08, this room only): 51.4 s = +18 % over the nominal R1 (fell short because of practice on ~20 repeat runs; inside the 60 s cap, −7 % vs the §1.8 plan; damage/score/threats pass). No other exceptions besides L3 R2 (below); future rooms must meet +20–30 % time through layout (up to the 60 s cap).
- **Time exception L3 R2** (user-approved 2026-10-25, this room only): 52.3 s = +8.7 % over R1 48.1 s (4 runs with the final layout; three layout extensions — top-left cage backtrack, hammer ambush, far-left floor drop — raised it from 41.9 s; inside the 60 s cap; damage/score/threats pass; density at its limit, so no extra threats).
- **Threat-growth exception L1** (user-approved 2026-10-07): L1 was calibrated before the threat definition existed, so its room-to-room threat growth (5 → 9 → 10, +80 % / +11 %) is reported as INFO, not WARN. Level 1 only; from L2 on, threats must grow +20–30 % per room.
- Mini-boss / grand-secret rewards (Warden 100, Obsidian 100) are EXCLUDED from the room-growth comparison; they still count toward the level budget. (Option A, 2026-10-05)
- **New mechanics:** exactly 1 per room in L1–L3; from L4, 1 new per level (in R0), and R1/R2 introduce a new COMBINATION of known mechanics. At most 1 new idea per section. ~1 new enemy per level; a mini-boss at each level end, final boss in L12. [LOCKED 2026-10-07]
- L3: R0 Trunk, R1 hammer ambush (caged exit warp + run back), R2 Plant (+ combo + mini-boss) — user-approved 2026-10-17.
- L4: R0 Marsh Vent; Slime + Snail both new in R0; mini-boss = Chameleon Warden in R2 (`BP_Enemy_Chameleon`, tongue attack, not PIE-tested yet) = 3 new enemies in L4, Bluebird dropped (user-approved 2026-11-02 / 2026-11-04).
- Time targets: L1 R0 30 s → R1 35–45 s → R2 45–60 s. From L3: ~40 / 50 / 60 s, a level ≈ 2.5 min clean (~4.5–5.5 min real).
- Damage budget: room ≤ **4**. L1 1/2/3 (= 6), L2 2/3/4 (= 9); from L3 the level budget = **min(start HP − 2, 12)**; per-level split in §1.8. Deaths 0–1 per room in L1–L2, 1–2 per room from L3+. [LOCKED 2026-10-07]
- Checkpoints: 1 per room (more if >60 s), **2–3 tiles inside the room entrance**, never on the border. One before any spike strip or boss.
- Enemy HP: **keep base HP**. Scale by the **number of threats** and "tank" variants. Enemy damage **stays 1**. [LOCKED]
- Level knobs: **L2 [LIVE 2026-10-05]** Saw speed 200, FallDelay 0.35, Crab walk 150 (L1: 150 / 0.5 / 120). **L3+ [PLAN, caps LOCKED 2026-10-07]:** Saw 250 (L3) → 300 (L7) → 350 max (L11); FallDelay 0.25 (L3), min 0.2; shooter sight/interval/reaction →see "Shooter aggression curve" below; Crab walk ≤ 200. Mini-boss (scale 1.3–1.4) only at a level end; HP by the prize counter-stat rule (§1.7): L1–2 8, L3–4 12, then ×k for each DPS prize the level assumes (M5 ×k, M7 ×4/3, M9–M12 ×k); interval per the shooter aggression curve.
- **Shooter aggression curve** [LOCKED 2026-10-10, user-approved; L3+ only, L1/L2 unchanged]: per placed instance —
  Sight L3 800 · L4 900 · L5 1000 · L6 1050 · L7 1100 · L8 1150 · L9–10 1200 · L11 1250 · L12 1280 (cap = half room);
  ShootInterval 2.5 · 2.25 · 2.0 · 1.9 · 1.85 · 1.8 · 1.75 · 1.6 · 1.5 · 1.5 (min 1.5);
  ReactionDelay 0.3 (L3–5) · 0.25 (L6–8) · 0.2 (L9+); AggroDuration 5 (L3–5) · 6 (L6–9) · 8 (L10+).
  Mini-boss: interval = level − 0.5 (min 1.0), sight 2560. ≤1 shooter per sight line in L3–L4, ≤2 from L5.
  Replaces the older Lizard ShootInterval/SightRange plan.
- **Aggro when hit** [LOCKED 2026-10-10, L3+]: a hit enemy stays aggroed for AggroDuration (refreshed by each hit AND every tick it has line of sight to the player, so it calms down AggroDuration after losing sight; user-approved 2026-10-10) —
  shooters ignore the range limit (line of sight still required; horizontal-only shooters such as Trunk/Lizard/Plant keep their height limit, since their bullet can't reach other floors — user-approved 2026-10-11) and return fire after HitDuration + ReactionDelay;
  chasers start chasing; walkers face the player; fixed-direction shooters (Plant) only return fire when the player is in front of them (user-approved 2026-10-11).
- Log every playtest per room in `Docs/calibration_ledger.csv`: **clear time, damage taken, deaths, score collected / max, threats**; then run `Docs/check_calibration.ps1`.
- **I-frame fix** [LIVE 2026-10-25, user-verified]: during i-frames (`bIsInvincible`) ALL damage is ignored (enemy contact, projectiles, traps); only BP_FallDetector still kills. Ledger rows logged before 2026-10-25 may show slightly MORE damage (enemy hit + trap/bullet within 1.5 s used to cost 2 HP). Existing rows stay as they are; re-time a room only if the user asks.
- **Threat** = each placed enemy + saw + spike trap + falling platform + crumble section + marsh vent (user-approved 2026-11-03); **density** = threats / clear time × 10 s, checked against §1.8 (±15 %, cap 6). (user-approved 2026-10-07; L1 density re-measured on this definition = 2.5)
- **Spike strip = 1 threat** [LOCKED 2026-10-08, user-approved]: a continuous strip of adjacent spike actors counts as ONE threat (like 1 crumble section), not one per spike tile; this stops long strips from inflating the threat count. L2 R0/R1 recounted 2026-10-08: no change (each spike actor is a separate strip).
- **Two runs per room** [LOCKED 2026-10-14, user-approved]: (1) the **calibration run** (logged in the ledger) uses the average start-of-level loadout: the calibration monitor sets the start score to the ACTUAL average cumulative score after the previous level (ledger maxes × 0.7, §1.6; printed by `check_calibration.ps1`) via `GM_Action.AddScore`, so prizes come from the normal milestones; (2) one **no-prize run** (start score 0) proves "never require a prize"; not logged in the ledger.

### 1.4 Movement / geometry rules [LOCKED]
| Measure | Value |
|---|---|
| Single jump rise | 122–136 u (~2 tiles) |
| Best double jump | **254 u** (crosses a ~448 u gap) |
| Ground jump + 1 wall jump | ~333 u |
| Player capsule | 120 u tall (half 60), r 34 |
- Steps ≤ **112 u** single, ≤ **160 u** comfortable double. **Never ~220 u.** Any rise > 254 u needs a wall-jump shaft or a platform.
- A 3-tile corridor (192 u) caps the jump rise at ~72 u: shootable enemies only; spikes ≤1 tile wide.
- A 2-tile tunnel (128 u) = no jumping. A 1-tile corridor (64 u) is impassable.
- A ceiling hit mid-jump kills horizontal speed (~570 → 100–150 u/s).
- Repeated jumps on the same wall do not climb higher. Pressing toward a wall while rising starts a wall slide.
- **Big_Pipes_BRONZE tiles have THIN collision** (a 32 u bar): trace the real collision, don't trust the grid.

### 1.5 Encounter design rules [LOCKED]
- No **ranged** enemy where the player can't jump. A breather after each drop.
- Cherries (risk fruit) sit **inside** the danger zone.
- Keep the Eye > 500 u from other tiers' paths; size its `AggroRange` box per instance.
- Enemies outside the player's room are frozen (`BPC_RoomMember`) and reset home on room change. Kills never respawn.
- **Exception: hammer ambush** (user-approved 2026-10-17): placed enemies tagged Ambush_1 stay dormant (hidden, no collision/tick/damage) until the hammer is picked up, then appear via BP_Prop_AmbushTrigger (HammerTag / AmbushTag / AppearDelay 0.3). Ambush enemies: known types only, ScoreValue 0, count as threats.
- Shots to kill (Regular 1 / Partial 2 / Full 3): 3-HP enemies (Crab, Lizard, Pig, placed Eye, Black Bat, Crystal Bat, Trunk, Mushroom, Plant, Slime, Snail) = 3 regular / 2 partial / 1 full; Bat 5 HP = 5 regular or full + partial; Warden 8 HP (L1–2), 12 HP (L3–4).
- **Chaser HP rule** (user-approved 2026-10-05): enemies that CHASE the player (Eye-type: Eye, Black Bat, Crystal Bat) use the Eye base **3 HP**, whatever their art. A 5-HP chaser counts as a "tank" variant and is only for later rooms, never as a room's first chaser.
- **Microsections** [LOCKED 2026-10-25, user-approved; first built in L3 R2]: a room is made of short sections, each with ONE clear focus:
  - **A – Movement Mastery**: a traversal test (climb column, jump chain, falling platforms, moving saws); few or no enemies — the route itself is the challenge.
  - **B – Tactical Combat**: an enemy group with cover and readable sight lines — the challenge is order and positioning (which enemy first, when to cross cover).
  - **C – Risk vs Reward**: a fork — a safe route vs a harder optional route with better pickups (risk tier inside the danger zone); both routes lead on.
  L3 R2 order: B (bottom band, Plant/Trunk cover fight) → A (climb column) → C (top band: lower floor vs stone chain + saws) → mini-boss arena + backtrack.
  [LOCKED 2026-10-25, user-approved] From L4: every room uses ≥1 section of each type (A, B, C); "at most 1 new idea per section" (§1.3) still applies.


### 1.6 Scoring formulas [LOCKED, LIVE in CDOs]
**Fruit (Level 1 only; Level 2 uses crystals, Level 3+ uses level pickups, see below):**
| Fruit | Pts | Rule of use |
|---|---|---|
| Bananas | 5 | trails only: 3–5 in a line mark a jump arc or the way |
| Apple | 10 | path/guide: **1 per beat** on the main route |
| Orange | 20 | 1 per OPTIONAL movement feat |
| Kiwi | 25 | visible off-route side branch |
| Cherries | 30 | 1 per optional threat, inside its danger zone |
| Strawberry | 40 | skill + risk; not used in L1 (L2+ equivalent = Amber) |
| Melon | 50 | 1 per secret area |
| Pineapple | 100 | grand secret / mini-boss reward; not used in L1 (L2+ equivalent = Obsidian 100) |
- **Level 2 pickups = CRYSTALS** (user-approved 2026-10-05; `BP_Pickup_Crystal_*`, art `/Game/PaperAssets/Crystals`). The 8 fruit tiers fold into 5:
  | Crystal | Pts | Role |
  |---|---|---|
  | Ice | 5 | trails (Bananas) |
  | Clear (`FB_Crystals_Crystal1`) | 10 | 1 per beat on the main route (Apple) |
  | Emerald | 20 | optional move AND side branch (Orange + Kiwi) |
  | Amber | 30 | risk inside a danger zone (Cherries + Strawberry) |
  | Obsidian | 50 | secret (Melon); grand secret / mini-boss reward = Obsidian instance ScoreValue **100**, scale 1.5, MAX 1 per level (Pineapple) |
- Crystal placement: Clear/Emerald rest ON floors (floor top + 32), preferably near ledge-edge crystal tiles; Amber sits where the risk is (over spikes, a saw's path, a bat's zone); Ice only as short 2–3 arc trails where a jump is unclear; climb tops get one marker crystal. Prefer fewer, higher-value crystals with an even spread per corridor.
- **Level 3+ pickups = level-themed, same point tiers, no 5-pt trail tier** (user-approved 2026-10-11):
  | Tier | L3 Grove (`BP_Pickup_Grove_*`) | L4 Marsh (`BP_Pickup_Marsh_*`) |
  |---|---|---|
  | 10, main-route beat | Acorn | LotusBud |
  | 20, optional move / side branch | Clover | SwampPearl |
  | 30, risk | Berries | AmberDragonfly |
  | 50, secret (100 reward instance, scale 1.5, max 1 per level) | GoldenAcorn | SunkenCoin |
- **Room fruit formula:** apples = main-route beats; +1 Orange per optional move; +1 Cherries per optional threat; +1 Melon per secret; +1 Kiwi per side branch; Bananas only as trails.
- **Kill values:** Crab 10, Mushroom 10, Slime 10, Snail 20, Bat 20, Lizard 20, Crystal Lizard 20, Trunk 20, Plant 20, Eye 30, Black Bat 30, Crystal Bat 30, Warden 100 (instance override), Angry Pig 10 (not calibrated).
- **New enemy formula:** 10 × **fewest charged hits to kill** (Full 3 / Partial 2 dmg) + bonus: ranged **+10**, chaser **+20**, defensive **+10** (user-approved 2026-11-02), plain flier +0. Checks: Crab 1 hit = 10 · Bat full+partial = 20 · Lizard / Crystal Lizard / Trunk / Plant 1 + ranged = 20 · Eye / Black Bat / Crystal Bat 1 + chaser = 30 · Pig / Mushroom / Slime 1 = 10 · Snail 1 + defensive = 20. Mini-bosses use an instance override (Warden 100).
- No-damage room bonus: 50 in L1, +25 per level, cap 150 [PLAN].
- **Score survives death; a kill scores once** (`bScoreAwarded`).
- **Level budget:** L1 ≈ 1030 (actual 970, −6 %); ×1.3 per level to L5 → **L2 1340, L3 1740, L4 2260, L5 2940**; then **plateau +50/level → L6 3000 … L12 3300** (locked point values + fixed room size cap a room at ~1000–1100; verify in L3/L4). [LOCKED 2026-10-07]
- **Room score split** [LOCKED 2026-10-25, user-approved; L4+]: room max excl. reward = (level budget − 100 reward) × 1 : 1.25 : 1.5625 (≈ 26 / 33 / 41 %). L4 567 / 708 / 885 (+100), L5 745 / 931 / 1164 (+100). ±15 % per room. The extra score comes from pickup tiers + kill density (pts/s), never from longer rooms.
- Average player ≈ **70 %** of max. Cumulative average: L1 ~720, L2 ~1660, L3 ~2880, L4 ~4460, L5 ~6520, L6 ~8620, L7 ~10755, L8 ~12925, L9 ~15130, L10 ~17370, L11 ~19645, L12 ~21955. These are PLANNED values; the calibration start score uses ACTUAL ledger maxes (after L1 679 → L2 1561 → L3 2632). L3 −12 % vs budget is inside tolerance: no compensation in later levels (2026-10-25).
- **Tolerance:** drift > **±15 %** → change FRUIT, never the milestones.

### 1.7 Milestones / prizes (fixed anchors) [LOCKED]
| # | Score | Prize | Status |
|---|---|---|---|
| M1 | 300 | +1 max HP + full heal | LIVE (`GM_Action.Prize1Score`) |
| M2 | 800 | Spread Shot (regular shots only) | LIVE |
| M3 | 1500 | Full charge 1.8 → 1.2 s | LIVE |
| M4 | 2500 | +1 max HP (→ 12) | LIVE (`GM_Action.Prize4Score`; GrantPrize + ShowPrize map index 3 → 0, so it reuses the +1 HP prize and banner; user-verified 2026-11-04) |
| M5 | 3800 | new weapon (e.g. Pierce Shot) | PLAN |
| M6 | 5500 | +1 max HP (→ 13) | PLAN |
| M7 | 7500 | Full charge 1.2 → 0.9 s | PLAN |
| M8 | 9700 | +1 max HP (→ 14 = HP CAP) | PLAN |
| M9 | 12000 | new ability (non-movement, TBD) | PLAN |
| M10 | 14300 | new ability (non-movement, TBD) | PLAN |
| M11 | 16600 | new ability (non-movement, TBD) | PLAN |
| M12 | 18900 | new ability (non-movement, TBD) | PLAN |
- Gaps: 300 → +500 → +700 → +1000 → +1300 → +1700 → +2000 → +2200 → +2300 (flat after the score plateau). ~1 milestone per level. **Max HP cap 14.** No movement prizes (every layout must work without them). [LOCKED 2026-10-07]
- Design each level for the prizes the **AVERAGE** player owns at its START (L1 none; L2 11 HP; L3 11 HP + Spread + fast charge; L4 12 HP …; start HP per level in §1.8). **Never require a prize.**
- Prize power budget: single-target DPS gain ≤ **×1.5**, close-range ≤ **×2**. A ×k player stat → ×k counter-stat in the level that ASSUMES the prize. +1 HP → +1 level damage budget next level (up to the §1.3 cap); Spread → more flying/angled threats from L2; fast charge → boss HP ×1.5 from L3 (Warden 8 → 12).
- Spread [LIVE]: Regular only, side shots ×0.5 dmg, no Owner (no refund), cooldown 0.5 s, angle 15°, grounded 0/+15/+30°, airborne −15/0/+15°.
- After a respawn the pawn is NEW → `GM_Action.ReapplyPrizes` must keep working. Score + NextMilestone carry across maps via `GI_Platformer`.

### 1.8 12-level game plan [LOCKED 2026-10-07]
Clean tester times; scores = MAX budgets; "Prize reached" = the milestone the average player reaches during that level.
| L | Time R0/R1/R2 | Start HP | Dmg R0/R1/R2 (level) | Threats/10 s | Max score | Avg cum | Prize reached |
|---|---|---|---|---|---|---|---|
| 1 | 25/32/40 | 10 | 1/2/3 (6) | 2.5 | 970 | 720 | M1 |
| 2 | 35/37/55 | 11 | 2/3/4 (9) | 3.3 | 1340 | 1660 | M2, M3 |
| 3 | 40/50/60 | 11 | 2/3/4 (9) | 3.8 | 1740 | 2880 | M4 |
| 4 | 40/50/60 | 12 | 3/3/4 (10) | 4.2 | 2260 | 4460 | M5 |
| 5 | 40/50/60 | 12 | 3/3/4 (10) | 4.6 | 2940 | 6520 | M6 |
| 6 | 40/50/60 | 13 | 3/4/4 (11) | 4.9 | 3000 | 8620 | M7 |
| 7 | 40/50/60 | 13 | 3/4/4 (11) | 5.2 | 3050 | 10755 | M8 |
| 8 | 40/50/60 | 14 | 4/4/4 (12) | 5.4 | 3100 | 12925 | M9 |
| 9 | 40/50/60 | 14 | 4/4/4 (12) | 5.6 | 3150 | 15130 | M10 |
| 10 | 40/50/60 | 14 | 4/4/4 (12) | 5.8 | 3200 | 17370 | M11 |
| 11 | 40/50/60 | 14 | 4/4/4 (12) | 5.9 | 3250 | 19645 | M12 |
| 12 | 40/50/60 | 14 | 4/4/4 (12) | 6.0 | 3300 | 21955 | final boss |
- L2 R1 time = the approved exception (nominal 43.6 s). Times from L3 are targets at the 60 s cap.
- Expected real play time: L1 ~2.5 min, L2 ~3.4, L3–5 ~5 each, L6+ ~5–6 each → ≈ 55–60 min total.
- Tiles: every level reuses part of `TS_L1_Terrain` + its own level-specific tiles (no shared "worlds").
- Content need (estimate): ~18 mechanics, ~1 new enemy per level, a mini-boss per level, a final boss.

---

## 2. CORE PROJECT SETTINGS

### 2.1 Units, pixels, tiles [LOCKED]
| Setting | Value |
|---|---|
| PPU | **0.25** (`DefaultEditor.ini`) → **1 texel = 4 UU** |
| Tile | **16×16 px = 64×64 UU** |
| Sprite default | PPU 0.25, `MaskedUnlitSpriteMaterial` (FX: `TranslucentUnlitSpriteMaterial`) |
| Character material | `/Game/Materials/M_CustomUnlitSpriteMaterial` (Masked, Unlit, TwoSided; hit-flash MID) |
| Flipbook FPS | new character/enemy art **15 fps**; crab 7 fps |
| Pixel-art textures | **Nearest**, NoMipmaps, Pixels2D/UI, **Clamp** for full-height frame sheets |
| Tile sheets | **padded** ("Condition Tile Sheet Texture", spacing 4) |

### 2.2 Level / tilemap geometry [LOCKED]
| Setting | Value |
|---|---|
| Tilemap per level | **120 × 23 tiles** = 7680 × 1472 UU, SeparationPerLayer 4, CollisionThickness 50, 3D physics |
| Tilemap actor | at **origin (0,0,0)** |
| Tile → world | tile (x,y) centre = **(64·x, 0, −64·y)**; X −32..7648, top Z +32 |
| Layers | 0 `Gameplay` (collides) · 1 `Decoration` · 2 `Background` |
| Rooms | **3 × 40 tiles = 2560 UU**; room = **floor((X + 32) / 2560)**; R0 x0–39, R1 x40–79, R2 x80–119 |
| Room centre | X = **1248 + 2560·room**, Z = **−704** |
| L1 tilemap | `/Game/PaperAssets/Environment/Level_1/TM_Stage_1` |
| L2 tilemap | `/Game/PaperAssets/Environment/Level_2/TM_Level2` |
| L3 tilemap | `/Game/PaperAssets/Environment/Level_3/TM_Level3` |
| L4 tilemap | `/Game/PaperAssets/Environment/Level_4/TM_Level4` |
| Tilesets | each level = part of `TS_L1_Terrain` + its own level tiles |
| Backdrop | sRGB **#8F7C99**, cube `S{L}_Backdrop` at Y −300 (linear 0.2833/0.2087/0.3327) |

### 2.3 Camera and resolution [LOCKED]
| Setting | Value |
|---|---|
| Camera | BP_Player SpringArm 500, yaw −90, no lag; **Orthographic, OrthoWidth 2560**, **16:9 constrained** → **2560 × 1440 UU = one room** |
| Direction | at **+Y looking −Y** (larger Y = in front) |
| Mode | fixed per room; `FixedCameraLocation (1248,0,−704)` + room·2560; slide 0.75 s EaseInOut exp 3; `CameraPixelSnap 4`; the player freezes during the slide |
| Resolutions | 2560×1440: 1 texel = 4 px; **1920×1080: 1 texel = 3 px** |
| Rendering | AA **0**, MotionBlur/AutoExposure/AO off, Lumen/GI off, VSM off, ScreenPercentage 100, DynRes off |
| Lighting | **everything Unlit**; fake light = additive unlit planes |

### 2.4 Depth (Y) bands [LOCKED]
| Y | Content |
|---|---|
| +3 | Foreground FX (e.g. the player's ZzzBubble; MASKED material so translucent parallax can't cover it); added 2026-10-03 |
| +2.5 | Player sprite (`BP_Player` Sprite0; in front of enemies, pickups, saws; behind ZzzBubble +3). WORLD Y: the Tick sets relative Y = `PlayerSpriteDepthY` × forward X, so it stays +2.5 when the actor turns 180° (facing left). Toggle `bPlayerSpriteInFront` (off = old baseline rel 0.05). User-approved 2026-10-19 (Prompt 01 option D) |
| +1.1 | Saw sprites (`BP_Trap_Saw` Sprite/SpriteOff rel Y 1.1, in front of pickups to stop z-fighting); user-approved 2026-10-08 |
| +1 | Pickups, other trap sprites, WaterDrip |
| +0.04 … +0.98 | Enemies: `BP_Enemy_BASE` BeginPlay adds a random actor Y offset = RandomInt(2..49) × 0.02 (anti z-fighting, 48 steps). Always BEHIND pickups/other traps (+1), saws (+1.1) and the player (+2.5); in front of tile decoration (+0.03) and shimmer (+0.02). Synced to the live graph 2026-10-28 (Min 1 → 2 to avoid a +0.02 tie with shimmer; was documented as +0.04 … +2.0) |
| +0.03 | Decoration flipbooks on tiles (e.g. `S2_R0_VFX_CrystalPulse_01`); in front of shimmer overlays |
| +0.02 | Tile shimmer overlays (`BP_VFX_TileShimmer`) |
| 0 … −8 | Tilemap layers |
| −20 | Background particles |
| −150 | Parallax Middle |
| −200 | Parallax Background |
| −300 | Backdrop |
Gameplay actors at **world Y = 0**; movement plane-constrained (normal Y, `SnapToPlaneAtStart=false`).
- **Translucent sort rule** (user-confirmed 2026-10-03): translucent objects sort by distance from the camera to their bounds centre, and the parallax planes' centre is the room centre. So any TRANSLUCENT FX in front of the parallax (e.g. BgParticles, `TranslucencySortPriority 1`) needs **sort priority > 0** (parallax/backdrop stay 0) or a **Masked** material; otherwise it vanishes behind the parallax when it's >~400 u off the room centre. Set it on placed instances too (Python template edits don't propagate). Small background FX must also avoid spots behind front sprites (pickups, drips, traps at Y +1).

### 2.5 Collision [LOCKED]
- Custom channel **`Projectile` = ECC_GameTraceChannel1, default Block** (never change).
- Profile `Projectile`: overlaps Pawn + Projectile; ignores Visibility/Camera/PhysicsBody/Vehicle/Destructible.
- OverlapAll / OverlapAllDynamic edited: **Projectile = Ignore**. New overlap-style actors must ignore Projectile.
- Character capsules: Pawn, **Pawn = Overlap**, WorldStatic/Dynamic = Block, Visibility = Ignore.
- Enemy Wall/Ledge detectors: WorldDynamic QueryOnly 12×32×32 at local X +45 (ledge Z −40), ignore Pawn; wall overlaps from any BP_Enemy_BASE are ignored (Crab, Pig).

### 2.6 Player (BP_Player) [LIVE]
| Stat | Value |
|---|---|
| Capsule | half 60, r 34 |
| Walk / Accel / Brake | 600 / 2048 / 2048, friction 8 |
| JumpZ / Gravity | 600 / **5.5** (all characters 5.5) |
| Jumps | JumpMaxCount **2**, hold 0.172 |
| Air | AirControl 1.0, FallingLateralFriction 50 |
| Wall slide | speed −20, traces 40/55 (BoxTrace 1,1,24), flush snap |
| Health | MaxHealth **10**; HUD has **14** heart slots (HP cap 14; Image_9 keeps the 12 px bonus gap, Image_10–12 left pad 4) |
| Shooting | ShootEnergy 3, PartialCharge 0.8 s, FullCharge **1.8 s** |
| I-frames | `InvicibilityDuration` 1.5 s, flicker 0.12 s; `bIsInvincible` gates BP_Player AnyDamage (FallDetector exempt); at i-frame end Spikes/Saw still overlapping re-trigger (`OnPlayerTriggered`) (2026-10-25); restore order = Set `bIsInvincible` false → capsule Pawn → Overlap → trap loop, so an enemy/spike still overlapping hits again right away (fix D, user-verified 2026-10-25; never set the flag after the collision restore) |
| Damage debug | `bDamageDebug` (Debug, default **off**, dev only): Tick draws the player capsule GREEN = hittable / RED = i-frames; AnyDamage prints "DMG x by <causer> \| invincible (blocked)=…" (screen + log). Other hitboxes: PIE console `show Collision`. Keep OFF in calibration runs. Never replace with Python draws (§4 quirk) (2026-10-25) |
| Respawn | 2.0 s, NEW pawn |

### 2.7 Enemies, projectiles, traps [LIVE]
**Enemy templates have MaxHealth 10 — real HP is set PER PLACED INSTANCE.**
| Enemy | Capsule | Move | HP | Score | Notes |
|---|---|---|---|---|---|
| Trunk (L3) | 54/40 | walk 120 | 3 | 20 | walking shooter (Crab duplicate, AIC_Base); per-instance sight/interval per §1.3 curve; shoots only within height |dz| ≤ 96 (also when aggroed); idles `EdgeIdleTime` 1.0 s (per instance) at ledges + walls, then turns (not if it already turned to face the player); Hit anim; aggro when hit; bullet → BP_VFX_TrunkBulletPieces |
| Mushroom (L3) | 40/40 | walk 120 | 3 | 10 | plain walker (Trunk duplicate, shooting removed); idles `EdgeIdleTime` 1.0 s (per instance) at ledges + walls, then turns (not if a hit already turned it); Hit anim; aggro when hit = turns once to face the player (no AggroDuration, 2026-10-11); art faces left → sprite X −1; L3 walker (R0 low corridors/tunnel) |
| Plant (L3) | 64/40 | stationary turret | 3 | 20 | Trunk duplicate without walking/ledge/wall detectors; FIXED direction = instance yaw (0 right, 180 left), shoots only at a player in front (forward dot > 0) within |dz| ≤ 96; per-instance sight/interval per §1.3 curve; FireDelay 0.27 (Attack frame 4), AttackRecover 0.27; Hit anim; aggro when hit (range only); bullet → BP_VFX_PlantBulletPieces; art faces left → sprite X −1 |
| Slime (L4) | 48/48 | walk 120 | 3 | 10 | L4 new enemy (user-approved 2026-11-02); plain walker (Mushroom duplicate): `EdgeIdleTime` 1.0 s at ledges + walls, turns once to face the player when hit; Idle/Run share one 10-frame sheet (Idle 10 fps, Run 15 fps); Sprite0 rel Z 10, LedgeDetector (45,0,−43); cosmetic trail: every `TrailInterval` 0.3 s while moving spawns BP_VFX_SlimeTrail at WORLD Y 0.03 (decoration band, absolute because the base randomizes enemy Y), floor Z = actor −40, life 1.5 s; art faces left → sprite X −1 |
| Snail (L4) | 44/44 | walk 90 | 3 | 20 | L4 shell guard (Mushroom duplicate, user-approved 2026-11-02): a surviving hit → Hit anim → shell `ShellDuration` 2 s (bCanBeDamaged false, blocked shots flash ShellWallHit); a Full charge pierces the shell (`PierceDamage` 3) and also kills it outright before any shell; art faces left → sprite X −1 |
| Crab | 45/45 | walk 120 | 3 | 10 | AIC_Crab, ledge/wall turn |
| Angry Pig | 45/45 | MaxWalk 260 run; calm ×0.46 ≈ 120 | 3 | 10 | idles 1 s at edges; Hit1 → run; killing hit → Hit2 → hop 1000 → falls off the map; DeathDelay 1.3, no poof; sprite scale X −1 |
| Bat | 60/34 | bob, MovePlayRate 0.8 | 5 | 20 | |
| Eye | 43/34 | fly 400 | 3 | 30 | world-fixed aggro box + leash |
| Black Bat | (as Crystal Bat) | Eye chase, fly 400 | 3 | 30 | child of Eye; death: Ceiling_Out last frame + fall; untested, not placed |
| Crystal Bat (L2) | 60/43 | Eye chase, fly 400 | **3** | 30 | child of BlackBat → Eye; AggroRange sized per corridor; CDO Score set 20 → 30 on 2026-10-05 (placed instances were already 30) |
| Lizard | 45/34 | shooter | 3 | 20 | interval 3, sight 600, reaction 0.3, LOS, turns to face |
| Crystal Lizard (L2) | 45/34 | shooter | 3 | 20 | child of BP_Enemy_Lizard (recolour); own ABP + CrystalIdle/CrystalShoot, ShootFireball overridden (DefaultSlot); L2 R2 Lizard_01 + Warden use it; projectile art still orange |
| Warden | Lizard ×1.3 | | 8 (L3–4: 12) | 100 | interval 2.0, range 1100; L2 Warden = Crystal Lizard instance; L3 Warden = Trunk instance, HitStunCooldown 1.5 |
- Projectile damage: Regular 1 · Partial 2 · Full 3 · Lizard 1. No projectile lifespan; "aggro when hit" is L3+ only (§1.3), L1/L2 enemies have none.
- Traps (BP_Trap_BASE → `OnPlayerTriggered`): Saw dmg 1, speed 150, dist 300; FallingPlatform FallDelay 0.5, FallSpeed 800, RespawnDelay 3, one-way; **Spikes** (`BP_Trap_Spikes`, L2+) dmg 1, 1 tile, box 26/16/14 at z −18, ApplyDamage + Self causer; FallDetector = instant death; WinDetector `Level Name` → next map; **Marsh Vent** (`BP_Trap_MarshVent`, L4+, 1 threat, no damage): actor origin on the floor, cycle Idle 1.6 / Warn 0.7 / Erupt 0.7 s, `StartOffset` per instance, launches the player once per eruption (`LaunchSpeed` 1900; rise = speed² / 10780).
- **WinDetector level-end flag** [LIVE 2026-10-09]: `BP_WinDetector` has a `Flag` flipbook component (visible in the editor for placement, hidden at BeginPlay). Reveal = player's `CurrentRoomIndex` == the WinDetector's room AND camera slide done (`RoomTransitionAlpha >= 1`) → `RevealDelay` (0.5 s, per instance) → `FB_Level_Finished_Flag_Out` once (1.73 s) → `FB_Level_Finished_Flag_Idle` looping. Shown once per level (`bFlagShown`). Art in `/Game/PaperAssets/Props/LevelFinished`. Never set the flipbook/visibility on placed instances; move only the Flag component.
- **Level 2 live tweaks** (2026-10-05): Saw speed **200**, FallDelay **0.35**, Crystal Crab walk 150.
- BP_Enemy_BASE opt-in knobs: `DeathDelay` 0, `bSpawnDestroyVFX` true, `TurnCooldown` 0.15 (+`bPendingTurn`), `ScoreValue`, `bScoreAwarded`.
- AIC_Lizard values (1 / 1000 / 0.7) are unused; the actor values are live.

### 2.8 Parallax standard [LOCKED]
- `M_ParallaxLayer` Translucent (eroded alpha × room clip); textures Bilinear, NoMips, Pixels2D, Clamp, sRGB; `BP_ParallaxLayer` TickGroup PostUpdateWork.
- Per room at X 1248 + 2560·room, Z −704:
  - Background: Y −200, scale 1.03, Factor 0.003, InterpSpeed **1.5** (on the instance), Erode 0, RoomHalfWidth 1280
  - Middle: Y −150, scale 1.06, Factor 0.015, InterpSpeed 1.5, Erode 2, RoomHalfWidth 1280
- Image only via `LayerTexture`. **No foreground layer.**

### 2.9 Input [LIVE]
`IMC_Action`: `IA_Move` (A/D), `IA_Jump`, `IA_Shoot` (J, hold = charge), `IA_Pause`.

### 2.10 Naming and folders [LOCKED]
- `BP_<Category>_BASE` / `BP_<Category>_<Name>` / `AIC_<Name>`.
- Labels `S{level}_R{room}_{Type}_{Name|NN}`; particles/drips numbered by X then top-down; `S#_R#_Parallax_Background|Middle`. Exceptions: `S#_Backdrop`, the tilemap actor, PlayerStart, `_Global`.
- Outliner: `Level N/{Terrain(+FallDetectors), Gameplay, Enemies, Traps(+Spikes), Pickups, Parallax, VFX/{WaterDrips,BgParticles}}`; map-wide actors in `_Global`.
- Content: `/Game/Blueprints/{AI,Characters,Components,Enums,Environment,Pickups,Projectiles,Props,Traps,VFX}`, `/Game/PaperAssets/{Characters,Environment/Level_N,Fruits,Fx,Props,Traps,UI}`, `/Game/{Materials,Widgets,Audio,Input,Maps}`; project docs in `/Docs` (outside Content).

---

## 3. FUNDAMENTALS

1. **Inheritance = source of truth:** `BP_ActionChar_BASE` → `BP_Enemy_BASE` → enemies; `BP_Trap_BASE`; `BP_Pickup_BASE`; `BP_Projectile_BASE`. New content = a child, usually duplicated from the closest sibling.
2. **Base changes are opt-in**, with defaults that keep the old behaviour.
3. **Health only in `BPC_Vitality`; damage only via ApplyDamage WITH a DamageCauser.**
4. **`BPC_RoomMember`** on enemies/traps: frozen outside the room, reset home on exit. Position-based room camera.
5. **The user paints tiles**; Claude places/tunes actors and bot-tests on request.
6. **Calibration loop:** tiles + collision → beat plan → place → max score → user playtest → log in `Docs/calibration_ledger.csv` → run `Docs/check_calibration.ps1` → compare (+20–30 % within the level, §1.8 targets) → adjust fruit/threats.
7. **One map per level**; GI carries score/prizes; WinDetector → next map; the user switches maps.
8. **Visual hygiene:** a unique Y per plane; left-facing art → sprite scale X −1; avoid sub-texel slow motion; Clamp sheets.
9. **Instance overrides are fragile:** CDO changes don't reach placed instances; moving a BP actor resets component edits (location first); use exposed vars instead of mesh material overrides.
10. **Verify every mutation**; keep checkpoint notes for multi-step work.

---

## 4. CLAUDE RULES — avoiding editor crashes

Cause: the plugin runs tool calls mid-world-tick.

**Bans:** no `level_load` or level open/add/remove from Python · no compiling BPs that have placed instances (the user compiles, parent first) · no Interchange import (the user drags files in) · no closing editors / deleting assets with open editors in plain run_python · no Python reparent · no `.ini` edits (the user uses Project Settings) · map renames by the user.

**Must:** every run_python mutation inside a one-shot `register_slate_post_tick_callback` (work on tick ≥2, unregister, `unreal.log` + Grep `Saved/Logs/WhateverPlatformer.log`) · deferred compile only for NEW BPs without instances · save before risky steps · one logical change per call · graph tools are safe · **crash protocol:** read `Saved/Crashes` + `Saved/Logs`, record the cause, never repeat the failed method.

**Quirks:** focus switch = deferred `close_all_editors_for_asset` (tick 1) + `open_editor_for_assets` (tick 3); if the plugin context stays stuck (graph tools: "No Blueprint is currently focused"), the user closes the BP tab and re-opens it from the Content Browser (2026-10-11) · object-pin defaults read "" but work (check `asset_get_dependencies`) · generic var keys resolve to the last search (verify; ambiguous titles can pick the wrong node) · impossible via tools: parent-call nodes, timeline tracks, PaperZD state machines, object/enum vars, custom-event params, `GetComponentByClass` class pin · Python can't read `EdGraph.Nodes`/`Blueprint.Status` · Python collision changes need `body_instance` + profile · attaching to BP components isn't saved · `del` Python globals + `gc.collect()` before deleting assets · session-rendered materials can't be deleted until a restart · tilemap edit pipeline: make editable → set_tile → layers into the asset → set_tile_map → empty the instance + rename into `/Engine/Transient` → save · PIE bot via `EnhancedInputLocalPlayerSubsystem` injection, only when asked; label bot-caused errors · Claude can't write project files from the editor session (Write is denied): Claude gives full path + content and the user saves it · deleting/replacing a placed enemy in the editor spawns a BP_VFX_EnemyDestroyed poof that stays in the map → after any enemy swap/delete, list_actors "EnemyDestroyed" and delete the leftovers · editing a BP component template via Python (SubobjectDataSubsystem) does NOT update already-placed instances (even after compile) → also set the instances, then verify world values · on placed BP actors, `set_editor_property` on a component reruns the construction script and swaps components mid-loop → use component functions (`set_relative_location`, `set_flipbook`, `set_visibility`) instead. · on Crab-derived enemies (Crab, Trunk, Mushroom) the PaperZD comp owns the sprite playback, so flipbooks only animate through the Tick's manual `SetPlaybackPosition` sync → to stop movement (pauses, idles), gate `WalkForward`, never the Tick/playback sync · PaperSpriteFactory properties are not exposed to Python → make sprite frames by duplicating an existing sprite and setting `source_texture` / `source_dimension` / `source_uv` and ALSO set source_texture_dimension to the real texture size, or UE rescales the frames on the next editor load · `set_variable_config` category changes report success but don't apply (cosmetic; rename by hand). · **PIE debug/monitor crash** (2026-10-25, BitArray.h:1418 assert on stop_pie): a PERSISTENT Python post-tick callback that calls `draw_debug_*` on the PIE world / binds Python callables to actor delegates (`on_take_any_damage`) / drives a bot that keeps throwing errors every frame → races the render thread during PIE teardown → editor dies. Bypass: never `draw_debug_*` or delegate binds from Python; debug visuals = a dev-only Blueprint flag (draws run inside the world tick); Python PIE monitors only read + log (like the calibration monitor), stop themselves on the first exception, and are UNREGISTERED before `stop_pie` (or let the user stop PIE). · Python edits of a child BP's INHERITED component hit the PARENT template (path `BP_Parent_C:Comp_GEN_VARIABLE`); check `get_path_name()` contains the child, inherited overrides = the user's hand step (2026-11-02) · a new BP component's bound overlap event isn't offered by search_node_actions before compile; poll `IsOverlappingActor` from Tick instead (2026-11-03) · exception to "Claude can't write project files": `SourceArt/_tools/sourceart_write.py` writes inside `SourceArt` only (user-approved 2026-10-28)

---

## 5. STRICT NEVER-CHANGE RULES

1. PPU 0.25, 16 px = 64 UU, plane Y 0, gravity 5.5.
2. 120×23 tilemap at the origin, 3 × 2560 rooms, RoomOriginX −32, FixedCameraLocation (1248,0,−704), ortho 2560 16:9 at +Y.
3. Depth bands (§2.4).
4. Projectile channel default Block; OverlapAll(-Dynamic) ignore Projectile; capsules overlap Pawn.
5. BASE inheritance, BPC_Vitality, ApplyDamage + causer, opt-in base changes, one map per level + GI in DefaultEngine.ini.
6. R0 = difficulty 1.0; +20–30 % per room within a level, 60 s room cap, intensity growth between levels; mechanics rule (§1.3); enemy damage 1; never require prizes; 12-level plan (§1.8).
7. Fruit/kill values; milestones M1–M12 (§1.7) fixed; ±15 % fruit rule; ×1.3 per level to L5, then plateau +50/level; 70 % average; HP cap 14; prize budget ×1.5 / ×2.
8. Naming and folders (§2.10).
9. Parallax standard, no foreground layer.
10. The user designs tile layouts.
11. Editor-safety rules (§4).
12. Everything unlit, AA off, pixel textures Nearest + no mips.

## 6. TOKEN OPTIMIZATION RULES [LOCKED]

Why: every tool call re-sends the WHOLE conversation. Cost per step ≈ current context size, so long sessions get expensive fast.
(On 2026-10-02 one session grew from 12k to 445k; small questions at the end cost ~450k each.)

### 6.1 Session hygiene (the user's commands; Claude reminds)
- **One task = one session.** When a feature is done and its progress memory is saved → the user runs `/clear` (or starts a new session).
- **`/compact`** when a task must continue but the context is large (~150k+). Before suggesting it, Claude saves a checkpoint to the task's progress memory.
- **Quick checks** ("is X done?", "does the file have N rows?") go in a fresh session, not at the end of a long one.
- Claude says it plainly ("Context is large — save + /clear recommended") when:
  a task is finished, the topic changes, or the context passes ~150k.

### 6.2 Loading context
- New session: load **core.md only**. Load other memory files **on demand**, only the ones the task names (e.g. "continue parallax" → parallax-progress.md).
- Never bulk-read all memory files. For a project-wide analysis, ask first and list which files will be read.
- Don't re-read a file already in context. Use `offset/limit` for large files and `head_limit` / `count` for Grep.
- Never Read whole logs: Grep `Saved/Logs/WhateverPlatformer.log` for specific tags (`unreal.log` markers) with a small head_limit.

### 6.3 Tool-output discipline (Unreal MCP)
- Prefer narrow tools: `list_blueprint_variables` / `list_blueprint_functions` / `get_node_details` (one node) before `get_graph_nodes` (full dump).
- `get_graph_nodes` only on the specific graph needed (`set_active_graph` first), at most once per graph per task. Reuse the result.
- run_python: print **only** the needed values (counts, names, the changed property), never full object dumps or asset lists. Filter inside Python.
- `list_actors` / `asset_search`: always filter (class, folder, name). Never list a whole map or the whole content tree.
- Batch where possible (`level_spawn_actors_batch`, `add_data_table_rows_batch`, one Python tick doing several reads).
- Verify a mutation with ONE targeted read, not a re-dump.

### 6.4 Answer discipline
- Short answers: result + what the user must do (compile, playtest). No repeating plans or tables already shown.
- Ask clarifying questions in ONE message (numbered), not across several rounds.
- Don't re-explain a decision that's already recorded in core.md or memory. Link it instead.
- Progress memory = a short checkpoint (state, values, next step), not a narrative.

> Update this file when the user approves a change to any [LOCKED] item; record the date.