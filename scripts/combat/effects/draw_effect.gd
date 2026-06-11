class_name DrawEffect
extends BaseEffect
## 抽牌效果，为目标抽牌。

signal cards_drawn(cards: Array[CardData])

func execute() -> void:
	if target != null and target.has_method("draw_cards"):
		var cards: Array[CardData] = target.draw_cards(value)
		cards_drawn.emit(cards)


func get_description() -> String:
	return "Draw " + str(value)