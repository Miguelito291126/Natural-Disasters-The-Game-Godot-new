extends CharacterBody3D

@export var player_id: int = 1:
	set(id):
		player_id = id
		Globals.print_role("player id: " + str(id))
		set_auth.call_deferred(id)

@export var username: String = Globals.username
@export var points: int = Globals.points

var SPEED = 0

const SPEED_RUN = 25.0
const SPEED_WALK = 15.0
const JUMP_VELOCITY =  14.0
const SENSIBILITY = 0.02
const LERP_VAL =  .15

const bob_freq = 2.0
const bob_am = 0.08
@export var t_bob = 0.0

@export var mass: float = 0.5


var Max_Hearth = 100
var Max_temp = 44
var Max_oxygen = 100
var Max_bradiation = 100

var fall_strength = 0

var min_Hearth = 0
var min_temp = 24
var min_oxygen = 0
var min_bdradiation = 0


@export var hearth: float = Max_Hearth

@export var body_temperature: float = 37
@export var body_oxygen: float = Max_oxygen
@export var body_bradiation: float = min_bdradiation
@export var body_wind: float = 0

@export var Outdoor: bool = false
@export var IsInWater: bool = false
@export var IsInLava: bool = false
@export var IsUnderWater: bool = false
@export var IsUnderLava: bool = false
@export var IsOnFire: bool = false
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
@onready var temp_effect = $Temp_Effect/ColorRect
@onready var death_menu = $"Death Menu"
@onready var fire_particles = $Fire

@onready var sneeze_audio = $"head/Camera3D/sneeze audio"
@onready var sneeze = $head/Camera3D/Sneeze

@onready var vomit_audio = $head/Camera3D/Vomit
@onready var vomit = $head/Camera3D/Vomit

@onready var underwatereffect = $Underwater
@onready var underlavaeffect = $UnderLava


@onready var Rain_sound = $"Rain sound"
@onready var Wind_sound = $"Wind sound"
@onready var Wind_moderate_sound = $"Wind Morerate sound"
@onready var Wind_extreme_sound = $"Wind Extreme sound"

@onready var interactor: RayCast3D = $head/Camera3D/Interactor
@onready var spotLight3D = $head/Camera3D/SpotLight3D
@onready var spawn = $"../Spawn"

@onready var skeleton = $"Esqueleto/Skeleton3D"
@onready var skeleton_phy = $"Esqueleto/Skeleton3D/PhysicalBoneSimulator3D"
@onready var capsule: CollisionShape3D = $CollisionShape3D

@export var noclip: bool = false
@export var god_mode: bool = false
@export var admin_mode: bool = false
@export var ragdoll_enabled = false

func set_auth(id: int):
	if multiplayer.multiplayer_peer != null:
		Globals.print_role("set authority to: " + str(id))
		set_multiplayer_authority(id)

func _exit_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Helper que detecta si esta instancia corresponde al jugador local (cámara activa o Globals.local_player)
func _is_local_instance() -> bool:
	if Globals.local_player == self:
		return true

	if camera_node and camera_node.current:
		return true

	return false	

@rpc("any_peer", "call_local")
func rpc_set_ragdoll_state(enable: bool):
	_set_ragdoll_state(enable)
	

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
		if _is_local_instance():
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			if death_menu:
				death_menu.show()
	else:
		_stop_physical_bones_sim()

func _start_physical_bones_sim():
	if skeleton_phy:
		skeleton_phy.physical_bones_start_simulation()

func _stop_physical_bones_sim():
	if skeleton_phy:
		skeleton_phy.physical_bones_stop_simulation()





