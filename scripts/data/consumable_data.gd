class_name ConsumableData
extends Resource
## 消耗品数据资源，战斗中使用后立即消耗

enum ConsumableType {
	HEAL,           # 治疗
	ENERGY,         # 能量
	DAMAGE,         # 伤害
	STATUS,         # 状态
	DRAW,           # 抽牌
	BLOCK           # 格挡
}

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var type: ConsumableType = ConsumableType.HEAL
@export var value: int = 0
@export var icon: Texture2D
@export var rarity: int = 0  # 0=普通, 1=稀有, 2=传说