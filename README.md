# 🕹️ WhateverPlatformer

> A pixel-art 2D action platformer built in **Unreal Engine 5.3** with **Paper2D**. You jump, wall-slide and charge-shoot through 12 hand-built levels, and every room is tuned against a measured difficulty curve.
Few levels of the game has been built because I was bored. There is a lot of things that needs to be improved and levels to build but I still decided to share it, because meaby someone might find it useful for whatever reason.

>Read instruction to run the project on your machine. If there are any issues with running the project just use AI to solve it. You might also just use the Release Build to run the game to just check it.

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

# Unreal Engine 5.3 Project Setup

This project uses **Unreal Engine 5.3** and contains a C++ plugin that must be compiled locally after cloning the repository.

The repository intentionally does **not** contain generated Unreal Engine build files such as `Binaries/` and `Intermediate/`.

## Requirements

Install the following before opening the project:

- Unreal Engine **5.3**
- Visual Studio **2022**
- Visual Studio workload:
  - **Game development with C++**
- MSVC v143 toolset:
  - **14.34.31933**
- Windows 10 or Windows 11 SDK

The project contains the following C++ plugin:

```text
Plugins/RootMovement_5.3/
```

Its source code is included in the repository and the plugin is compiled locally.

---

## 1. Install Unreal Engine 5.3

Install Unreal Engine 5.3 using the Epic Games Launcher.

The project file should use:

```json
"EngineAssociation": "5.3"
```

If Windows opens the project using another Unreal Engine version:

1. Right-click the `.uproject` file.
2. Select **Switch Unreal Engine Version**.
3. Select **5.3**.

---

## 2. Install Visual Studio 2022

Open:

```text
Visual Studio Installer
```

Select:

```text
Visual Studio 2022
→ Modify
```

Install the workload:

```text
Game development with C++
```

Make sure a Windows SDK is also installed.

---

## 3. Install the compatible MSVC toolset

Unreal Engine 5.3 may fail to compile with newer MSVC versions such as `14.44`.

Install:

```text
MSVC v143 - VS 2022 C++ x64/x86 build tools
```

Required version:

```text
14.34.31933
```

You can verify installed MSVC versions with PowerShell:

```powershell
Get-ChildItem "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC"
```

Expected output should contain:

```text
14.34.31933
```

It is fine to have newer versions installed as well.

---

## 4. Configure Unreal Engine to use MSVC 14.34

Create this directory if it does not exist:

```powershell
New-Item -ItemType Directory -Force "$env:APPDATA\Unreal Engine\UnrealBuildTool"
```

Create the following file:

```text
%APPDATA%\Unreal Engine\UnrealBuildTool\BuildConfiguration.xml
```

with this content:

```xml
<?xml version="1.0" encoding="utf-8"?>
<Configuration xmlns="https://www.unrealengine.com/BuildConfiguration">
  <WindowsPlatform>
    <Compiler>VisualStudio2022</Compiler>
    <CompilerVersion>14.34.31933</CompilerVersion>
  </WindowsPlatform>
</Configuration>
```

Verify the configuration with:

```powershell
Get-Content "$env:APPDATA\Unreal Engine\UnrealBuildTool\BuildConfiguration.xml"
```

---

## 5. Clone the repository

Clone the project normally:

```bash
git clone <repository-url>
```

Then enter the project directory:

```bash
cd WhateverPlatformer
```

The repository should contain the plugin source:

```text
Plugins/
└── RootMovement_5.3/
    ├── RootMovement.uplugin
    ├── Source/
    │   └── RootMovement/
    │       ├── RootMovement.Build.cs
    │       ├── Public/
    │       └── Private/
    ├── Content/
    └── Resources/
```

Generated plugin folders such as these should not be required from Git:

```text
Plugins/RootMovement_5.3/Binaries/
Plugins/RootMovement_5.3/Intermediate/
```

---

## 6. Clean generated Unreal files

If the project was copied, renamed, moved between machines, or previously opened with another configuration, remove old generated files before building.

Close Unreal Engine and Visual Studio first.

From the project root run:

```powershell
Remove-Item -Recurse -Force .\Intermediate -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force .\Binaries -ErrorAction SilentlyContinue
```

These folders are generated automatically and can safely be recreated.

Do **not** delete:

```text
Content/
Config/
Plugins/RootMovement_5.3/Source/
*.uproject
```

---

## 7. Build the project manually

