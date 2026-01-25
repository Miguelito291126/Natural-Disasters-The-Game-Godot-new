extends Node


signal current_weather_and_disaster_changed(new_disaster: String)


#Editor
var version = ProjectSettings.get_setting("application/config/version")
var gamename = ProjectSettings.get_setting("application/config/name")
var credits = "Miguelito2911"

#Network
@export var ip: String
@export var port: int = 5555
@export var points: int
@export var username: String = "Player"
@export var players_conected: Array[Node]
var multiplayerpeer


#Globals Weather
@export var Temperature: float = 23
@export var pressure: float = 10000
@export var oxygen: float  = 100
@export var bradiation: float = 0
@export var Humidity: float = 25
@export var Wind_Direction: Vector3 = Vector3(1,0,0)
@export var Wind_speed: float = 0
@export var is_raining: bool = false
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

#Globals Time
@export var time: float = 0.0
@export var time_left: float = 0.0
@export var Day: int = 0
@export var Hour: int = 0
@export var Minute: int = 00

#Globals Weather target
@export var Temperature_target: float = 23
@export var pressure_target: float = 10000
@export var oxygen_target: float = 100
@export var bradiation_target: float = 0
@export var Humidity_target: float = 25
@export var Wind_Direction_target: Vector3 = Vector3(1,0,0)
@export var Wind_speed_target: float = 0

#Globals Weather original
@export var Temperature_original: float = 23
@export var pressure_original: float = 10000
@export var oxygen_original: float = 100
@export var bradiation_original: float = 0
@export var Humidity_original: float = 25
@export var Wind_Direction_original: Vector3 = Vector3(1,0,0)
@export var Wind_speed_original: float = 0

@export var seconds = Time.get_unix_time_from_system()

@export var main: Node3D
@export var main_menu: Control
@export var map: Node3D
@export var server_browser: Control
@export var local_player: CharacterBody3D

@export var bounding_radius_areas = {}

@export var node_group = "Destrollable"
@export var destrolled_node: Array

@export var started = false
@export var gamemode = "survival"
@export var GlobalsData: DataResource = DataResource.load_file()

var current_weather_and_disaster = "Original":
	set(value):
		if current_weather_and_disaster != value:
			current_weather_and_disaster = value
			current_weather_and_disaster_changed.emit(value)

		
@export var current_weather_and_disaster_int = 0

var player_scene = preload("res://Scenes/player.tscn")
var thunderstorm_scene = preload("res://Scenes/thunder.tscn")
var meteor_scene = preload("res://Scenes/meteor.tscn")
var tornado_scene = preload("res://Scenes/tornado.tscn")
var tsunami_scene = preload("res://Scenes/tsunami.tscn")
var volcano_scene = preload("res://Scenes/volcano.tscn")
var earthquake_scene = preload("res://Scenes/earthquake.tscn")

@onready var timer = $Timer
@onready var broadcast_Timer = $Broadcast_Timer

@export var room_list = {"name": "name", "players": 0}
@export var broadcaster_ip = "192.168.1.255"
@export var lisener_port = port + 1
@export var broadcaster_port = port - 1
var broadcaster: PacketPeerUDP
var lisener: PacketPeerUDP

@export var is_chat_open = false
@export var is_pause_menu_open = false
@export var	is_spawn_menu_open = false

@export var	character: String = "blue"
@export var	avalible_characters = ["blue", "red", "green", "yellow"]
@export var assigned_character: Dictionary

func convert_MetoSU(metres):
	return (metres * 39.37) / 0.75

func convert_KMPHtoMe(kmph):
	return (kmph*1000)/3600

func convert_VectorToAngle(vector):
	var x = vector.x
	var y = vector.z
	
	return int(360 + rad_to_deg(atan2(y,x))) % 360

func _get_direct_space_state(node: Node):
	# Intenta obtener el World3D a partir del nodo; si falla, intenta la escena actual.
	var world = null
	if node != null and is_instance_valid(node):
		world = node.get_world_3d()
	if world == null:
		var scene = get_tree().get_current_scene()
		if is_instance_valid(scene):
			world = scene.get_world_3d()
	if world == null:
		return null
	return world.direct_space_state

