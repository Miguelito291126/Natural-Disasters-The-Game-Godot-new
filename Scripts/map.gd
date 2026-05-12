extends Node3D
class_name Map

@onready var map_environment: MapEnvironment = $"WorldEnvironment"
@export var snow_decal_scene: PackedScene
@export var sand_decals_scene: PackedScene

var current_disaster: String = ""
var active_disaster_nodes: Array[Node3D] = []
var active_decals: Array[Node3D] = []
var is_spawning_lightning: bool = false

func _exit_tree() -> void:
	# Desconectar la señal para evitar que Globals llame a un objeto destruido
	Globals.current_weather_and_disaster_changed.disconnect(_on_disaster_changed)

	if multiplayer.is_server():
		Globals.set_weather_and_disaster.rpc("Original", -1)
		Globals.timer.stop()
		Globals.started = false

func _ready() -> void:
	Globals.map = self
	
	if !Globals.current_weather_and_disaster_changed.is_connected(_on_disaster_changed):
		Globals.current_weather_and_disaster_changed.connect(_on_disaster_changed)

	if multiplayer.is_server():
		Globals.set_weather_and_disaster.rpc("Original", -1)

		if Globals.gamemode == "survival":
			if !Globals.is_dedicated_server:
				Globals.MultiplayerPlayerSpawner()

			for i in multiplayer.get_peers():
				Globals.MultiplayerPlayerSpawner(i)

			Globals.Timer.wait_time = Globals.globals_data.TimerDisasters
			Globals.Timer.start()
		else:
			if !Globals.is_dedicated_server:
				Globals.MultiplayerPlayerSpawner()

			for i in multiplayer.get_peers():
				Globals.MultiplayerPlayerSpawner(i)

func _physics_process(_delta: float) -> void:
	# Llama a la función wind para cada objeto en la escena
	for child in get_children():
		if child is Node3D:
			Globals.wind(child)

func _process(_delta: float) -> void:
	if multiplayer.is_server():
		var is_server_feature = Globals.is_dedicated_server

		if is_server_feature:
			Globals.started = true
		else:
			if multiplayer.multiplayer_peer == null || multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
				Globals.started = true
				return

			if Globals.gamemode == "survival":
				if Globals.PlayersConected.size() > 1:
					Globals.started = true
				else:
					Globals.started = false
			else:
				Globals.started = true

func _start_sun_original() -> void:
	Globals.temperature_target = Globals.temperature_original
	Globals.humidity_target = Globals.humidity_original
	Globals.bradiation_target = Globals.bradiation_original
	Globals.oxygen_target = Globals.oxygen_original
	Globals.pressure_target = Globals.pressure_original
	Globals.wind_direction_target = Globals.wind_direction_original
	Globals.wind_speed_target = Globals.wind_speed_original

	_update_environment()

func _start_tsunami() -> void:
	var tsunami = Globals.tsunami_scene.instantiate()
	tsunami.position = Vector3(0, 0, 0)
	add_child(tsunami, true)
	active_disaster_nodes.append(tsunami)

	Globals.temperature_target = randf_range(20.0, 31.0)
	Globals.humidity_target = randf_range(0.0, 20.0)
	Globals.bradiation_target = 0.0
	Globals.oxygen_target = 100.0
	Globals.pressure_target = randf_range(10000.0, 10020.0)
	Globals.wind_direction_target = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
	Globals.wind_speed_target = randf_range(0.0, 10.0)

	_update_environment()

func _start_thunderstorm() -> void:
	Globals.temperature_target = randf_range(5.0, 15.0)
	Globals.humidity_target = randf_range(30.0, 40.0)
	Globals.bradiation_target = 0.0
	Globals.oxygen_target = 100.0
	Globals.pressure_target = randf_range(8000.0, 9000.0)
	Globals.wind_direction_target = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
	Globals.wind_speed_target = randf_range(0.0, 30.0)

	_update_environment()
	_spawn_lightning_timer()

