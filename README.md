# Gold Miner Roguelike

A roguelike take on the classic claw-mining arcade game, built in **Godot 4.6**.

Drop your claw, chain valuable grabs for combo multipliers, draft tools and skills from chests, **fuse them into evolved gear**, and survive procedurally generated floors.

## How to Play

1. Open the project in Godot 4.6+ and press **F5**.
2. Press **Space** or **left-click** to drop the claw.
3. Chain gold and gems to build **combo multipliers**.
4. Clear the floor goal before time runs out.
5. Open chests — **pick 1 of 3** tools, skills, or fusions with keys **1**, **2**, **3**.
6. Collect matching pairs to unlock **fused evolved gear**.
7. Keep descending until you miss a goal.

## Loadout System (VS-style)


| Type       | Tag | Description                                         |
| ---------- | --- | --------------------------------------------------- |
| **Tool**   | T   | Active gear — claw reach, blast rig, etc.           |
| **Skill**  | S   | Passive buff — reel speed, rope length, spawn luck  |
| **Fusion** | F   | Evolved form — requires both parents, replaces them |


Each tool/skill levels **1 → 3** from repeat chest picks. When you own both parents of a recipe, a **★ FUSION** option can appear in the draft.

### Fusion recipes


| Fusion             | Parents                  | Effect                      |
| ------------------ | ------------------------ | --------------------------- |
| **Sky Drill**      | Long Rope + Quick Reel   | Massive reach & reel speed  |
| **Snap Claw**      | Fast Swing + Steady Hand | Lightning swing & drop      |
| **Treasure Sense** | Magnet Hook + Prospector | Huge grab zone & gem luck   |
| **Titan Grip**     | Iron Claw + Light Touch  | Heavy haul specialist       |
| **Gold Hour**      | Gold Rush + Lucky Watch  | Floods of gold + extra time |
| **Shatter Core**   | Blast Rig + Quick Reel   | Explosive speed demon       |


Recipe progress shows on the chest screen (`✓` = owned, `○` = missing). Pause menu (ESC) also lists active fusion paths.

### Tools


| Tool        | Effect per level                            |
| ----------- | ------------------------------------------- |
| Iron Claw   | +10% reel (starter, always owned)           |
| Magnet Hook | +12% claw grab radius                       |
| Blast Rig   | +25% dynamite radius, −40% dynamite penalty |


### Skills


| Skill       | Effect per level       |
| ----------- | ---------------------- |
| Quick Reel  | +12% retract speed     |
| Long Rope   | +12% max rope          |
| Fast Swing  | +12% swing speed       |
| Steady Hand | +12% extend speed      |
| Light Touch | +12% weight resistance |
| Lucky Watch | +5 seconds each floor  |
| Gold Rush   | More gold spawns       |
| Prospector  | Better diamond odds    |


## Roguelike Features


| Feature                    | Description                                                |
| -------------------------- | ---------------------------------------------------------- |
| **Combo streaks**          | x1.25 / x1.5 / x2.0 multipliers for chained valuable grabs |
| **Tool fusion tree**       | Mix tools + skills into evolved forms                      |
| **Dragon guardians**       | Patrolling lane hazards                                    |
| **Jackpot Vaults**         | Rare dense-loot floors                                     |
| **Cursed loot & dynamite** | Risk/reward hazards                                        |
| **Treasure chests**        | Mid-floor and floor-clear draft picks                      |


## Controls


| Input                   | Action                       |
| ----------------------- | ---------------------------- |
| Space / Left Click      | Drop claw                    |
| 1 / 2 / 3               | Pick chest draft option      |
| ESC                     | Pause (shows fusion recipes) |
| N (paused)              | New run                      |
| Space (after cinematic) | Continue                     |


## Project Structure

```
game/
  data/
    tool_data.gd        # Tools, skills, fusion recipes
    level_data.gd
    upgrade_data.gd     # Legacy alias
  systems/
    run_loadout.gd      # Levels, drafts, modifiers, fusion logic
    game_manager.gd
    combo_system.gd
    chest_cinematic.gd
    loot_feedback.gd
  entities/
    claw.gd, miner.gd, item.gd, treasure_chest.gd, dragon_guardian.gd
  scenes/
```

## Requirements

- Godot 4.6 (GL Compatibility renderer)

