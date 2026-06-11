class_name CharacterData
extends Resource
## 角色数据资源

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var max_hp: int = 80
@export var starting_deck: PackedStringArray = []
@export var starting_energy: int = 3
@export var starting_relics: PackedStringArray = []