class_name EffectQueue
extends Node
## 效果队列，按顺序执行效果。

signal effect_started(effect: BaseEffect)
signal effect_completed(effect: BaseEffect)
signal queue_finished

var _queue: Array[BaseEffect] = []
var _is_processing: bool = false


func add_effect(effect: BaseEffect) -> void:
	if effect != null:
		_queue.append(effect)


func add_effects(effects: Array[BaseEffect]) -> void:
	for effect in effects:
		if effect != null:
			_queue.append(effect)


func execute_all() -> void:
	if _is_processing:
		return
	_is_processing = true
	_process_queue()


func _process_queue() -> void:
	while not _queue.is_empty():
		var effect: BaseEffect = _queue.pop_front()
		effect_started.emit(effect)
		effect.execute()
		effect_completed.emit(effect)
	_is_processing = false
	queue_finished.emit()


func clear() -> void:
	_queue.clear()
	_is_processing = false


func get_queue_size() -> int:
	return _queue.size()


func is_queue_processing() -> bool:
	return _is_processing