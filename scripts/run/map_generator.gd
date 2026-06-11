class_name MapGenerator
extends RefCounted
## 地图生成器，根据 Seed 生成分层路线图

const MapNode := preload("res://scripts/run/map_node.gd")

@export var layers: int = 12
@export var min_nodes_per_layer: int = 2
@export var max_nodes_per_layer: int = 5
@export var connection_chance: float = 0.6

var _rng: RandomNumberGenerator
var _nodes: Dictionary = {}  # id -> MapNode
var _layers_nodes: Array[Array] = []  # 每层的节点列表


func generate(seed_value: int) -> Dictionary:
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed_value
	
	_nodes.clear()
	_layers_nodes.clear()
	
	# 生成每层节点
	for layer in range(layers):
		var layer_nodes: Array[MapNode] = []
		var node_count: int = _rng.randi_range(min_nodes_per_layer, max_nodes_per_layer)
		
		# 最后一层固定为 Boss
		if layer == layers - 1:
			node_count = 1
		
		for i in range(node_count):
			var node_type: MapNode.NodeType = _get_node_type(layer)
			var node := MapNode.new(_generate_node_id(layer, i), node_type, layer)
			_nodes[node.id] = node
			layer_nodes.append(node)
		
		_layers_nodes.append(layer_nodes)
	
	# 连接相邻层
	_connect_layers()
	
	# 设置起点
	if _layers_nodes.size() > 0 and _layers_nodes[0].size() > 0:
		_layers_nodes[0][0].type = MapNode.NodeType.START
	
	# 为每个节点添加 index 数据用于 UI 布局
	for layer_idx in range(_layers_nodes.size()):
		for node_idx in range(_layers_nodes[layer_idx].size()):
			var node: MapNode = _layers_nodes[layer_idx][node_idx]
			node.set_data("index", node_idx)
	
	return {
		"nodes": _nodes,
		"layers": _layers_nodes,
		"seed": seed_value
	}


func _get_node_type(layer: int) -> MapNode.NodeType:
	if layer == layers - 1:
		return MapNode.NodeType.BOSS
	
	# 每隔 3 层可能有事件/熔炉
	if layer > 0 and layer % 3 == 0:
		var roll: float = _rng.randf()
		if roll < 0.3:
			return MapNode.NodeType.EVENT
		elif roll < 0.5:
			return MapNode.NodeType.FORGE
	
	return MapNode.NodeType.COMBAT


func _generate_node_id(layer: int, index: int) -> String:
	return "node_%d_%d" % [layer, index]


func _connect_layers() -> void:
	for layer_idx in range(_layers_nodes.size() - 1):
		var current_layer: Array = _layers_nodes[layer_idx]
		var next_layer: Array = _layers_nodes[layer_idx + 1]
		
		# 确保每个节点至少有一个连接
		for current_node in current_layer:
			# 随机连接到下一层 1-2 个节点
			var connect_count: int = _rng.randi_range(1, min(2, next_layer.size()))
			var shuffled_next: Array = next_layer.duplicate()
			shuffled_next.shuffle()
			
			for i in range(connect_count):
				var target: MapNode = shuffled_next[i]
				current_node.add_connection(target.id)
				target.set_data("incoming", target.get_data("incoming", 0) + 1)


func get_node(node_id: String) -> MapNode:
	return _nodes.get(node_id, null)


func get_nodes_in_layer(layer: int) -> Array[MapNode]:
	if layer < 0 or layer >= _layers_nodes.size():
		return []
	return _layers_nodes[layer].duplicate()


func get_all_nodes() -> Dictionary:
	return _nodes.duplicate()


func get_total_layers() -> int:
	return _layers_nodes.size()