## Sultan card (苏丹卡) system.
## spec sec 10.6, re-confirmed vs decompiled/GameController.c:
##   pool = pre-built deck (init sudan_pool array)
##   on draw: if sudan_shuffle flag -> ListExtensions.Shuffle(pool) once,
##            then RemoveLast (consume last-first)
##   redraw: re-insert discarded card at Random.Range(0, count)
##   empty pool -> no draw (HasMoreSudanCard checks count>0)
## Each sudan card id encodes action + rank:
##   2010001..2010004 = 杀戮(kill) 岩石/青铜/白银/黄金
##   2010005..2010008 = 纵欲(lust) ...
##   2010009..2010012 = 奢靡(luxury) ...
##   2010013..2010016 = 征服(conquer) ...
class_name SudanCards
extends RefCounted


# Action by id range (id - 2010001) / 4.
const ACTIONS := ["杀戮", "纵欲", "奢靡", "征服"]
# Rank by id % 4: 0=岩石(rock),1=青铜(bronze),2=白银(silver),3=黄金(gold).
const RANKS := ["岩石", "青铜", "白银", "黄金"]
# Rank precedence (higher rank required for higher-rank targets).
# 岩石 can target any; 青铜 can target 青铜+; 白银 targets 白银+; 黄金 only 黄金.


## Build and shuffle the sudan deck from the pool.
static func build_deck(rng, pool: Array, do_shuffle: bool) -> Array[int]:
	var deck: Array[int] = []
	for cid in pool:
		deck.append(int(cid))
	if do_shuffle:
		deck = rng.shuffle(deck)
	return deck


## Draw one card from the deck (consume last-first). Returns id or -1 if empty.
static func draw(deck: Array) -> int:
	if deck.is_empty():
		return -1
	return deck.pop_back()


## Has more cards to draw?
static func has_more(deck: Array) -> bool:
	return deck.size() > 0


## Redraw: re-insert the discarded card at a random position.
## [SRC: GameController.c @ RedrawSudanCard (0x5558b0): Random.Range(0,count)]
static func redraw(rng, deck: Array, discarded_id: int) -> void:
	var pos: int = rng.range_int(0, deck.size())
	deck.insert(pos, discarded_id)


## Decode a sudan card id into {action, rank, rank_index}.
static func decode(id: int) -> Dictionary:
	var base := id - 2010001
	if base < 0 or base > 15:
		return {}
	var action_idx := base / 4
	var rank_idx := base % 4
	return {
		"action": ACTIONS[action_idx],
		"rank": RANKS[rank_idx],
		"rank_index": rank_idx,
		"action_index": action_idx,
	}


## Whether a sudan card of `card_rank` can be satisfied by a target of `target_rank`.
## 岩石(0) can target any rank; 青铜(1) targets 青铜+; 白银(2) targets 白银+; 黄金(3) only 黄金.
## (A higher-rank card cannot be "wasted" on a lower-rank target per the game's rule.)
static func can_target(card_rank_idx: int, target_rank_idx: int) -> bool:
	# 岩石 card can target anything.
	if card_rank_idx == 0:
		return true
	# Otherwise the card rank must be <= target rank (can't use bronze on rock).
	return card_rank_idx <= target_rank_idx
