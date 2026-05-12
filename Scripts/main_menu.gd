extends Control
class_name MainMenu

# Nodos de la UI
@onready var main_menu: Control = $"Panel/Main_Menu"
@onready var tittle: Label = $Panel/Main_Menu/HBoxContainer/Title
@onready var multiplayer_menu: Control = $Panel/multiplayer_menu
@onready var multiplayer_menu_list: Control = $Panel/multiplayer_menu_list
@onready var settings: Control = $Panel/Settings
@onready var play_menu: Control = $Panel/Play
@onready var username: LineEdit = $Panel/multiplayer_menu/Username
@onready var username2: LineEdit = $Panel/multiplayer_menu_list/Username
@onready var ip_text: LineEdit = $Panel/multiplayer_menu/Ip
@onready var port_text: LineEdit = $Panel/multiplayer_menu/Port
@onready var port_text2: LineEdit = $Panel/multiplayer_menu_list/Port
@onready var fullscreen: CheckButton = $Panel/Settings/Fullscreen
@onready var vsync: CheckButton = $Panel/Settings/Vsync
@onready var fps: CheckButton = $Panel/Settings/Fps
@onready var anti_aliasing: OptionButton = $Panel/Settings/Antialiasing
@onready var anti_tropic: OptionButton = $Panel/Settings/Antitropic
@onready var volumen: HSlider = $Panel/Settings/Volumen
@onready var volumen_music: HSlider = $Panel/Settings/VolumenMusic
@onready var quality: OptionButton = $Panel/Settings/Quality
@onready var error_text: Label = $Panel/multiplayer_menu/error
@onready var error_text2: Label = $Panel/multiplayer_menu_list/error
@onready var resolutions: OptionButton = $Panel/Settings/Resolutions
@onready var version: Label = $Panel/Version
@onready var credits: Label = $Panel/Credits
@onready var time: Slider = $Panel/Play/Time
@onready var music: AudioStreamPlayer = $Music
@onready var private_check: CheckButton = $Panel/multiplayer_menu/PrivateCheck
@onready var private_check2: CheckButton = $Panel/multiplayer_menu_list/PrivateCheck
var multiplayer_mode: bool = false

