extends Node3D
class_name Earthquake

@export var magnitude: float = 7.0
@export var magnitude_modifier: float = 0.0
var next_physics_time: int = Time.get_ticks_msec()
var spawn_time: int = Time.get_ticks_msec()
@export var life: Array[int] = [15, 20]

@onready var start_weak_earthquake: AudioStreamPlayer3D = $earquake_start_sound_weak
@onready var start_strong_earthquake: AudioStreamPlayer3D = $earquake_start_sound_strong
@onready var earthquake_sound: AudioStreamPlayer = $earquake_sound
@onready var earthquake_aftershot_sound: AudioStreamPlayer3D = $earqueake_aftershot

func _ready() -> void:
	play_initial_sounds()
	destroy_all_houses()
	
	await get_tree().create_timer(randf_range(life[0], life[1])).timeout
	earthquake_decay()

func _physics_process(delta: float) -> void:
	magnitude_modulate_sound()
	process_magnitude()
	magnitude_modifier_increment(delta)

func _process(_delta: float) -> void:
	destroy_all_houses()

func play_initial_sounds() -> void:
	if magnitude > 5:
		start_strong_earthquake.play()
	else:
		start_weak_earthquake.play()

func earthquake_decay() -> void:
	if randi_range(1, 2) == 1:
		create_earthquake_with_parent()
	queue_free()

func send_clientside_effects(ply: Node3D, amplitude: float) -> void:
	if randi() % 8 == 0:
		if ply.has_node("CameraNode"): # Ajusta según tu estructura de Player
			ply.get_node("CameraNode").start_screen_shake(0.6, amplitude * 2, 25)

func process_magnitude() -> void:
	var mag = magnitude * magnitude_modifier
	
	if mag < 1:
		return
	elif mag < 2: magnitude_one()
	elif mag < 3: magnitude_two()
	elif mag < 4: magnitude_three()
	elif mag < 5: magnitude_four()
	elif mag < 6: magnitude_five()
	elif mag < 7: magnitude_six()
	elif mag < 8: magnitude_seven()
	elif mag < 9: magnitude_eight()
	elif mag < 10: magnitude_nine()
	elif mag < 11: magnitude_ten()
	elif mag < 12: magnitude_eleven()
	elif mag < 13: magnitude_twelve()

func do_physics() -> void:
	var mag = magnitude * magnitude_modifier
	if mag < 3: return

	var vec = (mag * 25) * Vector3(randf_range(-1.5, 1.5), randf_range(-0.5, 0.4), randf_range(-1.5, 1.5))
	var ang_vv = Vector3(randf_range(-1.5, 1.5), randf_range(-0.5, 0.4), randf_range(-1.5, 1.5)) * (mag * 8)

	if Globals.hit_chance(2):
		ang_vv *= 20

	# Efectos a jugadores
	for player in get_tree().get_nodes_in_group("player"):
		if player.is_on_floor():
			if mag >= 8:
				var multiplier = 1.125
				if mag >= 12: multiplier = 2.5
				elif mag >= 11: multiplier = 2.125
				elif mag >= 10: multiplier = 2.0
				elif mag >= 9: multiplier = 1.5
				player.velocity = vec * multiplier

	# Efectos a objetos
	for obj in get_tree().get_nodes_in_group("movable_objects"):
		if obj is RigidBody3D:
			var vel_mod = 1.0 - clamp(obj.linear_velocity.length() / 2000.0, 0, 1)
			var ang_v = ang_vv * vel_mod
			
			var force_mult = 1.0
			if mag >= 12: force_mult = 40.0
			elif mag >= 11: force_mult = 36.0
			elif mag >= 10: force_mult = 24.0
			elif mag >= 9: force_mult = 12.0
			elif mag >= 8: force_mult = 8.0
			elif mag >= 7: force_mult = 4.0
			elif mag >= 6: force_mult = 2.0
			
			if randi_range(1, 2) == 1:
				obj.apply_impulse(ang_v * force_mult)
				if mag >= 4: unfreeze(obj, mag)
		elif obj is Hause:
			if randi_range(1, 2) == 1:
				destroy_house(obj)

