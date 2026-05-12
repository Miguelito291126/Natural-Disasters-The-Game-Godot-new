extends RigidBody3D
class_name Meteor

@export var explosion_scene: PackedScene = preload("res://Scenes/explosion.tscn")
@export var is_volcano_rock: bool = false

func _ready() -> void:
	if not is_volcano_rock:
		global_position += Vector3(0, 1000, 0)

func _on_body_entered(body: Node) -> void:
	if body == self: return

	if multiplayer.is_server():
		spawn_explosion.call_deferred()
	
	queue_free()

func spawn_explosion() -> void:
	if not explosion_scene: return

	var explosion_node = explosion_scene.instantiate()
	explosion_node.top_level = true
	get_parent().add_child(explosion_node, true)
	
	explosion_node.global_position = global_position