class_name StatusManager
extends Node
## 状态管理器，管理玩家和敌人的状态效果

signal status_applied(target: Node, effect: StatusEffect)
signal status_removed(target: Node, effect: StatusEffect)
signal status_updated(target: Node, effect: StatusEffect)

var _statuses: Dictionary = {}  # Node -> Array[StatusEffect]


func apply_status(target: Node, type: StatusEffect.StatusType, stacks: int = 1) -> void:
	if target == null:
		return
	
	if not _statuses.has(target):
		_statuses[target] = []
	
	var existing: StatusEffect = null
	for effect in _statuses[target]:
		if effect.type == type:
			existing = effect
			break
	
	if existing != null:
		existing.stacks += stacks
		status_updated.emit(target, existing)
	else:
		var new_effect := StatusEffect.new(type, stacks)
		_statuses[target].append(new_effect)
		status_applied.emit(target, new_effect)


func remove_status(target: Node, type: StatusEffect.StatusType) -> void:
	if not _statuses.has(target):
		return
	
	var to_remove: Array = []
	for effect in _statuses[target]:
		if effect.type == type:
			to_remove.append(effect)
	
	for effect in to_remove:
		_statuses[target].erase(effect)
		status_removed.emit(target, effect)


func get_status(target: Node, type: StatusEffect.StatusType) -> StatusEffect:
	if not _statuses.has(target):
		return null
	
	for effect in _statuses[target]:
		if effect.type == type:
			return effect
	
	return null


func has_status(target: Node, type: StatusEffect.StatusType) -> bool:
	return get_status(target, type) != null


func get_all_statuses(target: Node) -> Array[StatusEffect]:
	if not _statuses.has(target):
		return []
	return _statuses[target].duplicate()


func clear_statuses(target: Node) -> void:
	if _statuses.has(target):
		_statuses.erase(target)


func tick_poison(target: Node) -> int:
	var poison: StatusEffect = get_status(target, StatusEffect.StatusType.POISON)
	if poison != null:
		var damage: int = poison.tick()
		return damage
	return 0


func modify_outgoing_damage(target: Node, damage: int) -> int:
	var result: int = damage
	
	var strength: StatusEffect = get_status(target, StatusEffect.StatusType.STRENGTH)
	if strength != null:
		result = strength.modify_damage(result, false)
	
	var weak: StatusEffect = get_status(target, StatusEffect.StatusType.WEAK)
	if weak != null:
		result = weak.modify_damage(result, false)
	
	return result


func modify_incoming_damage(target: Node, damage: int) -> int:
	var result: int = damage
	
	var vulnerable: StatusEffect = get_status(target, StatusEffect.StatusType.VULNERABLE)
	if vulnerable != null:
		result = vulnerable.modify_damage(result, true)
	
	return result


func on_turn_start(target: Node) -> void:
	# 每回合开始时处理中毒伤害
	var poison_damage: int = tick_poison(target)
	if poison_damage > 0 and target.has_method("take_damage"):
		target.take_damage(poison_damage)