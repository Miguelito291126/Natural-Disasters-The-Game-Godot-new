extends RigidBody3D

var explosion_scene = preload("res://Scenes/explosion.tscn")
@export var rand_num = randi_range(1,50)
@export var is_volcano_rock = false
@export var gravity_multiplier := 4.5

# Called when the node enters the scene tree for the first time.
func _ready():
	# Solo mover hacia arriba si NO es una roca del volcán
	if not is_volcano_rock:
		self.global_position += Vector3(0, 1000, 0)

		
	self.gravity_scale = gravity_multiplier


func _on_body_entered(body):
	if body == self:
		return

	var explosion_node = explosion_scene.instantiate()
	explosion_node.global_position = self.global_position
	explosion_node.get_node("Area3D/CollisionShape3D").shape.radius = rand_num
	get_parent().add_child(explosion_node, true)
	self.queue_free()
