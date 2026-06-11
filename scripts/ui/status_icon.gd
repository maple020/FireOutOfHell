class_name StatusIcon
extends TextureRect
## 状态图标组件，显示状态效果并提供 Tooltip

@export var status_effect: StatusEffect

var _tooltip_panel: Panel
var _tooltip_label: Label


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_create_tooltip()


func set_status(effect: StatusEffect) -> void:
	status_effect = effect
	if effect != null:
		tooltip_text = effect.get_name() + ": " + effect.get_description()
		visible = true
	else:
		visible = false


func _create_tooltip() -> void:
	_tooltip_panel = Panel.new()
	_tooltip_panel.visible = false
	add_child(_tooltip_panel)
	
	_tooltip_label = Label.new()
	_tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_panel.add_child(_tooltip_label)


func _on_mouse_entered() -> void:
	if status_effect != null and _tooltip_panel != null:
		_tooltip_label.text = status_effect.get_name() + "\n" + status_effect.get_description()
		_tooltip_panel.size = Vector2(200, 60)
		_tooltip_panel.position = Vector2(0, -70)
		_tooltip_panel.visible = true


func _on_mouse_exited() -> void:
	if _tooltip_panel != null:
		_tooltip_panel.visible = false