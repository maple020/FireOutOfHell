extends Node
## 全局单例，管理场景切换与全局配置。

var run_manager: RunManager


func _ready() -> void:
	run_manager = RunManager.new()
	add_child(run_manager)
