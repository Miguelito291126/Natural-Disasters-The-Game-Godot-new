extends Node


signal current_weather_and_disaster_changed(new_disaster: String)


#Editor
var version = ProjectSettings.get_setting("application/config/version")
var gamename = ProjectSettings.get_setting("application/config/name")
var credits = "Miguelillo223"

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


func Play_MultiplayerClient():
	multiplayerpeer = ENetMultiplayerPeer.new()
	var error = multiplayerpeer.create_client(ip, port)
	if error == OK:
		multiplayer.multiplayer_peer = multiplayerpeer
		if not multiplayer.is_server():
			print_role("Client Init")
			UnloadScene.unload_scene(main_menu)
	else:
		print_role("Fatal Error in client")

func MultiplayerConnectionFailed():
	print_role("client disconected: failed to load")
	get_tree().paused = false
	CloseUp()
	sync_player_list()
	remove_all_destrolled_nodes()

	multiplayerpeer = OfflineMultiplayerPeer.new()
	multiplayer.multiplayer_peer = multiplayerpeer

	LoadScene.load_scene(map, "res://Scenes/main_menu.tscn")
	
func MultiplayerServerDisconnected():
	print_role("Client disconected")
	get_tree().paused = false
	CloseUp()
	sync_player_list()
	remove_all_destrolled_nodes()

	multiplayerpeer = OfflineMultiplayerPeer.new()
	multiplayer.multiplayer_peer = multiplayerpeer

	LoadScene.load_scene(map, "res://Scenes/main_menu.tscn")


func MultiplayerConnectionServerSucess():
	print_role("connected to server")


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
	if map and is_instance_valid(map):
		print_role("Joined player id: " + str(peer_id))
		var player = player_scene.instantiate()
		player.name = str(peer_id)
		map.add_child(player, true)

		# ahora que el player está en el árbol, sincronizamos datos
		sync_player_list.rpc()                                # broadcast
		sync_destrolled_nodes.rpc_id(peer_id, destrolled_node) # envia al cliente
		set_weather_and_disaster.rpc_id(peer_id, current_weather_and_disaster_int)

			
			


func MultiplayerPlayerRemover(peer_id: int = 1):
	# Intentar obtener el jugador de forma segura
	var player_node = map.get_node_or_null(str(peer_id))
	if player_node and is_instance_valid(player_node):
		print_role("Disconected player id: " + str(peer_id))
		player_node.queue_free()
		sync_player_list.rpc()
	else:
		# fallback: buscar por grupo y authority (por si el nombre cambió)
		for p in get_tree().get_nodes_in_group("player"):
			if is_instance_valid(p) and p.get_multiplayer_authority() == peer_id:
				print_role("Disconected player id: " + str(peer_id))
				p.queue_free()
				sync_player_list.rpc()
				return

	# si no se encuentra, log para depurar
	print_role("player no found: " + str(peer_id))



func sync_weather_and_disaster():
	if multiplayer.is_server():
		var random_weather_and_disaster = randi_range(0,12)
		set_weather_and_disaster.rpc(random_weather_and_disaster)

@rpc("any_peer", "call_local")
func set_weather_and_disaster(weather_and_disaster_index):
	match weather_and_disaster_index:
		0:
			current_weather_and_disaster = "Sun"
			current_weather_and_disaster_int = 0
		1:
			current_weather_and_disaster = "Cloud"
			current_weather_and_disaster_int = 1
		2:
			current_weather_and_disaster = "Raining"
			current_weather_and_disaster_int = 2
		3:
			current_weather_and_disaster = "Storm"
			current_weather_and_disaster_int = 3
		4:
			current_weather_and_disaster = "Thunderstorm"
			current_weather_and_disaster_int = 4
		5:
			current_weather_and_disaster = "Tsunami"
			current_weather_and_disaster_int = 5
		6:
			current_weather_and_disaster = "Meteor_shower"
			current_weather_and_disaster_int = 6
		7:
			current_weather_and_disaster = "Volcano"
			current_weather_and_disaster_int = 7
		8:
			current_weather_and_disaster = "Tornado"
			current_weather_and_disaster_int = 8
		9:
			current_weather_and_disaster = "Acid rain"
			current_weather_and_disaster_int = 9
		10:
			current_weather_and_disaster = "Earthquake"
			current_weather_and_disaster_int = 10
		11:
			current_weather_and_disaster = "Sand Storm"
			current_weather_and_disaster_int = 11
		12:
			current_weather_and_disaster = "blizzard"
			current_weather_and_disaster_int = 12
		"Sun":
			current_weather_and_disaster = "Sun"
			current_weather_and_disaster_int = 0
		"Cloud":
			current_weather_and_disaster = "Cloud"
			current_weather_and_disaster_int = 1
		"Raining":
			current_weather_and_disaster = "Raining"
			current_weather_and_disaster_int = 2
		"Storm":
			current_weather_and_disaster = "Storm"
			current_weather_and_disaster_int = 3
		"Thunderstorm":
			current_weather_and_disaster = "Thunderstorm"
			current_weather_and_disaster_int = 4
		"Tsunami":
			current_weather_and_disaster = "Tsunami"
			current_weather_and_disaster_int = 5
		"Meteor_shower":
			current_weather_and_disaster = "Meteor_shower"
			current_weather_and_disaster_int = 6
		"Volcano":
			current_weather_and_disaster = "Volcano"
			current_weather_and_disaster_int = 7
		"Tornado":
			current_weather_and_disaster = "Tornado"
			current_weather_and_disaster_int = 8
		"Acid rain":
			current_weather_and_disaster = "Acid rain"
			current_weather_and_disaster_int = 9
		"Earthquake":
			current_weather_and_disaster = "Earthquake"
			current_weather_and_disaster_int = 10

		"Sand Storm":
			current_weather_and_disaster = "Sand Storm"
			current_weather_and_disaster_int = 11
		"blizzard":
			current_weather_and_disaster = "blizzard"
			current_weather_and_disaster_int = 12
		_:
			current_weather_and_disaster = "Original"
			current_weather_and_disaster_int = 0


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
		get_tree().paused = false
		LoadScene.load_scene(Globals.map, "res://Scenes/main_menu.tscn")
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
		if house and not house.destrolled:
			house.destroy()

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
