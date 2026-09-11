extends RefCounted

## Integration fixtures acknowledge informational UI through production
## continuations. A choice must be specified by its test, never guessed here.
static func finish_day(test, state, db, rng) -> Dictionary:
	var result := RoundLoop.advance_day(state, db, rng)
	for _step in range(256):
		if state.round_transition.is_empty():
			return result
		if not state.pending_operations.is_empty():
			var pending: Dictionary = state.pending_operations[0]
			if not pending.get("choices", {}).is_empty():
				test.fail_test("Day fixture needs an explicit choice: %s" % pending.get("id", ""))
				return result
			OperationsSequence.resume(state.consume_pending_operation(), state, db, rng)
		result = RoundLoop.resume_day(state, db, rng)
	test.fail_test("Day continuation did not complete within 256 operations")
	return result
