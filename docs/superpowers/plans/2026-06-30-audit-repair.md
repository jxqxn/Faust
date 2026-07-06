# Faust Audit Repair Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Repair the confirmed high-impact fidelity issues from `docs/AUDIT_2026-06-30.md` while preserving already-verified core mechanics.

**Architecture:** Fixes are staged from lowest-risk/highest-certainty to broader DSL coverage. Each behavior change gets a failing GUT test first, then minimal production code, then targeted verification. When `$faust-clone-reference` would stop for review, dispatch an independent subagent to re-check source/config/video evidence before implementation.

**Tech Stack:** Godot 4.6, GDScript, GUT, reverse-engineered `.c`/`dump.cs`/config JSON corpus.

---

## File Structure

- `docs/AUDIT_2026-06-30.md`: completed audit record and evidence ledger.
- `docs/superpowers/plans/2026-06-30-audit-repair.md`: this implementation plan.
- `sim/sudan_cards.gd`: Sultan card rank compatibility helper, currently correct after independent review.
- `tests/test_sudan.gd`: regression tests for rank compatibility.
- `sim/rite_resolver.gd`: execute settlement `action` alongside `result`.
- `sim/result.gd`: shared operation executor for keys currently used in `result` and `action`.
- `tests/test_sim.gd`: regression tests for action execution and selector/open-condition logic where possible.
- `ui/rite_view.gd`: preserve table cards outside current rite slots.
- `tests/test_rite_view.gd`: regression tests for persistent table state.
- `ui/rite_selector.gd`: evaluate `open_conditions` instead of skipping all gated rites.
- `README.md`: update fidelity and verification wording after fixes.

## Task 1: Sultan Card Rank Compatibility Regression Test

**Files:**
- Test: `tests/test_sudan.gd`

- [x] **Step 1: Independent evidence review**

Dispatch a subagent with:

```text
Read C:\Users\User\.codex\skills\faust-clone-reference\SKILL.md and docs/AUDIT_2026-06-30.md.
Review Finding 1 only. Verify whether Sultan card rank compatibility should be target_rank >= card_rank.
Use at least two signals from the audit/corpus/video notes/config. Report SUPPORTS, CONFLICT, or RUNTIME_OPEN and cite the evidence category.
Do not edit files.
```

Result: independent review returned SUPPORTS. The current implementation is equivalent to `target_rank_idx >= card_rank_idx`; no production change is required.

- [x] **Step 2: Strengthen the regression test**

Replace `test_can_target_rank_rules` in `tests/test_sudan.gd` with:

```gdscript
func test_can_target_rank_rules():
	# Higher-rank targets can satisfy lower-rank Sultan cards.
	assert_true(SudanCards.can_target(0, 0), "rock target satisfies rock card")
	assert_true(SudanCards.can_target(0, 3), "gold target satisfies rock card")
	assert_true(SudanCards.can_target(1, 2), "silver target satisfies bronze card")
	assert_true(SudanCards.can_target(2, 3), "gold target satisfies silver card")
	# Lower-rank targets cannot satisfy higher-rank Sultan cards.
	assert_false(SudanCards.can_target(1, 0), "rock target cannot satisfy bronze card")
	assert_false(SudanCards.can_target(3, 2), "silver target cannot satisfy gold card")
	assert_true(SudanCards.can_target(3, 3), "gold target satisfies gold card")
```

- [ ] **Step 3: Run test to verify it passes**

Run:

```powershell
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_sudan.gd -gexit
```

Expected: `test_can_target_rank_rules` passes. If GUT does not print visible output, fix the test command before claiming pass.

## Task 2: Settlement Action Execution

**Files:**
- Modify: `sim/rite_resolver.gd`
- Test: `tests/test_sim.gd`

- [x] **Step 1: Write failing tests**

Added to `tests/test_sim.gd`:

- `test_settlement_prior_executes_action_after_result`
- `test_settlement_normal_executes_action_after_result`
- `test_settlement_action_can_defer_over`
- `test_settlement_extre_executes_all_results_before_actions`

- [x] **Step 2: Verify RED**

Run:

```powershell
godot --headless --path . --log-file gut-test.log --script tools/run_gut.gd
```

Observed RED: 4 failing tests. Existing `result` assertions passed; action assertions failed for `event_on`, `rite`, `over`, and extre action ordering/coin count.

- [x] **Step 3: Implement action merge with source-confirmed extre ordering**

In `sim/rite_resolver.gd`:

- `settlement_prior`: first match executes `result`, then `action`.
- `settlement`: first match executes `result`, then `action`.
- `settlement_extre`: collect all matching entries, execute all `result` operations first, then execute all `action` operations.

Evidence: `OperationsExtensions.c @ Start (RVA 0x500dc0)` loops all settlement `+0x30` result entries before looping all settlement `+0x38` action entries.

- [x] **Step 4: Verify GREEN**

Run the same full GUT command. Observed GREEN:

- `Scripts 8`
- `Tests 78`
- `Passing Tests 78`
- `Asserts 751`
- `---- All tests passed! ----`

Residual verification note: Godot still reports resource/RID leak warnings at process exit; this predates Task 2 and remains a test-environment cleanup issue.

- [x] **Step 5: Independent review gate**

Subagent Meitner gave `PASS_WITH_CONCERNS` before implementation: proceed, but add SRC pointers and cover `settlement_prior`, extre two-stage ordering, and at least one non-event/rite action. The implemented tests and audit update address those concerns.

## Task 3: Preserve Non-Rite Table Cards

**Files:**
- Modify: `ui/rite_view.gd`
- Test: `tests/test_rite_view.gd`

