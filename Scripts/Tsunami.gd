extends Area3D

class_name Tsunami

@export var speed: int = 100
@export var tsunami_strength: int = 100
@export var direction: Vector3 = Vector3(0, 0, 1)
@export var total_distance: float = 4097.0

@onready var tsunami_node: Node3D = $tsunami

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

	for body in get_overlapping_bodies():
		if body.is_in_group("movable_objects") and body is RigidBody3D:
			var force = direction.normalized() * tsunami_strength * delta
			body.apply_central_impulse(force)
			body.freeze = false
		elif body.is_in_group("player") and body.has_method("apply_disasters_push"):
			var push_force = direction.normalized() * speed * 1.5
			body.apply_disasters_push(push_force)