# Faust - Sultan's Game Godot Prototype

A first playable Godot 4.6 prototype inspired by Sultan's Game, a narrative
card-battle game where you play a noble punished by the Sultan. Each week
you're forced to draw a Sultan card (kill/lust/luxury/conquer x
rock/bronze/silver/gold rank) that must be fulfilled within a time limit, or
the game ends.

## Status: v0.1.0 (first playable)

Core slices have been verified against the reverse-engineered `.c` source:
dice, counter, tag, loot, scope-filter, branch, settlement ordering, Sultan
card loop, and round/calendar. This is still a prototype: condition/result DSL
coverage and some UI flows are still being expanded.

## Systems implemented

- **Core rules engine** (`core/`): seeded RNG, weighted dice, counter
  add/sub/set with non-negative clamp, tag operations, loot tables,
  scope-filter bitmasks, branch choice/random operations
- **Data layer** (`data/`): loads real game data from JSON config copied from
  the reverse-engineering corpus
- **Simulation** (`sim/`): GameState, covered Condition DSL subset, Result DSL
  executor, RiteResolver prior/normal/extre settlement paths, SultanCards,
  RoundLoop, and SaveSystem
- **UI** (`ui/`): theme, card widget, main menu, game screen, rite selector,
  rite view with reactive gold dice, card detail overlay, debug tools, and
  game-over screen

## Fidelity verification

Implemented high-risk conclusions (direction, boundary, off-by-one, sign, and
clamp behavior) are verified against the decompiled `.c` source using the
`faust-clone-reference` workflow: one signal from `.c` code plus an independent
signal such as config data or dump symbols.

Key verified facts:

- Gold is the coin-card stack, not a counter.
- Gold dice are distinct from gold/coin.
- Dice success uses `die >= Y`; final success count is successes plus gold dice
  compared against `X`.
- Settlement prior/normal paths are first-match; extre executes all matching
  entries.
- Settlement entries execute `result` and `action`; extre runs all matched
  results before all matched actions.
- Sultan pool is a shuffled deck with last-first draw.
- Auto-begin rites start from the player's generated rite pool; they do not
  scan all config rites or automatically resolve results.

## Running

```powershell
# Run tests
$p = Start-Process -FilePath godot -ArgumentList @('--headless','--path','.', '--log-file','gut-test.log','--script','tools/run_gut.gd') -Wait -PassThru -WindowStyle Hidden
$p.ExitCode
Select-String -Path gut-test.log -Pattern 'Run Summary|Scripts|Tests|Passing Tests|Failing Tests|All tests'

# Launch the game
godot
```

## Testing

Tests use GUT (Godot Unit Test). Current headless verification covers 9 test
files across core systems, data loading, sim, Sultan cards, rite UI, selector,
save system, and end-to-end integration. Read `gut-test.log` for the current
pass/fail summary; Godot may still report resource/RID leak warnings at process
exit after a successful run.

## Developer tools

Debug builds expose a lightweight developer tools overlay from the title screen
and the in-game menu. It can start a normal run, start the explicit `init/1`
test-card profile, give a card by id, generate a rite by id, draw a Sultan card,
or clear the hand. Normal difficulty selection always uses the curated normal
starting hand; the large `init/1` `default_cards` list is only used when the
developer tool explicitly requests the test profile.

## Tech stack

- Engine: Godot 4.6
- Scripting: GDScript
- Testing: GUT
- Font: original game CJK body font (HYJieLongTaoHuaYuanW-2)

## License

This is a prototype for educational/research purposes. The original game and
its assets belong to their respective owners.