func perform_trace_collision(ply, direction):
	var start_pos = ply.global_position
	var end_pos = start_pos + direction * 1000
	var space_state = _get_direct_space_state(ply)
	if space_state == null:
		return false
	var ray = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	ray.exclude = [ply.get_rid()]
	var result = space_state.intersect_ray(ray)
	return result != {}
		

func perform_trace_wind(ply, direction):
	var start_pos = ply.global_position
	var end_pos = start_pos + direction * 60000
	var space_state = _get_direct_space_state(ply)
	if space_state == null:
		return end_pos
	var ray = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	ray.exclude = [ply.get_rid()]
	var result = space_state.intersect_ray(ray)
	if result:
		return result.position
	else:
		return end_pos

func get_node_by_id_recursive(node: Node, node_id: int) -> Node:
	if node.get_instance_id() == node_id:
		return node

	for child in node.get_children():
		var result := get_node_by_id_recursive(child, node_id)
		if result != null:
			return result

	return null

func is_below_sky(ply):
	var start_pos = ply.global_position
	var end_pos = start_pos + Vector3(0, 48000, 0)
	var space_state = _get_direct_space_state(ply)
	# Si no hay espacio de físicas disponible, asumimos "al aire libre" (true)
	if space_state == null:
		return true
	var ray = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	ray.exclude = [ply.get_rid()]
	var result = space_state.intersect_ray(ray)
	return !result


func is_outdoor(ply):
	var hit_sky = is_below_sky(ply)

	if ply.is_in_group("player"):
		if hit_sky:
			ply.Outdoor = true
		else:
			ply.Outdoor = false
		
		return hit_sky
	else:
		return hit_sky

func is_inwater(ply):
	if ply.is_in_group("player"):
		return ply.IsInWater

func is_underwater(ply):
	if ply.is_in_group("player"):
		return ply.IsUnderWater
	
func is_inlava(ply):
	if ply.is_in_group("player"):
		return ply.IsInLava

func is_underlava(ply):
	if ply.is_in_group("player"):
		return ply.IsUnderLava


func vec2_to_vec3(vector):
	return Vector3(vector.x, 0, vector.y)

func is_something_blocking_wind(entity):
	var start_pos = entity.global_position
	var end_pos = start_pos - (Wind_Direction * 300)
	var space_state = _get_direct_space_state(entity)
	if space_state == null:
		# Sin información del mundo, no asumimos bloqueo
		return false
	var ray = PhysicsRayQueryParameters3D.create(start_pos, end_pos)
	ray.exclude = [entity.get_rid()]
	var result = space_state.intersect_ray(ray)
	return result != {}

func calcule_bounding_radius(entity):
	var max_radius = 0.0
	
	for child in entity.get_children():
		if child.get_child_count() > 0:
			return calcule_bounding_radius(child)

		if child.is_class("MeshInstance3D") and child != null:
			var mesh = child.mesh
			var aabb = mesh.get_aabb()
			
			# Obtener los 8 vértices de la AABB original
			var vertices = [
				aabb.position,
				aabb.position + Vector3(aabb.size.x, 0, 0),
				aabb.position + Vector3(0, aabb.size.y, 0),
				aabb.position + Vector3(0, 0, aabb.size.z),
				aabb.position + Vector3(aabb.size.x, aabb.size.y, 0),
				aabb.position + Vector3(aabb.size.x, 0, aabb.size.z),
				aabb.position + Vector3(0, aabb.size.y, aabb.size.z),
				aabb.position + aabb.size
			]
			
			# Transformar los vértices con la matriz de transformación del MeshInstance3D
			var transformed_vertices = []
			for vertex in vertices:
				transformed_vertices.append(child.transform * vertex )
			
			# Calcular el nuevo AABB a partir de los vértices transformados
			# Calcular el radio de contorno a partir de los vértices transformados
			for vertex in transformed_vertices:
				var distance = vertex.length()
				max_radius = max(max_radius, distance)


	return max_radius



