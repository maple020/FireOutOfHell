class_name CardView
extends Control
## 卡牌 UI 场景，引用 CardData 并通过 Signal 与 CombatManager 通信。

signal card_selected(card_data: CardData)
signal card_hovered(card_data: CardData)

@export var card_data: CardData

@onready var _name_label: Label = $MarginContainer/VBox/NameLabel
@onready var _cost_label: Label = $MarginContainer/VBox/CostLabel
@onready var _desc_label: RichTextLabel = $MarginContainer/VBox/DescLabel

var _is_playable: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	if card_data:
		_update_display()


func setup(data: CardData) -> void:
	card_data = data
	_update_display()


func set_playable(is_playable: bool) -> void:
	_is_playable = is_playable
	modulate = Color(1.0, 1.0, 1.0, 1.0) if is_playable else Color(0.55, 0.55, 0.55, 0.9)


func _gui_input(event: InputEvent) -> void:
	if not _is_playable or card_data == null:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_selected.emit(card_data)
		accept_event()


func _on_mouse_entered() -> void:
	if card_data:
		card_hovered.emit(card_data)


func _update_display() -> void:
	if not card_data:
		return
	_name_label.text = card_data.display_name
	_cost_label.text = str(card_data.cost)
	_desc_label.text = card_data.description
