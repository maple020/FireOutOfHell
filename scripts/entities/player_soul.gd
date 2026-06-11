extends Node2D
## 玩家灵魂实体，管理生命、护盾与状态。

signal hp_changed(current: int, maximum: int)
signal block_changed(value: int)

@export var max_hp: int = 80

var current_hp: int = 80
var block: int = 0


func _ready() -> void:
	current_hp = max_hp


func take_damage(amount: int) -> void:
	var remaining := amount
	if block > 0:
		var absorbed := mini(block, remaining)
		block -= absorbed
		remaining -= absorbed
		block_changed.emit(block)
	current_hp = maxi(current_hp - remaining, 0)
	hp_changed.emit(current_hp, max_hp)


func heal(amount: int) -> void:
	current_hp = mini(current_hp + amount, max_hp)
	hp_changed.emit(current_hp, max_hp)


func gain_block(amount: int) -> void:
	block += amount
	block_changed.emit(block)
