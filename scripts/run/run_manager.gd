class_name RunManager
extends Node
## 管理整局 Run 状态：地图、牌组、遗物、种子与存档。

signal run_started(seed_value: int)
signal run_ended(victory: bool)

var current_seed: int = 0
var ascension_level: int = 0
var current_hp: int = 0
var max_hp: int = 0
var deck: Array[CardData] = []
var relics: Array[RelicData] = []


func start_new_run(seed_value: int = -1) -> void:
	current_seed = seed_value if seed_value >= 0 else randi()
	ascension_level = 0
	run_started.emit(current_seed)


func end_run(victory: bool) -> void:
	run_ended.emit(victory)
