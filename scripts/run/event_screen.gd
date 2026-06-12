class_name EventScreen
extends Control

signal event_finished

@onready var _title_label: Label = $TitleLabel
@onready var _desc_label: Label = $DescLabel
@onready var _choice_buttons: Array[Button] = []

var _events: Array[Dictionary] = [
	{
		"title": "灵魂之泉",
		"desc": "你发现了一口涌动着灵魂能量的泉水，泉水中的灵魂低语着诱惑...",
		"choices": [
			{"text": "饮用泉水（恢复30%生命）", "heal_pct": 0.3},
			{"text": "献祭灵魂（获得随机遗物）", "reward": "relic"},
			{"text": "无视并离开", "reward": "none"}
		]
	},
	{
		"title": "恶魔契约",
		"desc": "一个古老的恶魔出现在你面前，提出了一份诱人的契约...",
		"choices": [
			{"text": "接受契约（失去15%生命，获得稀有卡牌）", "hp_cost_pct": 0.15, "reward": "rare_card"},
			{"text": "拒绝契约", "reward": "none"}
		]
	},
	{
		"title": "地狱熔炉残骸",
		"desc": "你在一堆废墟中发现了一个废弃的熔炉，里面还有残余的火种...",
		"choices": [
			{"text": "使用残骸升级一张卡牌", "reward": "upgrade"},
			{"text": "搜刮残骸（获得金币）", "reward": "gold"},
			{"text": "离开", "reward": "none"}
		]
	},
	{
		"title": "迷失的灵魂",
		"desc": "一个迷失的灵魂在哭泣，它似乎在寻找解脱...",
		"choices": [
			{"text": "帮助它解脱（治疗至满血）", "heal_pct": 1.0},
			{"text": "吞噬它（获得最大生命+5）", "max_hp_bonus": 5},
			{"text": "无视它", "reward": "none"}
		]
	}
]


func _ready() -> void:
	# 动态创建按钮容器
	var button_container := VBoxContainer.new()
	button_container.name = "ChoiceContainer"
	button_container.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	button_container.position = Vector2(260, 600)
	button_container.custom_minimum_size = Vector2(500, 0)
	add_child(button_container)
	
	for i in range(3):
		var button := Button.new()
		button.custom_minimum_size = Vector2(460, 50)
		button_container.add_child(button)
		button.hide()
		_choice_buttons.append(button)
	
	_setup_random_event()


func _setup_random_event() -> void:
	var evt: Dictionary = _events[randi() % _events.size()]
	_title_label.text = evt["title"]
	_desc_label.text = evt["desc"]
	
	for i in range(_choice_buttons.size()):
		if i < evt["choices"].size():
			var choice: Dictionary = evt["choices"][i]
			_choice_buttons[i].text = choice["text"]
			_choice_buttons[i].show()
			_choice_buttons[i].disabled = false
			_choice_buttons[i].pressed.connect(_on_choice_pressed.bind(choice))
		else:
			_choice_buttons[i].hide()


func _on_choice_pressed(choice: Dictionary) -> void:
	for button in _choice_buttons:
		button.disabled = true
	
	_apply_choice(choice)
	event_finished.emit()


func _apply_choice(choice: Dictionary) -> void:
	var gm := get_node_or_null("/root/GameManager")
	var rm = gm.get_node_or_null("RunManager") if gm else null
	if rm == null:
		return
	
	if choice.has("heal_pct"):
		var heal_amount: int = int(rm.max_hp * choice["heal_pct"])
		rm.heal(heal_amount)
	
	if choice.has("hp_cost_pct"):
		var cost: int = int(rm.max_hp * choice["hp_cost_pct"])
		rm.take_damage(cost)
	
	if choice.has("max_hp_bonus"):
		rm.max_hp += choice["max_hp_bonus"]
		rm.current_hp += choice["max_hp_bonus"]
	
	if choice.has("reward"):
		match choice["reward"]:
			"rare_card":
				var card_path := "res://data/cards/flame_lash.tres"
				if ResourceLoader.exists(card_path):
					rm.add_card_to_deck(load(card_path))
			"relic":
				var relic_path := "res://data/relics/soul_shard.tres"
				if ResourceLoader.exists(relic_path):
					rm.add_relic(load(relic_path))
			"gold":
				pass
