class_name ObjectPool
extends Node
## 对象池，用于复用高频对象（如飘字、粒子）

@export var pool_size: int = 20
@export var prefab: PackedScene

var _pool: Array[Node] = []
var _active: Array[Node] = []


func _ready() -> void:
	_initialize_pool()


func _initialize_pool() -> void:
	if prefab == null:
		return
	
	for i in range(pool_size):
		var instance: Node = prefab.instantiate()
		instance.visible = false
		_pool.append(instance)
		add_child(instance)


func get_object() -> Node:
	if _pool.is_empty():
		# 池已耗尽，创建新对象
		if prefab != null:
			var new_instance: Node = prefab.instantiate()
			_active.append(new_instance)
			add_child(new_instance)
			return new_instance
		return null
	
	var obj: Node = _pool.pop_back()
	obj.visible = true
	_active.append(obj)
	return obj


func return_object(obj: Node) -> void:
	if obj == null:
		return
	
	if obj in _active:
		_active.erase(obj)
	
	obj.visible = false
	_pool.append(obj)


func clear_pool() -> void:
	for obj in _active:
		obj.queue_free()
	_active.clear()
	
	for obj in _pool:
		obj.queue_free()
	_pool.clear()