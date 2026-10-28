\# Audit report: technical baseline and architecture (read only)



I changed nothing. No values were edited, nothing was compiled or saved. The only side effect: I opened and closed Blueprint editor tabs one at a time so the read tools could see them. Every name below was checked against the live editor (asset registry parent tags, class default values, the variable and function lists, or reference lookups). Anything I couldn't check is marked \*\*UNVERIFIED\*\* and listed under "What still needs reading from the editor".



\## A. Inventory



\*\*Engine and approach:\*\* UE \*\*5.3\*\*. The project is \*\*100 % Blueprint\*\*: there is no `Source/` folder and no C++ module. It uses Paper2D for sprites and tilemaps, and \*\*PaperZD\*\* for the characters (`BP\_ActionChar\_BASE` derives from `PaperZDCharacter`). Plugins: PaperZD, ClaudeAssistant, RootMovement (in the project's `Plugins/` folder), ModelingToolsEditorMode (editor only). There are no Data Assets or DataTables. All tuning lives in Blueprint defaults and in values set on each placed actor.



\### Classes by system (verified parent → class)



| System | Assets | Verified responsibility |

|---|---|---|

| Movement / jump / camera | `BP\_Player` (from `BP\_ActionChar\_BASE`), `ABP\_Player`, `IMC\_Action` + `IA\_Move/Jump/Shoot/Pause`, `BP\_CameraRestrictor` | Movement uses the built-in character movement component. Wall slide, wall jump and ground slide are in `TryWallSlide`, `TryCancelSlide` and the EventGraph. Camera: `UpdateRoomCamera`, `UpdateCameraPos`. Idle float: `UpdateIdleLevitate` |

| Shooting / projectiles / hits | `BP\_Player` (`Spawn Projectile`, `TryChargeShot`, `HandleChargeFlash`, `RestoreShootEnergy`); `BP\_Projectile\_BASE` (`Faction`, `ProjectileDamage`, `ScaleDamage`, `PlayHitEffects`) → `BP\_PlayerProjectile\_BASE` → Regular / PartialCharge / FullCharge; `BP\_Enemy\_Projectile\_BASE` → `BP\_EnemyProjectile\_Lizard/Trunk/Plant`; `E\_Faction` | The shot type is mapped to an energy cost through `ProjectileToEnergy` |

| Damage / HP / death | `BPC\_Vitality` (`MaxHealth`, `CurrentHealth`, `IsDefeated`; `ReceiveDamage`, `AddMaxHealth`); `BP\_ActionChar\_BASE` EventGraph | `Event AnyDamage` → if not defeated → `ReceiveDamage` → if defeated, call the `Defeated` delegate; otherwise `TriggerFlash` (white-flash timeline) |

| Player i-frames / knockback / respawn | `BP\_Player` (`InvicibilityDuration`, `KnockBack\*`, `StunDuration`, `RespawnDelay`), `GM\_Action.RespawnPlayer`, `BP\_Checkpoint`, `BP\_FallDetector` | |

| Enemies | `BP\_Enemy\_BASE` (`ScoreValue`, `bScoreAwarded`, `DeathDelay`, `TurnCooldown`, `bSpawnDestroyVFX`, `TurnCharacter`) → Crab (→ CrystalCrab), Bat, Eye (→ BlackBat, CrystalBat), AngryPig, Lizard (→ CrystalLizard), Trunk, Mushroom, Plant | |

| Enemy AI | `AIC\_Base` → `AIC\_Crab`, `AIC\_Eye`, `AIC\_Lizard`, `AIC\_AngryPig` | Bat uses the plain `AIController`. Trunk, Mushroom and Plant use `AIC\_Base`. There are no behaviour trees |

| Power-ups | `GM\_Action` (`Prize1–3Score`, `NextMilestone`, `CheckMilestones`, `GrantPrize`, `ReapplyPrizes`) → `BP\_Player.ApplyPrize` → `BPC\_Vitality.AddMaxHealth`, `HasSpreadShot`, `FullChargeTime` | `ReapplyPrizes` loops `GrantPrize` up to `NextMilestone` when a new pawn spawns |

| Collectibles / score | `BP\_Pickup\_BASE` (`ScoreValue`, `bCollected`, `OnCollected`) → 8 fruit, 5 crystal and 4 grove pickups, plus `BP\_Pickup\_Hammer` (0 points); `GM\_Action.AddScore`; `GI\_Platformer` (`Score`, `NextMilestone`) | |

| Obstacles | `BP\_Trap\_BASE` (`bTriggered`, `OnPlayerTriggered`) → Saw, Spikes, CrumbleBlock. Separate, derived straight from `Actor`: `BP\_Trap\_FallingPlatform`, `BP\_Trap\_CrumbleSpawner`, `BP\_Prop\_BreakZone` | |

| Rooms / freezing | `BPC\_RoomMember` (`UpdateRoomState`, `ResetToHome`) | Works out its own room index using `RoomWidth`/`RoomOriginX` read from `BP\_Player`, and freezes the actor by setting its `CustomTimeDilation` to 0 |

| Progression / portals | `BP\_WinDetector` (next map, flag reveal), `BP\_Prop\_RoomWarp`, `BP\_Prop\_AmbushTrigger`; maps `MAP\_Level1/2/3`, `MAP\_Debug` | |

| HUD / notifications | `WBP\_HUD` (`UpdateScore`, `ShowPrize`, `HidePrize`), `WBP\_HealthComponent` (hearts), `WBP\_LevelIntro`, `WBP\_LevelClear`, `WBP\_PauseMenu`, `WBP\_Glyph`, `Widgets/Prizes/PopUp\_\*\_B\_ArcadeGlass` (MaxHP, SpreadShot, FastCharge, PierceShot) | `GM\_Action.PrizeFeedback` does a time-dilation slow-mo, then a flash |



\### Dependency map (verified with reference lookups)



GI\_Platformer ◄── GM\_Action, WBP\_LevelIntro           (score/milestone carry-over)

GM\_Action ◄── BP\_Player, BP\_Enemy\_BASE (kill score), BP\_Pickup\_BASE, BP\_Checkpoint, BP\_WinDetector

GM\_Action ──► WBP\_HUD (UpdateScore/ShowPrize), BP\_Player (GrantPrize→ApplyPrize)

BP\_Player ◄── BPC\_RoomMember, BP\_Trap\_BASE, BP\_Trap\_FallingPlatform, BP\_PlayerProjectile\_BASE,

&#x20;             BP\_Pickup\_BASE, BP\_Enemy\_Eye, BP\_FallDetector, BP\_Checkpoint, BP\_WinDetector,

&#x20;             BP\_Prop\_RoomWarp, BP\_CameraRestrictor, ABP\_Player, GM\_Action      ← hard casts everywhere

BP\_Player ──► BPC\_Vitality, WBP\_HUD, WBP\_HealthComponent, WBP\_PauseMenu, IMC\_Action, all player projectiles

BPC\_RoomMember ◄── BP\_Enemy\_BASE + most enemies, Trap\_BASE/Saw/Spikes/CrumbleBlock, MAP\_Level1/2/3

Level design ──► per-instance values (enemy HP, sight, interval, ScoreValue overrides, trap knobs)



\### Redundancies and overlapping responsibilities



1\. \*\*Score state lives in two places.\*\* `GM\_Action.Score/NextMilestone` and `GI\_Platformer.Score/NextMilestone` are copied across at BeginPlay.

2\. \*\*Shooter logic is copied, not inherited.\*\* Trunk, Mushroom and Plant derive from `BP\_Enemy\_BASE`, not from Crab or Lizard. `SightRange/ShootInterval/ReactionDelay` are declared separately in Lizard, Trunk and Plant. `AggroDuration/HitDuration/EdgeIdleTime` are copied across Trunk, Mushroom and Plant (and Pig).

3\. \*\*AIC\_Lizard holds sight/interval values that nothing uses\*\* (already noted in core.md).

4\. \*\*Trap inheritance is inconsistent.\*\* FallingPlatform and CrumbleSpawner bypass `BP\_Trap\_BASE`, and FallingPlatform has no `BPC\_RoomMember`. It runs its own `RespawnDelay` reset instead.

5\. \*\*Damage logic is split.\*\* Health is in `BPC\_Vitality`, but i-frames, knockback and stun are in `BP\_Player`, and Vitality has no "health changed" event. HUD hearts are driven from BP\_Player and WBP\_HUD (both reference `WBP\_HealthComponent`).

6\. \*\*Stale redirector:\*\* `/Game/Blueprints/Characters/Enemies/BP\_Enemy\_Lizard` is a leftover redirect. The real Blueprint is in `Lizard/`.

7\. \*\*Possible duplicate camera:\*\* a `Camera` component appeared twice when I listed BP\_Player's components. This needs a check in the Components panel.



\## B. Gameplay baseline (live default values; nothing changed)



| Area | Value |

|---|---|

| Player movement | MaxWalk \*\*600\*\*, Accel \*\*2048\*\*, BrakingDecel \*\*2048\*\*, GroundFriction 8, BrakingFrictionFactor 2, AirControl \*\*1.0\*\*, FallingLateralFriction 50, GravityScale \*\*5.5\*\*, constrained to a plane |

| Jump | JumpZ \*\*600\*\*, JumpMaxCount \*\*2\*\*, JumpMaxHold \*\*0.172 s\*\*, DoubleJumpAnimDuration 0.4 |

| Wall / slide | WallSlideSpeed −20, WallTrace 40 / stick 55, WallJump horizontal 1000 / vertical 1500, WallJumpLock 0.2 s, Slide strength 1000 / 0.3 s |

| Capsule | half-height 60, radius 34 |

| Shooting | ShootEnergy / ShotEnergyMax \*\*3\*\*. Energy cost: Regular 1, Partial 1, Full 3. PartialCharge \*\*0.8 s\*\*, FullCharge \*\*1.8 s\*\*. ShootAnimDuration 0.4 |

| Projectiles | speed \*\*1000\*\*, no gravity, \*\*no lifespan\*\* (life 0). Damage: Regular 1, Partial 2, Full 3, enemy shots 1. "Range" is unlimited; it is effectively the screen or a wall |

| Spread (prize) | angle 15°, side shots ×0.5 damage, cooldown 0.5 s, `HasSpreadShot` false by default |

| Player HP | `BPC\_Vitality.MaxHealth` \*\*10\*\* |

| Taking damage | `OverlapDamage` 1, \*\*InvicibilityDuration 1.5 s\*\* (the variable name has this typo), flicker 0.12 s, knockback 1200 / 800, stun 0.4 s, RespawnDelay 2.0 s (spawns a new pawn) |

| Enemy damage | every enemy projectile 1, saw 1, spikes 1, fall = instant death |

| Enemy defaults | All templates are \*\*MaxHealth 10\*\*; real HP is set on each placed actor. Crab walk speed 120, Pig 260, Eye flies at 400. Lizard / CrystalLizard: sight 600, interval 3.0, reaction 0.3. Trunk: 600 / 2.5 / 0.3 / aggro 5. Plant: 600 / 2.5 / 0.3 / aggro 5. The L3+ curve values are set on each placed actor |

| Camera | SpringArm 500, \*\*Orthographic, OrthoWidth 2560, 16:9\*\*, `UseFollowCamera` false, `FixedCameraLocation` (1248, 0, −704), RoomWidth 2560, RoomOriginX −32, slide 0.75 s, the player freezes during the slide, PixelSnap 4 |

| Upgrades | M1 = 300 (+1 max HP + heal), M2 = 800 (Spread), M3 = 1500 (charge time 1.8 → 1.2) |

| Traps | Saw 150 / 300 range; FallingPlatform 0.5 / 800 / respawn 3; CrumbleBlock \*\*StandTime 0.0\*\*, CrumbleTime 2.0 (template values) |



\*\*How dynamic values are worked out:\*\*

\- \*\*Milestones:\*\* `CheckMilestones` compares Score against `Select Int(Prize1/2/3Score)` by `NextMilestone`. It then calls `GrantPrize`, increments the milestone and calls itself again, so several prizes can trigger at once.

\- \*\*Respawns:\*\* `ReapplyPrizes` re-runs `GrantPrize` for indices 0..NextMilestone−1 on the new pawn.

\- \*\*Room index:\*\* `floor((X − RoomOriginX) / RoomWidth)`.

\- \*\*Per-level tuning\*\* (enemy HP, sight curve, saw speed, fall delay) comes from \*\*values set on each placed actor\*\*, not from formulas.



\## C. Safety



1\. \*\*There is no version control.\*\* I found no `.git`, `.plastic`, `.svn` or `.p4config`. This is the biggest risk right now.

2\. \*\*Proposal\*\* (needs your OK; I won't run it):

&#x20;  - With the editor closed: `git init`, git-lfs tracking `\*.uasset` and `\*.umap`, and a `.gitignore` excluding `Binaries/ DerivedDataCache/ Intermediate/ Saved/`.

&#x20;  - Make a baseline commit called "pre-optimization baseline 2026-10-19".

&#x20;  - Then `git switch -c design-tuning`. Optionally enable Git in UE's Source Control settings.

3\. \*\*Basic regression tests (manual playtest checklist):\*\*

&#x20;  1. Walk / brake / double jump heights (\~122–136 u single, 254 u double).

&#x20;  2. Wall slide and wall jump in the L1 R0 shaft.

&#x20;  3. Ground slide.

&#x20;  4. Regular, Partial and Full shots: damage 1/2/3 and energy costs.

&#x20;  5. Spread after 800 points.

&#x20;  6. Charge time 1.2 s after 1500 points.

&#x20;  7. Hit → 1.5 s i-frames, flicker, knockback.

&#x20;  8. Death → respawn at the checkpoint after 2 s, prizes reapplied, score kept.

&#x20;  9. Room transition: camera slide, player frozen, enemies in other rooms frozen and reset, kills don't respawn.

&#x20;  10. Every enemy type: HP per placed actor, score once (`bScoreAwarded`), Pig/Bat death delay.

&#x20;  11. Shooters: line of sight, height limit, aggro on hit (L3).

&#x20;  12. Saw, spikes, falling platform respawn, crumble respawn after death.

&#x20;  13. Pickups: correct points, collected only once.

&#x20;  14. Hammer ambush and room warp (L3 R1).

&#x20;  15. WinDetector flag → next map, score carried over by the GI. Also check a \*\*packaged build\*\*.

&#x20;  16. HUD: hearts (11 slots), score, prize popup + slow-mo, pause menu, level intro.

&#x20;  17. Run `Docs/check\_calibration.ps1`: it should report 0 FAIL.

4\. \*\*Systems that are especially sensitive to changes:\*\*

&#x20;  - `BP\_Player`: 64 variables, a 192-node EventGraph, and nearly everything casts to it.

&#x20;  - `GM\_Action` milestone chain + `ReapplyPrizes` (the new-pawn rule).

&#x20;  - `BPC\_RoomMember`: it freezes actors with `CustomTimeDilation` 0, but \*\*SetTimer timers are not affected by time dilation\*\* and keep running on frozen actors.

&#x20;  - `BP\_ActionChar\_BASE` AnyDamage path.

&#x20;  - Per-instance overrides. Changing a template's defaults does not update placed actors, and moving a placed actor resets component edits.

&#x20;  - The Projectile collision channel and profiles.

&#x20;  - Crab-derived enemies' playback syncing in Tick.

&#x20;  - The PaperZD state machines can't be edited through the tools.

5\. \*\*No automated refactoring is recommended.\*\* Every redundancy above is safe to leave as it is for now.



\## D. Risks, order of work, and what is ready to extend



\*\*Risks for future changes:\*\*

\- Without VCS, nothing can be undone.

\- The tight coupling to `BP\_Player` means any rename or refactor touches 13+ assets.

\- Values are scattered across placed actors, with no central data table, so a global rebalance means editing every map.

\- `GM\_Action` has room for only \*\*3\*\* prizes; M4+ needs new slots.

\- The HUD has 11 heart slots against an HP cap of 14.

\- Shooter logic is copied, so fixes must be repeated in Lizard, Trunk and Plant.

\- Compiling Blueprints that have placed actors is crash-prone (core §4).



\*\*Suggested order:\*\*

1\. VCS + baseline commit + branch.

2\. Run the regression checklist once and record the results as the "golden" baseline.

3\. Read the remaining unverified graphs (below).

4\. Do low-risk data-only tuning (fruit, values on placed actors) in the calibration loop.

5\. Additive, opt-in features: M4+ prize slots in GM, the 14-heart HUD, any new weapon.

6\. Only then consider consolidation, optional and one item at a time:

&#x20;  - a shared shooter parent;

&#x20;  - FallingPlatform/CrumbleSpawner moved under `BP\_Trap\_BASE` + RoomMember;

&#x20;  - a health-changed event on `BPC\_Vitality`;

&#x20;  - fixing the redirectors.



\*\*Already ready for extension:\*\*

\- `BP\_Pickup\_BASE` (new pickup = child + `ScoreValue`).

\- `BP\_Enemy\_BASE` opt-in knobs.

\- `BP\_Trap\_BASE.OnPlayerTriggered`.

\- `BPC\_RoomMember` (drop-in component).

\- The `BP\_Projectile\_BASE` hierarchy + `ProjectileToEnergy` map.

\- The `GrantPrize`/`ApplyPrize` path (needs more slots).

\- `BP\_WinDetector` / `BP\_Prop\_RoomWarp` / `BP\_Prop\_AmbushTrigger`.

\- The calibration ledger and check script.

\- The PIE calibration monitor.



\*\*What still needs reading from the editor (UNVERIFIED):\*\*

\- `BP\_Player.ApplyPrize` (19 nodes) and `Spawn Projectile` (67 nodes): exact spread and prize branches.

\- `BP\_Projectile\_BASE` EventGraph: hit filtering. Every projectile template shows `Faction = ENEMY`, including the player's own shots, so the faction must be set when the shot spawns. Not confirmed.

\- How `OverlapDamage` is applied on enemy contact.

\- `BP\_Trap\_CrumbleSpawner`: whether it sets the 3 s StandTime (the template value is 0).

\- The duplicate `Camera` entry on BP\_Player.

\- The PaperZD state machines (`ABP\_\*`). You'll need to check these yourself; the tools can't read them.

