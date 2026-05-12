extends CharacterBody3D
class_name Player

@export var player_id: int = 1
@export var username: String = "Player"
@export var points: int = 0

var SPEED = 0

const SPEED_RUN = 25.0
const SPEED_WALK = 15.0
const SPEED_NOCLIP = 100.0
const JUMP_VELOCITY =  14.0
const SENSIBILITY = 0.02
const LERP_VAL =  .15

const bob_freq = 2.0
const bob_am = 0.08
@export var t_bob = 0.0

@export var mass: float = 0.5


var max_health = 100
var max_temp = 44
var max_oxygen = 100
var max_bradiation = 100

@export var fall_strength = 0


var min_health = 0
var min_temp = 24
var min_oxygen = 0
var min_bdradiation = 0


@export var health: float = max_health

@export var body_temperature: float = 37
@export var body_oxygen: float = max_oxygen
@export var body_bradiation: float = min_bdradiation
@export var body_wind: float = 0

@export var outdoor: bool = false
@export var is_in_water: bool = false
@export var is_in_lava: bool = false
@export var is_underwater: bool = false
@export var is_underlava: bool = false
@export var is_on_fire: bool = false
@export var is_alive: bool = true

@export var swim_factor: float = 0.25
@export var swim_cap: float = 50

@onready var rain_node = $Rain
@onready var splash_node = $splash
@onready var dust_node = $Dust
@onready var sand_node = $Sand
@onready var snow_node = $Snow
@onready var pause_menu_node = $"Pause menu"
@onready var animationplayer_node = $"AnimationPlayer"
@onready var animation_tree_node = $AnimationTree
@onready var camera_node = $"head/Camera3D"
@onready var head_node = $"head"
@onready var hand_node = $"head/hand"
@onready var esqueleto_node = $"Esqueleto"
@onready var label = $Name
@onready var temp_effect = $TempEffect/ColorRect
@onready var death_menu = $"DeathMenu"
@onready var fire_particles = $Fire

@onready var sneeze_audio = $"head/Camera3D/sneeze audio"
@onready var sneeze = $head/Camera3D/Sneeze

@onready var vomit_audio = $head/Camera3D/Vomit
@onready var vomit = $head/Camera3D/Vomit

@onready var underwater_effect = $UnderWater
@onready var underlava_effect = $UnderLava


@onready var rain_sound = $"RainSound"
@onready var wind_sound = $"WindSound"
@onready var wind_moderate_sound = $"WindModerateSound"
@onready var wind_extreme_sound = $"WindExtremeSound"

@onready var interactor: RayCast3D = $head/Camera3D/Interactor
@onready var spotLight3D = $head/Camera3D/SpotLight3D
@onready var spawn = $"../Spawn"

@onready var skeleton = $"Esqueleto/Skeleton3D"
@onready var skeleton_phy = $"Esqueleto/Skeleton3D/PhysicalBoneSimulator3D"
@onready var capsule: CollisionShape3D = $CollisionShape3D
@onready var mesh = $Esqueleto/Skeleton3D/human

# Hueso físico de referencia para el ragdoll (cerca del cuello/torso)
@onready var ragdoll_follow_bone: Node3D = $"Esqueleto/Skeleton3D/PhysicalBoneSimulator3D/Physical Bone clumna3"

# Índice del hueso de la cabeza para seguir en ragdoll
var head_bone_index: int = -1

# Transforms originales de cabeza y cámara para restaurar al revivir / salir del ragdoll
var head_default_transform: Transform3D
var head_default_local_transform: Transform3D
var camera_default_transform: Transform3D
# Transform local original de la cámara (offset respecto al padre/head)
var camera_default_local_transform: Transform3D

@export var noclip: bool = false
@export var god_mode: bool = false
@export var admin_mode: bool = false
@export var ragdoll_enabled = false

