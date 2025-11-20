extends CanvasLayer

@onready var container = $Panel/GridContainer
@export var spawnlist: Array[Node]
@export var buttonlist: Array[Button]
@export var spawnedobject: Array[Node]
@onready var camera = get_parent().get_node("head/Camera3D")

var entity_scene = preload("res://Scenes/entity.tscn")

func _enter_tree() -> void:
	if Globals.is_networking:
		set_multiplayer_authority(get_parent().name.to_int())

func _ready():
	if Globals.is_networking:
		self.visible = false
		if not is_multiplayer_authority():
			return

	self.visible = false

	load_spawnlist_entities()
	load_buttons()

func _get_local_player():
	for p in get_tree().get_nodes_in_group("player"):
		if p.is_multiplayer_authority():
			return p
	return null



func load_spawnlist_entities():
	var directory = "res://Scenes/"
	var resources = ResourceLoader.list_directory(directory)
	for resource in resources:
		if resource.ends_with(".tscn"):
			var node = load(directory + "/" + resource).instantiate()
			if node is RigidBody3D or node is StaticBody3D or node is Area3D or node is GPUParticles3D:
				spawnlist.append(node)


func load_buttons():
	for i in spawnlist:
		var entity = entity_scene.instantiate()
		var label = entity.get_node("Label")
		label.text = i.name
		label.add_theme_font_size_override("FontSize", 20)
		label.custom_minimum_size = Vector2(150, 150) # cada celda fija

		var icon = entity.get_node("Icon")
		var icon_image = load("res://Icons/" + i.name + "_icon.png")
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_normal = icon_image
		icon.custom_minimum_size = Vector2(64, 64) # icono fijo
		container.add_child(entity)

		icon.pressed.connect(func(): on_press(i))



func on_press(i: Node):
	var player = _get_local_player()
	if player == null or not player.admin_mode:
		Globals.print_role("No tienes permisos para spawnear")
		return

	if Globals.is_networking:
		if not multiplayer.is_server():
			Globals.print_role("You are not the host")
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
		Globals.map.add_child(new_i, true)


	



func spawnmenu():
	var player = _get_local_player()
	if player == null or not player.admin_mode:
		Globals.print_role("No tienes permisos para abrir el menú de spawn")
		return

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
	if Globals.is_networking:
		if not is_multiplayer_authority():
			return

	if Input.is_action_just_pressed("Spawnmenu"):
		spawnmenu()

	if Input.is_action_just_pressed("Remove"):
		remove()
