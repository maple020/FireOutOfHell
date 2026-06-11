class_name DamageEffect
extends BaseEffect
## 伤害效果，对目标造成伤害。

func execute() -> void:
	if target != null and target.has_method("take_damage"):
		target.take_damage(value)


func get_description() -> String:
	return "Damage " + str(value)