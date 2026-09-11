## One entry of the un-drawn Sultan pool.
##
## The original keeps `player.sudan_card_pool` as a List<Card> (player+0xB0),
## not a list of config ids: every entry is a full Card object with its own uid,
## count, life and runtime tag delta. The corpus sample proves the pool really
## holds duplicate ids (27 entries over 16 distinct card ids), so keying runtime
## state by card id loses real objects.
## [SRC: dump.cs Player.sudan_card_pool (void* @0xB0, List<Card>);
##       Player.c .ctor 0x3a5000 writes a fresh List to +0xB0;
##       GameController.c @ GenSudanCard (0x54f6f0) reads player+0xB0, removes
##       the chosen object from that list and hands the SAME object to
##       PlayerExtensions.AddCard / MarkCardGen / PutCardOnTable;
##       GameController.c @ RedrawSudanCard (0x5558b0) re-inserts the discarded
##       Card object at Random.Range(0, pool.count).]
##
## `tag` is the runtime delta (Card.tag@0x30), read through GameState's
## effective-row helpers exactly like a drawn CardInstance.
class_name SudanPoolCard
extends RefCounted
var uid := 0
var card_id := 0
var count := 1
## Elapsed days carried by the pool object (Card.life@0x24). The corpus pool
## entries all sit at 0; a redrawn discard re-enters with its own value.
var life := 0
var tags: Dictionary = {}
## Player.sudan_pool_pos@0xB8 bookkeeping; the original stores it on Player, the
## clone keeps it per entry so the array survives a save round trip.
var pos := 0


func _init(instance_uid: int = 0, definition_id: int = 0) -> void:
	uid = instance_uid
	card_id = definition_id


func duplicate_entry():
	# Self-instantiation stays preload-free: the global class table only knows
	# this class after an editor scan, so never spell the class name here.
	var copy = get_script().new(uid, card_id)
	copy.count = count
	copy.life = life
	copy.tags = tags.duplicate(true)
	copy.pos = pos
	return copy


## Save row. Mirrors the original Card serialization: the definition stays in
## config and only the runtime delta is written.
func to_save_dict() -> Dictionary:
	return {
		"uid": uid,
		"card_id": card_id,
		"count": count,
		"life": life,
		"tags": tags.duplicate(true),
		"pos": pos,
	}


static func from_save_dict(data: Dictionary):
	var entry = new(
		int(data.get("uid", 0)),
		int(data.get("card_id", data.get("id", 0)))
	)
	entry.count = maxi(int(data.get("count", 1)), 1)
	entry.life = int(data.get("life", 0))
	entry.pos = int(data.get("pos", 0))
	var saved_tags: Variant = data.get("tags", data.get("tag", {}))
	if saved_tags is Dictionary:
		entry.tags = saved_tags.duplicate(true)
	return entry
