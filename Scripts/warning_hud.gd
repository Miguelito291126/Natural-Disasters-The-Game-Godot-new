extends CanvasLayer

class_name WarningHud

@onready var label: Label = $Panel/Label

func _enter_tree() -> void:
	# Intentamos obtener el ID del nombre del padre (Player) para la autoridad
	var parent_name = get_parent().name
	if parent_name.is_valid_int():
		set_multiplayer_authority(parent_name.to_int())
	else:
		# Si falla, usamos la autoridad del padre directamente
		set_multiplayer_authority(get_parent().get_multiplayer_authority())

func _ready() -> void:
	# Solo el dueño de este HUD debe verlo
	visible = is_multiplayer_authority()
	
	if not is_multiplayer_authority():
		set_process(false) # Ahorra rendimiento si no es nuestro HUD

func _process(_delta: float) -> void:
	# Verificamos autoridad local
	if not is_multiplayer_authority():
		return

	if Globals.started:
		# Formateamos la hora y minutos (D2 en C# es %02d en GDScript)
		var time_string = "%02d:%02d" % [Globals.hour, Globals.minute]
		var weather_info = "Current Disasters/Weather is: \n" + Globals.current_weather_and_disaster

		if Globals.gamemode != "survival":
			label.text = weather_info + "\nTime:\n" + time_string
		else:
			# Aquí iría la lógica específica de survival que tenías pendiente
			label.text = "Survival Mode\nTime: " + time_string