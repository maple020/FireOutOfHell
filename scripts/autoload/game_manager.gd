extends Node
## 全局单例，管理场景切换与全局配置。

var run_manager: RunManager
var current_scene: Node = null
var _map_screen_instance: Node = null

const MAIN_MENU_SCENE := "res://scenes/main/main_menu.tscn"
const MAP_SCENE := "res://scenes/run/map_screen.tscn"
const COMBAT_SCENE := "res://scenes/combat/combat_scene.tscn"
const REWARD_SCENE := "res://scenes/ui/reward_screen.tscn"
const RUN_RESULT_SCENE := "res://scenes/ui/run_result.tscn"
const FORGE_SCENE := "res://scenes/run/forge_screen.tscn"
const SHOP_SCENE := "res://scenes/run/shop_screen.tscn"


func _ready() -> void:
	run_manager = RunManager.new()
	add_child(run_manager)
	# 启动时显示主菜单
	call_deferred("show_main_menu")


func show_main_menu() -> void:
	goto_scene(MAIN_MENU_SCENE)


func goto_scene(scene_path: String) -> void:
	call_deferred("_deferred_goto_scene", scene_path)


func _deferred_goto_scene(scene_path: String) -> void:
	if current_scene != null:
		current_scene.queue_free()
		current_scene = null
	
	var new_scene: PackedScene = load(scene_path)
	if new_scene != null:
		current_scene = new_scene.instantiate()
		get_tree().root.add_child(current_scene)
		get_tree().current_scene = current_scene
		
		# === 地图场景完整初始化 ===
		if scene_path == MAP_SCENE and current_scene is MapScreen:
			var map_screen := current_scene as MapScreen
			# 1. 初始化地图数据（创建节点按钮和连接线）
			map_screen.setup_map(run_manager.map_data)
			# 2. 高亮可用节点
			var available := run_manager.get_available_nodes()
			map_screen.highlight_available_nodes(available)
			# 3. 连接信号
			if map_screen.has_signal("node_selected"):
				if not map_screen.is_connected("node_selected", _on_map_node_selected):
					map_screen.node_selected.connect(_on_map_node_selected)
			if map_screen.has_signal("back_requested"):
				if not map_screen.is_connected("back_requested", show_main_menu):
					map_screen.back_requested.connect(show_main_menu)
		
		# === 奖励场景初始化 ===
		elif scene_path == REWARD_SCENE and current_scene is RewardScreen:
			# 信号连接在 enter_reward 中处理
			pass
		
		# === 结算场景初始化 ===
		elif scene_path == RUN_RESULT_SCENE and current_scene is RunResult:
			# 信号连接在 show_run_result 中处理
			pass
		
		# === 战斗场景初始化 ===
		elif scene_path == COMBAT_SCENE:
			# 战斗场景的 _ready 会自动启动
			pass


func start_new_run(seed_value: int = -1) -> void:
	# 默认使用灵魂收割者角色
	var character: CharacterData = null
	var char_path := "res://data/characters/soul_reaver.tres"
	if ResourceLoader.exists(char_path):
		character = load(char_path)
	
	run_manager.start_new_run(seed_value, character)
	
	# 生成地图
	var generator := MapGenerator.new()
	var map_data: Dictionary = generator.generate(run_manager.current_seed)
	run_manager.set_map_data(map_data)
	
	goto_scene(MAP_SCENE)


func load_run() -> void:
	var save_manager := SaveManager.new()
	var save_data := save_manager.load_run()
	if not save_data.is_empty():
		# 恢复 Run 状态
		run_manager.current_seed = save_data.get("seed", 0)
		run_manager.current_hp = save_data.get("hp", 80)
		run_manager.max_hp = save_data.get("max_hp", 80)
		run_manager.deck = save_data.get("deck", [])
		run_manager.relics = save_data.get("relics", [])
		run_manager.current_node_id = save_data.get("current_node", "")
		run_manager.visited_nodes = save_data.get("visited_nodes", [])
		run_manager.map_data = save_data.get("map_data", {})
		
		goto_scene(MAP_SCENE)
	else:
		start_new_run()


func has_save() -> bool:
	var save_manager := SaveManager.new()
	return save_manager.has_save()


func enter_combat(enemy_data: EnemyData = null) -> void:
	goto_scene(COMBAT_SCENE)
	# TODO: 传递 enemy_data 到战斗场景


func enter_reward(cards: Array[CardData]) -> void:
	goto_scene(REWARD_SCENE)
	if current_scene is RewardScreen:
		current_scene.setup_rewards(cards)
		if current_scene.has_signal("card_selected"):
			current_scene.card_selected.connect(_on_reward_card_selected)
		if current_scene.has_signal("reward_skipped"):
			current_scene.reward_skipped.connect(_on_reward_skipped)


func _on_reward_card_selected(card: CardData) -> void:
	run_manager.add_card_to_deck(card)
	return_to_map()


func _on_reward_skipped() -> void:
	return_to_map()


func enter_forge() -> void:
	goto_scene(FORGE_SCENE)


func enter_shop() -> void:
	goto_scene(SHOP_SCENE)


func return_to_map() -> void:
	goto_scene(MAP_SCENE)


func show_run_result(victory: bool) -> void:
	goto_scene(RUN_RESULT_SCENE)
	if current_scene is RunResult:
		current_scene.setup_result(victory, 0, 0, run_manager.deck.size())
		if current_scene.has_signal("restart_requested"):
			current_scene.restart_requested.connect(_on_restart_requested)


func _on_restart_requested() -> void:
	show_main_menu()


func _on_map_node_selected(node_id: String) -> void:
	var nodes: Dictionary = run_manager.map_data.get("nodes", {})
	var node = nodes.get(node_id, null)
	
	if node == null:
		return
	
	run_manager.visit_node(node_id)
	
	match node.type:
		MapNode.NodeType.COMBAT:
			enter_combat()
		MapNode.NodeType.BOSS:
			enter_combat()
		MapNode.NodeType.EVENT:
			# TODO: 进入事件场景
			return_to_map()
		MapNode.NodeType.FORGE:
			enter_forge()
		MapNode.NodeType.SHOP:
			enter_shop()
		_:
			return_to_map()
