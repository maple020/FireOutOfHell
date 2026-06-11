class_name BlockEffect
extends BaseEffect
## 格挡效果，为目标增加护盾。

func execute() -> void:
	if target != null and target.has_method("gain_block"):
		target.gain_block(value)


func get_description() -> String:
	return "Block " + str(value)