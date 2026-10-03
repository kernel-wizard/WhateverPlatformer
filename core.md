# WhateverPlatformer: CORE KNOWLEDGE / GUARD RAILS

> Source of truth for how this project is built, calibrated and safely edited.
> Compiled 2026-10-02 from the live project (DefaultEngine.ini, asset CDOs, placed actors in MAP_Level1) and every
> design/calibration decision the user approved so far.
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
| Maps | `/Game/Maps/MAP_Level1` (GameDefaultMap + EditorStartupMap), `/Game/Maps/MAP_Level2`, `/Game/Maps/MAP_Debug` (safe sandbox) |
| Old names | "MAP_2DStage" in older notes = **MAP_Level1**. "TM_Stage_2" in older notes = the tilemap now named **TM_Stage_1** (`/Game/PaperAssets/Environment/Level_1/TM_Stage_1`, 120x23), used by the actor `TM_Stage_1` in MAP_Level1 |

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
| R0 | 30 s | 1 | 0 | 230 | wall jump + shooting |
| R1 | 47 s | 1 | 0 | 255 | moving/falling platforms (FallDelay 0.5) |
| R2 | 55 s | 0 | 0 | 455 | saws + Eye + Lizard Warden mini-boss |
| **L1 total** | ~2.2 min | 2 | 0 | **940** | |
Compare rooms **relative to each other**. Absolute times depend on the tester's skill.

### 1.3 Scaling formulas
- **Each room ≈ +20–30 % over the previous room** (time, threat count, score). [LOCKED]
- **Exactly 1 new mechanic per room**, and at most 1 new idea per section. [LOCKED]
- Time targets: R0 30 s → R1 35–45 s → R2 45–60 s. A whole level ≈ 2–2.5 min.
- Damage budget: R0 ≤1, R1 ≤2, R2 ≤3; a whole level ≤6 of 10 HP. **+1 damage budget per room per level**; deaths 0–1 per room in L1–L2, up to 1–2 per room from L3+.
- Checkpoints: 1 per room (more if >60 s), **2–3 tiles inside the room entrance**, never on the border. One before any spike strip or boss.
- Enemy HP: **keep base HP**. Scale by the **number of threats** and "tank" variants. Enemy damage **stays 1**. [LOCKED]
- Later-level knobs [PROPOSAL]: Lizard ShootInterval 3 → 2.5 → 2, SightRange 600 → 800; Saw speed 150 → 200 → 250; FallDelay 0.5 → 0.35 → 0.25; Crab walk 120 → 150. Mini-boss (scale 1.3–1.4, HP 8–10, interval 1–2) only at a level end.
- Log every playtest per room: **clear time, damage taken, deaths, score collected / max**.

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
- Shots to kill (Regular 1 / Partial 2 / Full 3): 3-HP enemies (Crab, Lizard, Pig, placed Eye) = 3 regular / 2 partial / 1 full; Bat 5 HP = 5 regular or full + partial; Warden 8 HP.

### 1.6 Scoring formulas [LOCKED, LIVE in CDOs]
| Fruit | Pts | Rule of use |
|---|---|---|
| Bananas | 5 | trails only: 3–5 in a line mark a jump arc or the way |
| Apple | 10 | path/guide: **1 per beat** on the main route |
| Orange | 20 | 1 per OPTIONAL movement feat |
| Kiwi | 25 | visible off-route side branch |
| Cherries | 30 | 1 per optional threat, inside its danger zone |
| Strawberry | 40 | skill + risk, Level 2+ only |
| Melon | 50 | 1 per secret area |
| Pineapple | 100 | grand secret / mini-boss reward, MAX 1 per level, L2+ |
- **Room fruit formula:** apples = main-route beats; +1 Orange per optional move; +1 Cherries per optional threat; +1 Melon per secret; +1 Kiwi per side branch; Bananas only as trails.
- **Kill values:** Crab 10, Bat 20, Lizard 20, Eye 30, Warden 100 (instance override), Angry Pig 10 (not calibrated). New enemy ≈ **10 × hits-to-kill** + bonus for ranged/flying.
- No-damage room bonus: 50 in L1, +25 per level [PLAN].
- **Score survives death; a kill scores once** (`bScoreAwarded`).
- **Level budget:** L1 ≈ 1030 (actual 940, −9 %); ×1.3 per level → **L2 1340, L3 1740, L4 2260, L5 2940**.
- Average player ≈ **70 %** of max. Cumulative average: L1 ~720, L2 ~1660, L3 ~2880, L4 ~4460, L5 ~6520.
- **Tolerance:** drift > **±15 %** → change FRUIT, never the milestones.

