extends Area3D

class_name Tornado

@export var movement_speed: float = 10.0
@export var movement_radius: float = 50.0
@export var ray_length: float = 1000.0
@export var tornado_strength: float = 100.0
@export var radius: float = 10.0

var ground_height: float = 0.0
@onready var ray_cast: RayCast3D = $RayCast

func _ready() -> void:
	ray_cast.target_position = Vector3(0, -ray_length, 0)
	ray_cast.force_raycast_update()

func _process(delta: float) -> void:
	if ray_cast.is_colliding():
		ground_height = ray_cast.get_collision_point().y
		global_position.y = ground_height

	var new_pos = Vector3(randf_range(-movement_radius, movement_radius), 0, randf_range(-movement_radius, movement_radius))
	var direction = (new_pos - global_position).normalized()
	translate(direction * movement_speed * delta)

func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		var direction = (body.global_position - global_position).normalized()
		var perpendicular = Vector3(-direction.z, 0, direction.x)
		var force = perpendicular * tornado_strength
		
		if body.is_in_group("movable_objects") and body is RigidBody3D:
			body.apply_central_impulse(force)
			body.freeze = false
		elif body.is_in_group("player") and body.has_method("apply_disasters_push"):
			body.apply_disasters_push(force)