func _start_meteor_shower() -> void:
	Globals.temperature_target = randf_range(20.0, 31.0)
	Globals.humidity_target = randf_range(0.0, 20.0)
	Globals.pressure_target = randf_range(10000.0, 10020.0)
	Globals.bradiation_target = 0.0
	Globals.oxygen_target = 100.0
	Globals.wind_direction_target = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
	Globals.wind_speed_target = randf_range(0.0, 10.0)

	_spawn_meteor_shower_timer()
	_update_environment()

func _start_blizzard() -> void:
	Globals.temperature_target = randf_range(-20.0, -35.0)
	Globals.humidity_target = randf_range(20.0, 30.0)
	Globals.bradiation_target = 0.0
	Globals.oxygen_target = 100.0
	Globals.pressure_target = randf_range(8000.0, 9020.0)
	Globals.wind_direction_target = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
	Globals.wind_speed_target = randf_range(40.0, 50.0)

	_update_environment()

func _start_sandstorm() -> void:
	Globals.temperature_target = randf_range(30.0, 35.0)
	Globals.humidity_target = randf_range(0.0, 5.0)
	Globals.bradiation_target = 0.0
	Globals.oxygen_target = 100.0
	Globals.pressure_target = randf_range(10000.0, 10020.0)
	Globals.wind_direction_target = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
	Globals.wind_speed_target = randf_range(30.0, 50.0)

	_update_environment()

func _start_volcano() -> void:
	Globals.temperature_target = randf_range(20.0, 31.0)
	Globals.humidity_target = randf_range(0.0, 20.0)
	Globals.bradiation_target = 0.0
	Globals.oxygen_target = 100.0
	Globals.pressure_target = randf_range(10000.0, 10020.0)
	Globals.wind_direction_target = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
	Globals.wind_speed_target = randf_range(0.0, 10.0)

	var rand_pos = Vector3(randf_range(0.0, 4097.0), 1000.0, randf_range(0.0, 4097.0))
	var space_state = get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(rand_pos, rand_pos - Vector3(0, 10000, 0))
	var result = space_state.intersect_ray(ray)

	var volcano = Globals.volcano_scene.instantiate()
	if result.has("position"):
		volcano.position = result["position"]
	else:
		volcano.position = Vector3(randf_range(0.0, 4097.0), 0.0, randf_range(0.0, 4097.0))
	
	active_disaster_nodes.append(volcano)
	add_child(volcano, true)
	_update_environment()

func _start_tornado() -> void:
	var rand_pos = Vector3(randf_range(0.0, 4097.0), 1000.0, randf_range(0.0, 4097.0))
	var space_state = get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(rand_pos, rand_pos - Vector3(0, 10000, 0))
	var result = space_state.intersect_ray(ray)

	var tornado = Globals.tornado_scene.instantiate()
	if result.has("position"):
		tornado.position = result["position"]
	else:
		tornado.position = Vector3(randf_range(0.0, 4097.0), 0.0, randf_range(0.0, 4097.0))
	
	add_child(tornado, true)
	active_disaster_nodes.append(tornado)

	Globals.temperature_target = randf_range(5.0, 15.0)
	Globals.humidity_target = randf_range(30.0, 40.0)
	Globals.bradiation_target = 0.0
	Globals.oxygen_target = 100.0
	Globals.pressure_target = randf_range(8000.0, 9000.0)
	Globals.wind_direction_target = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
	Globals.wind_speed_target = randf_range(0.0, 30.0)

	_update_environment()
	_spawn_lightning_timer()

func _start_acid_rain() -> void:
	Globals.temperature_target = randf_range(20.0, 31.0)
	Globals.humidity_target = randf_range(0.0, 20.0)
	Globals.bradiation_target = 100.0
	Globals.oxygen_target = 100.0
	Globals.pressure_target = randf_range(10000.0, 10020.0)
	Globals.wind_direction_target = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
	Globals.wind_speed_target = randf_range(0.0, 10.0)
	_update_environment()

func _start_earthquake() -> void:
	Globals.temperature_target = randf_range(20.0, 31.0)
	Globals.humidity_target = randf_range(0.0, 20.0)
	Globals.bradiation_target = 0.0
	Globals.oxygen_target = 100.0
	Globals.pressure_target = randf_range(10000.0, 10020.0)
	Globals.wind_direction_target = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
	Globals.wind_speed_target = randf_range(0.0, 10.0)

	var earthquake = Globals.earthquake_scene.instantiate()
	add_child(earthquake, true)
	active_disaster_nodes.append(earthquake)
	_update_environment()

