extends Node3D

var explosion_force = 100
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
	
	

func _on_area_3d_body_entered(body:Node3D):
	if body.is_in_group("player"):
		var distance = (body.global_position - global_position).length()
		var direction = (body.global_position - global_position).normalized()
		var force = explosion_force * (1 - distance / explosion_radius)
		body.velocity = direction * force
		body.damage(100)

	elif body.is_in_group("movable_objects") and body.is_class("RigidBody3D"):
		var distance = (body.global_position - global_position).length()
		var direction = (body.global_position - global_position).normalized()
		var force = explosion_force * (1 - distance / explosion_radius)
		body.apply_central_impulse(direction * force)
		body.freeze = false


func _on_finished():
	self.queue_free()

