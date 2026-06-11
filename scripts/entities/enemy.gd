class_name EnemyActor
extends Node2D
## 战斗敌人实体，显示意图与状态。

signal intent_updated(intent_id: String, value: int)
signal enemy_died
signal enemy_selected(enemy: Node)

@export var enemy_data: EnemyData

var current_hp: int = 0
var block: int = 0

@onready var _hp_label: Label = $HPLabel
@onready var _select_button: Button = $SelectButton


func _ready() -> void:
	if enemy_data:
		current_hp = enemy_data.max_hp
	_update_hp_label()
	_select_button.disabled = true
	_select_button.pressed.connect(_on_select_button_pressed)


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