var resolutions_dic: Dictionary = {
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

func addresolutions():
	resolutions.clear()
	var index = 0
	
	for r in resolutions_dic:
		resolutions.add_item(r,index)
		index += 1



# Called when the node enters the scene tree for the first time.
func _ready():
	Globals.main_menu = self

	_on_back_pressed()

	version.text = "V" + Globals.version
	tittle.text = Globals.gamename
	credits.text = "by " + Globals.credits
	

	LoadGameScene()

	if Globals.is_dedicated_server:
		Globals.print_role("Starting server...")

		var args = OS.get_cmdline_user_args()
		for i in range(args.size()):
			Globals.print_role("args: " + args[i])
			match args[i]:
				"--port", "port", "-p", "p":
					if i + 1 < args.size():
						Globals.port = args[i + 1].to_int()

				"--gamemode", "gamemode", "-g", "g":
					if i + 1 < args.size():
						Globals.gamemode = args[i + 1]

		Globals.print_role("port: " + str(Globals.port))
		Globals.print_role("ip: " + IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")), IP.TYPE_IPV4))
		Globals.print_role("Init dedicated server...")
		
		await get_tree().create_timer(2).timeout


		Globals.Play_MultiplayerServer(Globals.port)



func LoadGameScene():
	addresolutions()

	ip_text.text = Globals.globals_data.ip
	username.text = Globals.globals_data.username
	username2.text = Globals.globals_data.username
	port_text.text = str(Globals.globals_data.port)
	port_text2.text = str(Globals.globals_data.port)

	

	_on_antialiasing_item_selected(Globals.globals_data.antialiasing)
	_on_antitropic_item_selected(Globals.globals_data.antitropic)
	_on_vsycn_toggled(Globals.globals_data.vsync)
	_on_volumen_value_changed(Globals.globals_data.volumen)
	_on_volumen_music_value_changed(Globals.globals_data.volumen_music)
	_on_resolutions_item_selected(Globals.globals_data.resolution)
	_on_fullscreen_toggled(Globals.globals_data.fullscreen)
	_on_fps_toggled(Globals.globals_data.FPS)
	_on_username_text_changed(Globals.globals_data.username)
	_on_time_value_changed(Globals.globals_data.timer_disasters)
	_on_quality_item_selected(Globals.globals_data.quality)

	fullscreen.button_pressed = Globals.globals_data.fullscreen
	fps.button_pressed = Globals.globals_data.FPS
	vsync.button_pressed = Globals.globals_data.vsync
	volumen.value = Globals.globals_data.volumen
	volumen_music.value = Globals.globals_data.volumen_music
	time.value = Globals.globals_data.timer_disasters
	quality.selected = Globals.globals_data.quality
	anti_aliasing.selected = Globals.globals_data.antialiasing
	resolutions.selected = Globals.globals_data.resolution
	anti_tropic.selected = Globals.globals_data.antitropic
	private_check.button_pressed= Globals.globals_data.private_mode
	private_check2.button_pressed = Globals.globals_data.private_mode








func _process(_delta):
	if self.visible:
		await music.finished
		music.play()
	else:
		music.stop()


func _on_ip_text_changed(new_text:String):
	Globals.ip = new_text
	if Globals.globals_data:
		Globals.globals_data.ip = new_text
		Globals.globals_data.save_file()


func _on_port_text_changed(new_text:String):
	Globals.port = int(new_text)
	if Globals.globals_data:
		Globals.globals_data.port = new_text.to_int()
		Globals.globals_data.save_file()



func _on_join_pressed():
	if Globals.username.length() >= 1:
		if Globals.use_steam:
			Globals.Play_MultiplayerClientSteam(Globals.lobby_id)
		else:
			Globals.Play_MultiplayerClient(Globals.ip, Globals.port)
	else:
		error_text.visible = true
		await get_tree().create_timer(2).timeout
		error_text.visible = false


func _on_host_pressed():
	if Globals.username.length() >= 1:
		multiplayer_mode = true
		main_menu.hide()
		multiplayer_menu.hide()
		settings.hide()
		multiplayer_menu_list.hide()
		play_menu.show()
	else:
		error_text.visible = true
		await get_tree().create_timer(2).timeout
		error_text.visible = false


func _on_multiplayer_pressed():
	main_menu.hide()
	settings.hide()
	play_menu.hide()

	if Globals.use_steam:
		multiplayer_menu_list.show()
	else:
		multiplayer_menu.show()

func _on_sandbox_pressed() -> void:
	if Globals.username.length() < 1:
		return

	Globals.gamemode = "sandbox"
	if multiplayer_mode:
		Globals.Play_MultiplayerServer(Globals.port)
	else:
		LoadScene.load_scene(self, "map")

func _on_survival_pressed():
	if Globals.username.length() < 1:
		return
	
	Globals.gamemode = "survival"
	if multiplayer_mode:
		Globals.Play_MultiplayerServer(Globals.port)
	else:
		LoadScene.load_scene(self, "map")



func _on_settings_pressed():
	main_menu.hide()
	multiplayer_menu.hide()
	settings.show()
	multiplayer_menu_list.hide()
	play_menu.hide()


func _on_exit_pressed():
	get_tree().quit()



func _on_fps_toggled(toggled_on:bool):
	if Globals.globals_data:
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

func _on_username_text_changed(new_text:String):
	Globals.username = new_text

	if Globals.globals_data:
		Globals.globals_data.username = new_text
		Globals.globals_data.save_file()



func _on_time_value_changed(value):
	if Globals.globals_data:
		Globals.globals_data.timer_disasters = value
		Globals.globals_data.save_file()


func _on_volumen_value_changed(value:float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
	if Globals.globals_data:
		Globals.globals_data.volumen = value
		Globals.globals_data.save_file()

func _on_resolutions_item_selected(index: int) -> void:
	var res_name = resolutions.get_item_text(index)
	var size = resolutions_dic[res_name]
	get_window().size = size
	# Guardar en globals_data si existe
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


func _on_singleplayer_pressed():
	multiplayer_mode = false
	main_menu.hide()
	multiplayer_menu.hide()
	settings.hide()
	multiplayer_menu_list.hide()
	play_menu.show()



func _on_volumen_music_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))
	if Globals.globals_data:
		Globals.globals_data.volumen_music = value
		Globals.globals_data.save_file()


func _on_quality_item_selected(index: int) -> void:
	if Globals.globals_data:
		Globals.globals_data.quality = index
		Globals.globals_data.save_file()

func _on_back_pressed() -> void:
	main_menu.show()
	multiplayer_menu.hide()
	settings.hide()
	multiplayer_menu_list.hide()
	play_menu.hide()

func _on_antialiasing_item_selected(index: int) -> void:
	var vp = get_viewport()
	match index:
		0: vp.msaa_3d = Viewport.MSAA_DISABLED
		1: vp.msaa_3d = Viewport.MSAA_2X
		2: vp.msaa_3d = Viewport.MSAA_4X
		3: vp.msaa_3d = Viewport.MSAA_8X
	
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

func _on_private_check_toggled(toggled_on: bool) -> void:
	Globals.private_mode = toggled_on
	if Globals.globals_data:
		Globals.globals_data.private_mode = toggled_on
		Globals.globals_data.save_file()
