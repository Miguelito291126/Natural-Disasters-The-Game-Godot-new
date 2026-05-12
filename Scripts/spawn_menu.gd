extends CanvasLayer
class_name SpawnMenu

var container: GridContainer
@export var spawnlist: Array[Node3D] = []
@export var buttonlist: Array[Button] = []
@export var spawned_objects: Array[Node3D] = []
var camera: Camera3D

var entity_scene: PackedScene = load("res://Scenes/entity.tscn")
var spawn_paths: Array[String] = [
	"res://Scenes/meteor.tscn", 
	"res://Scenes/tornado.tscn", 
	"res://Scenes/volcano.tscn", 
	"res://Scenes/tsunami.tscn", 
	"res://Scenes/earthquake.tscn", 
	"res://Scenes/thunder.tscn", 
	"res://Scenes/cube.tscn", 
	"res://Scenes/sphere.tscn", 
	"res://Scenes/hause.tscn"
]

func _enter_tree() -> void:
	# Intentamos obtener el ID del nombre, pero con precaución
	var parent_name = get_parent().name
	if parent_name.is_valid_int():
		set_multiplayer_authority(parent_name.to_int())
	else:
		# Si el nombre no es un número, usamos la autoridad del padre (el Player)
		set_multiplayer_authority(get_parent().get_multiplayer_authority())

func _ready() -> void:
	container = get_node("Panel/GridContainer")
	camera = get_parent().get_node("head/Camera3D")
	visible = false

	load_spawnlist_entities()
	load_buttons()

func _get_local_player() -> Node3D:
	for p in get_tree().get_nodes_in_group("player"):
		if p.is_multiplayer_authority():
			return p
	return null

func load_spawnlist_entities() -> void:
	for path in spawn_paths:
		var scene = load(path)
		if scene:
			var node = scene.instantiate()
			spawnlist.append(node)

func load_buttons() -> void:
	for i in spawnlist:
		# 1. Instanciamos la UI
		var entity = entity_scene.instantiate()
		
		var label = entity.get_node("Label")
		label.text = i.name
		
		var icon_button = entity.get_node("Icon")
		
		# 2. Lógica de iconos
		var node_name = str(i.name)
		var candidates = [
			"res://icons/%s_icon.png" % node_name,
			"res://icons/%s_icon.png" % node_name.replace(" ", "_"),
			"res://icons/%s_icon.png" % node_name.to_lower().replace(" ", "_"),
			"res://icons/%s_icon.png" % node_name.to_lower().replace(" ", "")
		]

		var icon_image: Texture2D = null
		for path in candidates:
			if ResourceLoader.exists(path):
				icon_image = load(path)
				break
		
		icon_button.texture_normal = icon_image if icon_image else load("res://icons/default_icon.png")

		container.add_child(entity)

		# 3. Conexión de señal usando un callable con argumentos (bind)
		icon_button.pressed.connect(self.on_press.bind(i))

func on_press(i: Node3D) -> void:
	var player = _get_local_player()
	if player == null or not player.get("admin_mode"):
		return
		
	if not is_multiplayer_authority(): 
		return

	var raycast = get_parent().interactor

	if raycast.is_colliding():
		var collision_point = raycast.get_collision_point()
		var collision_normal = raycast.get_collision_normal()

		var new_i = i.duplicate()
		new_i.transform = Transform3D.IDENTITY

		spawned_objects.append(new_i)
		new_i.set_multiplayer_authority(1)
		
		# Acceso a Globals (asumiendo que es un Autoload)
		Globals.map.add_child(new_i, true)

		# Comprobación de clase (en GDScript se usa 'is')
		if new_i is Meteor:
			new_i.global_position = collision_point + (collision_normal * 0.5) + Vector3(0, 1000, 0)
		else:
			new_i.global_position = collision_point + (collision_normal * 0.5)
		
		Globals.print_role("Spawned %s at %s" % [i.name, str(new_i.global_position)])

func toggle_spawn_menu() -> void:
	Globals.is_spawn_menu_open = not Globals.is_spawn_menu_open

	if Globals.is_spawn_menu_open:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	self.visible = Globals.is_spawn_menu_open

func remove_last_spawned() -> void:
	if spawned_objects.size() > 0:
		var last = spawned_objects.pop_back()
		if is_instance_valid(last):
			last.queue_free()

func _process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return

	if Globals.gamemode == "survival":
		return

	if Input.is_action_just_pressed("Spawnmenu"):
		toggle_spawn_menu()

	if Input.is_action_just_pressed("Remove"):
		remove_last_spawned()