@rpc("authority", "call_local")
func rpc_damage(amount: float):
	if not is_multiplayer_authority():
		return

	if god_mode:
		return

	if not is_alive:
		return

	hearth = clamp(hearth - amount, min_Hearth, Max_Hearth)
	Globals.print_role("damage aplicado:" + str(amount) + " hearth ahora:" + str(hearth))

	if hearth <= 0:
		is_alive = false
		# Notificamos a todos que este jugador debe ponerse en ragdoll (visual)
		rpc_set_ragdoll_state.rpc(true)
		# Aquí puedes además ejecutar lógica server-side: perder puntos, respawn timer, etc.
	else:
		is_alive = true

func damage(amount: float) -> void:
	if multiplayer.multiplayer_peer != null:
		rpc_damage.rpc(amount)
	else:
		if god_mode:
			return

		if not is_alive:
			return

		hearth = clamp(hearth - amount, min_Hearth, Max_Hearth)
		Globals.print_role("damage aplicado:" + str(amount) + " hearth ahora:" + str(hearth))

		if hearth <= 0:	
			is_alive = false
			# Notificamos a todos que este jugador debe ponerse en ragdoll (visual)
			_set_ragdoll_state(true)
			# Aquí puedes además ejecutar lógica server-side: perder puntos, respawn timer, etc.
		else:
			is_alive = true


func ignite(time):
	IsOnFire = true
	await get_tree().create_timer(time).timeout
	IsOnFire = false

func Sneeze():
	sneeze_audio.play()
	sneeze.emitting = true

func Vomit():	
	vomit_audio.play()
	vomit.emitting = true

func _ready():
	rain_node.emitting = false
	sand_node.emitting = false
	splash_node.emitting = false
	dust_node.emitting = false
	snow_node.emitting = false



	if multiplayer.multiplayer_peer != null:
		Globals.print_role("player name: " + str(name.to_int()))
		Globals.print_role("is authority: " + str(is_multiplayer_authority()))
		Globals.print_role("get authority: " + str(get_multiplayer_authority()))

		camera_node.current = is_multiplayer_authority()

		if is_multiplayer_authority():
			Globals.local_player = self
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			_reset_player()
			rpc_set_ragdoll_state.rpc(false)

			if multiplayer.is_server():
				admin_mode = true

	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		Globals.local_player = self
		camera_node.current = true
		admin_mode = true
		_reset_player()
		_set_ragdoll_state(false)

	
		
		




func body_temp(delta):
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

	var ambient_equilibrium        = clamp(((Globals.Temperature - body_temperature)*body_heat_genK), -body_heat_genMAX*1.1, body_heat_genMAX * 1.1)
	
	if Globals.Temperature >= 5 and Globals.Temperature <= 37:
		ambient_equilibrium	= 0
	
	body_temperature = clamp(body_temperature + core_equilibrium  + heatsource_equilibrium + coldsource_equilibrium + ambient_equilibrium, min_temp, Max_temp)
	temp_effect.material.set_shader_parameter("temp", body_temperature)
	temp_effect.material.set_shader_parameter("Temp", body_temperature)

	var alpha_hot  =  1-((44-clamp(body_temperature,39,44))/5)
	var alpha_cold =  ((35-clamp(body_temperature,24,35))/11)

	if randi_range(1,25) == 25:
		if alpha_cold != 0:
			damage(alpha_hot + alpha_cold)	
		elif alpha_hot != 0:
			damage(alpha_hot + alpha_cold)

	if body_temperature > 39 and randi() % 400 == 0:
		Vomit()

	if body_temperature < 35 and randi() % 400 == 0:
		Sneeze()

func body_oxy(delta):
	if god_mode:
		return

	if Globals.oxygen <= 20 or Globals.is_inwater(self) or IsUnderWater or Globals.is_inlava(self) or IsUnderLava:
		body_oxygen = clamp(body_oxygen - 5 * delta, min_oxygen, Max_oxygen)
	else:
		body_oxygen = clamp(body_oxygen + 5 * delta, min_oxygen, Max_oxygen)
	
	
	if body_oxygen <= 0:
		if randi_range(1,25) == 25:
			damage(randi_range(1,30))

