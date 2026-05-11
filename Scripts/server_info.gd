extends HBoxContainer
class_name ServerInfo

var lobby_id: String
var host_id: String
var server_port: String
var last_seen: int

func _on_button_pressed() -> void:
	Globals.lobby_id = lobby_id.to_int()
	Globals.steam_id = host_id.to_int()
	Globals.port = server_port.to_int() + 1
	Globals.Play_MultiplayerClientSteam(lobby_id.to_int())
