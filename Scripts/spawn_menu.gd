extends CanvasLayer

@onready var container = $Panel/GridContainer
@export var spawnlist: Array[Node]
@export var buttonlist: Array[Button]
@export var spawnedobject: Array[Node]
@onready var camera = get_parent().get_node("head/Camera3D")

var entity_scene = preload("res://Scenes/entity.tscn")
var spawn_list: Array[String] = [
				"res://Scenes/meteor.tscn",
				"res://Scenes/tornado.tscn",
				"res://Scenes/volcano.tscn",
				"res://Scenes/tsunami.tscn",
				"res://Scenes/earthquake.tscn",
				"res://Scenes/thunder.tscn",
				"res://Scenes/cube.tscn",
				"res://Scenes/Sphere.tscn",
				"res://Scenes/hause.tscn",
				]

func _enter_tree() -> void:
	set_multiplayer_authority(get_parent().name.to_int())

func _ready():
	self.visible = false
	
	load_spawnlist_entities()
	load_buttons()

func _get_local_player():
	for p in get_tree().get_nodes_in_group("player"):

		if p.is_multiplayer_authority():
			return p

	return null



func load_spawnlist_entities():
	for spawn in spawn_list:
		var node = load(spawn).instantiate()
		spawnlist.append(node)


func load_buttons():
	for i in spawnlist:
		var entity = entity_scene.instantiate()
		var label = entity.get_node("Label")
		label.text = i.name
		label.add_theme_font_size_override("FontSize", 20)
		label.custom_minimum_size = Vector2(150, 150) # cada celda fija

		var icon = entity.get_node("Icon")
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(64, 64) # icono fijo

		# Intentar cargar icono con varias variantes (por si hay espacios/mayúsculas)
		var candidates = [
			"res://Icons/%s_icon.png" % i.name,
			"res://Icons/%s_icon.png" % i.name.replace(" ", "_"),
			"res://Icons/%s_icon.png" % i.name.to_lower().replace(" ", "_"),
			"res://Icons/%s_icon.png" % i.name.to_lower().replace(" ", ""),
		]

		var icon_image = null
		for p in candidates:
			icon_image = load(p)
			if icon_image != null:
				break

		# Fallback a un icono por defecto si no se encuentra ninguno
		if icon_image == null:
			icon_image = load("res://Icons/default_icon.png")
			if icon_image == null:
				Globals.print_role("spawn_menu.gd: icon not found for '%s' (tried %s). Create 'res://Icons/default_icon.png' to avoid this message." % [i.name, str(candidates)])
		
		if icon_image != null:
			icon.texture_normal = icon_image

		container.add_child(entity)
		icon.pressed.connect(func(): on_press(i))



func on_press(i: Node):
	var player = _get_local_player()
	if player == null or not player.admin_mode:
		Globals.print_role("You dont have perms")
		return

	if not is_multiplayer_authority():
		return

	var raycast = get_parent().interactor

	if raycast.is_colliding():
		var collision_point = raycast.get_collision_point()
		var collision_normal = raycast.get_collision_normal()

		var new_i = i.duplicate()
		new_i.transform.origin = collision_point + collision_normal * 0.5
		spawnedobject.append(new_i)
		
		# Asignar autoridad al servidor (peer_id = 1 es el servidor)
		new_i.set_multiplayer_authority(1)
		
		# Añadir al mapa como propiedad de la escena
		Globals.map.add_child(new_i, true)


	



func spawnmenu():
	Globals.is_spawn_menu_open = !Globals.is_spawn_menu_open

	if Globals.is_spawn_menu_open:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	self.visible = Globals.is_spawn_menu_open




func remove():
	if spawnedobject.size() > 0:
		var last = spawnedobject.pop_back()
		if is_instance_valid(last):
			last.queue_free()



func _process(_delta):

	if not is_multiplayer_authority():
		return

	if Globals.gamemode == "survival":
		return

	if Input.is_action_just_pressed("Spawnmenu"):
		spawnmenu()

	if Input.is_action_just_pressed("Remove"):
		remove()
