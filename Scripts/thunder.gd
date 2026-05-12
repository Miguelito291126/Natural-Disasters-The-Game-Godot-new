extends Node3D
class_name Thunder

var explosion_scene = preload("res://Scenes/thunder_explosion.tscn")

@onready var spark = $spark
@onready var light = $light
@onready var star = $star

# Called when the node enters the scene tree for the first time.
func _ready():
	# Configurar la posición de la explosión en la posición del suelo	
	spark.emitting = true
	light.emitting = true
	star.emitting = true

	if multiplayer.is_server():
		spawn_explosion.call_deferred()

func _on_spark_finished():
	self.queue_free()

func spawn_explosion() -> void:
	if not explosion_scene:
		return

	var explosion_node = explosion_scene.instantiate() as Node3D
	explosion_node.top_level = true
	get_parent().add_child(explosion_node, true)
	explosion_node.global_position = global_position