func search_in_node(node, origin: Vector3, radius: float, result: Array):
	for i in range(node.get_child_count()):
		var child = node.get_child(i)
		if child.is_class("Spatial"): # Solo considerar nodos Spatial (puedes ajustar esto según tus necesidades)
			var distance = origin.distance_to(child.global_position)
			if distance <= radius:
				result.append(child)
		# Recursión si el nodo tiene hijos
		if child.get_child_count() > 0:
			search_in_node(child, origin, radius, result)

	return result

func find_in_sphere(origin: Vector3, radius: float) -> Array:
	var result = []
	var scene_root = get_tree().get_root()
	
	result = search_in_node(scene_root, origin, radius, result)

	return result

func wind(object):
	# Verificar si el objeto es un jugador
	if object.is_in_group("player"):
		if not is_instance_valid(object):
			return
	
		# Calcular la velocidad del viento local
		var local_wind = Wind_speed
		if not is_outdoor(object) or is_something_blocking_wind(object):
			local_wind = 0

		object.body_wind = local_wind
		
		# Calcular la velocidad del viento y la fricción
		var wind_vel = Wind_Direction * local_wind 
		# Verificar si está al aire libre y no hay obstáculos que bloqueen el viento
		if is_outdoor(object) and not is_something_blocking_wind(object) and local_wind >= 30:
			var delta_velocity = wind_vel - object.velocity
			object.velocity += delta_velocity * 0.3

	elif object.is_in_group("movable_objects") and object.is_class("RigidBody3D"):
		if is_instance_valid(object) and is_outdoor(object) and not is_something_blocking_wind(object):
			var wind_vel = Wind_Direction * Wind_speed
			var delta_velocity = wind_vel - object.linear_velocity
			
			# Aplica fuerza en vez de modificar directamente la velocidad
			object.apply_central_force(delta_velocity * 0.3)

	elif object.is_in_group("movable_objects") and object.is_class("StaticBody3D"):
		if is_instance_valid(object):
			if object.is_in_group("Destrollable") or object.is_in_group("Hause"):
				if Wind_speed > 100:
					object.destroy.rpc()

			
			


func Area(entity):
	if not "bounding_radius_area" in entity or entity.bounding_radius_area == null:
		var bounding_radius = calcule_bounding_radius(entity)
		var bounding_radius_area = (2 * PI) * (bounding_radius * bounding_radius)
		bounding_radius_areas[entity] = bounding_radius_area
		
		return bounding_radius_area
	else:
		return entity.bounding_radius_area

func get_frame_multiplier() -> float:
	var frame_time: float = Engine.get_frames_per_second()
	if frame_time == 0:
		return 0
	else:
		return 60 / frame_time

func get_physics_multiplier() -> float:
	var physics_interval: float = get_physics_process_delta_time()
	return (200.0 / 3.0) / physics_interval

func hit_chance(chance: int) -> bool:
	if multiplayer.is_server():
		# En el servidor
		return randf() < (clamp(chance * get_physics_multiplier(), 0, 100) / 100)
	else:
		# En el cliente
		return randf() < (clamp(chance * get_frame_multiplier(), 0, 100) / 100)

	
@rpc("any_peer", "call_local")
func sync_player_list():
	players_conected.clear()

	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p):
			players_conected.append(p)

# Función para verificar si hay jugadores con el mismo nombre
func hay_jugadores_con_mismo_nombre(nombre_a_verificar: String, excluir_jugador: Node = null) -> bool:
	var contador = 0
	for player in get_tree().get_nodes_in_group("player"):
		# Si se debe excluir un jugador específico, saltarlo
		if excluir_jugador != null and player == excluir_jugador:
			continue
		
		# Verificar si el nombre coincide
		if is_instance_valid(player) and player.has("username") and player.username == nombre_a_verificar:
			contador += 1
			# Si encontramos al menos uno con el mismo nombre, retornar true
			if contador >= 1:
				return true
	
	return false

# Función para obtener todos los jugadores que tienen el mismo nombre
func obtener_jugadores_con_mismo_nombre(nombre_a_verificar: String, excluir_jugador: Node = null) -> Array:
	var jugadores_duplicados = []
	
	for player in get_tree().get_nodes_in_group("player"):
		# Si se debe excluir un jugador específico, saltarlo
		if excluir_jugador != null and player == excluir_jugador:
			continue
		
		# Verificar si el nombre coincide
		if is_instance_valid(player) and player.has("username") and player.username == nombre_a_verificar:
			jugadores_duplicados.append(player)
	
	return jugadores_duplicados

