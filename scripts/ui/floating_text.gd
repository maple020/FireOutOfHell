class_name FloatingText
extends Label
## 飘字效果组件，用于显示伤害、治疗、格挡等数值反馈

signal finished

@export var duration: float = 0.8
@export var rise_distance: float = 50.0
@export var color_damage: Color = Color(1, 0.3, 0.3)
@export var color_heal: Color = Color(0.3, 1, 0.3)
@export var color_block: Color = Color(0.3, 0.7, 1)

var _tween: Tween


func show_text(text: String, type: String = "damage") -> void:
	self.text = text
	
	match type:
		"damage":
			add_theme_color_override("font_color", color_damage)
		"heal":
			add_theme_color_override("font_color", color_heal)
		"block":
			add_theme_color_override("font_color", color_block)
		_:
			add_theme_color_override("font_color", Color.WHITE)
	
	_start_animation()


func _start_animation() -> void:
	_tween = create_tween()
	_tween.set_parallel(true)
	
	# 上升动画
	_tween.tween_property(self, "position:y", position.y - rise_distance, duration).set_ease(Tween.EASE_OUT)
	
	# 淡出动画
	_tween.tween_property(self, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)
	
	_tween.set_parallel(false)
	_tween.tween_callback(_on_animation_finished)


func _on_animation_finished() -> void:
	finished.emit()
	queue_free()