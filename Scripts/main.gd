extends Node3D
class_name Main

func _ready() -> void:
	Globals.main = self
	LoadScene.load_scene(null, "res://Scenes/main_menu.tscn")
