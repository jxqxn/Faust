# Faust — 苏丹的游戏 Godot 克隆

A faithful Godot 4.6 clone of《苏丹的游戏》, a narrative card-battle game
where you play a noble punished by the Sultan. Each week you're forced to
draw a 苏丹卡 (kill/lust/luxury/conquer × rock/bronze/silver/gold rank)
that must be fulfilled within a time limit, or the game ends.

## Status: v0.1.0 (first playable)

All 6 core systems verified against the reverse-engineered `.c` source:
dice, counter, tag, loot, scope-filter, branch. The settlement pipeline,
sudan card loop, and round/calendar are functional. 64/64 tests pass.

## Systems implemented

- **Core rules engine** (`core/`): seeded RNG, weighted dice (success ⟺
  die ≥ Y), counter (add/sub/set with non-negative clamp), tag (discrete
  ±=), loot (SimpleWeightLoot / WeightedNChooseM), scope-filter (bitmask),
  branch (ChooseOperations / RandomOperations)
- **Data layer** (`data/`): loads real game data (1400+ cards, 1495 rites,
  193 loot tables, tags, init config) from JSON config copied from corpus
- **Simulation** (`sim/`): GameState, Condition DSL evaluator (full dispatch
  from dump.cs), Result DSL executor, RiteResolver (prior/normal/extre),
  SudanCards (shuffled deck, last-first draw), RoundLoop (day/round,
  deadlines, auto-rites), SaveSystem (JSON)
- **UI** (`ui/`): theme with original game CJK font, card widget, main menu
  (difficulty select), game screen (HUD/sudan/hand/actions/log), rite
  selector (830 rites by location), rite view (slots/dice/reactive gold
  dice/settlement), game over screen

## Fidelity verification

Every high-risk conclusion (direction/boundary/off-by-one) was verified
against the decompiled `.c` source using the faust-clone-reference skill's
dual-signal rule: one signal from `.c` code + one independent signal
(config desc, save sample, or authoritative machine).

Key verified facts:
- Gold = coin CARD stack (id 2000093), not a counter
- Gold dice = Counter 7100006, distinct from gold/coin
- Dice success ⟺ die ≥ Y(=5), final = successes + goldDice vs X
- Settlement: prior/normal = first-match mutually exclusive; extre = all match
- Sudan pool = shuffled deck, RemoveLast (not weighted sampling)
- Auto-rites fire per-round via OnBeginRound, not per-day

## Running

```powershell
# Run tests (64/64)
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit

# Launch the game
godot
```

## Testing

Tests use GUT (Godot Unit Test). 7 test files covering core systems, data
layer, sim, sudan cards, save system, and end-to-end integration.

## Tech stack

- Engine: Godot 4.6
- Scripting: GDScript
- Testing: GUT
- Font: original game CJK body font (HYJieLongTaoHuaYuanW-2)

## License

This is a clone for educational/research purposes. The original game and
its assets belong to their respective owners.
