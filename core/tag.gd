## Tag (标签) discrete operations.
## Re-confirmed vs decompiled/CardExtensions.c:
##   ConvertToAddOrSub (0x37f1c0): '+' gated by can_add flag (offset 0x40);
##     can_add==true → stack; can_add==false → only add if absent (else no-op).
##   RemoveTag (0x382e40): '-' decrements value, NO clamp-to-zero, negative
##     values persist (can_nagative_and_zero at offset 0x43 is display-only).
## [SRC: CardExtensions.c @ ConvertToAddOrSub (+) lines 928-983;
##       CardExtensions.c @ RemoveTag lines 2166-2191]
class_name TagSystem
extends RefCounted


enum Op { ADD = 0, SUB = 1, SET = 2 }


## Convert a result-key op char ('+'/'-'/'=') to an Op.
static func op_from_char(c: String) -> int:
	match c:
		"+":
			return Op.ADD
		"-":
			return Op.SUB
		"=":
			return Op.SET
	return -1


## Apply a tag op to a tag dictionary {tag_name: value}.
## `can_add`: whether the tag may stack (tag.json can_add flag). When false,
## ADD only proceeds if the tag is absent; a repeat ADD is a no-op.
## `effective_value`: the card's current GetTag result, used by the can_add
## gate. Callers that mutate the runtime delta must pass it, because the gate
## reads the whole tag row (definition + delta), not the delta alone.
## Returns true when the stored value actually changed, so callers can decide
## whether an operation is worth surfacing (see Result._mutate_tag).
## [SRC: CardExtensions.c @ ConvertToAddOrSub (0x37f1c0) '+' branch calls
##  GetTag and compares the result against 1; GetTag reads CardNode.tag@0x58
##  plus Card.tag@0x30, so a definition value alone already blocks the add.]
static func apply(
	tags: Dictionary,
	tag_name: String,
	op: int,
	amount: int = 1,
	can_add: bool = true,
	effective_value: int = -2147483648
) -> bool:
	if effective_value == -2147483648:
		effective_value = int(tags.get(tag_name, 0))
	var before := int(tags.get(tag_name, 0))
	match op:
		Op.ADD:
			if can_add or effective_value < 1:
				tags[tag_name] = before + amount
		Op.SUB:
			# Decrement without clamping: negative values persist in storage.
			# [SRC: CardExtensions.c @ RemoveTag: tagGroup[code] += (-amount),
			#  no clamp, no erase at <= 0]
			tags[tag_name] = before - amount
		Op.SET:
			tags[tag_name] = amount
	return int(tags.get(tag_name, 0)) != before


## Get a tag value (0 if absent).
static func get_value(tags: Dictionary, tag_name: String) -> int:
	return int(tags.get(tag_name, 0))