@export var character = "blue"
var _last_applied_character := ""
@export var player_materials = [preload("res://Materials/player blue.tres"), preload("res://Materials/player red.tres"), preload("res://Materials/player green.tres"), preload("res://Materials/player yellow.tres") ]
@onready var chat_node: Chat = get_tree().root.find_child("chat", true, false)
var current_water_area: Area3D
var current_lava_area: Area3D
var external_force: Vector3

func _enter_tree() -> void:
	player_id = name.to_int()
	Globals.print_role("set authority to: " + name)
	set_multiplayer_authority(player_id)

func _exit_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


@rpc("any_peer", "call_local")
func _set_admin_mode(enable: bool) -> void:
	admin_mode = enable
	if multiplayer.is_server():
		Globals.print_role("Admin mode cambiado para %s: %s" % [username, str(enable)])

@rpc("any_peer", "call_local")
func _set_ragdoll_state(enable: bool) -> void:
	ragdoll_enabled = enable

	# Propiedades que afectan al servidor de fisica -> también deferidas por seguridad
	if skeleton_phy:
		skeleton_phy.set_deferred("active", enable)

	if animation_tree_node:
		animation_tree_node.set_deferred("active", not enable)

	if animationplayer_node:
		animationplayer_node.set_deferred("active", not enable)
		
	if capsule:
		capsule.set_deferred("disabled", enable)

	# Iniciar/parar la simulación física — también lo deferimos para evitar condiciones
	if enable:
		_start_physical_bones_sim()
	else:
		_stop_physical_bones_sim()
		# Al salir del ragdoll, restaurar la posición/rotación de la cabeza y la cámara
		if head_node:
			head_node.transform = head_default_local_transform
		if camera_node:
			camera_node.transform = camera_default_local_transform

func _start_physical_bones_sim():
	if skeleton_phy:
		skeleton_phy.physical_bones_start_simulation()

func _stop_physical_bones_sim():
	if skeleton_phy:
		skeleton_phy.physical_bones_stop_simulation()

func _update_camera_follow_ragdoll():
	# 1) Prioridad: seguir un hueso FÍSICO (PhysicalBone3D), que sí se mueve con el ragdoll
	if ragdoll_follow_bone and camera_node:
		var bone_transform: Transform3D = ragdoll_follow_bone.global_transform
		# Posición: misma posición relativa que la cámara viva, pero rotación original (para que no mire al suelo)
		var local_origin: Vector3 = camera_default_local_transform.origin
		var target_position: Vector3 = bone_transform * local_origin
		camera_node.global_position = target_position
		camera_node.global_basis = camera_default_transform.basis
		return

	# 2) Fallback: si por alguna razón no hay hueso físico, usar el hueso "cuello" del Skeleton
	if skeleton and head_bone_index >= 0 and camera_node:
		var bone_global_pose: Transform3D = skeleton.get_bone_global_pose(head_bone_index)
		var bone_world_transform: Transform3D = skeleton.global_transform * bone_global_pose
		
		var local_origin2: Vector3 = camera_default_local_transform.origin
		var target_position2: Vector3 = bone_world_transform * local_origin2
		camera_node.global_position = target_position2
		camera_node.global_basis = camera_default_transform.basis

func apply_disasters_push(force):
	external_force = force

@rpc("any_peer", "call_local")
func damage(amount: float) -> void:
	if god_mode:
		return

	if not is_alive:
		return

	health = clamp(health - amount, min_health, max_health)
	Globals.print_role("damage applied:" + str(amount) + ", health now:" + str(health))

	if health <= 0:	
		is_alive = false

		# Solo ejecutar die() y quitar puntos en la instancia local del jugador que murió
		if is_multiplayer_authority():
			die()
			Globals.remove_points()

		_set_ragdoll_state.rpc(true)

	else:
		is_alive = true


func die():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if death_menu:
		death_menu.show()

func ignite(time):
	is_on_fire = true
	await get_tree().create_timer(time).timeout
	is_on_fire = false

