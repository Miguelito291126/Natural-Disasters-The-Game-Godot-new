extends HBoxContainer

var server_ip = ""
var server_port = ""

func _on_button_pressed() -> void:
    Globals.ip = server_ip
    Globals.port = server_port.to_int() + 1
    Globals.joinwithip(Globals.ip, Globals.port)
