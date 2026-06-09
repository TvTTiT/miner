# Gold Miner Roguelike

A roguelike take on the classic claw-mining arcade game, built in **Godot 4.6**.

Drop your claw, haul up gold and gems, dodge rocks and dynamite, and survive as many procedurally generated floors as you can. Each run is permadeath — fail a floor and you start over.

## How to Play

1. Open the project in Godot 4.6+ and press **F5** (or click Play).
2. Press **Space** or **left-click** to drop the claw while it swings.
3. Hit the floor goal before the timer runs out to advance.
4. **Hook treasure chests** underground for random stat drops mid-floor.
5. After clearing a floor, a **reward chest cinematic** grants another random buff.
6. Keep descending until you miss a goal — then the run ends.

## Roguelike Features

| Feature | Description |
|---------|-------------|
| **Procedural floors** | Item layout, types, and positions are randomly generated each floor from a run seed |
| **Permadeath** | Missing a floor goal ends the entire run |
| **Structured veins** | Gold spawns in readable vertical lanes — shallow nuggets, deeper bigger hauls |
| **Scaling difficulty** | Goals rise and timers tighten as you go deeper |
| **Treasure chests** | Random stat loot with rarity tiers and cinematic reveals |
| **Run records** | Best depth and best total earnings are saved locally |

## Items

| Item | Value | Notes |
|------|-------|-------|
| Small Gold | $50 | Light, fast to reel in |
| Medium Gold | $100 | Moderate weight |
| Large Gold | $250 | Heavy — slows the claw |
| Diamond | $500 | Rare, light, high value |
| Rock | $11 | Very heavy |
| Bone | $3 | Light junk |
| Dynamite | −$150 | **Avoid!** Penalizes your earnings |

## Upgrades

- **Quick Reel** — Reel in 30% faster
- **Long Rope** — Reach 20% farther underground
- **Fast Swing** — Swing 25% faster for better aim
- **Light Touch** — Heavy items slow you less
- **Lucky Watch** — +8 seconds on every floor
- **Gold Rush** — More gold spawns on future floors
- **Prospector** — Better diamond odds on future floors
- **Steady Hand** — Claw extends 20% faster

Each upgrade can only be taken once per run. Chests roll rarity-weighted loot (common → epic).

### Chest loot rarities

| Rarity | Color | Examples |
|--------|-------|----------|
| Common | Gray | Quick Reel, Long Rope, Fast Swing |
| Uncommon | Green | Light Touch, Lucky Watch |
| Rare | Blue | Gold Rush, Prospector |
| Epic | Purple | Steady Hand |

## Controls

| Input | Action |
|-------|--------|
| Space / Left Click | Drop claw (title & game over: start / retry) |
| ESC | Pause (resume with ESC again) |
| N (while paused) | Start a new run |
| Space / Click (after chest opens) | Continue after loot reveal |

Floor goals are set from the **actual treasure on the map** (~55% of total gold value), so clearing every item always completes the floor.

## Project Structure

```
game/
  data/                 # Static definitions (items, upgrades, floor generation)
    level_data.gd
    upgrade_data.gd
  systems/              # Game loop, persistence, cinematics
    game_manager.gd
    run_save.gd
    chest_cinematic.gd
  entities/             # In-game nodes and behaviors
    claw.gd
    miner.gd
    item.gd
    treasure_chest.gd
  scenes/               # Godot scenes
    main.tscn
    miner.tscn
    item.tscn
    chest.tscn
    chest_cinematic.tscn
assets/
  icons/                # Project icon
addons/
  godot_ai/             # Editor MCP plugin (local install)
```

## Requirements

- Godot 4.6 (GL Compatibility renderer)