func Sneeze():
	sneeze_audio.play()
	sneeze.emitting = true

func Vomit():	
	vomit_audio.play()
	vomit.emitting = true

# Función para verificar si hay jugadores con el mismo nombre
func hay_jugadores_con_mismo_nombre(nombre_a_verificar: String, excluir_este_jugador: bool = true) -> bool:
	var contador = 0
	for player in get_tree().get_nodes_in_group("player"):
		# Si se debe excluir este jugador, saltarlo
		if excluir_este_jugador and player == self:
			continue
		
		# Verificar si el nombre coincide
		if player.username == nombre_a_verificar:
			contador += 1
			# Si encontramos al menos uno con el mismo nombre, retornar true
			if contador >= 1:
				return true
	
	return false

# Función para obtener todos los jugadores que tienen el mismo nombre
func obtener_jugadores_con_mismo_nombre(nombre_a_verificar: String, excluir_este_jugador: bool = true) -> Array:
	var jugadores_duplicados = []
	
	for player in get_tree().get_nodes_in_group("player"):
		# Si se debe excluir este jugador, saltarlo
		if excluir_este_jugador and player == self:
			continue
		
		# Verificar si el nombre coincide
		if player.username == nombre_a_verificar:
			jugadores_duplicados.append(player)
	
	return jugadores_duplicados

func _ready():
	rain_node.emitting = false
	sand_node.emitting = false
	splash_node.emitting = false
	dust_node.emitting = false
	snow_node.emitting = false
	spotLight3D.visible = false


	Globals.print_role("player name: " + str(name.to_int()))
	Globals.print_role("is authority: " + str(is_multiplayer_authority()))
	Globals.print_role("get authority: " + str(get_multiplayer_authority()))

	camera_node.current = is_multiplayer_authority()

	# Guardar transform original de la cabeza y de la cámara
	if head_node:
		head_default_transform = head_node.global_transform
		head_default_local_transform = head_node.transform
	if camera_node:
		camera_default_transform = camera_node.global_transform
		camera_default_local_transform = camera_node.transform

	# Obtener el índice del hueso "cuello" para seguir en ragdoll
	if skeleton:
		head_bone_index = skeleton.find_bone("cuello")
		# Si por alguna razón no lo encuentra, usar un índice conocido del esqueleto (9 = cuello en la escena)
		if head_bone_index == -1 and skeleton.get_bone_count() > 9:
			head_bone_index = 9

	if is_multiplayer_authority():
		Globals.local_player = self
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		_reset_player()
		_set_ragdoll_state.rpc(false)
		username = Globals.username
		
		# Verificar si hay jugadores con el mismo nombre y añadir número si es necesario
		var nombre_base = Globals.username
		var contador = 0
		
		for player in get_tree().get_nodes_in_group("player"):
			# Saltar el jugador actual
			if player == self:
				continue

			if player is Player:
				# Verificar si el nombre coincide (sin contar números añadidos)
				var player_username = player.username
				if player_username == nombre_base or player_username.begins_with(nombre_base):
					contador += 1
		
		# Si hay duplicados, añadir número al nombre
		if contador > 0:
			Globals.username = nombre_base + str(contador + 1)
			username = Globals.username

		if multiplayer.is_server():
			admin_mode = true


