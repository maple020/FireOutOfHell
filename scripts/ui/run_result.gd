class_name RunResult
extends Control
## Run 结算界面

signal restart_requested

@onready var _title_label: Label = $TitleLabel
@onready var _turns_label: Label = $StatsContainer/TurnsLabel
@onready var _enemies_label: Label = $StatsContainer/EnemiesLabel
@onready var _deck_label: Label = $StatsContainer/DeckLabel
@onready var _restart_button: Button = $RestartButton

var _is_victory: bool = false
var _turns: int = 0
var _enemies_defeated: int = 0
var _deck_size: int = 0


func _ready() -> void:
	_restart_button.pressed.connect(_on_restart_pressed)


func setup_result(victory: bool, turns: int = 0, enemies: int = 0, deck_size: int = 0) -> void:
	_is_victory = victory
	_turns = turns
	_enemies_defeated = enemies
	_deck_size = deck_size
	
	if victory:
		_title_label.text = "胜利！"
		_title_label.modulate = Color(0.5, 1, 0.5)
	else:
		_title_label.text = "失败..."
		_title_label.modulate = Color(1, 0.5, 0.5)
	
	_turns_label.text = "回合数: %d" % turns
	_enemies_label.text = "击败敌人: %d" % enemies
	_deck_label.text = "最终牌组: %d 张" % deck_size


func _on_restart_pressed() -> void:
	restart_requested.emit()