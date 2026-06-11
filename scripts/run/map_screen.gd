class_name MapScreen
extends Control
## 地图 UI 场景

signal node_selected(node_id: String)
signal back_requested

const MapNodeClass := preload("res://scripts/run/map_node.gd")

@onready var _node_container: Control = $MapContainer/NodeContainer
@onready var _line_container: Control = $MapContainer/LineContainer
@onready var _back_button: Button = $BackButton

var _nodes: Dictionary = {}  # id -> MapNode
var _node_buttons: Dictionary = {}  # id -> Button
var _current_run_seed: int = 0


func _ready() -> void:
	_back_button.pressed.connect(_on_back_pressed)


func setup_map(map_data: Dictionary) -> void:
	_nodes = map_data.get("nodes", {})
	_current_run_seed = map_data.get("seed", 0)
	
	_clear_ui()
	_create_node_buttons()
	_draw_connections()


func _clear_ui() -> void:
	for child in _node_container.get_children():
		child.queue_free()
	for child in _line_container.get_children():
		child.queue_free()
	_node_buttons.clear()


func _create_node_buttons() -> void:
	for node_id in _nodes:
		var node: MapNodeClass = _nodes[node_id]
		var button := Button.new()
		button.text = node.get_display_name()
		button.custom_minimum_size = Vector2(80, 40)
		
		# 根据类型设置颜色
		match node.type:
			MapNodeClass.NodeType.START:
				button.modulate = Color(0.5, 1, 0.5)
			MapNodeClass.NodeType.BOSS:
				button.modulate = Color(1, 0.5, 0.5)
			MapNodeClass.NodeType.EVENT:
				button.modulate = Color(0.5, 0.5, 1)
			MapNodeClass.NodeType.FORGE:
				button.modulate = Color(1, 1, 0.5)
		
		# 位置布局
		var x: float = 100 + node.layer * 120
		var y: float = 150 + (node.get_data("index", 0) % 5) * 80
		button.position = Vector2(x, y)
		
		button.pressed.connect(_on_node_button_pressed.bind(node_id))
		_node_container.add_child(button)
		_node_buttons[node_id] = button
		
		# 已访问的节点禁用
		if node.visited:
			button.disabled = true


func _draw_connections() -> void:
	for node_id in _nodes:
		var node: MapNodeClass = _nodes[node_id]
		var source_button: Button = _node_buttons.get(node_id, null)
		if source_button == null:
			continue
		
		for target_id in node.connections:
			var target_button: Button = _node_buttons.get(target_id, null)
			if target_button == null:
				continue
			
			var line := Line2D.new()
			line.width = 2.0
			line.default_color = Color(0.5, 0.5, 0.5, 0.6)
			line.points = PackedVector2Array([
				source_button.position + source_button.size / 2,
				target_button.position + target_button.size / 2
			])
			_line_container.add_child(line)


func highlight_available_nodes(available_ids: Array[String]) -> void:
	for node_id in _node_buttons:
		var button: Button = _node_buttons[node_id]
		var node: MapNodeClass = _nodes.get(node_id, null)
		
		if node != null:
			# 起点（layer 0）或可用节点且未访问 → 高亮
			if (node.layer == 0 or node_id in available_ids) and not node.visited:
				button.modulate = Color(1.2, 1.2, 0.8)  # 高亮
				button.disabled = false
			elif node.visited:
				button.disabled = true
				button.modulate = Color(0.5, 0.5, 0.5)  # 灰色表示已访问


func _on_node_button_pressed(node_id: String) -> void:
	var node: MapNodeClass = _nodes.get(node_id, null)
	if node != null and not node.visited:
		node_selected.emit(node_id)


func _on_back_pressed() -> void:
	back_requested.emit()