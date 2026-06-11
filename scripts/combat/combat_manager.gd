class_name CombatManager
extends Node
## 战斗核心逻辑，通过 Signal 与 UI 解耦。

const CARD_SCENE := preload("res://scenes/card/card.tscn")
const EffectQueue := preload("res://scripts/combat/effects/effect_queue.gd")
const DamageEffect := preload("res://scripts/combat/effects/damage_effect.gd")
const BlockEffect := preload("res://scripts/combat/effects/block_effect.gd")
const DrawEffect := preload("res://scripts/combat/effects/draw_effect.gd")

signal state_changed(new_state: CombatState.State)
signal energy_changed(current_energy: int, max_energy: int)
signal card_played(card_data: CardData, target: Node)
signal card_targeting_started(card_data: CardData)
signal card_targeting_cleared
signal card_play_failed(card_data: CardData, reason: String)
signal hand_updated(hand: Array[CardData])
signal cards_drawn(cards: Array[CardData])
signal pile_sizes_changed(pile_sizes: Dictionary)
signal turn_ended
signal combat_finished(victory: bool)

@export var starting_deck: Array[CardData] = []
@export var initial_seed: int = -1
@export var hand_limit: int = 5

var current_state: CombatState.State = CombatState.State.IDLE
var current_energy: int = 0
var max_energy: int = 3

var deck_manager: DeckManager
var effect_queue: EffectQueue
var _selected_card: CardData

@onready var _hand_area: HBoxContainer = get_node_or_null("CombatUI/HandArea")
@onready var _enemy_area: Control = get_node_or_null("CombatUI/EnemyArea")
@onready var _player_soul: Node = get_node_or_null("CombatUI/PlayerArea/PlayerSoul")


func _ready() -> void:
	_ensure_deck_manager()
	_ensure_effect_queue()
	_connect_deck_manager_signals()
	_connect_scene_nodes()
	if not starting_deck.is_empty():
		setup_combat_deck(starting_deck, initial_seed)



func change_state(new_state: CombatState.State) -> void:
	current_state = new_state
	state_changed.emit(new_state)
	_update_hand_card_states()

func setup_combat_deck(deck_list: Array[CardData], seed_value: int = -1) -> void:
	_ensure_deck_manager()
	deck_manager.initialize(deck_list, seed_value, hand_limit)
	_clear_target_selection()


func start_player_turn() -> void:
	_clear_target_selection()
	current_energy = max_energy
	energy_changed.emit(current_energy, max_energy)
	_ensure_deck_manager()
	deck_manager.draw_to_hand_limit()
	change_state(CombatState.State.PLAYER_TURN)


func play_card(card_data: CardData, target: Node) -> void:
	if current_state != CombatState.State.PLAYER_TURN:
		card_play_failed.emit(card_data, "invalid_state")
		return
	_ensure_deck_manager()
	if not deck_manager.contains_in_hand(card_data):
		card_play_failed.emit(card_data, "card_not_in_hand")
		return
	if not _is_valid_target(card_data, target):
		card_play_failed.emit(card_data, "invalid_target")
		return
	if current_energy < card_data.cost:
		card_play_failed.emit(card_data, "not_enough_energy")
		return
	current_energy -= card_data.cost
	energy_changed.emit(current_energy, max_energy)
	_clear_target_selection()
	change_state(CombatState.State.RESOLVING)
	card_played.emit(card_data, target)
	deck_manager.move_played_card(card_data)
	_build_and_execute_effects(card_data, target)


func request_play_card(card_data: CardData) -> void:
	if card_data == null:
		return
	if current_state != CombatState.State.PLAYER_TURN:
		card_play_failed.emit(card_data, "invalid_state")
		return
	if current_energy < card_data.cost:
		card_play_failed.emit(card_data, "not_enough_energy")
		return

	match card_data.target_type:
		CardData.TargetType.NONE:
			play_card(card_data, null)
		CardData.TargetType.SELF:
			play_card(card_data, _player_soul)
		CardData.TargetType.ALL_ENEMIES:
			play_card(card_data, _enemy_area)
		CardData.TargetType.ENEMY:
			var living_enemies: Array[Node] = _get_living_enemies()
			if living_enemies.is_empty():
				card_play_failed.emit(card_data, "no_valid_target")
			elif living_enemies.size() == 1:
				play_card(card_data, living_enemies[0])
			else:
				_selected_card = card_data
				change_state(CombatState.State.TARGETING)
				_set_enemy_targeting_enabled(true)
				card_targeting_started.emit(card_data)


func end_turn() -> void:
	_ensure_deck_manager()
	_clear_target_selection()
	deck_manager.discard_hand()
	change_state(CombatState.State.ENEMY_TURN)
	turn_ended.emit()


func get_current_hand() -> Array[CardData]:
	_ensure_deck_manager()
	return deck_manager.get_hand()


func get_pile_sizes() -> Dictionary:
	_ensure_deck_manager()
	return deck_manager.get_pile_sizes()


func select_target(target: Node) -> void:
	if current_state != CombatState.State.TARGETING or _selected_card == null:
		return
	if not _is_valid_target(_selected_card, target):
		card_play_failed.emit(_selected_card, "invalid_target")
		return
	change_state(CombatState.State.PLAYER_TURN)
	play_card(_selected_card, target)