func update_temp_effect(delta):
	if god_mode:
		return

	var body_heat_genK        = delta
	var body_heat_genMAX      = 0.01/4
	var fire_heat_emission    = 50

	var heatscale               = 0
	var coolscale               = 0

	var core_equilibrium           =  clamp((37 - body_temperature)*body_heat_genK, -body_heat_genMAX, body_heat_genMAX)
	var heatsource_equilibrium     =  clamp((fire_heat_emission * (heatscale ))*body_heat_genK, 0, body_heat_genMAX * 1.3)
	var coldsource_equilibrium     =  clamp((fire_heat_emission * ( coolscale))*body_heat_genK,body_heat_genMAX * -1.3, 0) 

	var ambient_equilibrium        = clamp(((Globals.temperature - body_temperature)*body_heat_genK), -body_heat_genMAX*1.1, body_heat_genMAX * 1.1)
	
	if Globals.temperature >= 5 and Globals.temperature <= 37:
		ambient_equilibrium	= 0
	
	body_temperature = clamp(body_temperature + core_equilibrium  + heatsource_equilibrium + coldsource_equilibrium + ambient_equilibrium, min_temp, max_temp)
	temp_effect.material.set_shader_parameter("temp", body_temperature)
	temp_effect.material.set_shader_parameter("Temp", body_temperature)

	var alpha_hot  =  1-((44-clamp(body_temperature,39,44))/5)
	var alpha_cold =  ((35-clamp(body_temperature,24,35))/11)

	if randi_range(1,25) == 25:
		if alpha_cold != 0:
			damage.rpc(alpha_hot + alpha_cold)	
		elif alpha_hot != 0:
			damage.rpc(alpha_hot + alpha_cold)


	if body_temperature > 39 and randi() % 400 == 0:
		Vomit()

	if body_temperature < 35 and randi() % 400 == 0:
		Sneeze()

func update_oxy_effect(delta):
	if god_mode:
		return

	if Globals.oxygen <= 20 or Globals.is_in_water(self) or is_underwater or Globals.is_in_lava(self) or is_underlava:
		body_oxygen = clamp(body_oxygen - 5 * delta, min_oxygen, max_oxygen)
	else:
		body_oxygen = clamp(body_oxygen + 5 * delta, min_oxygen, max_oxygen)
	
	
	if body_oxygen <= 0:
		if randi_range(1,25) == 25:
			damage.rpc(randi_range(1,30))

func update_rad_effect(delta):
	if god_mode:
		return

	if Globals.bradiation >= 80 and Globals.is_outdoor(self) and outdoor:
		body_bradiation = clamp(body_bradiation + 5 * delta, min_bdradiation, max_bradiation)
	else:
		body_bradiation = clamp(body_bradiation - 5 * delta, min_bdradiation, max_bradiation)

	if body_bradiation >= 100:
		if randi_range(1,25) == 25:
			damage.rpc(randi_range(1,30))

func update_character():
	# Determinar el personaje deseado: si no somos autoridad, usamos el dict sincronizado.
	var desired_char = character
	if not is_multiplayer_authority():
		if Globals.assigned_character.has(player_id):
			desired_char = Globals.assigned_character[player_id]

	if desired_char == null or desired_char == "" or desired_char == _last_applied_character:
		return

	_last_applied_character = desired_char
	character = desired_char

	if desired_char == "blue":
		update_material(0)
	elif desired_char == "red":
		update_material(1)
	elif desired_char == "green":
		update_material(2)
	elif desired_char == "yellow":
		update_material(3)
	else:
		update_material(0)

func update_material(index):
	if not mesh:
		return

	# MeshInstance3D usa overrides de superficie; aplicamos a las tres superficies.
	mesh.set_surface_override_material(0, player_materials[index])
	mesh.set_surface_override_material(1, player_materials[index])
	mesh.set_surface_override_material(2, player_materials[index])

