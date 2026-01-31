extends CanvasLayer

@onready var label = $Panel/Label

func _enter_tree():
	set_multiplayer_authority(multiplayer.get_unique_id())

func _ready() -> void:

	self.visible = is_multiplayer_authority()
	if not is_multiplayer_authority():
		return


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):

	if not is_multiplayer_authority():
		return

		
	if not multiplayer.is_server():
		return

	if Globals.started:
		if Globals.gamemode != "survival":
			label.text = "Current Disasters/Weather is: \n"  + Globals.current_weather_and_disaster + "\nTime:\n" + str(Globals.Hour) + ":" + str(Globals.Minute)
		else:
			label.text = "Current Disasters/Weather is: \n"  + Globals.current_weather_and_disaster + "\nTime Left for the next disasters: \n" + str(int(Globals.timer.time_left)) + "\nTime:\n" + str(Globals.Hour) + ":" + str(Globals.Minute)
	else:
		label.text = "Waiting for players... Time remain: \n" + str(int(Globals.time_left))
