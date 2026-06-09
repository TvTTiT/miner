# Changelog

All notable changes to Gold Miner Roguelike are documented in this file.

## [0.0.1] — 2026-06-09

### Added

- Core claw-mining gameplay: swinging claw, extend/retract physics, weighted items
- Roguelike run loop with permadeath, run seeds, and scaling floor depth
- Procedural floor generation with structured gold veins (lane-based layout)
- Floor goals derived from on-map treasure (~55% of spawn value)
- Mineable items: gold (small/medium/large), diamond, rock, bone, dynamite
- Eight stackable run upgrades applied to claw stats (reel speed, rope length, swing, weight resistance, time, spawn odds)
- Treasure chests underground — hook with claw for mid-floor random stat drops
- Floor-clear reward chest with cinematic reveal (dim, shake, lid burst, flash, particles, rarity-colored loot text)
- Rarity-weighted chest loot: common, uncommon, rare, epic
- Local run records (best depth, best run earnings) via `user://roguelike_save.cfg`
- Pause menu: ESC to pause/resume, N for new run
- HUD: floor earnings, goal, timer, depth, run total

### Changed

- Replaced fixed five-level campaign with infinite procedural descent
- Replaced manual 1–2–3 upgrade picker with chest-based random loot
- Tuned early-floor balance: more resources, readable layouts, achievable goals
- Reorganized project into `game/` (data, systems, entities, scenes) and `assets/`
