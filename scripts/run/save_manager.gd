class_name SaveManager
extends Node
## Run 存档管理器

const SAVE_PATH := "user://run_save.json"

var _current_save: Dictionary = {}


func save_run(run_state: Dictionary) -> bool:
	_current_save = run_state.duplicate(true)
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("无法创建存档文件")
		return false
	
	var json_string := JSON.stringify(_current_save, "\t")
	file.store_string(json_string)
	file.close()
	
	return true


func load_run() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("无法读取存档文件")
		return {}
	
	var json_string := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		push_error("存档文件解析失败")
		return {}
	
	_current_save = json.data
	return _current_save.duplicate(true)


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	_current_save.clear()


func get_current_save() -> Dictionary:
	return _current_save.duplicate(true)