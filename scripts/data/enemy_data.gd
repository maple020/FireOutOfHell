class_name EnemyData
extends Resource
## 敌人数据资源，定义基础属性与意图池。

@export var id: String = ""
@export var display_name: String = ""
@export var max_hp: int = 50
@export var art: Texture2D
@export var intent_pool: Array[String] = []
