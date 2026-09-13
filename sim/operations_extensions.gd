## Serializable counterpart of the event operation Promise sequence.
## [SRC: OperationsExtensions.Start 0x500a70 -> ListExtensions.DoSequence
## 0x38b120 -> Promise.Sequence; dump.cs:311993-312024.]
## Frames retain raw payloads and explicit key order across JSON save/load.
## RiteSettlement uses these sequences for manual, next-day and Think results.
class_name OperationsSequence
extends RefCounted

static func start(payloads: Array, state, db, rng, context: Dictionary = {}, initial_status: int = 0) -> Dictionary:
	var sequence := {"frames": [], "context": ResultExec._queue_context(context), "status": initial_status, "tag": ""}
	for i in range(payloads.size() - 1, -1, -1):
		_push(sequence, payloads[i])
	return _run(sequence, state, db, rng)


static func _push(sequence: Dictionary, payload: Variant, keys: Array = []) -> void:
	# Outer save JSON sorts dictionaries. Retain raw nested operation order too,
	# including a case body that has not been entered at the save boundary.
	var operations := SourceJSON.entries(payload)
	if not keys.is_empty():
		operations = keys.map(func(index): return operations[index])
	sequence.frames.append({"operations_json": JSON.stringify(operations, "", false), "index": 0})


static func _attach(operation: Dictionary, sequences: Array) -> void:
	if not operation.has("continuations"):
		operation.continuations = []
	operation.continuations.append_array(sequences)


## Called once, after removing the completed UI operation from the queue.
static func resume(operation: Dictionary, state, db, rng, choice_key: String = "") -> void:
	var sequences: Array = operation.get("continuations", [])
	var response: Dictionary = operation.get("sequence_response", {})
	if not sequences.is_empty() and not response.is_empty():
		var owner: Dictionary = sequences[0]
		if response.kind == "option":
			if not response.choices.has(choice_key):
				return
			var selection: Dictionary = response.choices[choice_key]
			owner.status = int(selection.index) + 3
			owner.tag = str(selection.tag)
		elif response.kind == "confirm":
			owner.status = 1 if choice_key == "confirm_cancel" else 0
			owner.tag = ""
			state.last_confirm_cancelled = choice_key == "confirm_cancel"
	for i in range(sequences.size()):
		if not state.pending_operations.is_empty():
			_attach(state.pending_operations.back(), sequences.slice(i))
			return
		_run(sequences[i], state, db, rng)


