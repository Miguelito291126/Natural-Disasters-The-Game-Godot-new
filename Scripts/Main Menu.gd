extends Control

@onready var main_menu = $Panel/Menu
@onready var tittle = $Panel/Menu/HBoxContainer/Title
@onready var Multiplayer = $Panel/Multiplayer
@onready var Multiplayer_list = $Panel/Multiplayer_list
@onready var Settings = $Panel/Settings
@onready var Singleplayer = $Panel/Singleplayer
@onready var username = $Panel/Multiplayer/username
@onready var ip_text = $Panel/Multiplayer/ip
@onready var port_text = $Panel/Multiplayer/port
@onready var fullscreen = $Panel/Settings/Fullscreen
@onready var vsync = $Panel/Settings/vsync
@onready var fps = $Panel/Settings/fps
@onready var anti_aliasing = $Panel/Settings/antialiasing
@onready var volumen = $Panel/Settings/Volumen
@onready var volumen_music = $"Panel/Settings/Volumen Music"
@onready var time = $Panel/Singleplayer/Time
@onready var time2 = $Panel/Multiplayer/Time
@onready var quality = $Panel/Settings/quality
@onready var music = $Music
@onready var error_text = $Panel/Multiplayer/Label
@onready var resolutions = $Panel/Settings/resolutions
@onready var version = $Panel/Version
@onready var credits = $Panel/Credits

var resolution: Dictionary = {
	"2400x1080 ": Vector2i(2400, 1080 ),
	"1920x1080": Vector2i(1920, 1080),
	"1600x900": Vector2i(1600, 900),
	"1440x1080": Vector2i(14400, 1080),
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
	var current_resolution = Globals.GlobalsData.resolution
	var index = 0
	
	for r in resolution:
		resolutions.add_item(r,index)
		
		if resolution[r] == current_resolution:
			resolutions._select_int(index)
		index += 1


# Called when the node enters the scene tree for the first time.
func _ready():
	Globals.main_menu = self

	main_menu.show()
	tittle.show()
	Multiplayer.hide()
	Settings.hide()
	Multiplayer_list.hide()
	Singleplayer.hide()

	version.text = "V" + Globals.version
	tittle.text = Globals.gamename
	credits.text = "by " + Globals.credits
	

	LoadGameScene()
	Globals.SetUpLisener()

	if OS.has_feature("dedicated_server") or "s" in OS.get_cmdline_user_args() or "server" in OS.get_cmdline_user_args():
		Globals.print_role("Iniciando servidor...")

		var args = OS.get_cmdline_user_args()
		for i in range(args.size()):
			Globals.print_role("args: " + args[i])
			match args[i]:
				"--port", "port", "-p", "p":
					if i + 1 < args.size():
						Globals.port = args[i + 1].to_int()
						Globals.lisener_port = Globals.port + 1
						Globals.broadcaster_port = Globals.port - 1

		Globals.print_role("port: " + str(Globals.port))
		Globals.print_role("ip: " + IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")), IP.TYPE_IPV4))
		Globals.print_role("Iniciando servidor dedicado...")
		
		await get_tree().create_timer(2).timeout

		Globals.hostwithport(Globals.port)
	else: 
		Globals.print_role("No se puede jugar en modo de servidor")
   

func LoadGameScene():
	username.text = Globals.username
	ip_text.text = Globals.ip
	port_text.text = str(Globals.port)
	
	addresolutions()
	DisplayServer.window_set_size(Globals.GlobalsData.resolution)
	get_viewport().set_size(Globals.GlobalsData.resolution)

	fullscreen.button_pressed = Globals.GlobalsData.fullscreen
	fps.button_pressed = Globals.GlobalsData.FPS
	vsync.button_pressed = Globals.GlobalsData.vsync
	anti_aliasing.button_pressed = Globals.GlobalsData.antialiasing
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(Globals.GlobalsData.volumen))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(Globals.GlobalsData.volumen_music))
	volumen.value = Globals.GlobalsData.volumen
	volumen_music.value = Globals.GlobalsData.volumen_music
	time.value = Globals.GlobalsData.timer_disasters
	time2.value = Globals.GlobalsData.timer_disasters
	quality.selected = Globals.GlobalsData.quality





