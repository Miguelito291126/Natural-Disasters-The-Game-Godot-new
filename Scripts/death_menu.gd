extends CanvasLayer

func _ready():
	self.hide()

func _on_return_pressed():
	if multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		get_tree().paused = false

	get_parent()._reset_player()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	self.hide()
		

func _on_exit_pressed():
	Globals.close_conection()
		
