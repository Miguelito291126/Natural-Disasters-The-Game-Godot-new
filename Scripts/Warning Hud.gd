extends CanvasLayer

@onready var label = $Panel/Label

func _enter_tree():
	if multiplayer.multiplayer_peer != null:
		set_multiplayer_authority(multiplayer.get_unique_id())

func _ready() -> void:
	if multiplayer.multiplayer_peer != null:
		self.visible = is_multiplayer_authority()
		if not is_multiplayer_authority():
			return

	if Globals.gamemode != "survival":
		self.visible = false
		return
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if multiplayer.multiplayer_peer != null:
		if not is_multiplayer_authority():
			return
		if not multiplayer.is_server():
			return

	if Globals.started:
		label.text = "Current Disasters/Weather is: \n"  + Globals.current_weather_and_disaster + "\nTime Left for the next disasters: \n" + str(int(Globals.timer.time_left)) + "\nTime:\n" + str(Globals.Hour) + ":" + str(Globals.Minute)
	else:
		label.text = "Waiting for players... Time remain: \n" + str(int(Globals.time_left))