static func _run(sequence: Dictionary, state, db, rng) -> Dictionary:
	var summary := ResultExec.execute({}, state, db)
	if state.over_pending:
		summary.over = true
		sequence.frames.clear()
		return summary
	if not state.pending_operations.is_empty():
		_attach(state.pending_operations.back(), [sequence])
		return summary
	var context: Dictionary = sequence.context.duplicate(true)
	context["state"] = state
	context["db"] = db
	context["rng"] = rng
	while not sequence.frames.is_empty():
		# [SRC: OperationsExtensions.DoWrapper 0x500510 rejects further
		# operations after GameController.gameover, including nested events.]
		if state.over_pending:
			summary.over = true
			sequence.frames.clear()
			return summary
		var frame: Dictionary = sequence.frames.back()
		var operations: Array
		if frame.has("operations_json"):
			operations = JSON.parse_string(frame.operations_json)
		else:
			# Older saves stored unique-key frames.
			var legacy: Dictionary = JSON.parse_string(frame.source_json)
			operations = frame.keys.map(func(key): return {key: legacy[key]})
		if int(frame.index) >= operations.size():
			# NoPromptOperations.Do 0x5001f0 / completion0x506390 restores
			# the entry text after nested work, even when it suspended for UI.
			if frame.has("restore_pre_extra_result"):
				sequence["pre_extra_result"] = str(frame.restore_pre_extra_result)
			sequence.frames.pop_back()
			continue
		var entry: Dictionary = operations[int(frame.index)]
		var key: String = entry.keys()[0]
		frame.index = int(frame.index) + 1
		var value = entry[key]
		# Prompt.Do 0x519340 reads and clears OperationContext.preExtraResult,
		# then appends it with stringliteral0x25ACA58 (newline). Keep this text
		# in the serializable sequence rather than a transient UI queue.
		if key == "prompt" and value is Dictionary:
			var extra: String = str(sequence.get("pre_extra_result", ""))
			sequence["pre_extra_result"] = ""
			if not extra.is_empty():
				value = value.duplicate(true)
				value["text"] = str(value.get("text", "")) + "\n" + extra
		var no_prompt := key == "no_prompt" or key.begins_with("no_prompt:")
		if (value is Dictionary or value is Array) and (key in ["all", "no_show"] or no_prompt):
			_push(sequence, value)
			if no_prompt:
				sequence.frames.back()["restore_pre_extra_result"] = str(sequence.get("pre_extra_result", ""))
			continue
		if (value is Dictionary or value is Array) and (key in ["success", "failed"] or key.begins_with("case:")):
			# Unmatched branches preserve the status; only an executed branch resets.
			# [SRC: SuccessOperations.Do 0x3a7930; FailedOperations.Do 0x39d5a0;
			# CaseOperations.Do 0x399570; Option callback 0x51f250.]
			var matched := false
			if key == "success":
				matched = int(sequence.status) != 1
			elif key == "failed":
				matched = int(sequence.status) == 1
			else:
				var tag := key.substr(5)
				matched = int(tag) == int(sequence.status) - 2 if tag.is_valid_int() else tag == str(sequence.tag)
				matched = matched or (tag == "def" and int(sequence.status) - 2 >= 3)
			if matched:
				sequence.status = 0
				sequence.tag = ""
				_push(sequence, value)
			continue
		if (value is Dictionary or value is Array) and (key == "choose" or key.begins_with("choose:")):
			var keys: Array = range(SourceJSON.entries(value).size())
			var count := maxi(1, int(key.substr(7))) if key.begins_with("choose:") else 1
			# [SRC: ChooseOperations.GetOperations 0x4f3830: N > Count keeps order.]
			if count <= keys.size():
				for i in range(keys.size() - 1, 0, -1):
					var j: int = rng.range_int(0, i) if rng != null else randi_range(0, i)
					var temp = keys[i]
					keys[i] = keys[j]
					keys[j] = temp
				keys = keys.slice(0, count)
			_push(sequence, value, keys)
			continue
		var response: Dictionary = {}
		if key == "option" and value is Dictionary:
			var prompt: Dictionary = value.duplicate(true)
			prompt["context"] = sequence.context
			prompt["choices"] = {}
			response = {"kind": "option", "choices": {}}
			var items: Array = value.get("items", [])
			for i in range(items.size()):
				var choice := "option:%d" % i
				prompt.choices[choice] = {"text": str(items[i].get("text", "")), "value": i}
				response.choices[choice] = {"index": i, "tag": str(items[i].get("tag", ""))}
			state.queue_prompt(prompt)
			summary.choose = prompt
		else:
			var previous_rite: int = state.active_rite_uid
			state.active_rite_uid = int(context.get("rite_uid", previous_rite))
			var deferred := ResultExec.execute({key: value}, state, db, context)
			state.active_rite_uid = previous_rite
			RiteSettlement.record(context, deferred, state)
			# EventOn start_trigger is a nested sequence, not a synthetic event panel.
			# [SRC: EventOn callback 0x51f1a0 -> EventTrigger.Add 0x4fa9d0.]
			var effects: Array = deferred.get("ordered_effects", [])
			if effects.is_empty():
				DeferredEffects.apply(deferred, state, db, rng)
			else:
				for effect in effects:
					if effect.kind == "event":
						DeferredEffects.execute_event(db.get_event(int(effect.payload.id)), state, db, rng, context)
					elif effect.kind == "rite":
						var born_uid: int = DeferredEffects._add_rite_and_note(int(effect.payload.id), state, db, rng)
						_append_rite_start_result(sequence, born_uid, state, db)
					else:
						DeferredEffects._apply_ordered_effect(effect, state, db, rng)
			DeferredEffects._merge(summary, deferred)
			if bool(deferred.get("over", false)):
				state.over_pending = true
				sequence.frames.clear()
				return summary
			if key == "confirm":
				response = {"kind": "confirm"}
		if not state.pending_operations.is_empty():
			var operation: Dictionary = state.pending_operations.back()
			if not response.is_empty():
				operation["sequence_response"] = response
			_attach(operation, [sequence])
			return summary
	return summary


## [SRC: StartRite.Do 0x51bcf0 -> AddExtraResult_RiteStart 0x39f810;
## dump.cs:392398 Rite.new_born@0x20. The source guards new_born, not is_show.
## OperationContext.AddExtraResult 0x39fa10 joins using PROMPT_RESULT_SEPERATOR;
## UI template0x258CDD0 = PROMPT_RITE_START_RESULT.]
static func _append_rite_start_result(sequence: Dictionary, uid: int, state, db) -> void:
	var rite = state.get_rite_instance(uid)
	if rite == null or not rite.new_born:
		return
	var text: String = db.translate("PROMPT_RITE_START_RESULT")
	text = text.replace("{0}", state.rite_display_name(rite.id, db))
	# Current source template uses only {0}; do not invent a location label.
	var previous: String = str(sequence.get("pre_extra_result", ""))
	if not previous.is_empty():
		previous += str(db.variable_config.get("PROMPT_RESULT_SEPERATOR", ""))
	sequence["pre_extra_result"] = previous + text
