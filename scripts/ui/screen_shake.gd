class_name ScreenShake
extends Node
## 屏幕震动组件

@export var enabled: bool = true
@export var max_shake_intensity: float = 10.0

var _camera: Camera2D
var _shake_timer: float = 0.0
var _shake_intensity: float = 0.0
var _original_position: Vector2


func _ready() -> void:
	_find_camera()


func _find_camera() -> void:
	_camera = get_viewport().get_camera_2d()
	if _camera != null:
		_original_position = _camera.position


func start_shake(intensity: float, duration: float) -> void:
	if not enabled:
		return
	
	if _camera == null:
		_find_camera()
		if _camera == null:
			return
	
	_shake_intensity = min(intensity, max_shake_intensity)
	_shake_timer = duration
	_original_position = _camera.position


func _process(delta: float) -> void:
	if _shake_timer > 0 and _camera != null:
		_shake_timer -= delta
		
		# 计算震动偏移
		var offset := Vector2(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity)
		)
		
		_camera.position = _original_position + offset
		
		# 衰减
		_shake_intensity = lerp(_shake_intensity, 0.0, delta * 5.0)
		
		if _shake_timer <= 0:
			_camera.position = _original_position