# Función para contar cuántos jugadores tienen el mismo nombre
func contar_jugadores_con_mismo_nombre(nombre_a_verificar: String, excluir_jugador: Node = null) -> int:
	var contador = 0
	for player in get_tree().get_nodes_in_group("player"):
		# Si se debe excluir un jugador específico, saltarlo
		if excluir_jugador != null and player == excluir_jugador:
			continue
		
		# Verificar si el nombre coincide
		if is_instance_valid(player) and player.has("username") and player.username == nombre_a_verificar:
			contador += 1
	
	return contador


func print_role(msg: String):
	var peer = multiplayer.multiplayer_peer
	
	if peer == null \
	or peer is OfflineMultiplayerPeer \
	or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		print(msg)
		return

	var is_server = multiplayer.is_server()	
	if is_server:
		# Azul
		print_rich("[color=blue][Server] " + msg + "[/color]")
	else:
		# Amarillo
		print_rich("[color=yellow][Client] " + msg + "[/color]")

		



func Play_MultiplayerServer():
	multiplayerpeer = ENetMultiplayerPeer.new()
	var error = multiplayerpeer.create_server(port)
	if error == OK:
		multiplayer.multiplayer_peer = multiplayerpeer
		if multiplayer.is_server():
			if OS.has_feature("dedicated_server") or "s" in OS.get_cmdline_user_args() or "server" in OS.get_cmdline_user_args():
				print_role("Dedicated server init")

				await get_tree().create_timer(2).timeout

				SetUpBroadcast(username)
				LoadScene.load_scene(main_menu, "map")
			else:
				print_role("Server init")
				SetUpBroadcast(username)
				LoadScene.load_scene(main_menu, "map")
	else:
		print_role("Fatal Error in server")

@rpc("any_peer")
func request_pick_object(player_path: NodePath, target_path: NodePath) -> void:
	# Solo el servidor debe ejecutar esta lógica
	if not multiplayer.is_server():
		return

	var root := get_tree().get_root()

	var player := root.get_node_or_null(player_path)
	var target := root.get_node_or_null(target_path)

	if player == null or target == null:
		return

	if not target.is_in_group("Pickable"):
		return

	# Colocar el objeto en la mano del jugador
	target.global_position = player.hand_node.global_position
	target.global_rotation = player.hand_node.global_rotation
	target.collision_layer = 2

	if target is RigidBody3D:
		target.linear_velocity = Vector3(0.1, 3, 0.1)

func Play_MultiplayerClient():
	multiplayerpeer = ENetMultiplayerPeer.new()
	var error = multiplayerpeer.create_client(ip, port)
	if error == OK:
		multiplayer.multiplayer_peer = multiplayerpeer
		if not multiplayer.is_server():
			print_role("Client Init")
	else:
		print_role("Fatal Error in client")

func MultiplayerConnectionFailed():
	print_role("Client disconected")

	players_conected.clear()
	assigned_character.clear()
	destrolled_node.clear()

	CloseUp()
	
	multiplayerpeer = OfflineMultiplayerPeer.new()
	multiplayer.multiplayer_peer = multiplayerpeer

	LoadScene.load_scene(map, "res://Scenes/main_menu.tscn")

@rpc("any_peer", "call_local")
func assing_character(charac: String):
	for c in avalible_characters:
		if c == charac:
			character = charac
			break

	if local_player and is_instance_valid(local_player):
		local_player.character = charac

	print_role("Asignado el personaje: " + charac)

@rpc("authority", "call_local")
func assing_character_to_player(id: int, charac: String):
	var chosen_char = charac

	# Si el char recibido no es válido o ya está ocupado, buscamos el siguiente disponible.
	if chosen_char == null or chosen_char == "" or not is_character_avalible(chosen_char):
		chosen_char = get_next_avalible_character()

	if chosen_char == null or chosen_char == "" or not is_character_avalible(chosen_char):
		print_role("No hay personaje disponible para el id " + str(id))
		return false

	assigned_character[id] = chosen_char
	assing_character.rpc_id(id, chosen_char)
	print_role("Asignado al id " + str(id) + " el personaje " + chosen_char)
	return true

