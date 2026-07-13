# Faust - Sultan's Game Godot Prototype

A first playable Godot 4.7 prototype inspired by Sultan's Game, a narrative
card-battle game where you play a noble punished by the Sultan. Each week
you're forced to draw a Sultan card (kill/lust/luxury/conquer x
rock/bronze/silver/gold rank) that must be fulfilled within a time limit, or
the game ends.

## Status: v0.1.0 (first playable)

Core slices have been verified against the reverse-engineered `.c` source:
dice, counter, tag, loot, scope-filter, branch, settlement ordering, Sultan
card loop, round/calendar, and the shared desktop event/prompt surface. This is
still a prototype: condition/result DSL coverage is visible through tests and
keeps expanding with each newly enabled content batch.

Runtime cards use stable `CardInstance` identities. Mutable tags, stack count,
loss state, and hand/slot/Sultan placement belong to the instance rather than
the immutable card definition. Rite slot ownership is keyed by card UID, and
save version 5 persists those instances; version 4 and older saves are
intentionally rejected and do not expose Continue.

Runtime events, prompts and choices share one FIFO `pending_operations` queue.
Every entry retains its event/prompt payload plus `card_uid`, `rite_uid` and
trigger context, so two occurrences of the same event remain independent.
Delayed operations are persisted separately and execute once at the Next Day
boundary. Existing v5 saves without these optional fields are synthesized from
their legacy split queues; v4 and older saves remain rejected.

## Systems implemented

- **Core rules engine** (`core/`): seeded RNG, weighted dice, counter
  add/sub/set with non-negative clamp, tag operations, loot tables,
  scope-filter bitmasks, branch choice/random operations
- **Data layer** (`data/`): loads real game data from JSON config copied from
  the reverse-engineering corpus
- **Simulation** (`sim/`): GameState, covered Condition DSL subset, Result DSL
  executor, deferred event/choice/loot effect application, RiteResolver
  prior/normal/extre settlement paths, SultanCards, RoundLoop, and SaveSystem
- **UI** (`ui/`): theme, card widget, main menu, game screen, rite selector,
  rite view with reactive gold dice, desktop I-think drop target, event/prompt
  overlay, card detail overlay, title-screen test start entry, and game-over
  screen

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

Tests use GUT (Godot Unit Test). Run `tools/run_gut.ps1`; it fails on test
failures, `SCRIPT ERROR`, `ERROR`, orphan counts, and leak diagnostics. The
suite covers core systems, data loading, simulation,
runtime card instances, Sultan cards, rite UI, save system, and end-to-end
integration including first-week queue/DSL regressions. The runner accepts `-GodotPath`, then checks `GODOT_BIN`, the
verified local Godot 4.7 path, and finally PATH.

Export the current condition/result/action coverage report when deciding which
content batch to implement next. The report records every unsupported key with
its config type, ID, JSON path, and field location:

```powershell
godot --headless --path . --script tools/export_dsl_audit.gd
```

It writes `dsl_audit.json` and `dsl_audit.md` under `user://dsl_audit` by
default. The report marks each source with a conservative static reachability
hop count from normal-start roots through implemented rite, event, loot, and
card generation edges. It is a prioritization aid, not proof that a condition
branch fires in a real run. Pass `-- --out user://another_folder` to choose a
different user-data folder without modifying tracked content.

## Developer test start

Debug builds expose a single `Test Start` entry on the title screen. It starts
the explicit `init/1` test-card profile for fast local verification. Normal
difficulty selection always uses the curated normal starting hand; the large
`init/1` `default_cards` list is only used by this explicit test entry.

Continue is shown only for valid version-5 player saves. Older raw JSON files,
test data, and v4-or-earlier saves are rejected without deleting the source
file, and they do not light up the player-facing continue button.

Manual archives are separate from the current continue save. The title screen
lists valid named archives for load or deletion; the in-game menu can create a
new archive or overwrite a selected one. Archives use a 50-slot index under
`user://user_archives`; loading one refreshes `user://save.json` as the
current continue save, and deleting one removes both its index entry and JSON
payload.

The currently accepted first-week content scope is governance, I-think, book
shop/search and the tagged Sultan -> Power Game chain. The full configuration
set is not claimed complete: `tools/export_dsl_audit.gd` continues to report
unsupported keys with their source IDs and locations.

## Tech stack

- Engine: Godot 4.7
- Scripting: GDScript
- Testing: GUT
- Font: original game CJK body font (HYJieLongTaoHuaYuanW-2)

## License

This is a prototype for educational/research purposes. The original game and
its assets belong to their respective owners.