If Unreal displays:

```text
The following modules are missing or built with a different engine version:

RootMovement

Would you like to rebuild them now?
```

you can first try selecting:

```text
Yes
```

If Unreal reports:

```text
could not be compiled. Try rebuilding from source manually.
```

build the project manually from PowerShell.

From the project directory run:

```powershell
& "C:\Program Files\Epic Games\UE_5.3\Engine\Build\BatchFiles\Build.bat" `
  Development Win64 `
  -Project="$PWD\WhateverPlatformer.uproject" `
  -TargetType=Editor `
  -Progress `
  -NoEngineChanges `
  -NoHotReloadFromIDE
```

Replace:

```text
WhateverPlatformer.uproject
```

with the actual project filename if necessary.

A successful build should generate the plugin DLL under:

```text
Plugins/RootMovement_5.3/Binaries/Win64/
```

For example:

```text
UnrealEditor-RootMovement.dll
```

After the build succeeds, open the `.uproject` normally.

---

## 8. Duplicate target error

If the manual build reports an error similar to:

```text
Found multiple targets with TargetType=Editor
```

for example:

```text
MegaActionPlatformerEditor
WhateverPlatformerEditor
```

the project most likely contains stale generated target files from before the project was renamed.

Check them with:

```powershell
Get-ChildItem -Recurse -Filter *.Target.cs
```

If old targets are inside:

```text
Intermediate/Source/
```

do not edit them manually.

Delete the generated project folders:

```powershell
Remove-Item -Recurse -Force .\Intermediate
Remove-Item -Recurse -Force .\Binaries -ErrorAction SilentlyContinue
```

Then run the manual build again.

---

## 9. Build logs

If compilation still fails, check the UnrealBuildTool log:

```powershell
Get-Content "$env:LOCALAPPDATA\UnrealBuildTool\Log.txt" -Tail 120
```

Useful errors usually appear near the end of this file.

Also check:

```text
Saved/Logs/
```

for project-specific Unreal Engine logs.

---

## Git configuration

Generated Unreal Engine files should not be committed.

Recommended `.gitignore` rules:

```gitignore
# Visual Studio
.vs/

# Compiled Object files
*.slo
*.lo
*.o
*.obj

# Precompiled Headers
*.gch
*.pch

# Compiled Dynamic libraries
*.so
*.dylib
*.dll

# Compiled Static libraries
*.lai
*.la
*.a
*.lib

# Executables
*.exe
*.out
*.app
*.ipa

# Generated project files
*.xcodeproj
*.xcworkspace
*.sln
*.suo
*.opensdf
*.sdf
*.VC.db
*.VC.opendb
.vsconfig

# Unreal generated project folders
Binaries/
Intermediate/
Saved/
DerivedDataCache/

# Unreal generated plugin folders
Plugins/**/Binaries/
Plugins/**/Intermediate/

# Builds
Build/*

# Keep PakBlacklist files
!Build/*/
Build/*/**
!Build/*/PakBlacklist*.txt

# Keep icon files
!Build/**/*.ico

# Built map data
*_BuiltData.uasset

# Precompiled source art
SourceArt/**/*.png
SourceArt/**/*.tga
```

The plugin source itself must remain committed:

```text
Plugins/RootMovement_5.3/RootMovement.uplugin
Plugins/RootMovement_5.3/Source/
Plugins/RootMovement_5.3/Content/
Plugins/RootMovement_5.3/Resources/
```

Do not solve compilation problems by committing generated plugin DLLs or `Intermediate` files.

---

# Quick setup

For a new machine:

```text
1. Install Unreal Engine 5.3
2. Install Visual Studio 2022
3. Install "Game development with C++"
4. Install MSVC v143 14.34.31933
5. Configure BuildConfiguration.xml to use 14.34.31933
6. Clone the repository
7. Delete Binaries/ and Intermediate/ if they exist
8. Build the project
9. Open the .uproject
```

Manual build command:

```powershell
& "C:\Program Files\Epic Games\UE_5.3\Engine\Build\BatchFiles\Build.bat" `
  Development Win64 `
  -Project="$PWD\WhateverPlatformer.uproject" `
  -TargetType=Editor `
  -Progress `
  -NoEngineChanges `
  -NoHotReloadFromIDE
```

If the build succeeds, Unreal Engine should launch normally and the `RootMovement` plugin will be compiled for the local machine.
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
