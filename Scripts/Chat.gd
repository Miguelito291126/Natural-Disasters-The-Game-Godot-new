extends CanvasLayer



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
	
}

func _cmd_teleport_position(pos):
	for player in self.get_children():
		if player.is_multiplayer_authority() and player.is_in_group("player"):
			player.position = pos

func _cmd_teleport_player(player_name):
	for player in self.get_children():
		if player.is_multiplayer_authority() and player.is_in_group("player"):
			for player2 in self.get_children():
				if player2.is_in_group("player") and player2.username == player_name  :
					player.position = player2.position


func _cmd_kill_player(player_name):
	for player2 in self.get_children():
		if player2.is_in_group("player") and player2.username == player_name  :
			player2.damage(100)

func _cmd_god_mode_player(player_name):
	for player2 in self.get_children():
		if player2.is_in_group("player") and player2.username == player_name  :
			player2.god_mode = true

func _cmd_kick_player(player_name):
	for player2 in self.get_children():
		if player2.is_in_group("player") and player2.username == player_name  :
			multiplayer.multiplayer_peer.disconnect_peer(player2.id, true)

func _cmd_damage_player(player_name, damage):
	for player2 in self.get_children():
		player2.damage(damage)

func _cmd_spawn_disaster_weather(disaster_name):
	Globals.set_weather_and_disaster(disaster_name)

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

	if $LineEdit.text.begins_with("/"):
		if Input.is_action_just_pressed('dev_console_autocomplete'):
			for method in autocomplete_methods:
				if method.begins_with($LineEdit.text.erase(0,1)):
					# Populate console input with match
					$LineEdit.text = "/" + method
					# Make sure the caret goes to the end of the line
					$LineEdit.caret_column = 100000

		if Input.is_action_just_pressed('_dev_console_enter'):
			if $LineEdit.has_focus():
				history.push_front($LineEdit.text.erase(0, 1))
				
				if Globals.is_networking:
					if not is_multiplayer_authority():
						return
						
					if $LineEdit.text.begins_with("/"):
						msg_rpc(Globals.username, $LineEdit.text)
					else:
						msg_rpc.rpc(Globals.username, $LineEdit.text)
				else:
					msg_rpc(Globals.username, $LineEdit.text)

				history_index = -1
				$LineEdit.text = ""
				$LineEdit.release_focus()
			$Button.release_focus()
		elif Input.is_action_just_released('_dev_console_prev'):
			if history.size() == 0:
				return
			history_index = clamp(history_index + 1, 0, history.size() - 1)
			$LineEdit.text = "/" + history[history_index]
			# Hack to make the caret go to the end of the line
			# If I ever have a line of code over 100k characters, please send help
			$LineEdit.caret_column = 100000
		elif Input.is_action_just_released('_dev_console_next'):
			if history.size() == 0:
				return
			history_index = clamp(history_index - 1, 0, history.size() - 1)
			$LineEdit.text = "/" + history[history_index]
			$LineEdit.caret_column = 100000

	else:
		if Input.is_action_just_pressed('Enter'):
			if $LineEdit.has_focus():
				if Globals.is_networking:
					if not is_multiplayer_authority():
						return

					msg_rpc.rpc(Globals.username, $LineEdit.text)
				else:
					msg_rpc(Globals.username, $LineEdit.text)

				$LineEdit.text = ""
				$LineEdit.release_focus()
				$Button.release_focus()
	
func _console_print(text: String):
	$TextEdit.text += text + "\n"
	$TextEdit.scroll_vertical = $TextEdit.get_line_height()

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
					$TextEdit.text += str(username, ": ", data, "\n")
					$TextEdit.scroll_vertical =  $TextEdit.get_line_height()
				data = data.erase(0, 1)
				Globals.print_role(data)
				_run_command.rpc(data)
			else:
				$TextEdit.text +=  "You are not a have admin... \n"	
				$TextEdit.scroll_vertical =  $TextEdit.get_line_height()
		else:
			if data != "" or data != " ":
				$TextEdit.text += str(username, ": ", data, "\n")
				$TextEdit.scroll_vertical =  $TextEdit.get_line_height()
	else:
		if data.begins_with("/"):
			if data != "" or data != " ":
				$TextEdit.text += str(username, ": ", data, "\n")
				$TextEdit.scroll_vertical =  $TextEdit.get_line_height()
			data = data.erase(0, 1)
			Globals.print_role(data)
			_run_command(data)
		else:
			if data != "" or data != " ":
				$TextEdit.text += str(username, ": ", data, "\n")
				$TextEdit.scroll_vertical =  $TextEdit.get_line_height()	

	

func _on_button_pressed():
	if Globals.is_networking:
		if not is_multiplayer_authority():
			return

		if $LineEdit.text.begins_with("/"):
			msg_rpc(Globals.username, $LineEdit.text)
		else:
			msg_rpc.rpc(Globals.username, $LineEdit.text)
	else:
		msg_rpc(Globals.username, $LineEdit.text)
	
	$LineEdit.text = ""
	$LineEdit.release_focus()
	$Button.release_focus()


func _on_line_edit_focus_entered() -> void:
	Globals.is_chat_open = true

func _on_line_edit_focus_exited():
	Globals.is_chat_open = false
