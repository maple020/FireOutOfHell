class_name EnemyActor
extends Node2D
## 战斗敌人实体，显示意图与状态。

@icon("res://icon.svg")

signal intent_updated(intent_id: String, value: int)
signal enemy_died
signal enemy_selected(enemy: Node)

@export var enemy_data: EnemyData

var current_hp: int = 0
var block: int = 0
var _intent_list: Array[Dictionary] = []
var _intent_index: int = 0
var _current_intent: Dictionary = {}


@onready var _hp_label: Label = $HPLabel
@onready var _select_button: Button = $SelectButton
@onready var _intent_icon: TextureRect = $IntentIcon
@onready var _hp_bar: TextureProgressBar = $HPBar
@onready var _block_bar: TextureProgressBar = $BlockBar


func _ready() -> void:
	if enemy_data:
		current_hp = enemy_data.max_hp
		_load_intents()
	_update_hp_label()
	_select_button.disabled = true
	_select_button.pressed.connect(_on_select_button_pressed)
	_update_intent_display()


func take_damage(amount: int) -> void:
	var remaining := amount
	if block > 0:
		var absorbed := mini(block, remaining)
		block -= absorbed
		remaining -= absorbed
	current_hp = maxi(current_hp - remaining, 0)
	_update_hp_label()
	if current_hp <= 0:
		_select_button.disabled = true
		_play_death_animation()
		enemy_died.emit()


func is_alive() -> bool:
	return current_hp > 0


func set_targetable(enabled: bool) -> void:
	_select_button.disabled = not enabled


func _on_select_button_pressed() -> void:
	if is_alive():
		enemy_selected.emit(self)


func _update_hp_label() -> void:
	_hp_label.text = str(current_hp)
	if _hp_bar != null:
		if enemy_data != null:
			_hp_bar.max_value = enemy_data.max_hp
		_hp_bar.value = current_hp
	if _block_bar != null:
		_block_bar.value = block


func _load_intents() -> void:
	_intent_list.clear()
	if enemy_data == null or enemy_data.intent_pool.is_empty():
		return
	for intent_str in enemy_data.intent_pool:
		var parts: PackedStringArray = intent_str.split(":")
		if parts.size() == 2:
			_intent_list.append({"type": parts[0], "value": parts[1].to_int()})


func prepare_next_intent() -> void:
	if _intent_list.is_empty():
		_current_intent = {}
		intent_updated.emit("", 0)
		return
	_current_intent = _intent_list[_intent_index % _intent_list.size()]
	_intent_index += 1
	intent_updated.emit(_current_intent.get("type", ""), _current_intent.get("value", 0))
	_update_intent_display()


func execute_intent(target: Node) -> void:
	if _current_intent.is_empty():
		return
	var type: String = _current_intent.get("type", "")
	var value: int = _current_intent.get("value", 0)
	match type:
		"attack":
			if target != null and target.has_method("take_damage"):
				target.take_damage(value)
		"defend":
			block += value
			if _block_bar != null:
				_block_bar.value = block
		"buff", "debuff":
			pass
	_update_hp_label()


func _update_intent_display() -> void:
	if _intent_icon == null:
		return
	if _current_intent.is_empty():
		_intent_icon.visible = false
	else:
		_intent_icon.visible = true
		_intent_icon.tooltip_text = _current_intent.get("type", "") + " " + str(_current_intent.get("value", 0))


func _play_death_animation() -> void:
	# 禁用交互
	_select_button.disabled = true
	if _intent_icon != null:
		_intent_icon.visible = false
	
	# 播放淡出和缩放动画
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(0.3, 0.3), 0.6).set_ease(Tween.EASE_IN)
	
	tween.set_parallel(false)
	tween.tween_callback(queue_free)