func update_underwater_or_underlava_effect():
# --- LÓGICA PARA AGUA ---
	if is_in_water and current_water_area != null:
		var collider = current_water_area.get_node_or_null("CollisionShape3D")
		if collider != null and collider.shape is BoxShape3D:
			var box = collider.shape
			# Calculamos la superficie real en el mundo
			# En GDScript se usa .size en lugar de .Size
			var water_surface_y = current_water_area.global_position.y + (box.size.y / 2.0)
			is_underwater = camera_node.global_position.y < water_surface_y

	# --- LÓGICA PARA LAVA ---
	if is_in_lava and current_lava_area != null:
		var collider = current_lava_area.get_node_or_null("CollisionShape3D")
		if collider != null and collider.shape is BoxShape3D:
			var box = collider.shape
			# Calculamos la superficie real en el mundo
			var lava_surface_y = current_lava_area.global_position.y + (box.size.y / 2.0)
			is_underlava = camera_node.global_position.y < lava_surface_y
			
		elif collider != null and collider.shape is SphereShape3D:
			var sphere = collider.shape
			# En GDScript obtenemos la escala global directamente de global_transform.basis.get_scale()
			var escala_y = current_lava_area.global_transform.basis.get_scale().y
			
			# El punto más alto de la esfera en el mundo
			var sphere_radius_world = sphere.radius * escala_y
			var lava_surface_y = current_lava_area.global_position.y + sphere_radius_world

			# Detectar si la cámara está por debajo de la parte superior de la esfera
			is_underlava = camera_node.global_position.y < lava_surface_y
		
		ignite(10) # Aplicar fuego si estás en contacto con lava

	# --- APLICAR VISIBILIDAD DE UI ---
	if underwater_effect != null:
		underwater_effect.visible = is_underwater
	if underlava_effect != null:
		underlava_effect.visible = is_underlava

	# Apagar fuego si entras al agua
	if is_in_water and is_on_fire:
		is_on_fire = false

func update_fire_effect() -> void:
	if fire_particles != null:
		fire_particles.emitting = is_on_fire

	if is_on_fire:
		# randi_range(1, 5) es inclusivo, devolviendo un entero entre 1 y 5
		if randi_range(1, 5) == 5:
			damage.rpc(5)


func _input(event: InputEvent) -> void:
	# 1. Validaciones iniciales (Cláusulas de guarda)
	if not is_multiplayer_authority():
		return
	
	# Bloquear si el chat está abierto o enfocado
	if Globals.is_chat_open:
		return
		
	# Comprobación segura del chat_node y su LineEdit
	if chat_node and chat_node.line_edit and chat_node.line_edit.has_focus():
		return

	# 2. Procesar entrada de teclado
	if event is InputEventKey and event.pressed and not event.is_echo():
		# Solo si es admin y modo sandbox
		if not admin_mode or Globals.gamemode != "sandbox":
			return

		var disaster_id: int = -1
		var total_desastres: int = 13 

		# Estructura match (equivalente al switch de C#)
		match event.keycode:
			KEY_RIGHT: # SIGUIENTE
				var siguiente = Globals.current_weather_and_disaster_id + 1
				if siguiente > total_desastres:
					siguiente = 0 # Reinicia al primero si pasa del máximo
				disaster_id = siguiente

			KEY_LEFT: # ANTERIOR
				var anterior = Globals.current_weather_and_disaster_id - 1
				if anterior < 0:
					anterior = total_desastres # Va al último si baja de 0
				disaster_id = anterior

			_: # Caso por defecto (default)
				return

		# Si disaster_id cambió, enviamos el RPC
		if disaster_id != -1:
			Globals.set_weather_and_disaster.rpc("", disaster_id)

func update_rain_sound() -> void:
	# 1. Verificamos si realmente debe sonar la lluvia
	# Combinamos: ¿El emisor de partículas está activo? Y ¿El jugador está a la intemperie?
	var should_play: bool = rain_node.emitting and Globals.is_outdoor(self)

	# Actualizamos el estado global (Asegúrate de que 'is_raining' exista en Globals.gd)
	Globals.is_raining = should_play

	if rain_sound == null:
		return # Seguridad

	if should_play:
		if not rain_sound.playing:
			rain_sound.play()
	else:
		if rain_sound.playing:
			rain_sound.stop()


