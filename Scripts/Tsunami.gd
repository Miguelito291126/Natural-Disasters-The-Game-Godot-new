extends Area3D

@onready var tsunami = $tsunami
@export var speed = 100
@export var tsunami_strength = 100
@export var direction = Vector3(0, 0, 1)
@export var distance_traveled = 0.0
@export var total_distance = 4097.0  # Adjust this value based on your scene

func _physics_process(delta):
	global_position += direction * speed * delta

	for body in get_overlapping_bodies():
		if body.is_in_group("movable_objects") and body.is_class("RigidBody3D"):
			var force = direction.normalized() * tsunami_strength * delta
			body.apply_central_impulse(force)
			body.freeze = false
		elif body.is_in_group("player"):
			body.velocity = direction * speed * 100 * delta