func _start_sun() -> void:
	Globals.temperature_target = randf_range(20.0, 31.0)
	Globals.humidity_target = randf_range(0.0, 20.0)
	Globals.bradiation_target = 0.0
	Globals.oxygen_target = 100.0
	Globals.pressure_target = randf_range(10000.0, 10020.0)
	Globals.wind_direction_target = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
	Globals.wind_speed_target = randf_range(0.0, 10.0)
	_update_environment()

func _start_cloud() -> void:
	Globals.temperature_target = randf_range(20.0, 25.0)
	Globals.humidity_target = randf_range(10.0, 30.0)
	Globals.bradiation_target = 0.0
	Globals.oxygen_target = 100.0
	Globals.pressure_target = randf_range(9000, 10000)
	Globals.wind_direction_target = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
	Globals.wind_speed_target = randf_range(0, 10)
	_update_environment()

func _start_raining() -> void:
	Globals.temperature_target = randf_range(10.0, 20.0)
	Globals.humidity_target = randf_range(20.0, 40.0)
	Globals.bradiation_target = 0.0
	Globals.oxygen_target = 100.0
	Globals.pressure_target = randf_range(9000.0, 9020.0)
	Globals.wind_direction_target = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
	Globals.wind_speed_target = randf_range(0.0, 20.0)
	_update_environment()

func _start_storm() -> void:
	Globals.temperature_target = randf_range(5.0, 15.0)
	Globals.humidity_target = randf_range(30.0, 40.0)
	Globals.bradiation_target = 0.0
	Globals.oxygen_target = 100.0
	Globals.pressure_target = randf_range(8000.0, 9000.0)
	Globals.wind_direction_target = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
	Globals.wind_speed_target = randf_range(30.0, 60.0)

	_update_environment()
	_spawn_lightning_timer()

func _start_dust_storm() -> void:
	Globals.temperature_target = randf_range(30.0, 40.0)
	Globals.humidity_target = randf_range(0.0, 10.0)
	Globals.bradiation_target = 0.0
	Globals.oxygen_target = 0.0
	Globals.pressure_target = randf_range(10000.0, 10020.0)
	Globals.wind_direction_target = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0))
	Globals.wind_speed_target = randf_range(0.0, 50.0)
	_update_environment()

func _on_disaster_changed(new_disaster: String) -> void:
	_cleanup_disaster()
	current_disaster = new_disaster

	match new_disaster:
		"Tsunami":
			_start_tsunami()
		"Thunderstorm":
			_start_thunderstorm()
		"Meteors shower":
			_start_meteor_shower()
		"blizzard":
			_start_blizzard()
			_spawn_decals(snow_decal_scene, 200)
		"Sand Storm":
			_start_sandstorm()
			_spawn_decals(sand_decals_scene, 200)
		"Volcano":
			_start_volcano()
		"Tornado":
			_start_tornado()
		"Acid rain":
			_start_acid_rain()
		"Earthquake":
			_start_earthquake()
		"Sun":
			_start_sun()
		"Cloud":
			_start_cloud()
		"Raining":
			_start_raining()
		"Storm":
			_start_storm()
		"Dust Storm":
			_start_dust_storm()
		_:
			_start_sun_original()

func _cleanup_disaster() -> void:
	is_spawning_lightning = false

	for node in active_disaster_nodes:
		if is_instance_valid(node):
			node.queue_free()
	active_disaster_nodes.clear()

	if Globals.gamemode == "survival":
		Globals.rpc("AddPoints", 100)

func _spawn_decals(scene: PackedScene, amount: int) -> void:
	if !multiplayer.is_server():
		return

	var space_state = get_world_3d().direct_space_state

	for i in range(amount):
		var rand_pos = Vector3(randf_range(0, 4097), 1000, randf_range(0, 4097))
		var ray = PhysicsRayQueryParameters3D.create(rand_pos, rand_pos - Vector3(0, 2000, 0))
		var result = space_state.intersect_ray(ray)

		if result.has("position"):
			var decal = scene.instantiate() as Decal
			var random_size = randf_range(3.0, 500.0)
			decal.size = Vector3(random_size, random_size, random_size)
			decal.position = result["position"] + Vector3(0, 0.05, 0)
			decal.rotation = Vector3(0, randf_range(0, TAU), 0)

			add_child(decal, true)
			active_decals.append(decal)

