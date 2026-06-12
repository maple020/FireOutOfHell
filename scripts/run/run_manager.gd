class_name RunManager
extends Node
## 管理整局 Run 状态：地图、牌组、遗物、种子与存档。

signal run_started(seed_value: int)
signal run_ended(victory: bool)
signal node_visited(node_id: String)

const MapNodeClass := preload("res://scripts/run/map_node.gd")

var current_seed: int = 0
var ascension_level: int = 0
var current_hp: int = 80
var max_hp: int = 80
var deck: Array[CardData] = []
var relics: Array[RelicData] = []
var current_node_id: String = ""
var map_data: Dictionary = {}
var visited_nodes: Array[String] = []


func start_new_run(seed_value: int = -1, character: CharacterData = null) -> void:
	current_seed = seed_value if seed_value >= 0 else randi()
	ascension_level = 0
	current_hp = max_hp
	deck.clear()
	relics.clear()
	current_node_id = ""
	visited_nodes.clear()
	map_data.clear()
	
	# 加载起始牌组
	if character != null:
		max_hp = character.max_hp
		current_hp = max_hp
		for card_id in character.starting_deck:
			var card_path := "res://data/cards/%s.tres" % card_id
			if ResourceLoader.exists(card_path):
				var card: CardData = load(card_path)
				if card != null:
					deck.append(card)
		
		# 加载起始遗物
		for relic_id in character.starting_relics:
			var relic_path := "res://data/relics/%s.tres" % relic_id
			if ResourceLoader.exists(relic_path):
				var relic: RelicData = load(relic_path)
				if relic != null:
					relics.append(relic)
	else:
		# 默认起始牌组
		var default_cards := ["hellfire_strike", "hellfire_strike", "soul_shield", "soul_shield", "ash_draw", "flame_lash", "flame_lash"]
		for card_id in default_cards:
			var card_path := "res://data/cards/%s.tres" % card_id
			if ResourceLoader.exists(card_path):
				var card: CardData = load(card_path)
				if card != null:
					deck.append(card)
	
	run_started.emit(current_seed)


func end_run(victory: bool) -> void:
	run_ended.emit(victory)


func set_map_data(data: Dictionary) -> void:
	map_data = data


func visit_node(node_id: String) -> void:
	current_node_id = node_id
	if node_id not in visited_nodes:
		visited_nodes.append(node_id)
	node_visited.emit(node_id)
	
	# 标记节点为已访问
	var nodes: Dictionary = map_data.get("nodes", {})
	var node = nodes.get(node_id, null)
	if node is MapNodeClass:
		node.mark_visited()


func get_available_nodes() -> Array[String]:
	if map_data.is_empty():
		return []
	
	var nodes: Dictionary = map_data.get("nodes", {})
	var available: Array[String] = []
	
	# 找到当前层级：基于已访问的节点确定当前层
	var current_layer: int = -1
	for node_id in visited_nodes:
		var node = nodes.get(node_id, null)
		if node is MapNodeClass:
			if node.layer > current_layer:
				current_layer = node.layer
	
	# 如果没有访问任何节点，允许访问第0层
	if current_layer == -1:
		current_layer = -1  # 下一层将是0层
	
	# 查找当前层+1的所有未访问节点
	var target_layer: int = current_layer + 1
	for node_id in nodes:
		var node = nodes[node_id]
		if node is MapNodeClass and not node.visited and node.layer == target_layer:
			# 对于第0层，直接可用
			if target_layer == 0:
				available.append(node_id)
			else:
				# 检查是否有已访问的前置节点连接
				if _has_visited_connection(node, nodes):
					available.append(node_id)
	
	return available


func _has_visited_connection(node, all_nodes: Dictionary) -> bool:
	for node_id in all_nodes:
		var other = all_nodes[node_id]
		if other is MapNodeClass and other.visited and other.is_connected_to(node.id):
			return true
	return false


func add_card_to_deck(card: CardData) -> void:
	if card != null:
		deck.append(card)


func remove_card_from_deck(card: CardData) -> void:
	deck.erase(card)


func add_relic(relic: RelicData) -> void:
	if relic != null:
		relics.append(relic)


func take_damage(amount: int) -> void:
	current_hp = max(current_hp - amount, 0)


func heal(amount: int) -> void:
	current_hp = min(current_hp + amount, max_hp)


func get_run_state() -> Dictionary:
	return {
		"seed": current_seed,
		"ascension": ascension_level,
		"hp": current_hp,
		"max_hp": max_hp,
		"deck": deck,
		"relics": relics,
		"current_node": current_node_id,
		"visited_nodes": visited_nodes,
		"map_data": map_data
	}
