extends Node3D
var snow_texture = preload("res://Textures/snow.png")
var sand_texture = preload("res://Textures/sand.png")

@onready var terrain = $HTerrain
@onready var worldenvironment = $WorldEnvironment


var current_disaster = ""
var active_disaster_nodes = []
var is_spawning_lightning = false


func _exit_tree():
	if multiplayer.is_server():
		Globals.set_weather_and_disaster.rpc("Original")
		Globals.timer.stop()
		Globals.started = false

func _ready():
	Globals.map = self

	if not Globals.current_weather_and_disaster_changed.is_connected(_on_disaster_changed):
		Globals.current_weather_and_disaster_changed.connect(_on_disaster_changed)

	
	if multiplayer.is_server():
		Globals.set_weather_and_disaster.rpc("Original")

		if Globals.gamemode == "survival":
			if not OS.has_feature("dedicated_server"):
				Globals.MultiplayerPlayerSpawner()

			for i in multiplayer.get_peers():
				Globals.MultiplayerPlayerSpawner(i)
			
			Globals.timer.wait_time = Globals.GlobalsData.timer_disasters
			Globals.timer.start()

		else:
			if not OS.has_feature("dedicated_server"):
				Globals.MultiplayerPlayerSpawner()

			for i in multiplayer.get_peers():
				Globals.MultiplayerPlayerSpawner(i)		


				

# Llama a la función wind para cada objeto en la escena
func _physics_process(_delta):
	for object in get_children():
		Globals.wind(object)

	
func _process(_delta):
	terrain.ambient_wind = Globals.Wind_speed * _delta

	if multiplayer.is_server():
		if OS.has_feature("dedicated_server") or "s" in OS.get_cmdline_user_args() or "server" in OS.get_cmdline_user_args():
			Globals.started = true
		else:

			if multiplayer.multiplayer_peer == null \
			or multiplayer.multiplayer_peer is OfflineMultiplayerPeer \
			or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
				Globals.started = true
				return

			if Globals.gamemode == "survival":
				if Globals.players_conected.size() > 1:
					Globals.started = true
				else:
					Globals.started = false
			else:
				Globals.started = true


func _start_sun_original():
	Globals.Temperature_target = Globals.Temperature_original
	Globals.Humidity_target = Globals.Humidity_original
	Globals.bradiation_target = Globals.bradiation_original
	Globals.oxygen_target = Globals.oxygen_original
	Globals.pressure_target = Globals.pressure_original
	Globals.Wind_Direction_target = Globals.Wind_Direction_original
	Globals.Wind_speed_target = Globals.Wind_speed_original

	_update_environment()
		



func _start_tsunami():
	var tsunami = Globals.tsunami_scene.instantiate()
	tsunami.position = Vector3(0,0,0)
	add_child(tsunami, true)
	active_disaster_nodes.append(tsunami)

	Globals.Temperature_target = randf_range(20,31)
	Globals.Humidity_target = randf_range(0,20)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randf_range(10000,10020)
	Globals.Wind_Direction_target = Vector3(randf_range(-1,1),0,randf_range(-1,1))
	Globals.Wind_speed_target = randf_range(0, 10)

	_update_environment()




func _start_thunderstorm():

	Globals.Temperature_target = randf_range(5,15)
	Globals.Humidity_target = randf_range(30,40)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randf_range(8000,9000)
	Globals.Wind_Direction_target =  Vector3(randf_range(-1,1),0,randf_range(-1,1))
	Globals.Wind_speed_target = randf_range(0, 30)

	_update_environment()
	_spawn_lightning_timer()



func _start_meteor_shower():
	Globals.Temperature_target = randf_range(20,31)
	Globals.Humidity_target = randf_range(0,20)
	Globals.pressure_target = randf_range(10000,10020)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.Wind_Direction_target = Vector3(randf_range(-1,1),0,randf_range(-1,1))
	Globals.Wind_speed_target = randf_range(0, 10)
	
	_spawn_meteor_shower_timer()
	_update_environment()

func _start_blizzard():
	Globals.Temperature_target =  randf_range(-20,-35)
	Globals.Humidity_target = randf_range(20,30)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randf_range(8000,9020)
	Globals.Wind_Direction_target =  Vector3(randf_range(-1,1),0,randf_range(-1,1))
	Globals.Wind_speed_target = randf_range(40, 50)


	_update_environment()


func _start_sandstorm():
	Globals.Temperature_target =  randf_range(30,35)
	Globals.Humidity_target = randf_range(0,5)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randf_range(10000,10020)
	Globals.Wind_Direction_target =  Vector3(randf_range(-1,1),0,randf_range(-1,1))
	Globals.Wind_speed_target = randf_range(30, 50)

	_update_environment()

