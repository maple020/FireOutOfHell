class_name RelicData
extends Resource
## 遗物数据资源，整局永久生效的修改器。

enum RelicRarity { COMMON, UNCOMMON, RARE, BOSS, SPECIAL }

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var rarity: RelicRarity = RelicRarity.COMMON
@export var icon: Texture2D
