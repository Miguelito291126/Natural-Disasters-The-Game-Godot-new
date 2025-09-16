extends CanvasLayer

@onready var player = get_parent()
var NextHeartSoundTime = Time.get_unix_time_from_system()

@onready var hearth = $Panel/Panel2/Heart
@onready var label = $Panel/Label
@onready var fps = $FPS
@onready var hearthbeat_sound = $Heartbeat
@onready var animation_player = $Panel/Panel2/Heart/AnimationPlayer

func _ready() -> void:
	animation_player.play("Heartbeat")

func _process(_delta):

	if Globals.is_networking:
		if not player.is_multiplayer_authority():
			self.visible = player.is_multiplayer_authority()
			return
		
	self.visible = true
	var freq = clamp((1-float((44-round( get_parent().body_temperature)) / 20)) * (180/60), 0.5, 20)

	if get_parent().hearth <= 0:
		freq = 0.05

	animation_player.speed_scale = freq

	if Globals.GlobalsData.FPS:
		fps.visible = true
	else:
		fps.visible = false

	label.text = "Temperature: " + str(snapped(Globals.Temperature, 0.1)) + "ºC\n" + "Humidity: " + str(round(Globals.Humidity)) + "%\n" + "Wind Direction: " + str(round(Globals.convert_VectorToAngle(Globals.Wind_Direction))) + "º\n" + "Wind Speed: " + str(round(Globals.Wind_speed)) + "km/s\n" + "Body Hearth: " + str(round(player.hearth)) + "%\n" + "Body Temperature: " + str(snapped(player.body_temperature, 0.1)) + "ºC\n" + "Body Oxygen: " + str(round(player.body_oxygen))  + "%\n" + "Local Wind Speed: " + str(round(player.body_wind)) + "km/s\n"
	fps.text = "FPS: " + str(Engine.get_frames_per_second())

	if Time.get_unix_time_from_system() >= NextHeartSoundTime:
		hearthbeat_sound.play()
		NextHeartSoundTime = Time.get_unix_time_from_system() + freq/1
