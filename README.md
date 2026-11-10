# 🕹️ WhateverPlatformer

> A pixel-art 2D action platformer built in **Unreal Engine 5.3** with **Paper2D**. You jump, wall-slide and charge-shoot through 12 hand-built levels, and every room is tuned against a measured difficulty curve.
Few levels of the game has been built because I was bored. There is a lot of things that needs to be improved and levels to build but I still decided to share it, because meaby someone might find it useful for whatever reason.

![Engine](https://img.shields.io/badge/Unreal%20Engine-5.3-0E1128?logo=unrealengine)
![2D](https://img.shields.io/badge/Paper2D-PaperZD-6E4C9E)
![Platform](https://img.shields.io/badge/platform-Windows-0078D6?logo=windows)
![Status](https://img.shields.io/badge/status-in%20development-orange)

---

## ✨ What is it?

WhateverPlatformer is a **side-scrolling run-and-gun platformer**: precise movement, a charge-shot blaster and pixel-art worlds.

- 🧗 **Tight movement:** double jump, wall slide and wall jump. Every gap and step in a layout is measured against real jump arcs.
- 🔫 **Charge shooting:** tap for regular shots, hold for a partial (0.8 s) or full (1.8 s) charge. Unlock **Spread Shot** and faster charging as your score grows.
- 🏆 **Score-driven progression:** fruit, crystals and level-themed pickups raise your score. Fixed score milestones unlock prizes like extra hearts and weapon upgrades. Score survives death.
- 🎥 **Room-based camera:** each level has three rooms of one screen each. The orthographic camera slides smoothly between rooms.
- 👾 **A growing bestiary:** crabs, bats, chasing eyes, crystal lizards, walking tree-trunk shooters, plant turrets, marsh slimes, shell-guarding snails and a **Warden mini-boss** at the end of every level.
- 🪤 **New mechanics every level:** falling platforms, saws, spikes, crumble tiles, hammer floor-breaks, hammer ambushes and timed marsh gas vents.

---

## 🗺️ The Journey

| Level | Theme | New mechanics | New enemies |
|---|---|---|---|
| **1** | Bronze caverns | Wall jump, shooting, falling platforms, saws | Crab, Bat, Lizard, Eye, *Lizard Warden* |
| **2** | Crystal caves | Spikes, crumble tiles, hammer + floor-drop shortcut | Crystal Bat, Crystal Crab, *Crystal Warden* |
| **3** | The Grove | Hammer ambush, combo rooms, microsections | Trunk, Mushroom, Plant, *Trunk Warden* |
| **4** | The Marsh | Marsh vents (gas launchers) | Slime, Snail, *Chameleon Warden* |
| **5–12** | *Coming soon…* | One new mechanic per level, rising intensity | ~1 new enemy per level → **final boss** |

🎯 **Target:** 12 levels, about **1 hour** for a first playthrough.

---

## 📐 Designed by numbers

The difficulty curve comes from measured playtests, not guesswork.

- **Baseline:** Level 1, Room 0 is difficulty **1.0** (about 30 s, 1 damage, 0 deaths).
- **Inside a level:** each room is about **+20–30 %** harder than the one before (time, threats, score), with a 60 s cap per room.
- **Between levels:** growth comes from *intensity*: threat density, precision and new mechanic combos. Rooms don't get longer.
- **Room layout:** from Level 4, every room mixes three section types:
  - 🏃 **Movement Mastery:** the route itself is the challenge.
  - ⚔️ **Tactical Combat:** enemy groups with cover and clear sight lines.
  - 💎 **Risk vs Reward:** a safe path or a dangerous one with better pickups.
- **Never require a prize:** every layout can be cleared without upgrades.

Every playtest is logged in [`Docs/calibration_ledger.csv`](Docs/calibration_ledger.csv). A checker script compares the results against the design targets:

```powershell
powershell -File Docs/check_calibration.ps1   # exit code = number of failed checks
```

---

## 🎮 Controls

| Action | Key |
|---|---|
| Move | `A` / `D` |
| Jump / double jump / wall jump | `Jump` |
| Shoot (hold to charge) | `J` |
| Pause | `Pause` |

---

## 🛠️ Tech overview

| | |
|---|---|
| **Engine** | Unreal Engine 5.3 (Blueprints) |
| **2D stack** | Paper2D sprites, flipbooks and tilemaps, plus PaperZD for player animation |
| **Pixel scale** | 16×16 px tiles = 64×64 units; nearest-neighbour filtering, no AA, fully unlit |
| **Camera** | Orthographic, 2560 units wide, 16:9 locked: one room per screen |
| **Levels** | One map per level, each a 120×23 tilemap split into three rooms |
| **Architecture** | Inheritance-based: `BP_ActionChar_BASE → BP_Enemy_BASE → enemies`, plus base classes for traps, pickups and projectiles. Health lives in a `BPC_Vitality` component. A `BPC_RoomMember` component freezes and resets actors outside the active room |
| **Persistence** | `GI_Platformer` (Game Instance) carries score and prizes across maps |
| **Parallax** | Two-layer translucent parallax per room over a flat backdrop |

### 📁 Project layout

```
Content/
├── Blueprints/      # AI, Characters, Components, Pickups, Projectiles, Props, Traps, VFX
├── PaperAssets/     # Sprites, flipbooks, tilesets and tilemaps per level
├── Maps/            # MAP_Level1 … MAP_Level4, MAP_Debug
├── Materials/  Widgets/  Audio/  Input/
Docs/                # Calibration ledger, checker script, audits
core.md              # Full design + calibration rulebook
```

---

## 🚀 Getting started

1. Install **Unreal Engine 5.3**.
2. Clone the repository:
   ```bash
   git clone <this-repo-url>
   ```
3. Open `WhateverPlatformer.uproject`. If asked, let the engine rebuild modules. The **PaperZD** plugin must be installed.
4. Press **Play** in `MAP_Level1`, which is the default map.

> 💡 `MAP_Debug` is a safe sandbox for testing enemies and traps.

---

## 📖 Want the deep dive?

[`core.md`](core.md) is the full rulebook for the project. It covers scoring formulas, milestone prizes, enemy stats, jump geometry, depth sorting, collision channels and the 12-level plan. Anything you want to know about *why* something works the way it does is in there.

---

## 🎨 Credits
PLEASE REMEMBER TO SUPPORT CREATORS OF THE ASSETS
- Pixel art based on the **Pixel Adventure** asset style, with custom level-specific tiles and props.
- Built with Unreal Engine, Paper2D and [PaperZD](https://www.unrealengine.com/marketplace/en-US/product/paperzd).
- https://pixabay.com/sound-effects/film-special-effects-swish-sound-94707/
- https://pixabay.com/sound-effects/technology-achievement-unlocked-463070/
- https://pixabay.com/sound-effects/film-special-effects-glitch-sound-effect-hd-379466/
- https://pixelfrog-assets.itch.io/pixel-adventure-1
- https://pixelfrog-assets.itch.io/pixel-adventure-2
- https://ansimuz.itch.io/super-grotto-escape-pack
- https://karsiori.itch.io/pixel-art-pipes-and-cables-modular
---

<p align="center"><i>Jump. Shoot. Collect. Repeat. 🍒</i></p>