@rpc("any_peer", "call_local")
func sync_assigned_character(data: Dictionary):
	assigned_character = data.duplicate(true)

func is_character_avalible(charac: String):
	for id in assigned_character:
		if assigned_character[id] == charac:
			return false

	return true


func get_next_avalible_character():
	for charac in avalible_characters:
		if is_character_avalible(charac):
			return charac

	return null


	
func MultiplayerServerDisconnected():
	print_role("Client disconected")

	players_conected.clear()
	assigned_character.clear()
	destrolled_node.clear()

	CloseUp()
	
	multiplayerpeer = OfflineMultiplayerPeer.new()
	multiplayer.multiplayer_peer = multiplayerpeer

	LoadScene.load_scene(map, "res://Scenes/main_menu.tscn")


func MultiplayerConnectionServerSucess():
	print_role("connected to server")
	UnloadScene.unload_scene(main_menu)

func _exit_tree() -> void:
	multiplayer.peer_connected.disconnect(MultiplayerPlayerSpawner)
	multiplayer.peer_disconnected.disconnect(MultiplayerPlayerRemover)
	multiplayer.server_disconnected.disconnect(MultiplayerServerDisconnected)
	multiplayer.connected_to_server.disconnect(MultiplayerConnectionServerSucess)
	multiplayer.connection_failed.disconnect(MultiplayerConnectionFailed)

	Globals.Temperature_target = Globals.Temperature_original
	Globals.Humidity_target = Globals.Humidity_original
	Globals.pressure_target = Globals.pressure_original
	Globals.Wind_Direction_target = Globals.Wind_Direction_original
	Globals.Wind_speed_target = Globals.Wind_speed_original

	CloseUp()



func _process(_delta):
	if not multiplayer.has_multiplayer_peer():
		return
	
	if not multiplayer.is_server(): 
		return

	time_left = timer.time_left
	Temperature = clamp(Temperature, -275.5, 275.5)
	Humidity = clamp(Humidity, 0, 100)
	bradiation = clamp(bradiation, 0, 100)
	pressure = clamp(pressure , 0, 100000)
	oxygen = clamp(oxygen, 0, 100)

	Temperature = lerp(Temperature, Temperature_target, 0.005)
	Humidity = lerp(Humidity, Humidity_target, 0.005)
	bradiation = lerp(bradiation, bradiation_target, 0.005)
	pressure = lerp(pressure, pressure_target, 0.005)
	oxygen = lerp(oxygen, oxygen_target, 0.005)
	Wind_Direction = lerp(Wind_Direction, Wind_Direction_target, 0.005)
	Wind_speed = lerp(Wind_speed, Wind_speed_target, 0.005)


func _ready():
	multiplayer.peer_connected.connect(MultiplayerPlayerSpawner)
	multiplayer.peer_disconnected.connect(MultiplayerPlayerRemover)
	multiplayer.server_disconnected.connect(MultiplayerServerDisconnected)
	multiplayer.connected_to_server.connect(MultiplayerConnectionServerSucess)
	multiplayer.connection_failed.connect(MultiplayerConnectionFailed)

	multiplayerpeer = OfflineMultiplayerPeer.new()
	multiplayer.multiplayer_peer = multiplayerpeer
	

		
func MultiplayerPlayerSpawner(peer_id: int = 1):
	if not multiplayer.is_server():
		return

	if map and is_instance_valid(map):
		print_role("Joined player id: " + str(peer_id))
		var player = player_scene.instantiate()
		player.name = str(peer_id)
		map.add_child(player, true)

		
		var assigned_ok = true

		if not peer_id in assigned_character:
			var next_character = get_next_avalible_character()
			assigned_ok = assing_character_to_player(peer_id, next_character)

		if assigned_ok:
			sync_assigned_character.rpc(assigned_character)  
			sync_assigned_character(assigned_character)  
			sync_player_list.rpc()
			sync_destrolled_nodes.rpc_id(peer_id, destrolled_node) # envia al cliente
			set_weather_and_disaster.rpc_id(peer_id, current_weather_and_disaster_int)
		else:
			print_role("No se pudo asignar personaje al jugador con id: " + str(peer_id))
		
	else:
		sync_assigned_character.rpc(assigned_character)  
		sync_assigned_character(assigned_character)  
		sync_player_list.rpc()     
		sync_destrolled_nodes.rpc_id(peer_id, destrolled_node)                           # broadcast
		print_role("No se pudo añadir al jugador con el id: " + str(peer_id))	


