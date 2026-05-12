extends CanvasLayer
class_name HUD

var player: Player # Se asigna en _ready
var timer: float = 0.0

@onready var health: TextureRect = $Panel/Panel2/Heart
@onready var label: Label = $Panel/Label
@onready var fps: Label = $FPS
@onready var healthbeat_sound: AudioStreamPlayer = $Heartbeat
@onready var animation_player: AnimationPlayer = $Panel/Panel2/Heart/AnimationPlayer

func _enter_tree() -> void:
	var parent_name = get_parent().name
	if parent_name.is_valid_int():
		set_multiplayer_authority(parent_name.to_int())
	else:
		set_multiplayer_authority(get_parent().get_multiplayer_authority())

func _ready() -> void:
	player = get_parent()
	
	# Solo mostramos el HUD si somos el dueño de este jugador
	visible = is_multiplayer_authority()
	
	if not is_multiplayer_authority():
		set_process(false)

func _process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	# Lógica de latidos basada en la temperatura del cuerpo del jugador
	var normal_temp: float = 37.0
	# Asumiendo que tu script de Player tiene 'body_temperature'
	var temp: float = player.body_temperature if "body_temperature" in player else 37.0
	var delta_temp: float = abs(temp - normal_temp)
	
	# Frecuencia basada en temperatura (más lejos de 37, más rápido)
	var freq: float = clamp(1.0 + (delta_temp * 0.15), 0.8, 4.0)
	animation_player.speed_scale = freq

	timer += delta * freq
			
	if timer >= 1.2: # Umbral de latido
		if not healthbeat_sound.playing:
			# El tono sube un poco al estar más agitado
			healthbeat_sound.pitch_scale = lerp(1.0, 1.3, freq / 4.0)
			healthbeat_sound.play()
		timer = 0.0

	# Mostrar FPS si la configuración lo permite
	if Globals.globals_data and "fps" in Globals.globals_data:
		fps.visible = Globals.globals_data.fps
	
	if fps.visible:
		fps.text = "FPS: %d" % Engine.get_frames_per_second()

	# Actualización de información de clima y salud
	var display_temp = snapped(Globals.temperature, 0.1)
	var display_health = player.health
	var display_body_temp = player.body_temperature
	var display_body_oxygen = player.body_oxygen
	var display_body_radiation = player.body_bradiation
	var display_oxygen = snapped(Globals.oxygen, 0.1)
	var display_radiation = snapped(Globals.bradiation, 0.1)
	var display_pressure = snapped(Globals.pressure, 0.1)
	var display_wind_speed = snapped(Globals.wind_speed, 0.1)
	var display_wind_dir = Globals.wind_direction # Esto suele ser un Vector3



	label.text = "Temperature: " + str(display_temp) + "Cº\n" + \
				"Body Temperature: " + str(display_body_temp) + "Cº\n" + \
				"Health: " + str(display_health) + "\n" + \
				"Body Oxygen: " + str(display_body_oxygen) + "%\n" + \
				"Oxygen: " + str(display_oxygen) + "%\n" + \
				"Radiation: " + str(display_radiation) + "%\n" + \
				"Body Radiation: " + str(display_body_radiation) + "%\n" + \
				"Pressure: " + str(display_pressure) + " Pa\n" + \
				"Wind Speed: " + str(display_wind_speed) + "km/h\n" + \
				"Wind Direction: " + str(display_wind_dir)
