class_name RewardScreen
extends Control
## 战斗奖励界面

signal card_selected(card_data: CardData)
signal reward_skipped

@onready var _card_buttons: Array[Button] = [
	$RewardContainer/Card1,
	$RewardContainer/Card2,
	$RewardContainer/Card3
]
@onready var _skip_button: Button = $SkipButton

var _reward_cards: Array[CardData] = []


func _ready() -> void:
	for i in range(_card_buttons.size()):
		_card_buttons[i].pressed.connect(_on_card_pressed.bind(i))
	_skip_button.pressed.connect(_on_skip_pressed)


func setup_rewards(cards: Array[CardData]) -> void:
	_reward_cards = cards
	
	for i in range(_card_buttons.size()):
		if i < cards.size():
			var card: CardData = cards[i]
			_card_buttons[i].text = "%s\n%s" % [card.display_name, card.description]
			_card_buttons[i].visible = true
		else:
			_card_buttons[i].visible = false


func _on_card_pressed(index: int) -> void:
	if index < _reward_cards.size():
		card_selected.emit(_reward_cards[index])
		# 禁用所有按钮防止重复选择
		for button in _card_buttons:
			button.disabled = true


func _on_skip_pressed() -> void:
	reward_skipped.emit()
	for button in _card_buttons:
		button.disabled = true