func body_rad(delta):
	if god_mode:
		return

	if Globals.bradiation >= 80 and Globals.is_outdoor(self) and Outdoor:
		body_bradiation = clamp(body_bradiation + 5 * delta, min_bdradiation, Max_bradiation)
	else:
		body_bradiation = clamp(body_bradiation - 5 * delta, min_bdradiation, Max_bradiation)

	if body_bradiation >= 100:
		if randi_range(1,25) == 25:
			damage(randi_range(1,30))


func Underwater_or_Underlava_effects():
	underwatereffect.visible = IsUnderWater
	underlavaeffect.visible = IsUnderLava	

	if IsInLava:
		ignite(10)
	
	if IsInWater:
		if IsOnFire:
			IsOnFire = false	

func IsOnFire_effects():
	fire_particles.emitting = IsOnFire
	if IsOnFire:
		if randi_range(1,5) == 5:
			damage(5)



func rain_sound():
	Globals.is_raining = rain_node.emitting and Globals.is_outdoor(self) and Outdoor
	if Globals.is_raining:
		if not Rain_sound.playing:
			Rain_sound.play()
	else:
		Rain_sound.stop()

func wind_sound():
	if body_wind > 0 and body_wind <= 50:
		if not Wind_sound.playing:
			Wind_sound.play()
			Wind_moderate_sound.stop()
			Wind_moderate_sound.stop()
	elif body_wind > 50 and body_wind <= 100:
		if not Wind_moderate_sound.playing:
			Wind_sound.stop()
			Wind_moderate_sound.play()
			Wind_extreme_sound.stop()
	elif body_wind > 100:
		if not Wind_extreme_sound.playing:
			Wind_sound.stop()
			Wind_moderate_sound.stop()
			Wind_extreme_sound.play()
	else:
		Wind_sound.stop()
		Wind_moderate_sound.stop()
		Wind_extreme_sound.stop()


func _process(delta):
	points = Globals.points
	username = Globals.username
	label.text = Globals.username

	body_temp(delta)
	body_oxy(delta)
	body_rad(delta)
	Underwater_or_Underlava_effects()
	IsOnFire_effects()
	rain_sound()
	wind_sound()

func _physics_process(delta):
	if multiplayer.multiplayer_peer != null:
		if not is_multiplayer_authority():
			return

	if Globals.is_pause_menu_open:
		return
			
	if Globals.is_chat_open:
		return

	# Add the gravity.
	if not noclip:
		# Física normal
		if not is_on_floor():
			if IsInWater or IsInLava:
				velocity.y = Globals.gravity * delta * swim_factor
			else:
				velocity.y -= Globals.gravity * delta 
				fall_strength = velocity.y
		else:
			if IsInWater or IsInLava:
				pass
			else:
				if fall_strength <= -90:
					damage(50)
	else:
		# Gravedad desactivada
		velocity.y = 0

	# Handle jump.
	if Input.is_action_just_pressed("Jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY

		if IsInWater or IsInLava:
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
	if noclip:
		if Input.is_action_pressed("Jump"):
			input_vector.y += 1
		if Input.is_action_pressed("ui_down"): # o C para bajar
			input_vector.y -= 1

	var direction = (head_node.transform.basis * input_vector).normalized()

	if is_on_floor():
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 7.0)
			velocity.z = lerp(velocity.z,  direction.z * SPEED, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * SPEED, delta * 3.0)


	var horizontal_velocity = Vector2(velocity.x, velocity.z)

	animation_tree_node.set("parameters/conditions/is_falling", !is_on_floor() and velocity.y < 0)
	animation_tree_node.set("parameters/conditions/is_jumping", velocity.y > 0 )
	animation_tree_node.set("parameters/conditions/is_swiming", IsInWater or IsInLava)
	animation_tree_node.set("parameters/conditions/is_idle", is_on_floor() and horizontal_velocity.length() < 0.1)
	animation_tree_node.set("parameters/conditions/is_walking", is_on_floor() and horizontal_velocity.length() > 0.1)

	if interactor.is_colliding():
		var target = interactor.get_collider()
		if target != null and target.has_method("Interact"):
			if Input.is_action_just_pressed("Interact"):
				target.Interact()
		elif target != null and target.is_in_group("Pickable"):
			if Input.is_action_pressed("Interact"):
				target.global_position = hand_node.global_position
				target.global_rotation = hand_node.global_rotation
				target.collision_layer = 2
				target.linear_velocity = Vector3(0.1, 3, 0.1)

	if Input.is_action_just_pressed("noclip"):
		if admin_mode:
			if multiplayer.multiplayer_peer != null:
				_noclip.rpc()
			else:
				_noclip()
		else:
			Globals.print_role("No tienes permisos para usar noclip")

		
	move_and_slide()

