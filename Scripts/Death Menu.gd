extends CanvasLayer

func _ready():
	self.hide()

func _on_return_pressed():

	if not multiplayer.multiplayer_peer != null:
		get_tree().paused = false

	get_parent()._reset_player()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	self.hide()
		

func _on_exit_pressed():
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
		return

	get_tree().paused = false
	LoadScene.load_scene(Globals.map, "res://Scenes/main_menu.tscn")
