class_name PauseMenu
extends CanvasLayer

var mouse_action_state = false

@onready var map_env = Globals.map.get_node("WorldEnvironment")
@onready var light = map_env.get_node("Sun")
@onready var light2 = map_env.get_node("Moon")

@onready var pause_menu = $Panel/MarginContainer/Pause_Menu
@onready var Settings = $Panel/MarginContainer/Settings
@onready var fullscreen = $Panel/MarginContainer/Settings/Fullscreen
@onready var vsync = $Panel/MarginContainer/Settings/Vsync
@onready var fps = $Panel/MarginContainer/Settings/Fps
@onready var anti_aliasing = $Panel/MarginContainer/Settings/Antialiasing
@onready var anti_tropic = $Panel/MarginContainer/Settings/Antitropic
@onready var volumen = $Panel/MarginContainer/Settings/Volumen
@onready var volumen_music = $Panel/MarginContainer/Settings/VolumenMusic
@onready var time = $Panel/MarginContainer/Settings/Time
@onready var quality = $Panel/MarginContainer/Settings/Quality
@onready var resolutions = $Panel/MarginContainer/Settings/Resolutions


var resolutions_dic = {
	"2400x1080 ": Vector2i(2400, 1080 ),
	"1920x1080": Vector2i(1920, 1080),
	"1600x900": Vector2i(1600, 900),
	"1440x1080": Vector2i(1440, 1080),
	"1440x900": Vector2i(1440, 900),
	"1366x768": Vector2i(1366, 768),
	"1360x768": Vector2i(1360, 768),
	"1280x1024": Vector2i(1280, 1024),
	"1280x962": Vector2i(1280, 962),
	"1280x960": Vector2i(1280, 960),
	"1280x800": Vector2i(1280, 800),
	"1280x768": Vector2i(1280, 768),
	"1280x720": Vector2i(1280, 720),
	"1176x664": Vector2i(1176, 664),
	"1152x648": Vector2i(1152, 648),
	"1024x768": Vector2i(1024, 768),
	"800x600": Vector2i(800, 600),
	"720x480": Vector2i(720, 480),
}

var globals_data: DataResource = DataResource.load_file()

func addresolutions():
	resolutions.clear()
	var index = 0
	
	for r in resolutions_dic:
		resolutions.add_item(r,index)
		index += 1

# Called when the node enters the scene tree for the first time.
func _ready():
	if not is_multiplayer_authority():
		self.hide()
		return

	self.hide()
	_on_back_pressed()
	LoadGameScene()


func LoadGameScene():
	addresolutions()

	_on_antialiasing_item_selected(Globals.globals_data.antialiasing)
	_on_antitropic_item_selected(Globals.globals_data.antitropic)
	_on_vsycn_toggled(Globals.globals_data.vsync)
	_on_volumen_value_changed(Globals.globals_data.volumen)
	_on_volumen_music_value_changed(Globals.globals_data.volumen_music)
	_on_resolutions_item_selected(Globals.globals_data.resolution)
	_on_fullscreen_toggled(Globals.globals_data.fullscreen)
	_on_fps_toggled(Globals.globals_data.FPS)
	_on_time_value_changed(Globals.globals_data.timer_disasters)
	_on_quality_item_selected(Globals.globals_data.quality)



	fullscreen.button_pressed = Globals.globals_data.fullscreen
	fps.button_pressed = Globals.globals_data.FPS
	vsync.button_pressed = Globals.globals_data.vsync
	volumen.value = Globals.globals_data.volumen
	volumen_music.value = Globals.globals_data.volumen_music
	time.value = Globals.globals_data.timer_disasters
	quality.selected = Globals.globals_data.quality
	resolutions.selected = Globals.globals_data.resolution
	anti_aliasing.selected = Globals.globals_data.antialiasing
	anti_tropic.selected = Globals.globals_data.antitropic




func _on_ip_text_changed(new_text:String):
	Globals.ip = new_text


func _on_port_text_changed(new_text:String):
	Globals.port = int(new_text)


func _on_play_pressed():
	pause_menu.hide()
	Settings.hide()


func _on_settings_pressed():
	pause_menu.hide()
	Settings.show()


func _on_exit_pressed():
	pause()
	Globals.close_conection()
		
