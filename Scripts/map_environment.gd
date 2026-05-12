extends WorldEnvironment
class_name MapEnvironment

@export var sun: DirectionalLight3D
@export var moon: DirectionalLight3D

@export var ingame_speed: int = 60 # 1 = Tiempo real, 60 = 1 hora por minuto real
@export var initial_hour: float = 12.0
@export var sun_base_energy: float = 2.0 # Energía normal del sol
@export var moon_base_energy: float = 0.2 # Energía normal de la luna

var is_cloudy: bool = false # El Map cambiará esto
var is_raining: bool = false # El Map cambiará esto

func _ready() -> void:
	# Si no se asignaron en el inspector, buscarlos
	if sun == null: 
		sun = get_node_or_null("Sun")
	if moon == null: 
		moon = get_node_or_null("Moon")

	# Inicializar el tiempo en segundos totales
	# Globals debe ser un Autoload
	Globals.seconds = initial_hour * 3600.0

func _process(delta: float) -> void:
	# Avanzar tiempo en segundos
	Globals.seconds += delta * ingame_speed

	_recalculate_time()
	_update_lamps()

func _recalculate_time() -> void:
	var seconds_in_day = fmod(Globals.seconds, 86400.0) # Segundos en un día (24*3600)
	
	Globals.day = int(Globals.seconds / 86400.0)
	Globals.hour = int(seconds_in_day / 3600.0)
	Globals.minute = int(fmod(seconds_in_day, 3600.0) / 60.0)
	
	# Nota: En tu C# original, sobreescribías Globals.Day al final. 
	# He mantenido la lógica funcional para calcular el día correctamente.

func _update_lamps() -> void:
	var day_progress = fmod(Globals.seconds, 86400.0) / 86400.0
	# 0.0 a 360.0. 0 es medianoche, 180 es mediodía.
	var angle = day_progress * 360.0 

	if sun != null:
		# Rotación: el Sol gira sobre el eje X
		sun.rotation_degrees = Vector3(-angle + 90.0, 0, 0)
		
		# Intensidad basada en la altura (seno del ángulo)
		var sun_factors = clamp(sin(deg_to_rad(angle - 90.0)), 0.0, 1.0)
		
		# Si está nublado, reducimos la energía
		var cloud_multiplier = 0.2 if is_cloudy else 1.0
		
		sun.light_energy = sun_factors * sun_base_energy * cloud_multiplier

	if moon != null:
		# La luna está a 180 grados de diferencia
		moon.rotation_degrees = Vector3(-angle - 90.0, 0, 0)
		
		# La intensidad de la luna usa el seno invertido
		var moon_factors = clamp(sin(deg_to_rad(angle + 90.0)), 0.0, 1.0)
		
		# La luna también se ve afectada por nubes
		var cloud_multiplier = 0.1 if is_cloudy else 1.0

		moon.light_energy = moon_factors * moon_base_energy * cloud_multiplier
