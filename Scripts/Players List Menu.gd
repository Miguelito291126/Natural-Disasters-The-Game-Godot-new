extends CanvasLayer

@onready var list = $Panel/List

var player_info = preload("res://Scenes/player_info.tscn")

func _enter_tree() -> void:
	if multiplayer.multiplayer_peer != null:
		set_multiplayer_authority(get_parent().name.to_int())

func _ready():

	if is_multiplayer_authority():
		self.visible = false
	else:
		return

	self.visible = false
	

	

func _process(_delta):
	if multiplayer.multiplayer_peer != null:
		
		if not is_multiplayer_authority():
			return


		# Eliminar todos los hijos del VBoxContainer
		for child in list.get_children():
			if child.name == "Info":
				continue

			child.queue_free()

		# Iterar sobre los jugadores conectados y agregarlos a la lista
		if not Globals.players_conected.is_empty():
			for player_data in Globals.players_conected:
				if is_instance_valid(player_data):
					var player_info_instance = player_info.instantiate()
					player_info_instance.get_node("Username").text = player_data.username + " - "
					player_info_instance.get_node("Points").text = str(player_data.points)
					list.add_child(player_info_instance, true)

		# Mostrar u ocultar la lista de jugadores según la acción del teclado
		if Input.is_action_just_pressed("List of players"):
			self.visible = !self.visible
