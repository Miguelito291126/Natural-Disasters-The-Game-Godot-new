extends Panel

@onready var list = $List
var serverinfo = preload("res://Scenes/server_info.tscn") 

const TIMEOUT = 3.0

func _ready() -> void:
	Globals.server_browser = self

func _process(_delta: float) -> void:
	# 1) Eliminar servidores que llevan demasiado sin actualizar
	var now = Time.get_unix_time_from_system()
	Reload(now)

	if Globals.lisener.get_available_packet_count() > 0:
		var server_ip = Globals.lisener.get_packet_ip()
		var server_port = Globals.lisener.get_packet_port()
		var bytes = Globals.lisener.get_packet()
		var data = bytes.get_string_from_ascii()
		var room_list = JSON.parse_string(data)

		for i in list.get_children():
			if i.name == room_list.name:
				i.get_node("Name").text = room_list.name + " - "
				i.get_node("Players").text = str(room_list.players) + " - "
				i.server_ip = server_ip
				i.server_port = str(server_port)
				i.last_seen = now
				return

		var currentinfo = serverinfo.instantiate()
		currentinfo.name = room_list.name
		currentinfo.get_node("Name").text = room_list.name + " - "
		currentinfo.get_node("Players").text = str(room_list.players) + " - "
		currentinfo.server_ip = server_ip
		currentinfo.server_port = str(server_port)
		currentinfo.last_seen = now
		list.add_child(currentinfo, true)

func Reload(now):
	for i in list.get_children():
		if i is HBoxContainer:
			if now - i.last_seen > TIMEOUT:
				Globals.print_role("Eliminando servidor inactivo:" + i.name)
				i.queue_free()
