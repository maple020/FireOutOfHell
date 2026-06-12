class_name DeckManager
extends Node
## 管理战斗内的抽牌堆、手牌、弃牌堆与永劫堆。

signal deck_initialized(deck_size: int)
signal piles_changed
signal hand_changed(hand: Array[CardData])
signal cards_drawn(cards: Array[CardData])
signal discard_reshuffled(draw_pile_size: int)
signal card_discarded(card: CardData)
signal card_exhausted(card: CardData)

const DEFAULT_HAND_LIMIT := 5

var hand_limit: int = DEFAULT_HAND_LIMIT

var _draw_pile: Array[CardData] = []
var _hand: Array[CardData] = []
var _discard_pile: Array[CardData] = []
var _exhaust_pile: Array[CardData] = []
var _combat_deck: Array[CardData] = []

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func initialize(deck_list: Array[CardData], seed_value: int = -1, new_hand_limit: int = DEFAULT_HAND_LIMIT) -> void:
	hand_limit = max(new_hand_limit, 0)
	_hand.clear()
	_discard_pile.clear()
	_exhaust_pile.clear()
	_combat_deck = deck_list.duplicate()
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	_draw_pile = _combat_deck.duplicate()
	_shuffle_draw_pile()
	deck_initialized.emit(_combat_deck.size())
	_emit_pile_updates()


func set_seed(seed_value: int) -> void:
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()


func set_hand_limit(new_hand_limit: int) -> void:
	hand_limit = max(new_hand_limit, 0)
	_emit_pile_updates()


func draw_cards(amount: int) -> Array[CardData]:
	var drawn_cards: Array[CardData] = []
	if amount <= 0:
		return drawn_cards

	var draw_count: int = min(amount, max(hand_limit - _hand.size(), 0))
	while drawn_cards.size() < draw_count:
		if _draw_pile.is_empty():
			if _discard_pile.is_empty():
				break
			_reshuffle_discard_into_draw_pile()

		if _draw_pile.is_empty():
			break

		var card: CardData = _draw_pile.pop_back()
		_hand.append(card)
		drawn_cards.append(card)

	if not drawn_cards.is_empty():
		cards_drawn.emit(drawn_cards)
		_emit_pile_updates()

	return drawn_cards


func draw_to_hand_limit() -> Array[CardData]:
	return draw_cards(hand_limit - _hand.size())


func discard_hand() -> Array[CardData]:
	var discarded_cards: Array[CardData] = _hand.duplicate()
	if discarded_cards.is_empty():
		return discarded_cards

	for card in discarded_cards:
		_discard_pile.append(card)
		card_discarded.emit(card)
	_hand.clear()
	_emit_pile_updates()
	return discarded_cards


func discard_card(card: CardData) -> bool:
	var hand_index: int = _hand.find(card)
	if hand_index == -1:
		return false

	_hand.remove_at(hand_index)
	_discard_pile.append(card)
	card_discarded.emit(card)
	_emit_pile_updates()
	return true


func exhaust_card(card: CardData) -> bool:
	var hand_index: int = _hand.find(card)
	if hand_index == -1:
		return false

	_hand.remove_at(hand_index)
	_exhaust_pile.append(card)
	card_exhausted.emit(card)
	_emit_pile_updates()
	return true


func move_played_card(card: CardData) -> bool:
	if card == null:
		return false
	if card.exhaust:
		return exhaust_card(card)
	return discard_card(card)


func add_card_to_discard(card: CardData) -> void:
	if card == null:
		return
	_discard_pile.append(card)
	card_discarded.emit(card)
	_emit_pile_updates()


func add_card_to_draw_pile(card: CardData, shuffle_in: bool = false) -> void:
	if card == null:
		return
	_draw_pile.append(card)
	if shuffle_in:
		_shuffle_draw_pile()
	_emit_pile_updates()


func add_card_to_hand(card: CardData) -> bool:
	if card == null or _hand.size() >= hand_limit:
		return false
	_hand.append(card)
	_emit_pile_updates()
	return true


func get_draw_pile() -> Array[CardData]:
	return _draw_pile.duplicate()


func get_hand() -> Array[CardData]:
	return _hand.duplicate()


func get_discard_pile() -> Array[CardData]:
	return _discard_pile.duplicate()


func get_exhaust_pile() -> Array[CardData]:
	return _exhaust_pile.duplicate()


func get_draw_pile_size() -> int:
	return _draw_pile.size()


func get_hand_size() -> int:
	return _hand.size()


func get_discard_pile_size() -> int:
	return _discard_pile.size()


func get_exhaust_pile_size() -> int:
	return _exhaust_pile.size()


func get_pile_sizes() -> Dictionary:
	return {
		"draw": _draw_pile.size(),
		"hand": _hand.size(),
		"discard": _discard_pile.size(),
		"exhaust": _exhaust_pile.size(),
	}


func contains_in_hand(card: CardData) -> bool:
	return _hand.has(card)


func is_hand_full() -> bool:
	return _hand.size() >= hand_limit


func _reshuffle_discard_into_draw_pile() -> void:
	_draw_pile.assign(_discard_pile)
	_discard_pile.clear()
	_shuffle_draw_pile()
	discard_reshuffled.emit(_draw_pile.size())
	_emit_pile_updates()


func _shuffle_draw_pile() -> void:
	for index in range(_draw_pile.size() - 1, 0, -1):
		var swap_index: int = _rng.randi_range(0, index)
		var temp: CardData = _draw_pile[index]
		_draw_pile[index] = _draw_pile[swap_index]
		_draw_pile[swap_index] = temp


func _emit_pile_updates() -> void:
	piles_changed.emit()
	hand_changed.emit(_hand.duplicate())
