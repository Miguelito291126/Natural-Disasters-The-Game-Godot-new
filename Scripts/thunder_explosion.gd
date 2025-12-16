extends Node3D

var explosion_force = 100
var explosion_damage = 100
@onready var explosion_radius = $Area3D/CollisionShape3D.shape.radius
@onready var parks = $Parks

var lol = [preload("res://Sounds/disasters/nature/closethunder01.mp3"), preload("res://Sounds/disasters/nature/closethunder02.mp3"), preload("res://Sounds/disasters/nature/closethunder03.mp3"), preload("res://Sounds/disasters/nature/closethunder04.mp3"), preload("res://Sounds/disasters/nature/closethunder05.mp3")]
@onready var audio_player = $AudioStreamPlayer3D

# Called when the node enters the scene tree for the first time.
func _ready():
	parks.emitting = true

	# Configurar el sonido del trueno
	audio_player.stream = lol[randi_range(0, lol.size() - 1)]
	audio_player.play()
	

func _on_finished():
	self.queue_free()



func _on_area_3d_body_entered(body: Node3D) -> void:
	# Aplicar fuerza de explosión a objetos RigidBody3D
	if body is RigidBody3D:
		var distance = (global_position - body.global_position).length()
		# Calcular dirección desde la explosión hacia el objeto
		var direction = (body.global_position - global_position).normalized()
		
		# Calcular fuerza basada en la distancia (más cerca = más fuerza)
		var force_multiplier = 1.0 - clamp(distance / explosion_radius, 0.0, 1.0)
		var force = explosion_force * force_multiplier
		
		# Aplicar impulso al RigidBody3D
		body.apply_impulse(direction * force, Vector3.ZERO)
