class_name EventData
extends Resource
## 事件数据资源，叙事 + 机械选择分支。

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var art: Texture2D
@export var choice_labels: Array[String] = []
