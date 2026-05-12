extends Node3D
class_name Explosion

@export var explosion_force: int = 100
@export var explosion_damage: int = 100
var explosion_radius: int

@onready var col_shape: CollisionShape3D = $Area3D/CollisionShape3D
@onready var smoke: GPUParticles3D = $Smoke
@onready var smoke_shockwave: GPUParticles3D = $"Smoke shock"
@onready var sparks: GPUParticles3D = $Sparks
@onready var sparks_shock: GPUParticles3D = $"Sparks shock"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Obtener el radio desde la forma de colisión (SphereShape3D)
	if col_shape.shape is SphereShape3D:
		explosion_radius = col_shape.shape.radius

	# Activar la emisión de todas las partículas
	sparks.emitting = true
	smoke_shockwave.emitting = true
	smoke.emitting = true
	sparks_shock.emitting = true



func _on_finished():
	self.queue_free()


func _on_area_3d_body_entered(body: Node) -> void:
	# Aplicar fuerza de explosión a objetos RigidBody3D
	if body is RigidBody3D:
		var rigid_body = body as RigidBody3D
		var distance = global_position.distance_to(rigid_body.global_position)
		
		# Calcular dirección desde la explosión hacia el objeto
		var direction = (rigid_body.global_position - global_position).normalized()

		# Calcular fuerza basada en la distancia (más cerca = más fuerza)
		var force_multiplier = clamp(1.0 - (distance / explosion_radius), 0.0, 1.0)
		var final_force = direction * explosion_force * force_multiplier
		
		rigid_body.apply_central_impulse(final_force)

	elif body is Player:
		var player = body as Player
		var distance = global_position.distance_to(player.global_position)
		var direction = (player.global_position - global_position).normalized()
		var force_multiplier = clamp(1.0 - (distance / explosion_radius), 0.0, 1.0)
		var final_force = direction * explosion_force * force_multiplier

		player.apply_disasters_push(final_force)
		player.damage.rpc(float(explosion_damage) * force_multiplier)


func _on_area_3d_area_entered(area: Area3D) -> void:
	pass # Replace with function body.
