# Changelog

All notable changes to Gold Miner Roguelike are documented in this file.

## [0.0.3] — 2026-06-09

### Added

- **Tool & skill loadout** — separate gear types (Tools, Skills, Fusions) with 3-level upgrades
- **Chest draft picker** — choose 1 of 3 offerings with keys 1–3 (Vampire Survivors style)
- **Fusion recipes** — combine owned tool + skill pairs into evolved forms that replace parents
- Six fusions: Sky Drill, Snap Claw, Treasure Sense, Titan Grip, Gold Hour, Shatter Core
- Three tools: Iron Claw (starter), Magnet Hook, Blast Rig
- HUD loadout bar and fusion recipe hints on pause / chest screen

### Changed

- Chest loot no longer auto-grants a random buff — player always picks from a draft
- Claw stats computed from loadout modifiers instead of flat upgrade list
- Lucky Watch gives +5s per level (was +8s per stack)

## [0.0.2] — 2026-06-09

### Added

- **Combo streak system** — chain valuable grabs for x1.25 / x1.5 / x2.0 money multipliers
- Floating loot popups and screen punch feedback on big hauls
- **Dragon guardians** — patrolling lane hazards from depth 3+ (claw stun, −3s, combo break)
- **Cursed loot** — `cursed_idol` and `cursed_coin` traps that penalize earnings and break streaks
- **Dynamite chain reaction** — detonations destroy nearby treasure in a 120px radius
- **Jackpot Vault floors** (~7% chance) — dense loot, tighter timer, gold-tinted cave, always has a dragon
- Combo and vault bonuses improve chest loot rarity tiers
- HUD combo meter and vault depth indicator

### Changed

- Chest loot rolling accepts rarity bonus from hot streaks and vault clears
- Floor goal on vault floors uses 65% of spawn value (vs 55% normal)
- Vault floors subtract 15 seconds from the floor timer

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
