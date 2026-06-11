class_name MapNode
extends RefCounted
## 地图节点模型

enum NodeType {
	COMBAT,   # 战斗
	EVENT,    # 事件
	FORGE,    # 熔炉
	BOSS,     # Boss
	START,    # 起点
	SHOP      # 商店
}

@export var id: String = ""
@export var type: NodeType = NodeType.COMBAT
@export var layer: int = 0
@export var connections: Array[String] = []
@export var visited: bool = false
@export var position: Vector2 = Vector2.ZERO

var _data: Dictionary = {}


func _init(node_id: String = "", node_type: NodeType = NodeType.COMBAT, node_layer: int = 0) -> void:
	id = node_id
	type = node_type
	layer = node_layer


func add_connection(target_id: String) -> void:
	if target_id not in connections:
		connections.append(target_id)


func is_connected_to(target_id: String) -> bool:
	return target_id in connections


func mark_visited() -> void:
	visited = true


func set_data(key: String, value) -> void:
	_data[key] = value


func get_data(key: String, default_value = null):
	return _data.get(key, default_value)


func get_display_name() -> String:
	match type:
		NodeType.COMBAT:
			return "战斗"
		NodeType.EVENT:
			return "事件"
		NodeType.FORGE:
			return "熔炉"
		NodeType.BOSS:
			return "Boss"
		NodeType.START:
			return "起点"
		NodeType.SHOP:
			return "商店"
	return "未知"