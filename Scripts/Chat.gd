extends CanvasLayer

@onready var text_edit = $Panel/TextEdit

@onready var line_edit = $Panel/Panel2/LineEdit
@onready var button = $Panel/Panel2/Button


var autocomplete_matches: Array[String] = []
var autocomplete_index: int = 0
var autocomplete_methods: Array = []
var history: Array[String] = []
var history_index: int = -1
var user_is_scrolling: bool = false
var scroll_retries := 0
const MAX_SCROLL_RETRIES := 5



var dev_commands := {
	"god_mode": {
		"desc": "Muestra todos los comandos.",
		"method": "_cmd_god_mode_player",
		"args": 0
	},
	"ungod_mode": {
		"desc": "Muestra todos los comandos.",
		"method": "_cmd_ungod_mode_player",
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

	"unadmin": {
		"desc": "Genera un desastre o clima. Uso: /spawn_disaster disaster_name",
		"method": "_cmd_unadmin_mode_player",
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
	# Solo procesar input si este chat tiene autoridad
	if not is_multiplayer_authority():
		return
	
	if line_edit.has_focus():
		# Autocompletado con Tab
		if Input.is_action_just_pressed("dev_console_autocomplete"):
			var current = line_edit.text.erase(0,1)
			
			if autocomplete_matches.is_empty():
				for cmd in autocomplete_methods:
					if cmd.begins_with(current):
						autocomplete_matches.append(cmd)

			if autocomplete_matches.size() > 0:
				line_edit.text = "/" + autocomplete_matches[autocomplete_index]
				line_edit.caret_column = line_edit.text.length()
				autocomplete_index = (autocomplete_index + 1) % autocomplete_matches.size()

		# Reset autocompletado si se escribe algo distinto
		if Input.is_action_just_pressed("ui_text_indent"):
			autocomplete_matches.clear()
			autocomplete_index = 0

		# Recorrer historial con flechas
		if Input.is_action_just_pressed("dev_console_up"):
			if history.size() > 0:
				history_index = clamp(history_index + 1, 0, history.size() - 1)
				line_edit.text = "/" + history[history_index]
				line_edit.caret_column = line_edit.text.length()

		elif Input.is_action_just_pressed("dev_console_down"):
			if history.size() > 0:
				history_index = clamp(history_index - 1, 0, history.size() - 1)
				line_edit.text = "/" + history[history_index]
				line_edit.caret_column = line_edit.text.length()

		# Ejecutar comando con Enter
		if Input.is_action_just_pressed('Enter'):
			history.push_front(line_edit.text.erase(0, 1))
				
			msg_rpc.rpc(Globals.username, line_edit.text)

			history_index = -1
			line_edit.text = ""
			line_edit.release_focus()
			button.release_focus()
			# Asegurar que is_chat_open se establece en false cuando se cierra el chat
			Globals.is_chat_open = false

	# Seleccionar el LineEdit al presionar T
	if Input.is_action_just_pressed("Chat"):
		line_edit.grab_focus()
		# Asegurar que is_chat_open se establece cuando se abre el chat
		Globals.is_chat_open = true


	
func _is_at_bottom() -> bool:
	var scroll_bar = text_edit.get_v_scroll_bar()
	if scroll_bar == null:
		return true
	# Considerar que está al final si está dentro de 20 píxeles del máximo
	# Esto permite un pequeño margen para detectar si el usuario está scrolleando
	if scroll_bar.max_value <= 0:
		return true
	
	return scroll_bar.value >= (scroll_bar.max_value - 20)

func _scroll_to_bottom():
	scroll_retries = 0
	call_deferred("_do_scroll_to_bottom")

func _do_scroll_to_bottom():
	# Si el nodo ya no existe, parar
	if not is_instance_valid(self) or not is_inside_tree():
		return

	if not is_instance_valid(text_edit):
		return

	var scroll_bar = text_edit.get_v_scroll_bar()

	if scroll_bar == null:
		scroll_retries += 1
		if scroll_retries < MAX_SCROLL_RETRIES:
			call_deferred("_do_scroll_to_bottom")
		return

	var max_val = scroll_bar.max_value
	if max_val <= 0:
		scroll_retries += 1
		if scroll_retries < MAX_SCROLL_RETRIES:
			call_deferred("_do_scroll_to_bottom")
		return

	# Scroll final
	text_edit.scroll_vertical = max_val
	scroll_bar.value = max_val


func _console_print(text: String):
	# Verificar si estaba al final ANTES de añadir el texto
	var was_at_bottom = _is_at_bottom()
	text_edit.text += text + "\n"
	# Solo hacer scroll si estaba al final antes de añadir el texto
	if was_at_bottom:
		_scroll_to_bottom()

@rpc("any_peer", "call_local")
func _run_command(cmd: String) -> void:
	if not is_multiplayer_authority():
		return
		
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
	# Esta función se ejecuta en todos los clientes (call_local)
	# Asegurar que el scroll funcione incluso si este chat no tiene autoridad
	
	if data.begins_with("/"):
		# Buscar el jugador que envió el comando
		var jugador_encontrado = null
		for player in get_tree().get_nodes_in_group("player"):	
			if is_instance_valid(player) and player is CharacterBody3D:	
				var player_username = player.username
				if player_username == username:
					jugador_encontrado = player
					break
		
		# Si no se encuentra el jugador, bloquear el comando
		if jugador_encontrado == null:
			_console_print("Error: Jugador no encontrado")
			return
		
		# Verificar si el jugador es admin
		if not jugador_encontrado.admin_mode:
			_console_print("No tienes permisos para ejecutar comandos")
			return

		# Validar que el comando no esté vacío
		var comando_limpio = data.strip_edges()
		if comando_limpio.length() <= 1:  # Solo tiene "/" o está vacío
			return
		
		# Verificar si estaba al final ANTES de añadir el texto
		var was_at_bottom = _is_at_bottom()
		# Mostrar el comando en el chat
		text_edit.text += str(username, ": ", data, "\n")
		# Solo hacer scroll si estaba al final antes de añadir el texto
		if was_at_bottom:
			_scroll_to_bottom()
		
		# Ejecutar el comando solo si este chat tiene autoridad
		if is_multiplayer_authority():
			# Ejecutar el comando (quitar el "/" del inicio)
			data = data.erase(0, 1)
			Globals.print_role(data)
			_run_command(data)
	else:
		# Mensaje normal (no comando)
		var mensaje_limpio = data.strip_edges()
		if mensaje_limpio.length() > 0:
			# Verificar si estaba al final ANTES de añadir el texto
			var was_at_bottom = _is_at_bottom()
			text_edit.text += str(username, ": ", data, "\n")
			# Solo hacer scroll si estaba al final antes de añadir el texto
			if was_at_bottom:
				_scroll_to_bottom()


	

func _on_button_pressed():
	if not is_multiplayer_authority():
		return

	msg_rpc.rpc(Globals.username, line_edit.text)

	line_edit.text = ""
	line_edit.release_focus()
	button.release_focus()
	# Asegurar que is_chat_open se establece en false cuando se cierra el chat
	Globals.is_chat_open = false


func _on_line_edit_focus_entered() -> void:
	Globals.is_chat_open = true

func _on_line_edit_focus_exited():
	Globals.is_chat_open = false