func MultiplayerPlayerRemover(peer_id: int = 1):
	if not multiplayer.is_server():
		return

	# Intentar obtener el jugador de forma segura
	var player_node = map.get_node_or_null(str(peer_id))
	if player_node and is_instance_valid(player_node):
		print_role("Disconected player id: " + str(peer_id))
		player_node.queue_free()

		await player_node.tree_exited

		if peer_id in assigned_character:
			assigned_character.erase(peer_id)


		sync_assigned_character.rpc(assigned_character)  
		sync_assigned_character(assigned_character)  
		sync_player_list.rpc()

		
	else:
		if peer_id in assigned_character:
			assigned_character.erase(peer_id)

		sync_assigned_character.rpc(assigned_character)  
		sync_assigned_character(assigned_character)  
		sync_player_list.rpc()
		print_role("player no found: " + str(peer_id))


func sync_weather_and_disaster():
	if multiplayer.is_server():
		var random_weather_and_disaster = randi_range(0,12)
		set_weather_and_disaster.rpc(random_weather_and_disaster)

@rpc("authority", "call_local")
func set_weather_and_disaster(weather_and_disaster_index):
	match weather_and_disaster_index:
		0:
			current_weather_and_disaster = "Sun"
			current_weather_and_disaster_int = weather_and_disaster_index
		1:
			current_weather_and_disaster = "Cloud"
			current_weather_and_disaster_int = weather_and_disaster_index
		2:
			current_weather_and_disaster = "Raining"
			current_weather_and_disaster_int = weather_and_disaster_index
		3:
			current_weather_and_disaster = "Storm"
			current_weather_and_disaster_int = weather_and_disaster_index
		4:
			current_weather_and_disaster = "Thunderstorm"
			current_weather_and_disaster_int = weather_and_disaster_index
		5:
			current_weather_and_disaster = "Tsunami"
			current_weather_and_disaster_int = weather_and_disaster_index
		6:
			current_weather_and_disaster = "Meteor_shower"
			current_weather_and_disaster_int = weather_and_disaster_index
		7:
			current_weather_and_disaster = "Volcano"
			current_weather_and_disaster_int = weather_and_disaster_index
		8:
			current_weather_and_disaster = "Tornado"
			current_weather_and_disaster_int = weather_and_disaster_index
		9:
			current_weather_and_disaster = "Acid rain"
			current_weather_and_disaster_int = weather_and_disaster_index
		10:
			current_weather_and_disaster = "Earthquake"
			current_weather_and_disaster_int = weather_and_disaster_index
		11:
			current_weather_and_disaster = "Sand Storm"
			current_weather_and_disaster_int = weather_and_disaster_index
		12:
			current_weather_and_disaster = "blizzard"
			current_weather_and_disaster_int = weather_and_disaster_index
		13:
			current_weather_and_disaster = "Dust Storm"
			current_weather_and_disaster_int = weather_and_disaster_index
		"Sun":
			current_weather_and_disaster = weather_and_disaster_index
			current_weather_and_disaster_int = 0
		"Cloud":
			current_weather_and_disaster = weather_and_disaster_index
			current_weather_and_disaster_int = 1
		"Raining":
			current_weather_and_disaster = weather_and_disaster_index
			current_weather_and_disaster_int = 2
		"Storm":
			current_weather_and_disaster = weather_and_disaster_index
			current_weather_and_disaster_int = 3
		"Thunderstorm":
			current_weather_and_disaster = weather_and_disaster_index
			current_weather_and_disaster_int = 4
		"Tsunami":
			current_weather_and_disaster = weather_and_disaster_index
			current_weather_and_disaster_int = 5
		"Meteor_shower":
			current_weather_and_disaster = weather_and_disaster_index
			current_weather_and_disaster_int = 6
		"Volcano":
			current_weather_and_disaster = weather_and_disaster_index
			current_weather_and_disaster_int = 7
		"Tornado":
			current_weather_and_disaster = weather_and_disaster_index
			current_weather_and_disaster_int = 8
		"Acid rain":
			current_weather_and_disaster = weather_and_disaster_index
			current_weather_and_disaster_int = 9
		"Earthquake":
			current_weather_and_disaster = weather_and_disaster_index
			current_weather_and_disaster_int = 10

		"Sand Storm":
			current_weather_and_disaster = weather_and_disaster_index
			current_weather_and_disaster_int = 11
		"blizzard":
			current_weather_and_disaster = weather_and_disaster_index
			current_weather_and_disaster_int = 12
		"Dust Storm":
			current_weather_and_disaster = weather_and_disaster_index
			current_weather_and_disaster_int = 12
		_:
			current_weather_and_disaster = "Original"
			current_weather_and_disaster_int = -1