func _start_volcano():
	Globals.Temperature_target = randf_range(20,31)
	Globals.Humidity_target = randf_range(0,20)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randf_range(10000,10020)
	Globals.Wind_Direction_target = Vector3(randf_range(-1,1),0,randf_range(-1,1))
	Globals.Wind_speed_target = randf_range(0, 10)

	var rand_pos = Vector3(randf_range(0,4097),1000,randf_range(0,4097))
	var space_state = get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(rand_pos, rand_pos - Vector3(0,10000,0))
	var result = space_state.intersect_ray(ray)

	var volcano = Globals.volcano_scene.instantiate()
	if result.has("position"):
		volcano.position = result.position
	else:
		volcano.position = Vector3(randf_range(0,4097),0,randf_range(0,4097))
	active_disaster_nodes.append(volcano)

	add_child(volcano, true)

	_update_environment()

	


func _start_tornado():

	var rand_pos = Vector3(randf_range(0,4097),1000,randf_range(0,4097))
	var space_state = get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.create(rand_pos, rand_pos - Vector3(0,10000,0))
	var result = space_state.intersect_ray(ray)	

		
	var tornado = Globals.tornado_scene.instantiate()
	if result.has("position"):
		tornado.position = result.position
	else:
		tornado.position = Vector3(randf_range(0,4097),0,randf_range(0,4097))
	add_child(tornado, true)
	active_disaster_nodes.append(tornado)

	Globals.Temperature_target =  randf_range(5,15)
	Globals.Humidity_target = randf_range(30,40)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randf_range(8000,9000)
	Globals.Wind_Direction_target =  Vector3(randf_range(-1,1),0,randf_range(-1,1))
	Globals.Wind_speed_target = randf_range(0, 30)

	_update_environment()
	_spawn_lightning_timer()
	



func _start_acid_rain():
	Globals.Temperature_target = randf_range(20,31)
	Globals.Humidity_target = randf_range(0,20)
	Globals.bradiation_target = 100
	Globals.oxygen_target = 100
	Globals.pressure_target = randf_range(10000,10020)
	Globals.Wind_Direction_target = Vector3(randf_range(-1,1),0,randf_range(-1,1))
	Globals.Wind_speed_target = randf_range(0, 10)

	_update_environment()

func _start_earthquake():
	Globals.Temperature_target = randf_range(20,31)
	Globals.Humidity_target = randf_range(0,20)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randf_range(10000,10020)
	Globals.Wind_Direction_target = Vector3(randf_range(-1,1),0,randf_range(-1,1))
	Globals.Wind_speed_target = randf_range(0, 10)

	var earquake = Globals.earthquake_scene.instantiate()
	add_child(earquake,true)
	active_disaster_nodes.append(earquake)

	_update_environment()





func _start_sun():
	Globals.Temperature_target = randf_range(20,31)
	Globals.Humidity_target = randf_range(0,20)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randf_range(10000,10020)
	Globals.Wind_Direction_target = Vector3(randf_range(-1,1),0,randf_range(-1,1))
	Globals.Wind_speed_target = randf_range(0, 10)

	_update_environment()


func _start_cloud():
	Globals.Temperature_target =  randf_range(20,25)
	Globals.Humidity_target = randf_range(10,30)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randf_range(9000,10000)
	Globals.Wind_Direction_target = Vector3(randf_range(-1,1),0,randf_range(-1,1))
	Globals.Wind_speed_target =  randf_range(0, 10)


	_update_environment()



func _start_raining():

	Globals.Temperature_target =   randf_range(10,20)
	Globals.Humidity_target =  randf_range(20,40)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randf_range(9000,9020)
	Globals.Wind_Direction_target =  Vector3(randf_range(-1,1),0,randf_range(-1,1))
	Globals.Wind_speed_target = randf_range(0, 20)
	
	_update_environment()

func _start_storm():
	Globals.Temperature_target =  randf_range(5,15)
	Globals.Humidity_target = randf_range(30,40)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 100
	Globals.pressure_target = randf_range(8000,9000)
	Globals.Wind_Direction_target =  Vector3(randf_range(-1,1),0,randf_range(-1,1))
	Globals.Wind_speed_target = randf_range(30, 60)

	_update_environment()
	_spawn_lightning_timer()


func _start_DustStorm():
	Globals.Temperature_target =  randf_range(30,40)
	Globals.Humidity_target = randf_range(0,10)
	Globals.bradiation_target = 0
	Globals.oxygen_target = 0
	Globals.pressure_target = randf_range(10000,10020)
	Globals.Wind_Direction_target =  Vector3(randf_range(-1,1),0,randf_range(-1,1))
	Globals.Wind_speed_target = randf_range(0, 50)

	_update_environment()

