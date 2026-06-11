class_name ShopScreen
extends Control
## 商店/黑市场景

signal item_purchased(item_data, cost: int)
signal leave_requested

@onready var _gold_label: Label = $GoldLabel
@onready var _cards_container: HBoxContainer = $CardsContainer
@onready var _relics_container: HBoxContainer = $RelicsContainer
@onready var _consumables_container: HBoxContainer = $ConsumablesContainer
@onready var _leave_button: Button = $LeaveButton

var _current_gold: int = 100
var _card_buttons: Array[Button] = []
var _relic_buttons: Array[Button] = []
var _consumable_buttons: Array[Button] = []


func _ready() -> void:
	_leave_button.pressed.connect(_on_leave_pressed)


func setup_shop(cards: Array, relics: Array, consumables: Array, gold: int) -> void:
	_current_gold = gold
	_update_gold_display()
	_clear_containers()
	_create_card_buttons(cards)
	_create_relic_buttons(relics)
	_create_consumable_buttons(consumables)


func _update_gold_display() -> void:
	_gold_label.text = "金币: %d" % _current_gold


func _clear_containers() -> void:
	for child in _cards_container.get_children():
		child.queue_free()
	for child in _relics_container.get_children():
		child.queue_free()
	for child in _consumables_container.get_children():
		child.queue_free()
	_card_buttons.clear()
	_relic_buttons.clear()
	_consumable_buttons.clear()


func _create_card_buttons(cards: Array) -> void:
	for card in cards:
		var button := Button.new()
		button.custom_minimum_size = Vector2(150, 180)
		button.text = "%s\n%d金" % [card.display_name, 50]
		button.pressed.connect(_on_card_purchased.bind(card, 50, button))
		_cards_container.add_child(button)
		_card_buttons.append(button)


func _create_relic_buttons(relics: Array) -> void:
	for relic in relics:
		var button := Button.new()
		button.custom_minimum_size = Vector2(120, 120)
		button.text = "%s\n%d金" % [relic.display_name, 100]
		button.pressed.connect(_on_relic_purchased.bind(relic, 100, button))
		_relics_container.add_child(button)
		_relic_buttons.append(button)


func _create_consumable_buttons(consumables: Array) -> void:
	for consumable in consumables:
		var button := Button.new()
		button.custom_minimum_size = Vector2(120, 120)
		button.text = "%s\n%d金" % [consumable.display_name, 30]
		button.pressed.connect(_on_consumable_purchased.bind(consumable, 30, button))
		_consumables_container.add_child(button)
		_consumable_buttons.append(button)


func _on_card_purchased(card, cost: int, button: Button) -> void:
	if _current_gold >= cost:
		_current_gold -= cost
		_update_gold_display()
		item_purchased.emit(card, cost)
		button.disabled = true


func _on_relic_purchased(relic, cost: int, button: Button) -> void:
	if _current_gold >= cost:
		_current_gold -= cost
		_update_gold_display()
		item_purchased.emit(relic, cost)
		button.disabled = true


func _on_consumable_purchased(consumable, cost: int, button: Button) -> void:
	if _current_gold >= cost:
		_current_gold -= cost
		_update_gold_display()
		item_purchased.emit(consumable, cost)
		button.disabled = true


func _on_leave_pressed() -> void:
	leave_requested.emit()