func _process(_delta):
	if self.visible:
		await music.finished
		music.play()
	else:
		music.stop()


func _on_ip_text_changed(new_text:String):
	Globals.ip = new_text


func _on_port_text_changed(new_text:String):
	Globals.port = int(new_text)
	Globals.lisener_port = int(new_text) + 1
	Globals.broadcaster_port = int(new_text) - 1
	Globals.SetUpLisener()


func _on_join_pressed():
	if Globals.username.length() < 10 and Globals.username.length() >= 1:
		Globals.joinwithip(Globals.ip, Globals.port)
	else:
		error_text.visible = true
		await get_tree().create_timer(2).timeout
		error_text.visible = false


func _on_host_pressed():
	if Globals.username.length() < 10 and Globals.username.length() >= 1:
		Globals.hostwithport(Globals.port)
	else:
		error_text.visible = true
		await get_tree().create_timer(2).timeout
		error_text.visible = false


func _on_multiplayer_pressed():
	main_menu.hide()
	Multiplayer.show()
	Settings.hide()
	Multiplayer_list.hide()
	Singleplayer.hide()


func _on_play_pressed():
	LoadScene.load_scene(self, "map")


func _on_settings_pressed():
	main_menu.hide()
	Multiplayer.hide()
	Settings.show()
	Multiplayer_list.hide()
	Singleplayer.hide()


func _on_exit_pressed():
	get_tree().quit()



func _on_fps_toggled(toggled_on:bool):
	Globals.GlobalsData.FPS = toggled_on
	Globals.GlobalsData.save_file()


func _on_vsycn_toggled(toggled_on:bool):
	Globals.GlobalsData.vsync = toggled_on
	ProjectSettings.set_setting("display/window/vsync/vsync_mode", toggled_on)
	Globals.GlobalsData.save_file()


func _on_antialiasing_toggled(toggled_on:bool):
	Globals.GlobalsData.antialiasing = toggled_on
	ProjectSettings.set_setting("rendering/anti_aliasing/screen_space_roughness_limiter/enabled", toggled_on)
	Globals.GlobalsData.save_file()


func _on_back_pressed():
	main_menu.show()
	Multiplayer.hide()
	Settings.hide()
	Multiplayer_list.hide()
	Singleplayer.hide()


func _on_username_text_changed(new_text:String):
	Globals.username = new_text
	Globals.GlobalsData.save_file()


func _on_h_slider_2_value_changed(value):
	Globals.GlobalsData.timer_disasters = value
	Globals.GlobalsData.save_file()


func _on_volumen_value_changed(value:float):
	Globals.GlobalsData.volumen = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
	Globals.GlobalsData.save_file()

func _on_resolutions_item_selected(index:int):
	var size = resolution.get(resolutions.get_item_text(index))
	DisplayServer.window_set_size(size)
	get_viewport().set_size(size)
	Globals.GlobalsData.resolution = size
	Globals.GlobalsData.save_file()


func _on_fullscreen_toggled(toggled_on:bool):
	if toggled_on == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	Globals.GlobalsData.fullscreen = toggled_on
	Globals.GlobalsData.save_file()


func _on_singleplayer_pressed():
	main_menu.hide()
	Multiplayer.hide()
	Settings.hide()
	Multiplayer_list.hide()
	Singleplayer.show()



func _on_volumen_music_value_changed(value):
	Globals.GlobalsData.volumen_music = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))
	Globals.GlobalsData.save_file()


func _on_option_button_item_selected(index: int):
	Globals.GlobalsData.quality = index
	Globals.GlobalsData.save_file()


func _on_multiplayer_list_pressed() -> void:
	main_menu.hide()
	Multiplayer.hide()
	Settings.hide()
	Multiplayer_list.show()
	Singleplayer.hide()



func _on_back_multiplayer_pressed() -> void:
	main_menu.hide()
	Multiplayer.show()
	Settings.hide()
	Multiplayer_list.hide()
	Singleplayer.hide()


func _on_back_singleplayer_pressed() -> void:
	main_menu.show()
	Multiplayer.hide()
	Settings.hide()
	Multiplayer_list.hide()
	Singleplayer.hide()