func _exit_tree() -> void:
	Globals.temperature_target = Globals.temperature_original
	Globals.humidity_target = Globals.humidity_original
	Globals.pressure_target = Globals.pressure_original
	Globals.wind_direction_target = Globals.wind_direction_original
	Globals.wind_speed_target = Globals.wind_speed_original

func _on_fps_toggled(toggled_on: bool):
	Globals.globals_data.FPS = toggled_on
	Globals.globals_data.save_file()


func _on_vsycn_toggled(toggled_on: bool):
	

	if toggled_on:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		
	if Globals.globals_data:
		Globals.globals_data.vsync = toggled_on
		Globals.globals_data.save_file()

func _on_back_pressed():
	pause_menu.show()
	Settings.hide()


func _get_local_player():
	for p in get_tree().get_nodes_in_group("player"):
		if p.is_multiplayer_authority():
			return p

	return null



func mouse_action():
	if mouse_action_state:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	mouse_action_state = !mouse_action_state

func pause():
	Globals.is_pause_menu_open = !Globals.is_pause_menu_open

	if multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		get_tree().paused = false

	if !Globals.is_pause_menu_open:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	self.visible = Globals.is_pause_menu_open



func _process(_delta):
	if not is_multiplayer_authority():
		return

	if Input.is_action_just_pressed("Mouse Action"):
		mouse_action()

	if Input.is_action_just_pressed("Pause"):
		pause()


func _on_time_value_changed(value):
	var player = _get_local_player()
	if player == null or not player.admin_mode:
		Globals.print_role("You dont have perms")
		return

	if not Globals.started:
		return
		

	Globals.timer.wait_time = value
	if Globals.globals_data:
		Globals.globals_data.timer_disasters = value
		Globals.globals_data.save_file()

	
		
func _on_volumen_value_changed(value:float):
	
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
	if Globals.globals_data:
		Globals.globals_data.volumen = value
		Globals.globals_data.save_file()



func _on_resolutions_item_selected(index:int):
	var size = resolutions_dic.get(resolutions.get_item_text(index))
	DisplayServer.window_set_size(size)
	get_viewport().set_size(size)
	if Globals.globals_data:
		Globals.globals_data.resolution = index
		Globals.globals_data.save_file()


func _on_fullscreen_toggled(toggled_on:bool):
	if toggled_on == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	if Globals.globals_data:
		Globals.globals_data.fullscreen = toggled_on
		Globals.globals_data.save_file()

func _on_reset_player_pressed():
	get_parent()._reset_player()

func _on_return_pressed():
	pause()

func _on_volumen_music_value_changed(value):
	
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))
	if Globals.globals_data:
		Globals.globals_data.volumen_music = value
		Globals.globals_data.save_file()

func _on_quality_item_selected(index: int):

	match index:
		0:
			light.shadow_enabled = false
			light2.shadow_enabled = false
			map_env.environment.sdfgi_enabled = false
			map_env.environment.glow_enabled = false
			map_env.environment.ssao_enabled = false
		1:
			light.shadow_enabled = true
			light2.shadow_enabled = true
			map_env.environment.sdfgi_enabled = false
			map_env.environment.glow_enabled = true
			map_env.environment.ssao_enabled = false
		2:
			light.shadow_enabled = true
			light2.shadow_enabled = true
			map_env.environment.sdfgi_enabled = true
			map_env.environment.glow_enabled = true
			map_env.environment.ssao_enabled = true

	
	if Globals.globals_data:
		Globals.globals_data.quality = index
		Globals.globals_data.save_file()

func _on_antialiasing_item_selected(index: int) -> void:
	

	var viewport := get_viewport()

	match index:
		0: viewport.msaa_3d = Viewport.MSAA_DISABLED
		1: viewport.msaa_3d = Viewport.MSAA_2X
		2: viewport.msaa_3d = Viewport.MSAA_4X
		3: viewport.msaa_3d = Viewport.MSAA_8X

	if Globals.globals_data:
		Globals.globals_data.antialiasing = index
		Globals.globals_data.save_file()



func _on_antitropic_item_selected(index: int) -> void:
	

	var levels = [1, 2, 4, 8, 16]

	if index >= 0 and index < levels.size():
		ProjectSettings.set_setting(
			"rendering/textures/default_filters/anisotropic_filtering_level",
			levels[index]
		)

	if Globals.globals_data:
		Globals.globals_data.antitropic = index
		Globals.globals_data.save_file()
