class_name CardData
extends Resource
## 卡牌数据资源，通过 .tres 配置，无需改代码即可迭代。

enum CardType { ATTACK, SKILL, POWER }
enum CardRarity { COMMON, UNCOMMON, RARE, LEGENDARY }
enum TargetType { NONE, ENEMY, ALL_ENEMIES, SELF }

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var cost: int = 1
@export var card_type: CardType = CardType.ATTACK
@export var rarity: CardRarity = CardRarity.COMMON
@export var target_type: TargetType = TargetType.ENEMY
@export var exhaust: bool = false
@export var ethereal: bool = false
@export var art: Texture2D

## 效果配置（简单实现，单张卡最多支持2个效果）
@export var damage: int = 0
@export var block: int = 0
@export var draw: int = 0