@rpc("any_peer", "call_local")
func add_points():
	points += 1


@rpc("any_peer", "call_local")
func remove_points():
	points -= 1

	if points < 0:
		points = 0


func close_conection():
	var peer = multiplayer.multiplayer_peer

	# Si no hay peer o está desconectado o es offline → volver al menú
	if peer == null \
	or peer is OfflineMultiplayerPeer \
	or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		MultiplayerServerDisconnected()
		return

	# Si está conectado → cerrar conexión
	peer.close()
	multiplayerpeer.close()



func _on_timer_timeout():
	if gamemode == "survival":
		if started:
			sync_weather_and_disaster()
		else:
			multiplayer.multiplayer_peer.close()

@rpc("authority", "call_local")
func sync_destrolled_nodes(Hauses: Array):
	for house_name in Hauses:
		var house = get_tree().get_current_scene().get_node_or_null(house_name)
		if house:
			house.queue_free()

func add_destrolled_nodes(Name: String):

	if not multiplayer.is_server():
		return

	if not destrolled_node.has(Name):
		destrolled_node.append(Name)


func remove_destrolled_nodes(Name: String):
	if not multiplayer.is_server():
		return

	if destrolled_node.has(Name):
		destrolled_node.erase(Name)

func remove_all_destrolled_nodes():
	if not multiplayer.is_server():
		return

	for i in destrolled_node:
		remove_destrolled_nodes(i)

func SetUpLisener():
	lisener = PacketPeerUDP.new()
	var ok = lisener.bind(lisener_port)
	if ok == OK:
		print_role("Lisener port %s binded!!" % lisener_port)
		if server_browser != null:
			server_browser.get_parent().get_node("Label").text = "Lisener port %s binded!!" % lisener_port
	else:
		print_role("Lisener port %s FAILED!!" % lisener_port)
		if server_browser != null:
			server_browser.get_parent().get_node("Label").text = "Lisener port %s FAILED!!" % lisener_port

	
func CloseUp():
	if lisener != null:
		lisener.close()

	if broadcaster != null:
		broadcaster.close()

	if broadcast_Timer != null:
		broadcast_Timer.stop()

func SetUpBroadcast(Name):
	room_list.name = Name
	room_list.players = players_conected.size()

	broadcaster = PacketPeerUDP.new()
	broadcaster.set_broadcast_enabled(true)
	broadcaster.set_dest_address(broadcaster_ip, lisener_port)

	var ok = broadcaster.bind(broadcaster_port)
	if ok == OK:
		print_role("Broadcaster port %s binded!!" % broadcaster_port)
	else:
		print_role("Broadcaster port %s FAILED!!" % broadcaster_port)

	if broadcast_Timer != null:
		broadcast_Timer.start()

func _on_broadcast_timer_timeout() -> void:
	room_list.players = players_conected.size()
	var data = JSON.stringify(room_list)
	var packet = data.to_ascii_buffer()
	if broadcaster != null:
		broadcaster.put_packet(packet)
