extends Node
## 全局单例，管理场景切换与全局配置。

var run_manager: RunManager
var current_scene: Node = null
var _map_screen_instance: Node = null
var _pending_enemy_data: EnemyData = null
var _pending_reward_cards: Array[CardData] = []
var _pending_run_result: Dictionary = {}

const MAIN_MENU_SCENE := "res://scenes/main/main_menu.tscn"
const MAP_SCENE := "res://scenes/run/map_screen.tscn"
const COMBAT_SCENE := "res://scenes/combat/combat_scene.tscn"
const REWARD_SCENE := "res://scenes/ui/reward_screen.tscn"
const RUN_RESULT_SCENE := "res://scenes/ui/run_result.tscn"
const FORGE_SCENE := "res://scenes/run/forge_screen.tscn"
const SHOP_SCENE := "res://scenes/run/shop_screen.tscn"
const EVENT_SCENE := "res://scenes/run/event_screen.tscn"


func _ready() -> void:
	run_manager = RunManager.new()
	add_child(run_manager)
	run_manager.run_ended.connect(_on_run_ended)
	call_deferred("show_main_menu")


func show_main_menu() -> void:
	goto_scene(MAIN_MENU_SCENE)


func goto_scene(scene_path: String) -> void:
	call_deferred("_deferred_goto_scene", scene_path)


func _deferred_goto_scene(scene_path: String) -> void:
	if current_scene != null:
		# 立即从场景树中移除旧场景，防止 UI 残留
		get_tree().root.remove_child(current_scene)
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
			map_screen.setup_map(run_manager.map_data)
			var available := run_manager.get_available_nodes()
			map_screen.highlight_available_nodes(available)
			if map_screen.has_signal("node_selected"):
				if not map_screen.is_connected("node_selected", _on_map_node_selected):
					map_screen.node_selected.connect(_on_map_node_selected)
			if map_screen.has_signal("back_requested"):
				if not map_screen.is_connected("back_requested", show_main_menu):
					map_screen.back_requested.connect(show_main_menu)
		
		# === 奖励场景初始化 ===
		elif scene_path == REWARD_SCENE and current_scene is RewardScreen:
			var rs := current_scene as RewardScreen
			if not _pending_reward_cards.is_empty():
				rs.setup_rewards(_pending_reward_cards)
				_pending_reward_cards.clear()
			if rs.has_signal("card_selected"):
				if not rs.is_connected("card_selected", _on_reward_card_selected):
					rs.card_selected.connect(_on_reward_card_selected)
			if rs.has_signal("reward_skipped"):
				if not rs.is_connected("reward_skipped", _on_reward_skipped):
					rs.reward_skipped.connect(_on_reward_skipped)
		
		# === 结算场景初始化 ===
		elif scene_path == RUN_RESULT_SCENE and current_scene is RunResult:
			var rr := current_scene as RunResult
			if not _pending_run_result.is_empty():
				rr.setup_result(
					_pending_run_result.get("victory", false),
					_pending_run_result.get("turns", 0),
					_pending_run_result.get("enemies", 0),
					_pending_run_result.get("deck_size", 0)
				)
				_pending_run_result.clear()
			if rr.has_signal("restart_requested"):
				if not rr.is_connected("restart_requested", _on_restart_requested):
					rr.restart_requested.connect(_on_restart_requested)
		
		# === 战斗场景初始化 ===
		elif scene_path == COMBAT_SCENE and current_scene is CombatManager:
			var cm := current_scene as CombatManager
			if _pending_enemy_data != null:
				cm.incoming_enemy_data = _pending_enemy_data
				_pending_enemy_data = null
			if cm.has_signal("combat_finished"):
				if not cm.is_connected("combat_finished", _on_combat_finished):
					cm.combat_finished.connect(_on_combat_finished)
		
		# === 熔炉场景初始化 ===
		elif scene_path == FORGE_SCENE and current_scene is ForgeScreen:
			var fs := current_scene as ForgeScreen
			if fs.has_signal("leave_requested"):
				if not fs.is_connected("leave_requested", return_to_map):
					fs.leave_requested.connect(return_to_map)
			if fs.has_signal("option_selected"):
				if not fs.is_connected("option_selected", _on_forge_option_selected):
					fs.option_selected.connect(_on_forge_option_selected)
		
		# === 商店场景初始化 ===
		elif scene_path == SHOP_SCENE and current_scene is ShopScreen:
			var ss := current_scene as ShopScreen
			if ss.has_signal("leave_requested"):
				if not ss.is_connected("leave_requested", return_to_map):
					ss.leave_requested.connect(return_to_map)
			if ss.has_signal("item_purchased"):
				if not ss.is_connected("item_purchased", _on_shop_item_purchased):
					ss.item_purchased.connect(_on_shop_item_purchased)
		
		# === 事件场景初始化 ===
		elif scene_path == EVENT_SCENE and current_scene is EventScreen:
			var es := current_scene as EventScreen
			if es.has_signal("event_finished"):
				if not es.is_connected("event_finished", return_to_map):
					es.event_finished.connect(return_to_map)


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


func enter_combat(enemy_data_path: String = "") -> void:
	if not enemy_data_path.is_empty() and ResourceLoader.exists(enemy_data_path):
		_pending_enemy_data = load(enemy_data_path)
	goto_scene(COMBAT_SCENE)


func enter_reward(cards: Array[CardData]) -> void:
	_pending_reward_cards = cards
	goto_scene(REWARD_SCENE)


func _on_reward_card_selected(card: CardData) -> void:
	run_manager.add_card_to_deck(card)
	return_to_map()


func _on_reward_skipped() -> void:
	return_to_map()


func enter_forge() -> void:
	goto_scene(FORGE_SCENE)


func enter_shop() -> void:
	goto_scene(SHOP_SCENE)


func enter_event() -> void:
	goto_scene(EVENT_SCENE)


func return_to_map() -> void:
	goto_scene(MAP_SCENE)


func show_run_result(victory: bool) -> void:
	_pending_run_result = {
		"victory": victory,
		"turns": 0,
		"enemies": 0,
		"deck_size": run_manager.deck.size()
	}
	goto_scene(RUN_RESULT_SCENE)


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
			var enemy_path: String = node.get_data("enemy", "")
			enter_combat(enemy_path)
		MapNode.NodeType.BOSS:
			var enemy_path: String = node.get_data("enemy", "")
			enter_combat(enemy_path)
		MapNode.NodeType.EVENT:
			enter_event()
		MapNode.NodeType.FORGE:
			enter_forge()
		MapNode.NodeType.SHOP:
			enter_shop()
		_:
			return_to_map()


func _on_combat_finished(victory: bool) -> void:
	if not victory:
		run_manager.end_run(false)
		show_run_result(false)


func _on_forge_option_selected(option: String) -> void:
	match option:
		"heal":
			run_manager.heal(int(run_manager.max_hp * 0.3))
		"upgrade":
			pass
		"remove":
			if run_manager.deck.size() > 1:
				run_manager.remove_card_from_deck(run_manager.deck[0])


func _on_shop_item_purchased(item_data, cost: int) -> void:
	if item_data is CardData:
		run_manager.add_card_to_deck(item_data)
	elif item_data is RelicData:
		run_manager.add_relic(item_data)


func _on_run_ended(victory: bool) -> void:
	show_run_result(victory)
