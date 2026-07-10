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
## [SRC: CardExtensions.c @ ConvertToAddOrSub '+' branch: can_add==false and
##  GetTag>0 → zeroes delta (no-op); can_add==true → unchanged delta (stack)]
static func apply(tags: Dictionary, tag_name: String, op: int, amount: int = 1, can_add: bool = true) -> void:
	match op:
		Op.ADD:
			if can_add or int(tags.get(tag_name, 0)) < 1:
				tags[tag_name] = int(tags.get(tag_name, 0)) + amount
		Op.SUB:
			# Decrement without clamping: negative values persist in storage.
			# [SRC: CardExtensions.c @ RemoveTag: tagGroup[code] += (-amount),
			#  no clamp, no erase at <= 0]
			tags[tag_name] = int(tags.get(tag_name, 0)) - amount
		Op.SET:
			tags[tag_name] = amount


## Get a tag value (0 if absent).
static func get_value(tags: Dictionary, tag_name: String) -> int:
	return int(tags.get(tag_name, 0))