### 1.7 Milestones / prizes (fixed anchors, ×1.5) [LOCKED]
| # | Score | Prize | Status |
|---|---|---|---|
| M1 | 300 | +1 max HP + full heal | LIVE (`GM_Action.Prize1Score`) |
| M2 | 800 | Spread Shot (regular shots only) | LIVE |
| M3 | 1500 | Full charge 1.8 → 1.2 s | LIVE |
| M4 | 2500 | +1 max HP | PLAN (before Level 3) |
| M5 | 3800 | new weapon (e.g. Pierce Shot) | PLAN |
| M6 | 5500 | +1 max HP or charge 1.2 → 0.9 s | PLAN |
- Design each level for the prizes the **AVERAGE** player owns at its START (L1 none; L2 11 HP; L3 11 HP + Spread + fast charge; L4 12 HP …). **Never require a prize.**
- Prize power budget: single-target DPS gain ≤ **×1.5**, close-range ≤ **×2**. A ×k player stat → ×k counter-stat in the level that ASSUMES the prize. +1 HP → +1 dmg/room next level; Spread → more flying/angled threats from L2; fast charge → boss HP ×1.5 from L3 (Warden 8 → 12).
- Spread [LIVE]: Regular only, side shots ×0.5 dmg, no Owner (no refund), cooldown 0.5 s, angle 15°, grounded 0/+15/+30°, airborne −15/0/+15°.
- After a respawn the pawn is NEW → `GM_Action.ReapplyPrizes` must keep working. Score + NextMilestone carry across maps via `GI_Platformer`.

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
| +0.04 … +2.0 | Enemies (random per instance at BeginPlay, anti z-fighting) |
| +1 | Pickups, trap sprites, WaterDrip |
| +0.05 | Player sprite |
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
| Health | MaxHealth **10** (HUD 11 heart slots) |
| Shooting | ShootEnergy 3, PartialCharge 0.8 s, FullCharge **1.8 s** |
| Respawn | 2.0 s, NEW pawn |

### 2.7 Enemies, projectiles, traps [LIVE]
**Enemy templates have MaxHealth 10 — real HP is set PER PLACED INSTANCE.**
| Enemy | Capsule | Move | HP | Score | Notes |
|---|---|---|---|---|---|
| Crab | 45/45 | walk 120 | 3 | 10 | AIC_Crab, ledge/wall turn |
| Angry Pig | 45/45 | MaxWalk 260 run; calm ×0.46 ≈ 120 | 3 | 10 | idles 1 s at edges; Hit1 → run; killing hit → Hit2 → hop 1000 → falls off the map; DeathDelay 1.3, no poof; sprite scale X −1 |
| Bat | 60/34 | bob, MovePlayRate 0.8 | 5 | 20 | |
| Eye | 43/34 | fly 400 | 3 | 30 | world-fixed aggro box + leash |
| Lizard | 45/34 | shooter | 3 | 20 | interval 3, sight 600, reaction 0.3, LOS, turns to face |
| Warden | Lizard ×1.3 | | 8 | 100 | interval 2.0, range 1100 |
- Projectile damage: Regular 1 · Partial 2 · Full 3 · Lizard 1. No projectile lifespan ("aggro when hit" planned for L2).
- Traps (BP_Trap_BASE → `OnPlayerTriggered`): Saw dmg 1, speed 150, dist 300; FallingPlatform FallDelay 0.5, FallSpeed 800, RespawnDelay 3, one-way; FallDetector = instant death; WinDetector `Level Name` → next map.
- BP_Enemy_BASE opt-in knobs: `DeathDelay` 0, `bSpawnDestroyVFX` true, `TurnCooldown` 0.15 (+`bPendingTurn`), `ScoreValue`, `bScoreAwarded`.

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
- Content: `/Game/Blueprints/{AI,Characters,Components,Enums,Environment,Pickups,Projectiles,Props,Traps,VFX}`, `/Game/PaperAssets/{Characters,Environment/Level_N,Fruits,Fx,Traps,UI}`, `/Game/{Materials,Widgets,Audio,Input,Maps}`.

