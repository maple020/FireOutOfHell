class_name PlayerSoul
extends Node2D
## 玩家灵魂实体，管理生命、护盾与状态。

signal hp_changed(current: int, maximum: int)
signal block_changed(value: int)
signal player_died

@export var max_hp: int = 80

var current_hp: int = 80
var block: int = 0

@onready var _hp_bar: TextureProgressBar = $HPBar
@onready var _block_bar: TextureProgressBar = $BlockBar


func _ready() -> void:
	current_hp = max_hp
	_update_ui()
	_connect_ui_signals()


func take_damage(amount: int) -> void:
	var remaining := amount
	if block > 0:
		var absorbed := mini(block, remaining)
		block -= absorbed
		remaining -= absorbed
		block_changed.emit(block)
	current_hp = maxi(current_hp - remaining, 0)
	hp_changed.emit(current_hp, max_hp)
	if current_hp <= 0:
		player_died.emit()


func heal(amount: int) -> void:
	current_hp = mini(current_hp + amount, max_hp)
	hp_changed.emit(current_hp, max_hp)


func gain_block(amount: int) -> void:
	block += amount
	block_changed.emit(block)


func get_current_hp() -> int:
	return current_hp


func get_max_hp() -> int:
	return max_hp


func get_block() -> int:
	return block


func _update_ui() -> void:
	if _hp_bar != null:
		_hp_bar.max_value = max_hp
		_hp_bar.value = current_hp
	if _block_bar != null:
		_block_bar.value = block


func _connect_ui_signals() -> void:
	hp_changed.connect(_on_hp_changed)
	block_changed.connect(_on_block_changed)


func _on_hp_changed(current: int, maximum: int) -> void:
	if _hp_bar != null:
		_hp_bar.max_value = maximum
		_hp_bar.value = current


func _on_block_changed(value: int) -> void:
	if _block_bar != null:
		_block_bar.value = value
