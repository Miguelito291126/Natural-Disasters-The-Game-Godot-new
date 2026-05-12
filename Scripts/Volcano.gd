extends Node3D

class_name Volcano

var fireball_scene: PackedScene = preload("res://Scenes/meteor.tscn")
var earthquake_scene: PackedScene = preload("res://Scenes/earthquake.tscn")

@export var pressure: int = 0
@export var is_going_to_erupt: bool = false
@export var is_pressure_leaking: bool = false
@export var is_volcano_ash: bool = false

@onready var smoke: GPUParticles3D = $Smoke
@onready var erupt_sparks: GPUParticles3D = $"Erupt Sparks"
@onready var erupt_smoke: GPUParticles3D = $"Erupt Smoke"
@onready var erupt_sound: AudioStreamPlayer3D = $"Erupt Sound"
@onready var launch_marker: Marker3D = $launch_marker

func _process(_delta: float) -> void:
	check_pressure()

func check_pressure() -> void:
	if pressure >= 100 and not is_going_to_erupt:
		is_going_to_erupt = true
		
		var earthquake_node: Node3D = null
		if randi() % 3 == 0:
			earthquake_node = earthquake_scene.instantiate()
			get_parent().add_child(earthquake_node)
			earthquake_node.global_position = global_position

		await get_tree().create_timer(randf_range(10, 20)).timeout
		
		if is_instance_valid(self):
			erupt()
			pressure = 99
			is_going_to_erupt = false
			is_pressure_leaking = true

		await get_tree().create_timer(randf_range(10, 20)).timeout
		if is_instance_valid(earthquake_node):
			earthquake_node.queue_free()

func erupt() -> void:
	smoke.emitting = false
	erupt_sparks.emitting = true
	erupt_smoke.emitting = true
	erupt_sound.play()
	launch_fireballs(20)

	await get_tree().create_timer(10).timeout
	is_volcano_ash = true
	smoke.emitting = true
	
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