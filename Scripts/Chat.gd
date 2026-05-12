extends CanvasLayer
class_name Chat

@onready var text_edit: TextEdit = $Panel/TextEdit
@onready var line_edit: LineEdit = $Panel/Panel2/LineEdit
@onready var button: Button = $Panel/Panel2/Button

var autocomplete_matches: Array[String] = []
var autocomplete_index: int = 0
var history: Array[String] = []
var history_index: int = -1
var user_is_scrolling: bool = false
var scroll_retries := 0
var autocomplete_methods: Array = [] #
const MAX_SCROLL_RETRIES := 5

var dev_commands := {
	"god_mode": {"desc": "Activa modo Dios.", "method": "_cmd_god_mode_player", "args": 0},
	"ungod_mode": {"desc": "Desactiva modo Dios.", "method": "_cmd_ungod_mode_player", "args": 0},
	"kill_player": {"desc": "Mata a un jugador. /kill_player Nombre", "method": "_cmd_kill_player", "args": 1},
	"damage_player": {"desc": "Daña a un jugador. /damage_player Nombre Cantidad", "method": "_cmd_damage_player", "args": 2},
	"spawn_disaster": {"desc": "Genera desastre. /spawn_disaster Nombre", "method": "_cmd_spawn_disaster_weather", "args": 1},
	"admin": {"desc": "Da admin. /admin Nombre", "method": "_cmd_admin_mode_player", "args": 1},
	"unadmin": {"desc": "Quita admin. /unadmin Nombre", "method": "_cmd_unadmin_mode_player", "args": 1}
}

func _get_local_player():
	for p in get_tree().get_nodes_in_group("player"):
		if p.is_multiplayer_authority():
			return p

	return null

@rpc("any_peer", "call_local")
func _run_command(cmd_text: String) -> void:
	var parts = cmd_text.strip_edges().split(" ", false)
	if parts.size() == 0: return

	var command_name = parts[0].to_lower()
	if not dev_commands.has(command_name):
		_console_print("Comando desconocido: " + command_name)
		return

	var cmd_info = dev_commands[command_name]
	var args = parts.slice(1)

	if args.size() < cmd_info["args"]:
		_console_print("Uso: /%s %s" % [command_name, cmd_info["desc"]])
		return

	if has_method(cmd_info["method"]):
		# callv pasa el array de argumentos directamente a la función
		var result = callv(cmd_info["method"], args)
		if result != null:
			_console_print(str(result))


func _cmd_god_mode_player():
	var player = _get_local_player()
	if player == null or not player.admin_mode:
		return "No tienes permisos"
	player.god_mode = true
	return "God Mode activado en ti"

func _cmd_ungod_mode_player():
	var player = _get_local_player()
	if player == null or not player.admin_mode:
		return "No tienes permisos"
	player.god_mode = false
	return "God Mode desactivado en ti"


func _cmd_admin_mode_player(player_name):
	var local = _get_local_player()
	if local == null or not local.admin_mode:
		return "No tienes permisos"
	
	# Solo el servidor puede cambiar admin_mode
	if not multiplayer.is_server():
		return "Solo el servidor puede cambiar permisos de admin"
	
	# Buscar el jugador por nombre
	var jugador_encontrado = null
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p) and p.username == player_name:
			jugador_encontrado = p
			break
	
	if jugador_encontrado == null:
		return "Jugador no encontrado: %s" % player_name
	
	# Usar RPC para sincronizar el cambio en todos los clientes
	# call_local ya ejecuta la función localmente en el servidor
	jugador_encontrado._set_admin_mode.rpc(true)
	return "Ahora %s es admin" % player_name

func _cmd_unadmin_mode_player(player_name):
	var local = _get_local_player()
	if local == null or not local.admin_mode:
		return "No tienes permisos"
	
	# Solo el servidor puede cambiar admin_mode
	if not multiplayer.is_server():
		return "Solo el servidor puede cambiar permisos de admin"
	
	# Buscar el jugador por nombre
	var jugador_encontrado = null
	for p in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(p) and p.username == player_name:
			jugador_encontrado = p
			break
	
	if jugador_encontrado == null:
		return "Jugador no encontrado: %s" % player_name
	
	# Usar RPC para sincronizar el cambio en todos los clientes
	# call_local ya ejecuta la función localmente en el servidor
	jugador_encontrado._set_admin_mode.rpc(false)
	return "Ahora %s ya no es admin" % player_name


func _cmd_kill_player(player_name):
	var local = _get_local_player()
	if local == null or not local.admin_mode:
		return "No tienes permisos"
	for p in get_tree().get_nodes_in_group("player"):
		if p.username == player_name:
			p.damage(999)
			return "%s ha sido eliminado" % player_name
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
	var local = _get_local_player()
	if local == null or not local.admin_mode:
		return "No tienes permisos"

	Globals.set_weather_and_disaster(disaster_name)
	return "Clima/Desastre activado: %s" % disaster_name


func _enter_tree():
	set_multiplayer_authority(multiplayer.get_unique_id())

func _ready() -> void:

	if not is_multiplayer_authority():
		self.visible = false
		return

	self.visible = true
	
	autocomplete_methods = dev_commands.keys()

