extends Panel

@onready var list = $List
var serverinfo = preload("res://Scenes/server_info.tscn")

# tiempo máximo sin recibir broadcast antes de eliminar
const TIMEOUT := 5.0  

func _ready() -> void:
	Globals.server_browser = self

func _process(_delta: float) -> void:
	if Globals.lisener.get_available_packet_count() > 0:
		var server_ip = Globals.lisener.get_packet_ip()
		var server_port = Globals.lisener.get_packet_port()
		var bytes = Globals.lisener.get_packet()
		var data = bytes.get_string_from_ascii()
		var room_list = JSON.parse_string(data)

		var existing = null
		for i in list.get_children():
			if i.name == room_list.name:
				existing = i
				break

		if existing:
			existing.get_node("Name").text = room_list.name + " - "
			existing.get_node("Players").text = str(room_list.players) + " - "
			existing.server_ip = server_ip
			existing.server_port = str(server_port)
			existing.last_seen = Time.get_unix_time_from_system()
			return

		# si no existía, eliminar duplicados residuales
		for i in list.get_children():
			if i.name == "Info":
				continue
				
			if i.server_ip == server_ip and i.server_port == str(server_port):
				i.queue_free()

		var currentinfo = serverinfo.instantiate()
		currentinfo.name = room_list.name
		currentinfo.get_node("Name").text = room_list.name + " - "
		currentinfo.get_node("Players").text = str(room_list.players) + " - "
		currentinfo.server_ip = server_ip
		currentinfo.server_port = str(server_port)
		currentinfo.last_seen = Time.get_unix_time_from_system() # 👈 aquí
		list.add_child(currentinfo, true)


	# comprobar expirados
	for i in list.get_children():
		if i is HBoxContainer: # te aseguras de que es un server_info
			if Time.get_unix_time_from_system() - i.last_seen > TIMEOUT:
				print("Eliminando servidor inactivo:", i.name)
				i.queue_free()
