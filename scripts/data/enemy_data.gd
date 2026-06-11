class_name EnemyData
extends Resource
## 敌人数据资源，定义基础属性与意图池。

@export var id: String = ""
@export var display_name: String = ""
@export var max_hp: int = 50
@export var art: Texture2D
@export var intent_pool: Array[String] = []

## 意图定义：每条格式为 "类型:数值"，如 "attack:10", "defend:5", "buff:3"
## 支持的类型：attack（攻击）、defend（防御）、buff（强化）、debuff（减益）
