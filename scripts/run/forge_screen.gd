class_name ForgeScreen
extends Control
## 熔炉场景：提供恢复、升级、删牌等选择

signal option_selected(option: String)
signal leave_requested

@onready var _heal_button: Button = $OptionsContainer/HealButton
@onready var _upgrade_button: Button = $OptionsContainer/UpgradeButton
@onready var _remove_button: Button = $OptionsContainer/RemoveButton
@onready var _leave_button: Button = $LeaveButton

var _selected_option: String = ""


func _ready() -> void:
	_heal_button.pressed.connect(_on_heal_pressed)
	_upgrade_button.pressed.connect(_on_upgrade_pressed)
	_remove_button.pressed.connect(_on_remove_pressed)
	_leave_button.pressed.connect(_on_leave_pressed)


func _on_heal_pressed() -> void:
	_selected_option = "heal"
	option_selected.emit("heal")
	_disable_all_buttons()


func _on_upgrade_pressed() -> void:
	_selected_option = "upgrade"
	option_selected.emit("upgrade")
	_disable_all_buttons()


func _on_remove_pressed() -> void:
	_selected_option = "remove"
	option_selected.emit("remove")
	_disable_all_buttons()


func _on_leave_pressed() -> void:
	leave_requested.emit()


func _disable_all_buttons() -> void:
	_heal_button.disabled = true
	_upgrade_button.disabled = true
	_remove_button.disabled = true


func enable_option(option: String, enabled: bool) -> void:
	match option:
		"heal":
			_heal_button.disabled = not enabled
		"upgrade":
			_upgrade_button.disabled = not enabled
		"remove":
			_remove_button.disabled = not enabled