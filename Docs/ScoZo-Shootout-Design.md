# ScoZo Shootout – Design Document

## Overview

**ScoZo Shootout** is a fast-paced 2v2 arcade mini-game set entirely in the shooting circle. The player controls the home team's **GS** and **GA** against AI-controlled **GK** and **GD** defenders. The goal is to score without getting intercepted or running out of possession.

## Cast

| Role | Team | Control |
|------|------|---------|
| GS (Goal Shooter) | Home (Teal) | Human |
| GA (Goal Attack) | Home (Teal) | Human (via SWITCH) |
| GK (Goal Keeper) | Away (Magenta) | AI |
| GD (Goal Defence) | Away (Magenta) | AI |

**No C/WA/WD** – only four players in the arena.

## Arena

- Single shooting circle + short apron area
- One hoop (home team attacking upward)
- Players clamped to legal zones:
  - **GS/GA**: Can move within and around the shooting circle
  - **GK/GD**: Defend inside the circle, contesting shots and passes

## Controls

| Input | Action |
|-------|--------|
| **D-pad** | Move the selected attacker |
| **SWITCH** | Toggle selection between GS ↔ GA (prefers ball carrier) |
| **Tap teammate** | Set pass target (highlight + lane preview) |
| **PASS** | Throw to target (fallback: the other attacker) |
| **SHOOT** | Begin timing arc (only in circle with ball); release to fire |

### Ball Handling

- **Loose ball**: Auto-switch to nearest home player; pickup on contact
- **No running with ball**: Player pivots/shuffles when holding (limited movement)

## Rules (Arcade-Light)

| Rule | Description |
|------|-------------|
| **Held Ball** | 3-second turnover timer when holding |
| **Pass Restriction** | Only GS ↔ GA passes allowed |
| **Shoot Zone** | Must be inside shooting circle to shoot |
| **Intercepts** | Defenders can intercept passes in flight (tunable chance) |

## Win Condition

**Round Structure:**
- **First to 5 goals** wins the round
- Round ends early if:
  - **3 turnovers/stops** by defense
  - **90 seconds** clock expires
- On goal: reset attack possession (ball to home team)
- On turnover/stop: defense keeps possession briefly, then reset to home

## Result Screen

Shows:
- Goals scored vs defensive stops
- Win/Loss indication
- **REMATCH** button → new round
- **MENU** button → return to main menu

## AI Behavior

### GK (Goal Keeper)
- Biases toward hoop position
- Contests shots when shooter is in circle
- Chases rebounds

### GD (Goal Defence)
- Marks the ball carrier or off-ball attacker
- Cuts passing lanes
- Both defenders contest loose balls

## Teams (Adelaide Premier League)

| Club | Short |
|------|-------|
| Contax | CTX |
| Garville | GAR |
| Matrics | MAT |
| Norwood | NOR |
| Oakdale | OAK |
| South Adelaide | SOU |
| Tango | TAN |
| Walkerville | WAL |

**Club Selection:**
- Player picks their club from a grid picker (persisted via UserDefaults)
- AI randomly selects from remaining 7 clubs
- Club names shown in HUD (not baked onto player sprites — kits stay teal/magenta)

## Screen Flow

```
MenuScene → ClubPickerScene → ShootoutScene → ShootoutResultScene
                                    ↑_____REMATCH_______|
```

## Technical Implementation

### New Files
- `Scozo Play/Assets/ShootoutAssets.swift` – Asset loader with fallback to procedural shapes
- `Scozo Play/Shootout/Club.swift` – Club model + Adelaide Premier League roster + UserDefaults persistence
- `Scozo Play/Shootout/ClubPickerScene.swift` – Club selection grid before play
- `Scozo Play/Shootout/ShootoutScene.swift` – Main game scene
- `Scozo Play/Shootout/ShootoutContext.swift` – Game state container
- `Scozo Play/Shootout/ShootoutState.swift` – Score/clock/round state with club info
- `Scozo Play/Shootout/ShootoutAI.swift` – Defender AI
- `Scozo Play/Shootout/ShootoutRules.swift` – Round flow logic
- `Scozo Play/Shootout/ShootoutCourtNode.swift` – Half-court visuals (uses court texture when available)
- `Scozo Play/Shootout/ShootoutHUD.swift` – Goals vs Stops scoreboard with club names
- `Scozo Play/Shootout/ShootoutPassSystem.swift` – GS↔GA pass system
- `Scozo Play/Shootout/ShootoutPlayerNode.swift` – Player sprite with texture/shape fallback
- `Scozo Play/Shootout/ShootoutBallNode.swift` – Ball sprite with texture/shape fallback
- `Scozo Play/Shootout/ShootoutResultScene.swift` – End-of-round screen with club names

### Reused Components
- `VirtualControlsNode` – D-pad + Shoot/Pass/Switch buttons
- `HUDNode` – Scoreboard (simplified for shootout)
- `PlayerNode` – Player silhouettes (teal vs magenta)
- `BallNode` – Ball with flight trail
- `HoopNode` – Goal post
- `ShootSystem` – Timing arc + shot resolution
- `PassSystem` – Pass targeting + interception
- `FootworkSystem` – Movement + pivot rules
- `PossessionSystem` – Ball ownership

### Parked (Not Used in Shootout)
- Centre pass mechanics
- Full-court formations
- Quarter-based timing
- C/WA/WD positions

## Visual Style

Reference: 2D isometric look
- Teal (#00C2C7) vs Magenta (#E21B70) teams
- Wood court floor
- Dashed trajectory preview when shooting
- Timing/power arc around shooter
- Selection ring on active player

## Assets (2D Art Pack)

**Expected assets in `Assets.xcassets`:**

| Asset Name | Description |
|------------|-------------|
| `court` | Half-court floor with shooting circle |
| `ball` | Netball sprite |
| `selection-ring` | Glowing ring under selected player |
| `gs-idle` | Goal Shooter standing |
| `gs-shuffle` | Goal Shooter moving |
| `gs-pass` | Goal Shooter passing |
| `gs-shoot` | Goal Shooter shooting |
| `ga-idle` | Goal Attack standing |
| `ga-shuffle` | Goal Attack moving |
| `ga-pass` | Goal Attack passing |
| `ga-shoot` | Goal Attack shooting |
| `gd-idle` | Goal Defence standing |
| `gd-shuffle` | Goal Defence moving |
| `gd-defend` | Goal Defence defending |
| `gk-idle` | Goal Keeper standing |
| `gk-shuffle` | Goal Keeper moving |
| `gk-defend` | Goal Keeper defending |

**Note:** The game uses procedural shape-based placeholders until these PNG assets are added. The `ShootoutAssets` loader automatically detects and uses textures when available.

## Definition of Done

- [ ] PR with Shootout as primary Play mode
- [ ] GS/GA/GD/GK in circle; pass aim works; shoot arc displays
- [ ] Defenders can intercept passes
- [ ] Held-ball only triggers on actual carrier (no soft-lock)
- [ ] Win/lose → result → rematch flow works
- [ ] Short Simulator verification steps documented in PR