---

## 3. FUNDAMENTALS

1. **Inheritance = source of truth:** `BP_ActionChar_BASE` → `BP_Enemy_BASE` → enemies; `BP_Trap_BASE`; `BP_Pickup_BASE`; `BP_Projectile_BASE`. New content = a child, usually duplicated from the closest sibling.
2. **Base changes are opt-in**, with defaults that keep the old behaviour.
3. **Health only in `BPC_Vitality`; damage only via ApplyDamage WITH a DamageCauser.**
4. **`BPC_RoomMember`** on enemies/traps: frozen outside the room, reset home on exit. Position-based room camera.
5. **The user paints tiles**; Claude places/tunes actors and bot-tests on request.
6. **Calibration loop:** tiles + collision → beat plan → place → max score → user playtest → log → compare (+20–30 %) → adjust fruit/threats.
7. **One map per level**; GI carries score/prizes; WinDetector → next map; the user switches maps.
8. **Visual hygiene:** a unique Y per plane; left-facing art → sprite scale X −1; avoid sub-texel slow motion; Clamp sheets.
9. **Instance overrides are fragile:** CDO changes don't reach placed instances; moving a BP actor resets component edits (location first); use exposed vars instead of mesh material overrides.
10. **Verify every mutation**; keep checkpoint notes for multi-step work.

---

## 4. CLAUDE RULES — avoiding editor crashes

Cause: the plugin runs tool calls mid-world-tick.

**Bans:** no `level_load` or level open/add/remove from Python · no compiling BPs that have placed instances (the user compiles, parent first) · no Interchange import (the user drags files in) · no closing editors / deleting assets with open editors in plain run_python · no Python reparent · no `.ini` edits (the user uses Project Settings) · map renames by the user.

**Must:** every run_python mutation inside a one-shot `register_slate_post_tick_callback` (work on tick ≥2, unregister, `unreal.log` + Grep `Saved/Logs/WhateverPlatformer.log`) · deferred compile only for NEW BPs without instances · save before risky steps · one logical change per call · graph tools are safe · **crash protocol:** read `Saved/Crashes` + `Saved/Logs`, record the cause, never repeat the failed method.

**Quirks:** focus switch = deferred `close_all_editors_for_asset` (tick 1) + `open_editor_for_assets` (tick 3) · object-pin defaults read "" but work (check `asset_get_dependencies`) · generic var keys resolve to the last search (verify; ambiguous titles can pick the wrong node) · impossible via tools: parent-call nodes, timeline tracks, PaperZD state machines, object/enum vars, custom-event params, `GetComponentByClass` class pin · Python can't read `EdGraph.Nodes`/`Blueprint.Status` · Python collision changes need `body_instance` + profile · attaching to BP components isn't saved · `del` Python globals + `gc.collect()` before deleting assets · session-rendered materials can't be deleted until a restart · tilemap edit pipeline: make editable → set_tile → layers into the asset → set_tile_map → empty the instance + rename into `/Engine/Transient` → save · PIE bot via `EnhancedInputLocalPlayerSubsystem` injection, only when asked; label bot-caused errors.

---

## 5. STRICT NEVER-CHANGE RULES

1. PPU 0.25, 16 px = 64 UU, plane Y 0, gravity 5.5.
2. 120×23 tilemap at the origin, 3 × 2560 rooms, RoomOriginX −32, FixedCameraLocation (1248,0,−704), ortho 2560 16:9 at +Y.
3. Depth bands (§2.4).
4. Projectile channel default Block; OverlapAll(-Dynamic) ignore Projectile; capsules overlap Pawn.
5. BASE inheritance, BPC_Vitality, ApplyDamage + causer, opt-in base changes, one map per level + GI in DefaultEngine.ini.
6. R0 = difficulty 1.0; +20–30 % per room; 1 mechanic per room; enemy damage 1; never require prizes.
7. Fruit/kill values; milestones 300/800/1500/2500/3800/5500 fixed; ±15 % fruit rule; ×1.3 per level; 70 % average; prize budget ×1.5 / ×2.
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