class_name HitEffect
extends Node2D
## 命中特效组件，显示伤害/格挡/治疗等视觉反馈

@export var effect_type: String = "damage"  # damage, block, heal
@export var duration: float = 0.3

var _particles: GPUParticles2D


func _ready() -> void:
	_create_particles()


func play_effect(color: Color = Color.WHITE) -> void:
	if _particles != null:
		_particles.modulate = color
		_particles.restart()
		_particles.emitting = true
	
	# 自动销毁
	await get_tree().create_timer(duration).timeout
	queue_free()


func _create_particles() -> void:
	_particles = GPUParticles2D.new()
	add_child(_particles)
	
	var material := ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 20.0
	material.gravity = Vector3(0, 100, 0)
	material.initial_velocity_min = 50.0
	material.initial_velocity_max = 150.0
	material.scale_min = 2.0
	material.scale_max = 4.0
	material.lifetime_randomness = 0.3
	
	_particles.process_material = material
	_particles.amount = 20
	_particles.lifetime = 0.4
	_particles.one_shot = true
	_particles.explosiveness = 0.8