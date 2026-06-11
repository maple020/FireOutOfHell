class_name RelicManager
extends Node
## 遗物管理器，监听战斗/Run 事件并触发遗物效果

signal relic_triggered(relic: RelicData, trigger: String)

var active_relics: Array[RelicData] = []

enum TriggerType {
	BATTLE_START,      # 战斗开始
	TURN_START,        # 回合开始
	CARD_PLAYED,       # 出牌后
	PLAYER_DAMAGED,    # 受伤后
	BATTLE_VICTORY,    # 战斗胜利
	ENERGY_GAIN,       # 获得能量
	STATUS_APPLIED,    # 状态应用
}


func add_relic(relic: RelicData) -> void:
	if relic != null and relic not in active_relics:
		active_relics.append(relic)


func remove_relic(relic: RelicData) -> void:
	active_relics.erase(relic)


func clear_relics() -> void:
	active_relics.clear()


func trigger_relics(trigger: TriggerType, context: Dictionary = {}) -> void:
	for relic in active_relics:
		_handle_relic_trigger(relic, trigger, context)


func _handle_relic_trigger(relic: RelicData, trigger: TriggerType, context: Dictionary) -> void:
	# 基础触发框架，具体效果由子类或配置实现
	match trigger:
		TriggerType.BATTLE_START:
			relic_triggered.emit(relic, "battle_start")
		TriggerType.TURN_START:
			relic_triggered.emit(relic, "turn_start")
		TriggerType.CARD_PLAYED:
			relic_triggered.emit(relic, "card_played")
		TriggerType.PLAYER_DAMAGED:
			relic_triggered.emit(relic, "player_damaged")
		TriggerType.BATTLE_VICTORY:
			relic_triggered.emit(relic, "battle_victory")
		TriggerType.ENERGY_GAIN:
			relic_triggered.emit(relic, "energy_gain")
		TriggerType.STATUS_APPLIED:
			relic_triggered.emit(relic, "status_applied")


func get_relic_count() -> int:
	return active_relics.size()


func has_relic(relic_id: String) -> bool:
	for relic in active_relics:
		if relic.id == relic_id:
			return true
	return false