extends Panel

@onready var list = $List
var serverinfo = preload("res://Scenes/server_info.tscn") 

func _ready() -> void:
	Globals.server_browser = self

func _process(_delta: float) -> void:
	if Globals.lisener.get_available_packet_count() > 0:
		var server_ip = Globals.lisener.get_packet_ip()
		var server_port = Globals.lisener.get_packet_port()
		var bytes = Globals.lisener.get_packet()
		var data = bytes.get_string_from_ascii()
		var room_list = JSON.parse_string(data)
		var server_id = "%s:%s" % [server_ip, server_port]

		for i in list.get_children():
			if i is HBoxContainer:
				i.queue_free()
				
		var existing = null
		for i in list.get_children():
			if i.name == server_id:
				existing = i
				break

		if existing:
			existing.get_node("Name").text = room_list.name + " - "
			existing.get_node("Players").text = str(room_list.players) + " - "
			existing.server_ip = server_ip
			existing.server_port = str(server_port)
			return

		var currentinfo = serverinfo.instantiate()
		currentinfo.name = server_id
		currentinfo.get_node("Name").text = room_list.name + " - "
		currentinfo.get_node("Players").text = str(room_list.players) + " - "
		currentinfo.server_ip = server_ip
		currentinfo.server_port = str(server_port)
		list.add_child(currentinfo, true)

