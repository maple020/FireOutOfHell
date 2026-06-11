class_name MainMenu
extends Control
## 主菜单场景

@onready var _start_button: Button = $MenuContainer/StartButton
@onready var _continue_button: Button = $MenuContainer/ContinueButton
@onready var _settings_button: Button = $MenuContainer/SettingsButton
@onready var _quit_button: Button = $MenuContainer/QuitButton

var _game_manager: Node


func _ready() -> void:
	_game_manager = get_node_or_null("/root/GameManager")
	
	_start_button.pressed.connect(_on_start_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	
	# 检查是否有存档
	if _game_manager and _game_manager.has_method("has_save"):
		_continue_button.disabled = not _game_manager.has_save()
	else:
		_continue_button.disabled = true


func _on_start_pressed() -> void:
	if _game_manager and _game_manager.has_method("start_new_run"):
		_game_manager.start_new_run()


func _on_continue_pressed() -> void:
	if _game_manager and _game_manager.has_method("load_run"):
		_game_manager.load_run()


func _on_settings_pressed() -> void:
	# TODO: 打开设置界面
	print("设置（待实现）")


func _on_quit_pressed() -> void:
	get_tree().quit()