func _input(_event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return

	# Seleccionar el LineEdit al presionar T
	if Input.is_action_just_pressed("Chat") and not line_edit.has_focus():
		line_edit.grab_focus()
		Globals.is_chat_open = true
		get_viewport().set_input_as_handled() 
		return

	if line_edit.has_focus():
		# Autocompletado con Tab
		if Input.is_action_just_pressed("dev_console_autocomplete"):
			# Usar slice o substr es más seguro que erase para no modificar el original por error
			var current = line_edit.text.substr(1) if line_edit.text.begins_with("/") else line_edit.text
			
			if autocomplete_matches.is_empty():
				for cmd in dev_commands.keys(): # Usamos directamente las llaves del diccionario
					if cmd.begins_with(current):
						autocomplete_matches.append(cmd)

			if autocomplete_matches.size() > 0:
				line_edit.text = "/" + autocomplete_matches[autocomplete_index]
				line_edit.caret_column = line_edit.text.length()
				autocomplete_index = (autocomplete_index + 1) % autocomplete_matches.size()
			
			get_viewport().set_input_as_handled() # Evita que el Tab cambie de nodo UI


		elif Input.is_action_just_pressed("dev_console_up"):
			if not history.is_empty():
				history_index = clamp(history_index + 1, 0, history.size() - 1)
				line_edit.text = "/" + history[history_index]
				line_edit.caret_column = line_edit.text.length()
				# Al navegar por el historial, limpiamos el autocompletado previo
				autocomplete_matches.clear()
				autocomplete_index = 0
			get_viewport().set_input_as_handled()

		# --- 3. HISTORIAL (Con Flecha Abajo / dev_console_down) ---
		elif Input.is_action_just_pressed("dev_console_down"):
			if not history.is_empty():
				history_index = clamp(history_index - 1, 0, history.size() - 1)
				line_edit.text = "/" + history[history_index]
				line_edit.caret_column = line_edit.text.length()
				
				autocomplete_matches.clear()
				autocomplete_index = 0
			get_viewport().set_input_as_handled()

		if _event is InputEventKey and _event.pressed:
			if not _event.is_action("dev_console_autocomplete"):
				autocomplete_matches.clear()
				autocomplete_index = 0

		# Ejecutar comando con Enter
		if Input.is_action_just_pressed("Enter"): # "ui_accept" es el Enter por defecto
			if line_edit.text.strip_edges() != "":
				var clean_text = line_edit.text
				# Guardar en historial
				var history_text = clean_text.substr(1) if clean_text.begins_with("/") else clean_text
				history.push_front(history_text)
				
				msg_rpc.rpc(Globals.username, clean_text)

				history_index = -1
				line_edit.text = ""
				line_edit.release_focus()
				Globals.is_chat_open = false
				get_viewport().set_input_as_handled()


	
@rpc("any_peer", "call_local")
func msg_rpc(username: String, data: String) -> void:
	var was_at_bottom = _is_at_bottom()
	text_edit.text += "%s: %s\n" % [username, data]
	
	if was_at_bottom:
		_scroll_to_bottom()

	# Solo el servidor ejecuta la lógica de comandos por seguridad
	if data.begins_with("/") and multiplayer.is_server():
		var cmd_raw = data.substr(1)
		# Verificar si el que envió el mensaje es admin
		for p in get_tree().get_nodes_in_group("player"):
			if p.username == username and p.admin_mode:
				_run_command.rpc_id(multiplayer.get_remote_sender_id(), cmd_raw)
				break

func _handle_autocomplete():
	var current = line_edit.text.to_lower()
	var search = current.substr(1) if current.begins_with("/") else current
	
	if autocomplete_matches.is_empty():
		for key in dev_commands.keys():
			if key.begins_with(search):
				autocomplete_matches.append(key)
	
	if not autocomplete_matches.is_empty():
		line_edit.text = "/" + autocomplete_matches[autocomplete_index]
		line_edit.caret_column = line_edit.text.length()
		autocomplete_index = (autocomplete_index + 1) % autocomplete_matches.size()

func _handle_history(dir: int):
	if history.is_empty(): return
	history_index = clamp(history_index + dir, 0, history.size() - 1)
	line_edit.text = history[history_index]
	line_edit.caret_column = line_edit.text.length()

func _on_button_pressed():
	if line_edit.text.strip_edges() == "": return
	msg_rpc.rpc(Globals.username, line_edit.text)
	history.push_front(line_edit.text)
	line_edit.text = ""
	line_edit.release_focus()

func _is_at_bottom() -> bool:
	var v_scroll = text_edit.get_v_scroll_bar()
	return v_scroll.value >= (v_scroll.max_value - v_scroll.page - 10)

func _scroll_to_bottom():
	_do_scroll_to_bottom.call_deferred()

func _do_scroll_to_bottom():
	text_edit.scroll_vertical = text_edit.get_v_scroll_bar().max_value

func _console_print(text: String):
	text_edit.text += "[SISTEMA]: %s\n" % text
	_scroll_to_bottom()

func _on_line_edit_focus_entered(): 
	Globals.is_chat_open = true
func _on_line_edit_focus_exited(): 
	Globals.is_chat_open = false
