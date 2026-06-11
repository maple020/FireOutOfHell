class_name BaseEffect
extends RefCounted
## 效果基类，所有具体效果继承此类。

var source: Node = null
var target: Node = null
var value: int = 0


func _init(source_node: Node = null, target_node: Node = null, effect_value: int = 0) -> void:
	source = source_node
	target = target_node
	value = effect_value


## 执行效果，由子类重写
func execute() -> void:
	pass


## 获取效果描述
func get_description() -> String:
	return "Base Effect"