func _spawn_decals_over_time(scene: PackedScene, total: int, delay: float) -> void:
	for i in range(total):
		_spawn_decals(scene, 1)
		await get_tree().create_timer(delay).timeout

func _spawn_meteor_shower_timer() -> void:
	while Globals.current_weather_and_disaster == "Meteors shower":
		var meteor = Globals.meteor_scene.instantiate()
		var rand_pos = Vector3(randf_range(0, 4097), 1000, randf_range(0, 4097))
		meteor.position = rand_pos
		add_child(meteor, true)
		active_disaster_nodes.append(meteor)

		await get_tree().create_timer(1.0).timeout

func _update_environment() -> void:
	if !is_instance_valid(self) || !is_instance_valid(map_environment):
		return

	var player = Globals.local_player
	if !is_instance_valid(player):
		return

	var is_outdoor = Globals.is_outdoor(player)
	var env = map_environment.environment
	if env == null: return

	# Ajustes por desastre
	match current_disaster:
		"blizzard":
			player.snow_node.emitting = is_outdoor
			env.volumetric_fog_albedo = Color(1, 1, 1)
		"Sand Storm":
			player.sand_node.emitting = is_outdoor
			env.volumetric_fog_albedo = Color(1, 0.647, 0)
		"Acid rain":
			player.rain_node.emitting = is_outdoor
			env.volumetric_fog_albedo = Color(0, 1, 0)
		"Dust Storm":
			player.dust_node.emitting = is_outdoor
			env.volumetric_fog_albedo = Color(0, 0, 0)
		_:
			player.snow_node.emitting = false
			player.sand_node.emitting = false
			player.dust_node.emitting = false
			env.volumetric_fog_albedo = Color(1, 1, 1)

	var foggy_disasters = ["Thunderstorm", "Raining", "Storm", "Tornado", "blizzard", "Sand Storm", "Cloud", "Acid rain", "Dust Storm"]
	var rain_disasters = ["Thunderstorm", "Raining", "Storm", "Tornado", "Acid rain"]
	
	map_environment.is_cloudy = foggy_disasters.has(current_disaster)
	map_environment.is_raining= rain_disasters.has(current_disaster)
	env.volumetric_fog_enabled = map_environment.is_cloudy && is_outdoor
	
	player.rain_node.emitting = map_environment.is_raining && is_outdoor

	# Ajuste de nubes
	var sky_mat = env.sky.sky_material as ShaderMaterial
	if sky_mat:
		sky_mat.set_shader_parameter("clouds_fuzziness", 0.25 if map_environment.is_cloudy else 1.0)

func _spawn_lightning_timer() -> void:
	if is_spawning_lightning:
		return

	is_spawning_lightning = true

	while Globals.current_weather_and_disaster == "Thunderstorm" && is_spawning_lightning:
		var player = Globals.local_player

		if is_instance_valid(player) && Globals.is_outdoor(player):
			if randi_range(1, 25) == 25:
				var lighting = Globals.thunderstorm_scene.instantiate()
				var rand_pos = Vector3(randf_range(0, 4097), 1000, randf_range(0, 4097))
				var space_state = get_world_3d().direct_space_state

				if space_state != null:
					var ray = PhysicsRayQueryParameters3D.create(rand_pos, rand_pos - Vector3(0, 10000, 0))
					var result = space_state.intersect_ray(ray)

					if result.has("position"):
						lighting.position = result["position"]
					else:
						lighting.position = Vector3(randf_range(0, 4097), 0, randf_range(0, 4097))
				else:
					lighting.position = Vector3(randf_range(0, 4097), 0, randf_range(0, 4097))

				add_child(lighting, true)
				active_disaster_nodes.append(lighting)

		await get_tree().create_timer(0.5).timeout

	is_spawning_lightning = false
