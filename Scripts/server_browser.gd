extends ScrollContainer
class_name ServerBrowser

@onready var list: VBoxContainer = $List
@export var server_info_scene: PackedScene = preload("res://Scenes/server_info.tscn")
const TIMEOUT: float = 3.0

func _ready() -> void:
	Globals.server_browser = self
	
	# Conectar señales de Steam (GodotSteam usa señales en minúsculas usualmente)
	if Steam.has_signal("lobby_match_list"):
		Steam.lobby_match_list.connect(_on_steam_lobbies_received)

	# Timer para refrescar automáticamente
	var clean_timer = Timer.new()
	clean_timer.wait_time = 5.0
	clean_timer.autostart = true
	clean_timer.timeout.connect(refresh_server_list)
	add_child(clean_timer)
	
	refresh_server_list()

func refresh_server_list() -> void:
	# Limpiar lista visual
	for n in list.get_children():
		n.queue_free()

	if Globals.use_steam:
		print("Buscando lobbies en Steam...")
		# Filtros de Steam
		Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
		Steam.addRequestLobbyListStringFilter("game_id", "natural_disaster_game", Steam.LOBBY_COMPARISON_EQUAL)
		Steam.requestLobbyList()

func _on_steam_lobbies_received(lobbies: Array) -> void:
	print("Se encontraron %d lobbies de Steam." % lobbies.size())

	for lobby_id in lobbies:
		var current_info: ServerInfo = server_info_scene.instantiate()
		
		# Extraer datos del lobby usando el ID
		var lobby_name = Steam.getLobbyData(lobby_id, "name")
		var host_id = Steam.getLobbyData(lobby_id, "host_id")
		var players = Steam.getLobbyData(lobby_id, "players_count")
		var port = Steam.getLobbyData(lobby_id, "port")
		var local_ip = Steam.getLobbyData(lobby_id, "local_ip")
		var public_ip = Steam.getLobbyData(lobby_id, "public_ip")

		# Configurar el nodo visual (asegúrate de que los nombres coincidan en tu escena server_info)
		current_info.get_node("Name").text = str(lobby_name) + " - "
		current_info.get_node("Players").text = str(players) + " / 4 - "

		# Guardamos los datos en el script del item de la lista
		current_info.lobby_id = str(lobby_id)
		current_info.host_id = host_id
		current_info.server_port = port
		current_info.public_ip = public_ip
		current_info.local_ip = local_ip

		list.add_child(current_info)
