extends CanvasLayer

var mouse_action_state = false

@onready var worldenvironment = Globals.map.get_node("WorldEnvironment")
@onready var light = worldenvironment.get_node("Sun")
@onready var light2 = worldenvironment.get_node("Moon")

@onready var main_menu = $Panel/Menu
@onready var Settings = $Panel/Settings
@onready var fullscreen = $Panel/Settings/Fullscreen
@onready var vsync = $Panel/Settings/vsync
@onready var fps = $Panel/Settings/fps
@onready var anti_aliasing = $Panel/Settings/antialiasing
@onready var anti_tropic = $Panel/Settings/antitropic
@onready var volumen = $Panel/Settings/Volumen
@onready var volumen_music = $"Panel/Settings/Volumen Music"
@onready var time = $Panel/Settings/Time
@onready var quality = $Panel/Settings/quality
@onready var resolutions = $Panel/Settings/resolutions


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

var GlobalsData: DataResource = DataResource.load_file()

func addresolutions():
	var current_resolution = Globals.GlobalsData.resolution
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
	main_menu.show()
	Settings.hide()

	LoadGameScene()


func LoadGameScene():
	addresolutions()

	_on_antialiasing_item_selected(Globals.GlobalsData.antialiasing)
	_on_antitropic_item_selected(Globals.GlobalsData.antitropic)
	_on_vsycn_toggled(Globals.GlobalsData.vsync)
	_on_volumen_value_changed(Globals.GlobalsData.volumen)
	_on_volumen_music_value_changed(Globals.GlobalsData.volumen_music)
	_on_resolutions_item_selected(Globals.GlobalsData.resolution)
	_on_fullscreen_toggled(Globals.GlobalsData.fullscreen)
	_on_fps_toggled(Globals.GlobalsData.FPS)
	_on_time_value_changed(Globals.GlobalsData.timer_disasters)
	_on_option_button_item_selected(Globals.GlobalsData.quality)



	fullscreen.button_pressed = Globals.GlobalsData.fullscreen
	fps.button_pressed = Globals.GlobalsData.FPS
	vsync.button_pressed = Globals.GlobalsData.vsync
	volumen.value = Globals.GlobalsData.volumen
	volumen_music.value = Globals.GlobalsData.volumen_music
	time.value = Globals.GlobalsData.timer_disasters
	quality.selected = Globals.GlobalsData.quality
	resolutions.selected = Globals.GlobalsData.resolution
	anti_aliasing.selected = Globals.GlobalsData.antialiasing
	anti_tropic.selected = Globals.GlobalsData.antitropic




func _on_ip_text_changed(new_text:String):
	Globals.ip = new_text


func _on_port_text_changed(new_text:String):
	Globals.port = int(new_text)


func _on_play_pressed():
	main_menu.hide()
	Settings.hide()


func _on_settings_pressed():
	main_menu.hide()
	Settings.show()


func _on_exit_pressed():
	pause()
	Globals.close_conection()
		
func _exit_tree() -> void:
	Globals.Temperature_target = Globals.Temperature_original
	Globals.Humidity_target = Globals.Humidity_original
	Globals.pressure_target = Globals.pressure_original
	Globals.Wind_Direction_target = Globals.Wind_Direction_original
	Globals.Wind_speed_target = Globals.Wind_speed_original

func _on_fps_toggled(toggled_on:bool):
	Globals.GlobalsData.FPS = toggled_on
	Globals.GlobalsData.save_file()


func _on_vsycn_toggled(toggled_on: bool):
	Globals.GlobalsData.vsync = toggled_on

	if toggled_on:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

	Globals.GlobalsData.save_file()

func _on_back_pressed():
	main_menu.show()
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
		
	Globals.GlobalsData.timer_disasters = value
	Globals.GlobalsData.save_file()
	Globals.timer.wait_time = value

	
		
func _on_volumen_value_changed(value:float):
	Globals.GlobalsData.volumen = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
	Globals.GlobalsData.save_file()



func _on_resolutions_item_selected(index:int):
	Globals.GlobalsData.resolution = index
	var size = resolutions_dic.get(resolutions.get_item_text(index))
	DisplayServer.window_set_size(size)
	get_viewport().set_size(size)
	Globals.GlobalsData.save_file()


func _on_fullscreen_toggled(toggled_on:bool):
	if toggled_on == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	Globals.GlobalsData.fullscreen = toggled_on
	Globals.GlobalsData.save_file()

func _on_reset_player_pressed():
	get_parent()._reset_player()

func _on_return_pressed():
	pause()

func _on_volumen_music_value_changed(value):
	Globals.GlobalsData.volumen_music = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))
	Globals.GlobalsData.save_file()

func _on_option_button_item_selected(index: int):

	match index:
		0:
			light.shadow_enabled = false
			light2.shadow_enabled = false
			worldenvironment.environment.sdfgi_enabled = false
			worldenvironment.environment.glow_enabled = false
			worldenvironment.environment.ssao_enabled = false
		1:
			light.shadow_enabled = true
			light2.shadow_enabled = true
			worldenvironment.environment.sdfgi_enabled = false
			worldenvironment.environment.glow_enabled = true
			worldenvironment.environment.ssao_enabled = false
		2:
			light.shadow_enabled = true
			light2.shadow_enabled = true
			worldenvironment.environment.sdfgi_enabled = true
			worldenvironment.environment.glow_enabled = true
			worldenvironment.environment.ssao_enabled = true
	
	Globals.GlobalsData.quality = index
	Globals.GlobalsData.save_file()

func _on_antialiasing_item_selected(index: int) -> void:
	Globals.GlobalsData.antialiasing = index

	var viewport := get_viewport()

	match index:
		0: viewport.msaa_3d = Viewport.MSAA_DISABLED
		1: viewport.msaa_3d = Viewport.MSAA_2X
		2: viewport.msaa_3d = Viewport.MSAA_4X
		3: viewport.msaa_3d = Viewport.MSAA_8X

	Globals.GlobalsData.save_file()



func _on_antitropic_item_selected(index: int) -> void:
	Globals.GlobalsData.antitropic = index

	var levels = [1, 2, 4, 8, 16]

	if index >= 0 and index < levels.size():
		ProjectSettings.set_setting(
			"rendering/textures/default_filters/anisotropic_filtering_level",
			levels[index]
		)
		ProjectSettings.save()

	Globals.GlobalsData.save_file()