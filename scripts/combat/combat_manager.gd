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
var _enemies: Array[EnemyActor] = []
var incoming_enemy_data: EnemyData = null
var _turn_count: int = 0

## 动画倍率：1.0 = 正常，2.0 = 快速
var animation_speed: float = 1.0

@onready var _hand_area: HBoxContainer = get_node_or_null("CombatUI/HandArea")
@onready var _enemy_area: Control = get_node_or_null("CombatUI/EnemyArea")
@onready var _player_soul: PlayerSoul = get_node_or_null("CombatUI/PlayerArea/PlayerSoul") as PlayerSoul
@onready var _end_turn_button: Button = get_node_or_null("CombatUI/EndTurnButton")
@onready var _energy_label: Label = get_node_or_null("CombatUI/EnergyLabel")
@onready var _screen_shake: ScreenShake = get_node_or_null("ScreenShake")
@onready var _sound_manager: SoundManager = get_node_or_null("SoundManager")
@onready var _speed_toggle: Button = get_node_or_null("CombatUI/SpeedToggleButton")
@onready var _turn_label: Label = get_node_or_null("CombatUI/TurnLabel")
@onready var _battle_label: Label = get_node_or_null("CombatUI/BattleLabel")
@onready var _enemy_hint_label: Label = get_node_or_null("CombatUI/EnemyHintLabel")
@onready var _draw_pile_label: Label = get_node_or_null("CombatUI/PileInfo/DrawPileLabel")
@onready var _discard_label: Label = get_node_or_null("CombatUI/PileInfo/DiscardLabel")
@onready var _exhaust_label: Label = get_node_or_null("CombatUI/PileInfo/ExhaustLabel")


func _ready() -> void:
	_ensure_deck_manager()
	_ensure_effect_queue()
	_connect_deck_manager_signals()
	_connect_scene_nodes()
	if not starting_deck.is_empty():
		setup_combat_deck(starting_deck, initial_seed)
	
	# 自动开始战斗（测试用）
	call_deferred("_auto_start_combat")



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
	_turn_count += 1
	current_energy = max_energy
	energy_changed.emit(current_energy, max_energy)
	_ensure_deck_manager()
	deck_manager.draw_to_hand_limit()
	change_state(CombatState.State.PLAYER_TURN)
	_prepare_enemy_intents()
	_update_battle_ui()
	_update_enemy_hint()


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
	
	# 播放卡牌释放动画
	_play_card_release_animation(card_data, target)
	
	# 构建并执行效果
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
	# 播放回合结束音效
	if _sound_manager != null:
		_sound_manager.play_turn_end()
	_prepare_enemy_intents()
	_execute_enemy_turn()


func _execute_enemy_turn() -> void:
	var living_enemies: Array[Node] = _get_living_enemies()
	for enemy in living_enemies:
		var enemy_actor: EnemyActor = enemy as EnemyActor
		if enemy_actor != null:
			enemy_actor.execute_intent(_player_soul)
	if _turn_label != null:
		_turn_label.text = "回合 %d - 敌人回合" % _turn_count
	change_state(CombatState.State.PLAYER_TURN)
	start_player_turn()


func _prepare_enemy_intents() -> void:
	var living_enemies: Array[Node] = _get_living_enemies()
	for enemy in living_enemies:
		var enemy_actor: EnemyActor = enemy as EnemyActor
		if enemy_actor != null:
			enemy_actor.prepare_next_intent()


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
	if _player_soul != null and not _player_soul.is_connected("player_died", Callable(self, "_on_player_died")):
		_player_soul.player_died.connect(_on_player_died)
	if _enemy_area != null:
		for child in _enemy_area.get_children():
			var enemy: EnemyActor = child as EnemyActor
			if enemy != null:
				if not enemy.is_connected("enemy_selected", Callable(self, "_on_enemy_selected")):
					enemy.connect("enemy_selected", Callable(self, "_on_enemy_selected"))
				if not enemy.is_connected("enemy_died", Callable(self, "_on_enemy_died")):
					enemy.connect("enemy_died", Callable(self, "_on_enemy_died"))
	if _hand_area != null:
		_refresh_hand_ui(deck_manager.get_hand())
	if _end_turn_button != null and not _end_turn_button.is_connected("pressed", Callable(self, "_on_end_turn_pressed")):
		_end_turn_button.pressed.connect(_on_end_turn_pressed)
	if _speed_toggle != null and not _speed_toggle.is_connected("pressed", Callable(self, "_on_speed_toggle_pressed")):
		_speed_toggle.pressed.connect(_on_speed_toggle_pressed)
	energy_changed.connect(_on_energy_changed)


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
	_update_pile_labels()


