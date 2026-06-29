## Tag (标签) discrete operations.
## verified-conclusions.md #15, pitfall #5. Re-confirmed vs
## decompiled/ModifyTag.c @ PreDo (0x523780):
##   '+' -> add tag, '-' -> remove tag (only if GetTag > 0),
##   '=' -> assign (set) tag. NO numeric clamping; tags are discrete.
## Tag values live on a TagGroup; this module provides the op primitives.
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


## Apply a tag op to a tag dictionary {tag_name: value}. Returns the new value.
## ADD increments, SUB decrements (and removes if it reaches/below 0 per
## ConvertToAddOrSub's GetTag>0 guard), SET assigns.
static func apply(tags: Dictionary, tag_name: String, op: int, amount: int = 1) -> void:
	match op:
		Op.ADD:
			tags[tag_name] = int(tags.get(tag_name, 0)) + amount
		Op.SUB:
			var cur := int(tags.get(tag_name, 0))
			var nv := cur - amount
			if nv > 0:
				tags[tag_name] = nv
			else:
				tags.erase(tag_name)
		Op.SET:
			tags[tag_name] = amount


## Get a tag value (0 if absent).
static func get_value(tags: Dictionary, tag_name: String) -> int:
	return int(tags.get(tag_name, 0))