- [x] **Step 1: Write failing test**

Implemented `test_prepare_table_preserves_cards_outside_placed_slots` in `tests/test_rite_view.gd`. It verifies:

- An unrelated table card in slot 3 is preserved.
- A currently placed slot 1 card is replaced with the current placement.
- `test_prepare_table_clears_slots_cancelled_after_prior_placement` verifies that a slot previously managed by this RiteView is cleared if the placement is cancelled, while unrelated table cards still remain.

- [x] **Step 2: Verify RED**

Run:

```powershell
$p = Start-Process -FilePath godot -ArgumentList @('--headless','--path','.', '--log-file','gut-test.log','--script','tools/run_gut.gd') -Wait -PassThru -WindowStyle Hidden
```

Observed RED: `test_prepare_table_preserves_cards_outside_placed_slots` failed because unrelated table cards were cleared.

- [x] **Step 3: Implement minimal preservation**

Changed `_prepare_table_from_placements()` so it removes only slots present in `_placed`, then appends current placements:

```gdscript
func _prepare_table_from_placements() -> void:
	var slots_to_clear := _managed_slots.duplicate()
	for slot_key in _placed:
		var slot_num: int = slot_key.substr(1).to_int()
		if slot_num not in slots_to_clear:
			slots_to_clear.append(slot_num)
	for slot_num in slots_to_clear:
		_state.clear_slot(slot_num)
	_managed_slots.clear()
	for slot_key in _placed:
		var slot_num: int = slot_key.substr(1).to_int()
		_managed_slots.append(slot_num)
		_state.add_card_to_slot(int(_placed[slot_key]), slot_num, _db)
```

- [x] **Step 4: Verify GREEN**

Observed GREEN:

- `Scripts 8`
- `Tests 80`
- `Passing Tests 80`
- `Asserts 758`
- `---- All tests passed! ----`

Residual verification note: Godot still reports resource/RID leak warnings at process exit.

- [x] **Step 5: Independent review gate**

Subagent Kierkegaard returned `PASS_WITH_CONCERNS`: the implementation preserved unrelated slots and replaced placed slots, but cancellation could leave a previously placed slot behind. Added the cancellation regression test and `_managed_slots` tracking; GREEN rerun passed 80/80 tests.

## Task 4: Open-Condition Evaluation in Rite Selector

**Files:**
- Modify: `ui/rite_selector.gd`
- Test: `tests/test_sim.gd` or a new focused UI test if needed

- [x] **Step 1: Add selector state dependency**

Inspected `ui/game.gd` and `ui/rite_selector.gd`; implemented `RiteSelector.setup(db, state = null, rng = null)` and changed `ui/game.gd` to pass current `state/rng`.

- [x] **Step 2: Write failing test**

Added `tests/test_rite_selector.gd`:

```gdscript
func test_selector_shows_rite_when_open_conditions_are_satisfied():
	# Construct a playable rite with non-empty open_conditions and an empty
	# condition dictionary, which evaluates true.
```

Observed RED: selector rendered 0 buttons because it skipped every non-empty `open_conditions` array.

- [x] **Step 3: Implement minimal selector behavior**

Replace the skip-all-gated logic:

```gdscript
if oc is Array and not oc.is_empty():
	continue
```

with `_is_rite_open(rite)`, which evaluates each `entry.condition` through `ConditionEval.evaluate`.

- [x] **Step 4: Verify GREEN**

Observed GREEN:

- `Scripts 9`
- `Tests 84`
- `Passing Tests 84`
- `Asserts 762`
- `---- All tests passed! ----`

Residual verification note: Godot still reports resource/RID leak warnings at process exit.

- [x] **Step 5: Independent review gate**

Subagent Bernoulli returned `PASS_WITH_CONCERNS`: the core fix direction was supported, but unsatisfied conditions, multi-entry open-condition behavior, and no-state setup needed explicit coverage. Added tests for:

- `test_selector_hides_rite_when_open_condition_is_unsatisfied`
- `test_selector_requires_all_open_conditions_current_assumption`
- `test_selector_fails_closed_without_state_for_non_empty_condition`

Current implementation treats multiple `open_conditions` as conservative AND semantics pending stronger source evidence, and fails closed for non-empty conditions when no `GameState` is available.

## Task 5: README Honesty Pass

**Files:**
- Modify: `README.md`

- [x] **Step 1: Update wording**

Replaced "faithful clone" and "full dispatch" language with first playable prototype / verified core slices / covered DSL subset wording.

- [x] **Step 2: Update test command statement**

Removed the obsolete fixed-count claim and documented the current `tools/run_gut.gd` headless command. README now points readers to `gut-test.log` for the latest pass/fail summary, with resource/RID leak warnings noted as possible process-exit noise.

- [x] **Step 3: Verify documentation consistency**

Search for overstated claims:

```powershell
rg -n "faithful|full dispatch|64/64|All 6 core systems" README.md docs
```

Observed: current README no longer contains unsupported `faithful`, `full dispatch`, `64/64`, or `All 6 core systems` claims. Older planning/spec/audit docs may still quote historical claims as evidence.

## Verification

Run targeted tests after each task. Before final completion, run:

```powershell
$p = Start-Process -FilePath godot -ArgumentList @('--headless','--path','.', '--log-file','gut-test.log','--script','tools/run_gut.gd') -Wait -PassThru -WindowStyle Hidden
```

Read `gut-test.log` for the GUT summary. The old `gut_cmdln.gd` command can print only the engine banner in this Windows/Godot 4.6 setup.
