extends Node3D
class_name ThunderExplosion

@export var explosion_force: int = 100
@export var explosion_damage: int = 100
var explosion_radius: int 

@onready var col_shape: CollisionShape3D = $Area3D/CollisionShape3D
@onready var parks = $Parks

@export var lol: Array = [preload("res://Sounds/disasters/nature/closethunder01.mp3"), preload("res://Sounds/disasters/nature/closethunder02.mp3"), preload("res://Sounds/disasters/nature/closethunder03.mp3"), preload("res://Sounds/disasters/nature/closethunder04.mp3"), preload("res://Sounds/disasters/nature/closethunder05.mp3")]
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

# Called when the node enters the scene tree for the first time.
func _ready():
	parks.emitting = true

	if col_shape.shape is SphereShape3D:
		explosion_radius = col_shape.shape.radius

	# Configurar el sonido del trueno
	audio_player.stream = lol[randi_range(0, lol.size() - 1)]
	audio_player.play()
	

func _on_finished():
	self.queue_free()



func _on_area_3d_body_entered(body: Node3D) -> void:
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
	pass
