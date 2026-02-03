extends Node3D

# Variables para configurar el lanzamiento de bolas de fuego
var fireball_scene = preload("res://Scenes/meteor.tscn")  # Escena de la bola de fuego
var earthquake_scene = preload("res://Scenes/earthquake.tscn")



@export var launch_interval = 5  # Intervalo de lanzamiento en segundos
@export var launch_force = 50000  # Fuerza de lanzamiento de la bola de fuego
@export var launch_amount = 20  # Fuerza de lanzamiento de la bola de fuego
@export var launch_position = launch_marker.global_position

@export var Lava_Level  = 125
@export var Pressure = 0
@export var IsGoingToErupt = false
@export var IsPressureLeaking = false 
@export var IsVolcanoAsh = false

@onready var volcano = $Volcano
@onready var volcano_area = $Volcano_Area

@onready var smoke = $Smoke
@onready var erupt_sparks = $"Erupt Sparks"
@onready var erupt_smoke = $"Erupt Smoke"
@onready var erupt_sound = $"Erupt Sound"
@onready var launch_marker: Marker3D = $launch_marker

func check_pressure():
	# Verifica si la presión del volcán es mayor o igual a 100
	if Pressure >= 100:
		# Verifica si el volcán no está en proceso de erupción
		if not IsGoingToErupt:
			# Establece que el volcán está en proceso de erupción
			IsGoingToErupt = true
			
			
			var earthquake 
			
			# Si un número aleatorio entre 1 y 3 es igual a 3
			if randi() % 3 == 0:
				# Crea una instancia del objeto que representa el terremoto
				earthquake = earthquake_scene.instantiate()
				get_parent().add_child(earthquake)
				earthquake.global_transform.origin = global_transform.origin
				

				
			# Llama a la función Erupt después de un tiempo aleatorio entre 10 y 20 segundos
			await get_tree().create_timer(randi_range(10, 20)).timeout
			if is_instance_valid(self):
				erupt()
				Pressure = 99
				IsGoingToErupt = false
				IsPressureLeaking = true

			await get_tree().create_timer(randi_range(10, 20)).timeout
			
			if is_instance_valid(earthquake):
				earthquake.queue_free()
				


func erupt():
	smoke.emitting = false
	erupt_sparks.emitting = true
	erupt_smoke.emitting = true
	erupt_sound.play()
	_launch_fireball(launch_amount, launch_interval)

	await await get_tree().create_timer(10).timeout

	IsVolcanoAsh = true

	smoke.emitting = true

	Globals.Temperature_target =  randf_range(30,40)
	Globals.Humidity_target = randf_range(0,10)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 0
	Globals.pressure_target = randf_range(10000,10020)
	Globals.Wind_Direction_target =  Vector3(randf_range(-1,1),0,randf_range(-1,1))
	Globals.Wind_speed_target = randf_range(0, 50)

	if IsVolcanoAsh:
		Globals.set_weather_and_disaster.rpc("Dust Storm")

func _process(_delta: float) -> void:
	check_pressure()

func _launch_fireball(range: int, time: int):
	for i in range:
		var fireball = fireball_scene.instantiate()
		var launch_direction = Vector3(randi_range(-1,1), 1, randi_range(-1,1)).normalized()  # Dirección hacia arriba
		get_parent().add_child(fireball, true)  # Agregar la bola de fuego como hijo del volcán primero
		fireball.global_position = launch_position # Posición inicial en el volcán
		fireball.scale = Vector3(1,1,1)
		fireball.is_volcano_rock = true
		fireball.apply_impulse(launch_direction * launch_force, Vector3.UP)  # Aplicar fuerza para lanzar la bola de fuego
		await get_tree().create_timer(time).timeout