func update_wind_sound() -> void:
	if wind_sound == null or wind_moderate_sound == null or wind_extreme_sound == null:
		return

	var target_sound: AudioStreamPlayer = null

	# Selección de sonido basado en la intensidad
	if body_wind > 100:
		target_sound = wind_extreme_sound
	elif body_wind > 50:
		target_sound = wind_moderate_sound
	elif body_wind > 0:
		target_sound = wind_sound
	
	# Creamos un array con todos los sonidos de viento para iterar
	var all_winds: Array[AudioStreamPlayer] = [wind_sound, wind_moderate_sound, wind_extreme_sound]

	for v in all_winds:
		if v == target_sound:
			if not v.playing:
				v.play()
		else:
			if v.playing:
				v.stop()


func _process(delta):
	update_character() # también para clientes no autoridad (solo material)

	if not is_multiplayer_authority():
		return

	update_temp_effect(delta)
	update_oxy_effect(delta)
	update_rad_effect(delta)
	update_underwater_or_underlava_effect()
	update_fire_effect()
	update_rain_sound()
	update_wind_sound()
	update_labels()

func update_labels():
	if not is_multiplayer_authority():
		return

	username = Globals.username
	points = Globals.points
	label.text = Globals.username

func _physics_process(delta):
	if not is_multiplayer_authority():
		return

	if Globals.is_pause_menu_open:
		return
			
	if Globals.is_chat_open:
		return
	
	# Hacer que la cámara siga al cuerpo en ragdoll
	if ragdoll_enabled:
		_update_camera_follow_ragdoll()
		return  # No procesar movimiento cuando el ragdoll está activo

	# Add the gravity.
	if not noclip:
		if not is_on_floor():
			if is_in_water or is_in_lava:
				velocity.y = Globals.gravity * delta * swim_factor
			else:
				# Si está cayendo, aplica más gravedad
				if velocity.y < 0:
					velocity.y -= Globals.gravity * delta
				else:
					velocity.y -= Globals.gravity * delta

				fall_strength = velocity.y
		else:
			if not (is_in_water or is_in_lava):
				if fall_strength <= -90:
					damage.rpc(50)
	else:
		velocity.y = 0


	# Handle jump.
	if Input.is_action_just_pressed("Jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY

		if is_in_water or is_in_lava:
			velocity.y += JUMP_VELOCITY
			
	


	if Input.is_action_just_pressed("Flashligh"):
		spotLight3D.visible = !spotLight3D.visible

	if Input.is_action_pressed("Spring"):
		SPEED = SPEED_RUN
	else:
		SPEED = SPEED_WALK

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var input_vector = Vector3(input_dir.x, 0, input_dir.y)
	var direction = (head_node.transform.basis * input_vector).normalized()

	if noclip:

		SPEED = SPEED_NOCLIP

		# Movimiento directo en noclip (vuelo libre)
		var desired_velocity = direction * SPEED

		# Control vertical en noclip
		if Input.is_action_pressed("Jump"):

			desired_velocity.y = SPEED
		elif Input.is_action_pressed("down"):
			desired_velocity.y = -SPEED
		else:
			desired_velocity.y = 0

		# Asignar directamente la velocidad (sin gravedad ni lerp)
		velocity = desired_velocity
	else:
		# Lógica normal cuando no es noclip
		if is_on_floor():
			if direction:
				velocity.x = direction.x * SPEED
				velocity.z = direction.z * SPEED
			else:
				velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 7.0)
				velocity.z = lerp(velocity.z, direction.z * SPEED, delta * 7.0)
		else:
			velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 3.0)
			velocity.z = lerp(velocity.z, direction.z * SPEED, delta * 3.0)


	var horizontal_velocity = Vector2(velocity.x, velocity.z)

	animation_tree_node.set("parameters/conditions/is_falling", !is_on_floor() and velocity.y < 0)
	animation_tree_node.set("parameters/conditions/is_jumping", velocity.y > 0 )
	animation_tree_node.set("parameters/conditions/is_swiming", is_in_water or is_in_lava)
	animation_tree_node.set("parameters/conditions/is_idle", is_on_floor() and horizontal_velocity.length() < 0.1)
	animation_tree_node.set("parameters/conditions/is_walking", is_on_floor() and horizontal_velocity.length() > 0.1)

	if interactor.is_colliding():
		var target = interactor.get_collider()
		if target != null and target.has_method("Interact"):
			if Input.is_action_just_pressed("Interact"):
				target.Interact()
		elif target != null and target.is_in_group("Pickable"):
			if Input.is_action_pressed("Interact"):
				if multiplayer.is_server():
					# Si somos el servidor/host, llamamos DIRECTO
					Globals.request_pick_object(get_path(), target.get_path())
				else:
					# Si somos cliente, usamos RPC hacia el servidor
					Globals.request_pick_object.rpc(get_path(), target.get_path())

	if Input.is_action_just_pressed("noclip"):
		if admin_mode:
			_noclip()
		else:
			Globals.print_role("You dont have perms")

	velocity = velocity + external_force
	move_and_slide()
	
	external_force = Vector3.ZERO