func _update_pile_labels() -> void:
	if deck_manager == null:
		return
	var sizes := deck_manager.get_pile_sizes()
	if _draw_pile_label != null:
		_draw_pile_label.text = "抽牌: %d" % sizes.get("draw", 0)
	if _discard_label != null:
		_discard_label.text = "弃牌: %d" % sizes.get("discard", 0)
	if _exhaust_label != null:
		_exhaust_label.text = "永劫: %d" % sizes.get("exhaust", 0)


func _update_battle_ui() -> void:
	if _turn_label != null:
		_turn_label.text = "回合 %d - 玩家回合" % _turn_count
	if _battle_label != null and _turn_count == 1:
		_battle_label.text = "--- 战斗开始 ---"


func _update_enemy_hint() -> void:
	if _enemy_hint_label == null:
		return
	var living := _get_living_enemies()
	if living.size() > 1:
		_enemy_hint_label.text = "点击敌人选择目标"
		_enemy_hint_label.show()
	else:
		_enemy_hint_label.hide()


func _on_enemy_selected(enemy: Node) -> void:
	select_target(enemy)


func _on_player_died() -> void:
	if current_state == CombatState.State.VICTORY or current_state == CombatState.State.DEFEAT:
		return
	change_state(CombatState.State.DEFEAT)
	if _battle_label != null:
		_battle_label.text = "--- 战斗失败 ---"
	if _turn_label != null:
		_turn_label.text = "回合 %d - 失败" % _turn_count
	# 播放失败音效
	if _sound_manager != null:
		_sound_manager.play_defeat()
	combat_finished.emit(false)


func _on_enemy_died() -> void:
	if current_state == CombatState.State.VICTORY or current_state == CombatState.State.DEFEAT:
		return
	var living: Array[Node] = _get_living_enemies()
	if living.is_empty():
		change_state(CombatState.State.VICTORY)
		if _battle_label != null:
			_battle_label.text = "--- 战斗胜利！ ---"
		if _turn_label != null:
			_turn_label.text = "回合 %d - 胜利" % _turn_count
		# 播放胜利音效
		if _sound_manager != null:
			_sound_manager.play_victory()
		combat_finished.emit(true)
		# 延迟返回地图/奖励
		call_deferred("_handle_combat_victory")


func _on_end_turn_pressed() -> void:
	if current_state == CombatState.State.PLAYER_TURN:
		end_turn()


func _on_energy_changed(current: int, maximum: int) -> void:
	if _energy_label != null:
		_energy_label.text = "能量: %d/%d" % [current, maximum]


func _handle_combat_victory() -> void:
	# 通知 GameManager 战斗胜利
	var game_manager := get_node_or_null("/root/GameManager")
	if game_manager != null and game_manager.has_method("enter_reward"):
		# 生成 3 张奖励卡牌
		var reward_cards: Array[CardData] = []
		var all_card_ids := ["hellfire_strike", "soul_shield", "ash_draw", "flame_lash"]
		all_card_ids.shuffle()
		for i in range(min(3, all_card_ids.size())):
			var path := "res://data/cards/%s.tres" % all_card_ids[i]
			if ResourceLoader.exists(path):
				var card: CardData = load(path)
				if card != null:
					reward_cards.append(card)
		
		if not reward_cards.is_empty():
			game_manager.enter_reward(reward_cards)
		else:
			game_manager.return_to_map()
	else:
		# 如果没有 GameManager，直接返回地图
		if game_manager != null and game_manager.has_method("return_to_map"):
			game_manager.return_to_map()


