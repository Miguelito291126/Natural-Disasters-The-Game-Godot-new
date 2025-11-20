extends Node3D

var explosion_scene = preload("res://Scenes/thunder_explosion.tscn")
@onready var spark = $spark
@onready var light = $light
@onready var star = $star

# Called when the node enters the scene tree for the first time.
func _ready():
	# Configurar la posición de la explosión en la posición del suelo
	var explosion = explosion_scene.instantiate()
	explosion.position = self.position 
	get_parent().add_child(explosion)
	
	spark.emitting = true
	light.emitting = true
	star.emitting = true
	

func _on_spark_finished():
	self.queue_free()