@rpc("any_peer", "call_local")
func _noclip():
	noclip = !noclip
	if noclip:
		self.set_collision_layer(0)
		self.set_collision_mask(0)
		velocity.y = 0
		fall_strength = 0
		Globals.print_role("NOCLIP ACTIVADO")
	else:
		self.set_collision_layer(1)
		self.set_collision_mask(1)
		Globals.print_role("NOCLIP DESACTIVADO")


func _unhandled_input(event):
	if multiplayer.multiplayer_peer != null:
		if not is_multiplayer_authority():
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
	if multiplayer.multiplayer_peer != null:
		if not is_multiplayer_authority():
			return

	if body.is_in_group("Tsunami"):
		IsInWater = true
		if camera_node:
			IsUnderWater = true

	elif body.is_in_group("Meteor"):
		damage(100)

func _on_area_3d_body_exited(body: Node3D) -> void:
	if multiplayer.multiplayer_peer != null:
		if not is_multiplayer_authority():
			return

	if multiplayer.multiplayer_peer != null:
		if not is_multiplayer_authority():
			return
	
	if body.is_in_group("Tsunami"):
		IsInWater = false
		if camera_node:
			IsUnderWater = false




func _on_area_3d_area_entered(area: Area3D) -> void:
	if multiplayer.multiplayer_peer != null:
		if not is_multiplayer_authority():
			return

	if area.is_in_group("Explosion"):
		var area_parent = area.get_node("..")
		var distance = (area.global_position - global_position).length()
		var direction = (area.global_position - global_position).normalized()
		var force = area_parent.explosion_force * (1 - distance / area_parent.explosion_radius)
		velocity = direction * force
		var damag = area_parent.explosion_damage

		damage(damag)

	elif area.is_in_group("Volcano"):
		IsInLava = true

		if camera_node:
			IsUnderLava = true

	elif area.is_in_group("Tsunami"):
		IsInWater = true
		if camera_node:
			IsUnderWater = true

func _on_area_3d_area_exited(area: Area3D) -> void:
	if multiplayer.multiplayer_peer != null:
		if not is_multiplayer_authority():
			return
			
	if area.is_in_group("Volcano"):
		IsInLava = false

		if camera_node:
			IsUnderLava = false
	elif area.is_in_group("Tsunami"):
		IsInWater = false
		if camera_node:
			IsUnderWater = false



func _reset_player():
	hearth = Max_Hearth
	body_temperature = 37
	body_oxygen = Max_oxygen
	body_bradiation = min_bdradiation
	is_alive = true
	IsInWater = false
	IsInLava = false
	IsOnFire = false
	fall_strength = 0



	if multiplayer.multiplayer_peer != null:
		if not is_multiplayer_authority():
			return

	if multiplayer.multiplayer_peer != null:
		rpc_set_ragdoll_state.rpc(false)
	else:
		_set_ragdoll_state(false)
			
	position = spawn.position
	velocity = Vector3.ZERO