@rpc("any_peer", "call_local")
func _noclip():
	noclip = !noclip
	if noclip:
		capsule.disabled = true
		velocity.y = 0
		fall_strength = 0
		Globals.print_role("Noclip activated")
	else:
		capsule.disabled = false
		Globals.print_role("Noclip desactivated")


func _unhandled_input(event):
	if not is_multiplayer_authority():
		return

	# No permitir control de cámara cuando el chat está abierto
	# Verificar tanto la variable global como si algún LineEdit tiene foco
	var chat_node = get_tree().get_root().find_child("Chat", true, false)
	if chat_node != null:
		var line_edit = chat_node.get_node_or_null("Panel/Panel2/LineEdit")
		if line_edit != null and line_edit.has_focus():
			return
	
	if Globals.is_chat_open:
		return

	# No permitir control de cámara cuando el ragdoll está activo
	if ragdoll_enabled:
		return

	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			camera_node.rotation.x -= event.relative.y * SENSIBILITY
			camera_node.rotation_degrees.x = clamp(camera_node.rotation_degrees.x, -90, 90)
			head_node.rotation.y -= event.relative.x * SENSIBILITY
			esqueleto_node.rotation_degrees.y = head_node.rotation_degrees.y
		elif event is InputEventJoypadMotion:
			if event.axis == 2:	
				head_node.rotation.y += event.axis_value * SENSIBILITY
				esqueleto_node.rotation_degrees.y = head_node.rotation_degrees.y
			elif event.axis == 3:
				camera_node.rotation.x += event.axis_value * SENSIBILITY
				camera_node.rotation_degrees.x = clamp(camera_node.rotation_degrees.x, -90, 90)
			


func _on_area_3d_body_entered(body:Node3D):
	if body.is_in_group("Meteor"):
		damage.rpc(100) # Llamada RPC a la función damage


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("Water_Area"):
		is_in_water = false
		is_underwater = false
		current_water_area = null

func _on_area_3d_area_entered(area: Area3D) -> void:
	if area.is_in_group("Lava_Area"):
		is_in_lava = true
		current_lava_area = area

	elif area.is_in_group("Water_Area"):
		is_in_water = true
		current_water_area = area

func _on_area_3d_area_exited(area: Area3D) -> void:
	if area.is_in_group("Lava_Area"):
		is_in_lava = false
		is_underlava = false
		current_lava_area = null

	elif area.is_in_group("Water_Area"):
		is_in_water = false
		is_underwater = false
		current_water_area = null


@rpc("any_peer", "call_local")
func _reset_player():
	health = max_health
	body_temperature = 37
	body_oxygen = max_oxygen
	body_bradiation = min_bdradiation
	is_alive = true
	is_in_water = false
	is_in_lava = false
	is_on_fire = false
	fall_strength = 0


	if is_multiplayer_authority():
		_set_ragdoll_state.rpc(false)
		position = spawn.position
		velocity = Vector3.ZERO
