extends CanvasLayer

@onready var text_edit = $Panel/TextEdit

@onready var line_edit = $Panel/Panel2/LineEdit
@onready var button = $Panel/Panel2/Button


var history: Array[String] = []
var history_index: int = -1

var autocomplete_methods: Array = []

var dev_commands := {
	"god_mode": {
		"desc": "Muestra todos los comandos.",
		"method": "_cmd_god_mode_player",
		"args": 0
	},
	"kill_player": {
		"desc": "Cambia la velocidad del jugador. Uso: /set_speed 10",
		"method": "_cmd_kill_player",
		"args": 1
	},
	"teleport_player": {
		"desc": "Teletransporta al jugador a otro jugador. Uso: /teleport_player PlayerName",
		"method": "_cmd_teleport_player",
		"args": 1
	},
	"teleport_position": {
		"desc": "Teletransporta al jugador a una posición. Uso: /teleport_position Vector3(x,y,z)",
		"method": "_cmd_teleport_position",
		"args": 1
	},
	"kick_player": {
		"desc": "Expulsa a un jugador del servidor. Uso: /kick_player PlayerName",
		"method": "_cmd_kick_player",
		"args": 1
	},
	"damage_player": {
		"desc": "Inflige daño a un jugador. Uso: /damage_player PlayerName damage_amount",
		"method": "_cmd_damage_player",
		"args": 2
	},
	"spawn_disaster": {
		"desc": "Genera un desastre o clima. Uso: /spawn_disaster disaster_name",
		"method": "_cmd_spawn_disaster_weather",
		"args": 1
	},
	"admin": {
		"desc": "Genera un desastre o clima. Uso: /spawn_disaster disaster_name",
		"method": "_cmd_admin_mode_player",
		"args": 1
	},
	
}

func _get_local_player():
	for p in get_tree().get_nodes_in_group("player"):
		if p.is_multiplayer_authority():
			return p
	return null


func _cmd_god_mode_player():
	var player = _get_local_player()
	if player == null or not player.admin_mode:
		return "No tienes permisos"
	player.god_mode = true
	return "God Mode activado en ti"


func _cmd_admin_mode_player(player_name):
	var local = _get_local_player()
	if local == null or not local.admin_mode:
		return "No tienes permisos"
	for p in get_tree().get_nodes_in_group("player"):
		if p.username == player_name:
			p.admin_mode = true
			return "Ahora %s es admin" % player_name
	return "Jugador no encontrado"


func _cmd_kill_player(player_name):
	var local = _get_local_player()
	if local == null or not local.admin_mode:
		return "No tienes permisos"
	for p in get_tree().get_nodes_in_group("player"):
		if p.username == player_name:
			p.damage(999)
			return "💀 %s ha sido eliminado" % player_name
	return "Jugador no encontrado"


func _cmd_kick_player(player_name):
	var local = _get_local_player()
	if local == null or not local.admin_mode:
		return "No tienes permisos"
	for p in get_tree().get_nodes_in_group("player"):
		if p.username == player_name:
			multiplayer.multiplayer_peer.disconnect_peer(p.id, true)
			return "%s expulsado" % player_name
	return "Jugador no encontrado"


func _cmd_damage_player(player_name, damage):
	var local = _get_local_player()
	if local == null or not local.admin_mode:
		return "No tienes permisos"
	for p in get_tree().get_nodes_in_group("player"):
		if p.username == player_name:
			p.damage(int(damage))
			return "%s recibió %d de daño" % [player_name, damage]
	return "Jugador no encontrado"


func _cmd_teleport_player(player_name, target_name):
	var local = _get_local_player()
	if local == null or not local.admin_mode:
		return "No tienes permisos"

	var player = null
	var target = null

	for p in get_tree().get_nodes_in_group("player"):
		if p.username == player_name:
			player = p
		if p.username == target_name:
			target = p

	if player == null or target == null:
		return "Jugador no encontrado"

	player.global_position = target.global_position
	return "Teletransportado %s a %s" % [player_name, target_name]

func _cmd_spawn_disaster_weather(disaster_name):
	if Globals.admin_mode:
		Globals.set_weather_and_disaster(disaster_name)
		return "Clima/Desastre activado: %s" % disaster_name
	else:
		return "No tienes permisos para ejecutar este comando"



func _enter_tree():
	if Globals.is_networking:
		set_multiplayer_authority(multiplayer.get_unique_id())

func _ready() -> void:
	if Globals.is_networking:
		self.visible = is_multiplayer_authority()
		if not is_multiplayer_authority():
			return

	self.visible = true
	
	autocomplete_methods = dev_commands.keys()