func _on_disaster_changed(new_disaster: String):
	# Limpiar el desastre anterior
	_cleanup_disaster()
	current_disaster = new_disaster

	# Iniciar el nuevo desastre
	match new_disaster:
		"Tsunami":
			_start_tsunami()
		"Thunderstorm":
			_start_thunderstorm()
		"Meteor_shower":
			_start_meteor_shower()
		"blizzard":
			_start_blizzard()
		"Sand Storm":
			_start_sandstorm()
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
			_start_DustStorm()
		_:
			_start_sun_original()

func _cleanup_disaster():
	is_spawning_lightning = false

	# Limpiar efectos del desastre anterior
	for node in active_disaster_nodes:
		if is_instance_valid(node):
			node.queue_free()
	active_disaster_nodes.clear()

	if Globals.gamemode == "survival":
		Globals.add_points.rpc()

func _spawn_meteor_shower_timer():
	while Globals.current_weather_and_disaster == "Meteor_shower":
		var meteor = Globals.meteor_scene.instantiate()
		var rand_pos = Vector3(randf_range(0,4097),1000,randf_range(0,4097))
		meteor.position = rand_pos
		add_child(meteor, true)
		active_disaster_nodes.append(meteor)
		
		await get_tree().create_timer(1).timeout

func _update_environment():
	var player = Globals.local_player

	if not is_instance_valid(player):
		return

	var is_outdoor = Globals.is_outdoor(player)

	# Ajustes por desastre
	match current_disaster:
		"blizzard":
			player.snow_node.emitting = is_outdoor
			$WorldEnvironment.environment.volumetric_fog_albedo = Color(1, 1, 1)
		"Sand Storm":
			player.sand_node.emitting = is_outdoor
			$WorldEnvironment.environment.volumetric_fog_albedo = Color(1, 0.647059, 0)
		"Acid rain":
			player.rain_node.emitting = is_outdoor
			$WorldEnvironment.environment.volumetric_fog_albedo = Color(0, 1, 0)
		"Dust Storm":
			player.dust_node.emitting = is_outdoor
			$"WorldEnvironment".environment.volumetric_fog_albedo = Color(0,0,0)
		_:
			player.snow_node.emitting = false
			player.sand_node.emitting = false
			player.dust_node.emitting = false
			$WorldEnvironment.environment.volumetric_fog_albedo = Color(1, 1, 1)

	# Cuando hay lluvia/tormenta u otros eventos que requieren niebla, activarla sólo si el jugador está al aire libre
	var foggy_disasters = ["Thunderstorm", "Raining", "Storm", "Tornado", "blizzard", "Sand Storm", "Cloud", "Acid rain", "Dust Storm"]
	var rain_disasters = ["Thunderstorm", "Raining", "Storm", "Tornado", "Acid rain"]
	$WorldEnvironment.environment.volumetric_fog_enabled = current_disaster in foggy_disasters and is_outdoor

	# Nodos de partículas generales
	player.rain_node.emitting = (current_disaster in rain_disasters) and is_outdoor

	# Ajuste de nubes
	$WorldEnvironment.environment.sky.sky_material.set_shader_parameter("clouds_fuzziness",
		0.25 if current_disaster in foggy_disasters else 1)

func _spawn_lightning_timer():
	if is_spawning_lightning:
		return  # Evitar múltiples instancias del timer

	is_spawning_lightning = true

	while Globals.current_weather_and_disaster == "Thunderstorm" and is_spawning_lightning:
		var player = Globals.local_player
		
		if is_instance_valid(player) and Globals.is_outdoor(player):
			if randi_range(1, 25) == 25:
				var lighting = Globals.thunderstorm_scene.instantiate()
				var rand_pos = Vector3(randf_range(0, 4097), 1000, randf_range(0, 4097))
				var space_state = get_world_3d().direct_space_state
				
				if space_state != null:
					var ray = PhysicsRayQueryParameters3D.create(rand_pos, rand_pos - Vector3(0, 10000, 0))
					var result = space_state.intersect_ray(ray)
					
					if result.has("position"):
						lighting.position = result.position
					else:
						lighting.position = Vector3(randf_range(0, 4097), 0, randf_range(0, 4097))
				else:
					lighting.position = Vector3(randf_range(0, 4097), 0, randf_range(0, 4097))
				
				add_child(lighting, true)
				active_disaster_nodes.append(lighting)
		
		await get_tree().create_timer(0.5).timeout

	is_spawning_lightning = false