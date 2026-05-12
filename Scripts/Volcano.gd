extends Node3D

class_name Volcano

var fireball_scene: PackedScene = preload("res://Scenes/meteor.tscn")
var earthquake_scene: PackedScene = preload("res://Scenes/earthquake.tscn")

@export var pressure: float = 0
@export var pressure_speed: float = 5.0 
@export var is_going_to_erupt: bool = false
@export var is_pressure_leaking: bool = false
@export var is_volcano_ash: bool = false

@onready var smoke: GPUParticles3D = $Smoke
@onready var erupt_sparks: GPUParticles3D = $"Erupt Sparks"
@onready var erupt_smoke: GPUParticles3D = $"Erupt Smoke"
@onready var erupt_sound: AudioStreamPlayer3D = $"Erupt Sound"
@onready var launch_marker: Marker3D = $launch_marker

func _ready() -> void:
	randomize()

func _process(delta: float) -> void:
	increment_pressure(delta)
	check_pressure()

func increment_pressure(delta: float) -> void:
	if not is_going_to_erupt:
		if is_pressure_leaking:
			# Si hay fuga, la presión baja
			pressure -= (pressure_speed * 1.5) * delta
			if pressure <= 0:
				pressure = 0
				is_pressure_leaking = false # La fuga se detiene al vaciarse
		elif pressure < 100:
			# Si no hay fuga y no ha llegado al tope, sube
			pressure += pressure_speed * delta

func check_pressure() -> void:
	if pressure >= 100 and not is_going_to_erupt:
		is_going_to_erupt = true
		pressure = 100 # Lo fijamos en 100 para evitar que suba más durante el timer
	
		if multiplayer.is_server():
			if randi() % 3 == 0: 
				var earthquake_node = earthquake_scene.instantiate()
				get_parent().add_child(earthquake_node, true)
				earthquake_node.global_position = global_position
				print("Terremoto spawneado")
		
		# Ejecutar la erupción
		erupt()
		pressure = 99 
		is_going_to_erupt = false
		is_pressure_leaking = true

func erupt() -> void:
	smoke.emitting = false
	erupt_sparks.emitting = true
	erupt_smoke.emitting = true
	erupt_sound.play()
	launch_fireballs(20)

	await get_tree().create_timer(10).timeout
	is_volcano_ash = true
	smoke.emitting = true
	erupt_sparks.emitting = false
	erupt_smoke.emitting = false

	if is_volcano_ash:
		Globals.set_weather_and_disaster.rpc("Dust Storm", -1)

func launch_fireballs(amount: int) -> void:
	for i in range(amount):
		var fireball = fireball_scene.instantiate()
		get_parent().add_child(fireball, true)
		
		fireball.global_position = launch_marker.global_position
		fireball.is_volcano_rock = true
		
		var base_dir = launch_marker.global_transform.basis.y
		var spread = Vector3(randf_range(-0.3, 0.3), randf_range(0.0, 0.2), randf_range(-0.3, 0.3))
		var final_dir = (base_dir + spread).normalized()
		var force = randf_range(1500, 3000)
		
		fireball.apply_impulse(final_dir * force)