func _input(_event: InputEvent) -> void:

	if line_edit.text.begins_with("/"):
		if Input.is_action_just_pressed('dev_console_autocomplete'):
			for method in autocomplete_methods:
				if method.begins_with(line_edit.text.erase(0,1)):
					# Populate console input with match
					line_edit.text = "/" + method
					# Make sure the caret goes to the end of the line
					line_edit.caret_column = 100000

		if Input.is_action_just_pressed('_dev_console_enter'):
			if line_edit.has_focus():
				history.push_front(line_edit.text.erase(0, 1))
				
				if Globals.is_networking:
					if not is_multiplayer_authority():
						return
						
					if line_edit.text.begins_with("/"):
						msg_rpc(Globals.username, line_edit.text)
					else:
						msg_rpc.rpc(Globals.username, line_edit.text)
				else:
					msg_rpc(Globals.username, line_edit.text)

				history_index = -1
				line_edit.text = ""
				line_edit.release_focus()
			button.release_focus()
		elif Input.is_action_just_released('_dev_console_prev'):
			if history.size() == 0:
				return
			history_index = clamp(history_index + 1, 0, history.size() - 1)
			line_edit.text = "/" + history[history_index]
			# Hack to make the caret go to the end of the line
			# If I ever have a line of code over 100k characters, please send help
			line_edit.caret_column = 100000
		elif Input.is_action_just_released('_dev_console_next'):
			if history.size() == 0:
				return
			history_index = clamp(history_index - 1, 0, history.size() - 1)
			line_edit.text = "/" + history[history_index]
			line_edit.caret_column = 100000

	else:
		if Input.is_action_just_pressed('Enter'):
			if line_edit.has_focus():
				if Globals.is_networking:
					if not is_multiplayer_authority():
						return

					msg_rpc.rpc(Globals.username, line_edit.text)
				else:
					msg_rpc(Globals.username, line_edit.text)

				line_edit.text = ""
				line_edit.release_focus()
				button.release_focus()
	
func _console_print(text: String):
	text_edit.text += text + "\n"
	text_edit.scroll_vertical = text_edit.get_line_height()

@rpc("any_peer", "call_local")
func _run_command(cmd: String) -> void:
	var parts = cmd.strip_edges().split(" ")
	var command_name = parts[0]
	var args = parts.slice(1, parts.size())

	if dev_commands.has(command_name):
		var cmd_info = dev_commands[command_name]

		if args.size() < cmd_info["args"]:
			_console_print("Faltan argumentos. Uso: /%s" % command_name)
			return

		var method_name = cmd_info["method"]
		if has_method(method_name):
			var result = callv(method_name, args)
			if result != null:
				_console_print(str(result))
			return
		else:
			_console_print("Error interno: método no encontrado.")
			return


	_console_print("Comando desconocido: %s" % command_name)


@rpc("any_peer", "call_local")
func msg_rpc(username, data):
	if Globals.is_networking:
		if data.begins_with("/"):
			if multiplayer.is_server() and is_multiplayer_authority():
				if data != "" or data != " ":
					text_edit.text += str(username, ": ", data, "\n")
					text_edit.scroll_vertical =  text_edit.get_line_height()
				data = data.erase(0, 1)
				Globals.print_role(data)
				_run_command.rpc(data)
			else:
				text_edit.text +=  "You are not a have admin... \n"	
				text_edit.scroll_vertical =  text_edit.get_line_height()
		else:
			if data != "" or data != " ":
				text_edit.text += str(username, ": ", data, "\n")
				text_edit.scroll_vertical =  text_edit.get_line_height()
	else:
		if data.begins_with("/"):
			if data != "" or data != " ":
				text_edit.text += str(username, ": ", data, "\n")
				text_edit.scroll_vertical =  text_edit	.get_line_height()
			data = data.erase(0, 1)
			Globals.print_role(data)
			_run_command(data)
		else:
			if data != "" or data != " ":
				text_edit.text += str(username, ": ", data, "\n")
				text_edit.scroll_vertical =  text_edit.get_line_height()	

	

func _on_button_pressed():
	if Globals.is_networking:
		if not is_multiplayer_authority():
			return

		if line_edit.text.begins_with("/"):
			msg_rpc(Globals.username, line_edit.text)
		else:
			msg_rpc.rpc(Globals.username, line_edit.text)
	else:
		msg_rpc(Globals.username, line_edit.text)
	
	line_edit.text = ""
	line_edit.release_focus()
	button.release_focus()


func _on_line_edit_focus_entered() -> void:
	Globals.is_chat_open = true

func _on_line_edit_focus_exited():
	Globals.is_chat_open = false