func _ensure_deck_manager() -> void:
	if deck_manager != null:
		return
	deck_manager = DeckManager.new()
	deck_manager.name = "DeckManager"
	add_child(deck_manager)


func _ensure_effect_queue() -> void:
	if effect_queue != null:
		return
	effect_queue = EffectQueue.new()
	effect_queue.name = "EffectQueue"
	add_child(effect_queue)
	effect_queue.queue_finished.connect(_on_effect_queue_finished)


func _connect_scene_nodes() -> void:
	if _enemy_area != null:
		for child in _enemy_area.get_children():
			var enemy: EnemyActor = child as EnemyActor
			if enemy != null and not enemy.is_connected("enemy_selected", Callable(self, "_on_enemy_selected")):
				enemy.connect("enemy_selected", Callable(self, "_on_enemy_selected"))
	if _hand_area != null:
		_refresh_hand_ui(deck_manager.get_hand())


func _connect_deck_manager_signals() -> void:
	if deck_manager.hand_changed.is_connected(_on_hand_changed):
		return
	deck_manager.hand_changed.connect(_on_hand_changed)
	deck_manager.cards_drawn.connect(_on_cards_drawn)
	deck_manager.piles_changed.connect(_on_piles_changed)


func _on_hand_changed(hand: Array[CardData]) -> void:
	_refresh_hand_ui(hand)
	hand_updated.emit(hand)


func _on_cards_drawn(cards: Array[CardData]) -> void:
	cards_drawn.emit(cards)


func _on_piles_changed() -> void:
	pile_sizes_changed.emit(deck_manager.get_pile_sizes())


func _on_enemy_selected(enemy: Node) -> void:
	select_target(enemy)


func _refresh_hand_ui(hand: Array[CardData]) -> void:
	if _hand_area == null:
		return

	for child in _hand_area.get_children():
		child.queue_free()

	for card_data in hand:
		var card_view: CardView = CARD_SCENE.instantiate() as CardView
		if card_view == null:
			continue
		_hand_area.add_child(card_view)
		card_view.setup(card_data)
		card_view.card_selected.connect(_on_card_selected)
		card_view.set_playable(_can_play_card_now(card_data))


func _on_card_selected(card_data: CardData) -> void:
	request_play_card(card_data)


func _can_play_card_now(card_data: CardData) -> bool:
	if card_data == null:
		return false
	if current_state != CombatState.State.PLAYER_TURN:
		return false
	if current_energy < card_data.cost:
		return false

	match card_data.target_type:
		CardData.TargetType.ENEMY, CardData.TargetType.ALL_ENEMIES:
			return not _get_living_enemies().is_empty()
		_:
			return true


func _update_hand_card_states() -> void:
	if _hand_area == null:
		return
	for child in _hand_area.get_children():
		var card_view: CardView = child as CardView
		if card_view != null and card_view.card_data != null:
			card_view.set_playable(_can_play_card_now(card_view.card_data))


func _get_living_enemies() -> Array[Node]:
	var living_enemies: Array[Node] = []
	if _enemy_area == null:
		return living_enemies

	for child in _enemy_area.get_children():
		var enemy: EnemyActor = child as EnemyActor
		if enemy != null and enemy.is_alive():
			living_enemies.append(enemy)

	return living_enemies


func _is_valid_target(card_data: CardData, target: Node) -> bool:
	if card_data == null:
		return false

	match card_data.target_type:
		CardData.TargetType.NONE:
			return true
		CardData.TargetType.SELF:
			return target == _player_soul
		CardData.TargetType.ALL_ENEMIES:
			return target == _enemy_area and not _get_living_enemies().is_empty()
		CardData.TargetType.ENEMY:
			var enemy: EnemyActor = target as EnemyActor
			return enemy != null and enemy.is_alive()
		_:
			return false


func _set_enemy_targeting_enabled(enabled: bool) -> void:
	if _enemy_area == null:
		return

	for child in _enemy_area.get_children():
		var enemy: EnemyActor = child as EnemyActor
		if enemy != null:
			enemy.set_targetable(enabled and enemy.is_alive())


func _clear_target_selection() -> void:
	_selected_card = null
	_set_enemy_targeting_enabled(false)
	card_targeting_cleared.emit()


func _build_and_execute_effects(card_data: CardData, target: Node) -> void:
	if effect_queue == null:
		_ensure_effect_queue()
	effect_queue.clear()

	if card_data.damage > 0:
		var damage_target: Node = target if target != null else _player_soul
		effect_queue.add_effect(DamageEffect.new(self, damage_target, card_data.damage))

	if card_data.block > 0:
		var block_target: Node = target if target != null else _player_soul
		effect_queue.add_effect(BlockEffect.new(self, block_target, card_data.block))

	if card_data.draw > 0:
		effect_queue.add_effect(DrawEffect.new(self, deck_manager, card_data.draw))

	if effect_queue.get_queue_size() > 0:
		effect_queue.execute_all()
	else:
		_on_effect_queue_finished()


func _on_effect_queue_finished() -> void:
	if current_state == CombatState.State.RESOLVING:
		change_state(CombatState.State.PLAYER_TURN)