func unfreeze(v: Node3D, _mag: float) -> void:
	if randf() < (1.0 / (1024.0 - (25.6 * _mag))):
		if is_instance_valid(v) and v is RigidBody3D:
			v.sleeping = false
			v.freeze = false
	if randf() < (1.0 / (512.0 - (25.6 * _mag))):
		if is_instance_valid(v) and v is Hause:
			destroy_house(v)

func destroy_house(v: Hause) -> void:
	if is_instance_valid(v):
		v.rpc("destroy")

func destroy_all_houses() -> void:
	for house in get_tree().get_nodes_in_group("Hause"):
		if house is Hause and is_instance_valid(house):
			destroy_house(house)

func magnitude_modulate_sound() -> void:
	var vol_mod = pow(magnitude / 10.0, 3)

# Incrementa gradualmente el modificador de magnitud basado en el tiempo delta
func magnitude_modifier_increment(delta: float) -> void:
	magnitude_modifier = clamp(magnitude_modifier + (delta / 4.0), 0, 1)

# Crea una réplica (aftershock) del terremoto con una magnitud reducida
func create_earthquake_with_parent() -> void:
	if earthquake_aftershot_sound:
		earthquake_aftershot_sound.play()
	
	var new_mag = clamp(floor(magnitude) - (randi() % 3), 1, 12)
	var scene = load("res://Scenes/earthquake.tscn")
	var aftershock = scene.instantiate()
	
	aftershock.magnitude = int(new_mag)
	get_parent().add_child(aftershock, true)
	aftershock.global_position = global_position
	aftershock.show()

# Ejemplo de una de las funciones de magnitud (debes crear del 1 al 12)
func magnitude_one() -> void:
	for p in get_tree().get_nodes_in_group("player"):
		send_clientside_effects(p, 0.1)
	do_physics()

func magnitude_two() -> void:
	for v in get_tree().get_nodes_in_group("player"):
		if v.is_multiplayer_authority() and v.is_on_floor():
			send_clientside_effects(v, 0.2)
	do_physics()

func magnitude_three() -> void:
	for v in get_tree().get_nodes_in_group("player"):
		if v.is_multiplayer_authority() and v.is_on_floor():
			send_clientside_effects(v, 0.45)
	do_physics()

func magnitude_four() -> void:
	for v in get_tree().get_nodes_in_group("player"):
		if v.is_multiplayer_authority() and v.is_on_floor():
			send_clientside_effects(v, 1.2)
	do_physics()

func magnitude_five() -> void:
	for v in get_tree().get_nodes_in_group("player"):
		if v.is_multiplayer_authority() and v.is_on_floor():
			send_clientside_effects(v, 2.5)
	do_physics()

func magnitude_six() -> void:
	for v in get_tree().get_nodes_in_group("player"):
		if v.is_multiplayer_authority() and v.is_on_floor():
			send_clientside_effects(v, 6.0)
	do_physics()

func magnitude_seven() -> void:
	for v in get_tree().get_nodes_in_group("player"):
		if v.is_multiplayer_authority() and v.is_on_floor():
			send_clientside_effects(v, 11.0)
	do_physics()

func magnitude_eight() -> void:
	for v in get_tree().get_nodes_in_group("player"):
		if v.is_multiplayer_authority() and v.is_on_floor():
			send_clientside_effects(v, 16.0)
	do_physics()

func magnitude_nine() -> void:
	for v in get_tree().get_nodes_in_group("player"):
		if v.is_multiplayer_authority() and v.is_on_floor():
			send_clientside_effects(v, 24.0)
	do_physics()

func magnitude_ten() -> void:
	var percentage = clamp(magnitude / 10.99, 0, 1)
	# Cálculos de vibración basados en el original
	for v in get_tree().get_nodes_in_group("player"):
		if v.is_multiplayer_authority() and v.is_on_floor():
			send_clientside_effects(v, 38.0)
	do_physics()

func magnitude_eleven() -> void:
	for v in get_tree().get_nodes_in_group("player"):
		if v.is_multiplayer_authority() and v.is_on_floor():
			send_clientside_effects(v, 45.0) # Valor aproximado basado en progresión
	do_physics()

func magnitude_twelve() -> void:
	for v in get_tree().get_nodes_in_group("player"):
		if v.is_multiplayer_authority() and v.is_on_floor():
			send_clientside_effects(v, 60.0) # Máxima intensidad
	do_physics()