func _auto_start_combat() -> void:
	# 如果没有牌组，自动加载默认牌组
	if deck_manager == null or deck_manager.get_pile_sizes().get("draw", 0) == 0:
		var default_deck: Array[CardData] = []
		var default_ids := ["hellfire_strike", "hellfire_strike", "soul_shield", "soul_shield", "ash_draw", "flame_lash", "flame_lash"]
		for card_id in default_ids:
			var path := "res://data/cards/%s.tres" % card_id
			if ResourceLoader.exists(path):
				var card: CardData = load(path)
				if card != null:
					default_deck.append(card)
		
		if not default_deck.is_empty():
			setup_combat_deck(default_deck, 12345)
	
	# 自动开始玩家回合
	if current_state == CombatState.State.IDLE:
		# 确保有敌人
		if _enemies.is_empty():
			var enemy_scene := load("res://scenes/entities/enemy.tscn") as PackedScene
			if enemy_scene != null:
				# 优先使用传入的敌人数据，否则使用默认测试敌人
				var actual_enemy_data: EnemyData = incoming_enemy_data
				if actual_enemy_data == null:
					actual_enemy_data = load("res://data/enemies/imp.tres")
				incoming_enemy_data = null
				
				# 根据不同敌人数据决定生成数量
				var enemy_count: int = 2
				if actual_enemy_data.id == "hell_lord":
					enemy_count = 1
				
				for i in range(enemy_count):
					var enemy: EnemyActor = enemy_scene.instantiate()
					enemy.enemy_data = actual_enemy_data
					enemy.position = Vector2(200 + i * 200, 200)
					get_node("CombatUI/EnemyArea").add_child(enemy)
					_enemies.append(enemy)
					enemy.enemy_died.connect(_on_enemy_died)
					enemy.enemy_selected.connect(_on_enemy_selected)
		start_player_turn()


func _on_speed_toggle_pressed() -> void:
	# 切换动画倍率
	if animation_speed == 1.0:
		animation_speed = 2.0
		if _speed_toggle != null:
			_speed_toggle.text = "速度: 2x"
	else:
		animation_speed = 1.0
		if _speed_toggle != null:
			_speed_toggle.text = "速度: 1x"


func _play_hit_effect(target: Node, effect_type: String, color: Color) -> void:
	if target == null or not target is Node2D:
		return
	
	var hit_effect := preload("res://scripts/ui/hit_effect.gd").new() as HitEffect
	if hit_effect != null:
		hit_effect.effect_type = effect_type
		(target as Node2D).add_child(hit_effect)
		hit_effect.play_effect(color)


func _play_card_release_animation(card_data: CardData, target: Node) -> void:
	# 查找手牌中的卡牌视图
	if _hand_area == null:
		return
	
	for child in _hand_area.get_children():
		var card_view: CardView = child as CardView
		if card_view != null and card_view.card_data == card_data:
			# 计算目标位置
			var target_pos: Vector2 = Vector2.ZERO
			if target != null and target is Node2D:
				target_pos = (target as Node2D).global_position
			elif _enemy_area != null:
				target_pos = _enemy_area.global_position
			
			# 播放动画（应用动画倍率）
			var anim_duration: float = 0.4 / animation_speed
			card_view.play_release_animation(target_pos, anim_duration)
			break


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
		# 播放火焰伤害特效
		_play_hit_effect(damage_target, "damage", Color(1, 0.4, 0.2))
		# 播放伤害音效
		if _sound_manager != null:
			_sound_manager.play_damage()
		
		# 高伤害触发屏幕震动
		if card_data.damage >= 10 and _screen_shake != null:
			_screen_shake.start_shake(5.0, 0.2)

	if card_data.block > 0:
		var block_target: Node = target if target != null else _player_soul
		effect_queue.add_effect(BlockEffect.new(self, block_target, card_data.block))
		# 播放护盾特效
		_play_hit_effect(block_target, "block", Color(0.3, 0.7, 1))
		# 播放格挡音效
		if _sound_manager != null:
			_sound_manager.play_block()

	if card_data.draw > 0:
		effect_queue.add_effect(DrawEffect.new(self, deck_manager, card_data.draw))
		# 播放治疗/恢复特效
		_play_hit_effect(_player_soul, "heal", Color(0.3, 1, 0.3))

	if effect_queue.get_queue_size() > 0:
		effect_queue.execute_all()
	else:
		_on_effect_queue_finished()


func _on_effect_queue_finished() -> void:
	if current_state == CombatState.State.RESOLVING:
		change_state(CombatState.State.PLAYER_TURN)
