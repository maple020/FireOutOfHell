class_name AscensionRules
extends RefCounted
## Ascension 难度系统（0-5）

enum AscensionLevel {
	ASCENSION_0 = 0,
	ASCENSION_1 = 1,
	ASCENSION_2 = 2,
	ASCENSION_3 = 3,
	ASCENSION_4 = 4,
	ASCENSION_5 = 5,
}

var current_level: AscensionLevel = AscensionLevel.ASCENSION_0


func get_level_name(level: AscensionLevel) -> String:
	match level:
		AscensionLevel.ASCENSION_0:
			return "普通"
		AscensionLevel.ASCENSION_1:
			return "进阶 I"
		AscensionLevel.ASCENSION_2:
			return "进阶 II"
		AscensionLevel.ASCENSION_3:
			return "进阶 III"
		AscensionLevel.ASCENSION_4:
			return "进阶 IV"
		AscensionLevel.ASCENSION_5:
			return "进阶 V"
	return "未知"


func get_level_description(level: AscensionLevel) -> String:
	match level:
		AscensionLevel.ASCENSION_0:
			return "标准难度，无修改"
		AscensionLevel.ASCENSION_1:
			return "精英敌人出现概率+10%"
		AscensionLevel.ASCENSION_2:
			return "敌人生命+10%"
		AscensionLevel.ASCENSION_3:
			return "敌人伤害+10%"
		AscensionLevel.ASCENSION_4:
			return "Boss生命+25%"
		AscensionLevel.ASCENSION_5:
			return "所有敌人属性+15%，奖励减少"
	return ""


func get_enemy_hp_multiplier() -> float:
	match current_level:
		AscensionLevel.ASCENSION_2, AscensionLevel.ASCENSION_5:
			return 1.10
		AscensionLevel.ASCENSION_4:
			return 1.25
		_:
			return 1.0


func get_enemy_damage_multiplier() -> float:
	match current_level:
		AscensionLevel.ASCENSION_3, AscensionLevel.ASCENSION_5:
			return 1.10
		_:
			return 1.0


func get_boss_hp_multiplier() -> float:
	match current_level:
		AscensionLevel.ASCENSION_4, AscensionLevel.ASCENSION_5:
			return 1.25
		_:
			return 1.0


func get_elite_spawn_chance_bonus() -> float:
	match current_level:
		AscensionLevel.ASCENSION_1, AscensionLevel.ASCENSION_5:
			return 0.10
		_:
			return 0.0


func get_reward_multiplier() -> float:
	match current_level:
		AscensionLevel.ASCENSION_5:
			return 0.85
		_:
			return 1.0


func set_level(level: AscensionLevel) -> void:
	current_level = level


func get_all_levels() -> Array[AscensionLevel]:
	return [
		AscensionLevel.ASCENSION_0,
		AscensionLevel.ASCENSION_1,
		AscensionLevel.ASCENSION_2,
		AscensionLevel.ASCENSION_3,
		AscensionLevel.ASCENSION_4,
		AscensionLevel.ASCENSION_5,
	]