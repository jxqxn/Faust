## Typed data models loaded from the config JSON.
## Cards/Rites/Loot/Tags live as plain Dictionaries in the DB; these helpers
## provide typed accessors and constructors where the simulation needs them.
class_name GameModels
extends RefCounted


# ---- Card ----
# Raw shape (cards.json): {id,name,title,text,type,rare,tag{...},equips[],is_only,resource,vanish{}}
# type: "char" | "item" | "sudan"
# tag: {tag_name: int_value}  (attributes like 智慧/社交/体魄/魅力 plus traits like 男性/贵族)
# rare:品级 proxy (the actual rank is encoded in tags like 岩石/青铜/白银/黄金)

## Return a card's tag value (0 if absent).
static func card_tag(card: Dictionary, tag_name: String) -> int:
	return int(card.get("tag", {}).get(tag_name, 0))


## Sum the named attributes for a card (e.g. ["智慧","社交"]).
static func card_attr_sum(card: Dictionary, attrs: Array) -> int:
	var s := 0
	for a in attrs:
		s += card_tag(card, a)
	return s


## Whether a card has a non-zero tag.
static func card_has_tag(card: Dictionary, tag_name: String) -> bool:
	return card_tag(card, tag_name) != 0


## The coin card id (verified-correction from spec sec 10.2: gold is a CARD stack, id 2000093).
const COIN_CARD_ID := 2000093
## Gold dice counter id (vc#3).
const GOLD_DICE_COUNTER_ID := 7100006


# ---- Rite ----
# Raw shape (rite/<id>.json): {id,name,text,cards_slot{s1..s4},settlement_prior[],settlement[],settlement_extre[],open_conditions[],random_text{},auto_begin,auto_result,round_number,waiting_round,location,icon,tag_tips[]}
# Each settlement entry: {guid,condition{},result_title,result_text,result{},action{}}

## Get the slotted card ids for a rite instance {s1..s4 -> card_id or null}.
static func rite_slots(rite_state: Dictionary) -> Array:
	return [rite_state.get("s1"), rite_state.get("s2"), rite_state.get("s3"), rite_state.get("s4")]


# ---- Init / Difficulty ----
# Raw shape (init/1.json): {difficulty[], sudan_pool[], sudan_shuffle,
# default_cards[], sudan_redraw_times_per_round,
# sudan_redraw_times_recovery_round}. In this clone, init/1 default_cards is
# kept as an explicit test profile; normal runs use ConfigDB's curated start.

## Extract a difficulty's dice face weights as an Array.
static func difficulty_weights(diff_entry: Dictionary) -> Array:
	return diff_entry.get("single_dice_face_weight", [100,100,100,100,100,100])


## Tag id/name/code map (tag.json): {code: {id,name,code,type,...}}.
## Attributes are tags whose type is "buff" and name in the attribute set.
# Attribute names (from tag.json type=buff): 体魄 魅力 智慧 隐匿 社交 理智 ...
const ATTR_NAMES := ["体魄", "魅力", "智慧", "社交", "理智", "隐匿", "体魄", "灵巧"]


## Resolve an attribute expression token to a tag name. If it's already a name
## (智慧), return it; if it's a code, look it up in tag.json.
## The tag.json map is {code -> {name}}.
static func resolve_attr_name(token: String, tag_map: Dictionary) -> String:
	if tag_map.has(token):
		return tag_map[token].get("name", token)
	return token
