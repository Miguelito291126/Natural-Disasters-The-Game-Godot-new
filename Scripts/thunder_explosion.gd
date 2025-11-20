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
	

func _on_finished():
	self.queue_free()

