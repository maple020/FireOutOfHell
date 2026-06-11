class_name StatusEffect
extends RefCounted
## 状态效果基类

enum StatusType {
	VULNERABLE,  # 易伤：受到伤害增加
	WEAK,        # 虚弱：造成伤害减少
	POISON,      # 中毒：每回合扣血
	STRENGTH     # 力量：增加伤害
}

@export var type: StatusType = StatusType.VULNERABLE
@export var stacks: int = 0
@export var is_debuff: bool = true


func _init(status_type: StatusType, amount: int = 1) -> void:
	type = status_type
	stacks = amount
	is_debuff = type != StatusType.STRENGTH


func get_name() -> String:
	match type:
		StatusType.VULNERABLE:
			return "易伤"
		StatusType.WEAK:
			return "虚弱"
		StatusType.POISON:
			return "中毒"
		StatusType.STRENGTH:
			return "力量"
	return "未知"


func get_description() -> String:
	match type:
		StatusType.VULNERABLE:
			return "受到的伤害增加" + str(stacks * 25) + "%"
		StatusType.WEAK:
			return "造成的伤害减少" + str(stacks * 25) + "%"
		StatusType.POISON:
			return "每回合受到" + str(stacks) + "点伤害"
		StatusType.STRENGTH:
			return "造成的伤害增加" + str(stacks)
	return ""


func tick() -> int:
	# 返回本回合应造成的伤害（用于中毒）
	if type == StatusType.POISON:
		return stacks
	return 0


func modify_damage(damage: int, is_incoming: bool) -> int:
	if type == StatusType.VULNERABLE and is_incoming:
		return int(damage * (1.0 + stacks * 0.25))
	if type == StatusType.WEAK and not is_incoming:
		return int(damage * (1.0 - stacks * 0.25))
	if type == StatusType.STRENGTH and not is_incoming:
		return damage + stacks
	return damage