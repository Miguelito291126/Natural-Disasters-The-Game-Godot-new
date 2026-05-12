extends HBoxContainer
class_name ServerInfo

var lobby_id: String
var host_id: String
var server_port: String
var local_ip: String
var public_ip: String
var last_seen: int

func _on_button_pressed() -> void:
	Globals.lobby_id = lobby_id.to_int()
	Globals.steam_id = host_id.to_int()
	Globals.lobby_id = lobby_id.to_int()
	Globals.port = server_port.to_int()

	if public_ip  == Globals.public_ip :
		Globals.ip = local_ip
	else:
		Globals.ip = public_ip

	if Globals.use_steam:
		Globals.Play_MultiplayerClientSteam(Globals.lobby_id)
	else:
		Globals.Play_MultiplayerClient(Globals.ip, Globals.port)
