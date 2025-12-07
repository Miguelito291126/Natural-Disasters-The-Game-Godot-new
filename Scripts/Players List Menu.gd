extends CanvasLayer

@onready var list = $Panel/List
var player_info = preload("res://Scenes/player_info.tscn")

func _ready():
    self.visible = false

# --- RPC: recibir lista desde el servidor ---
@rpc("any_peer", "call_local")
func sync_players(players_array: Array):
    update_list(players_array)

func update_list(players_array: Array):
    # Limpiar lista
    for child in list.get_children():
        if child.name == "Info":
            continue
        child.queue_free()

    # Rellenar UI
    for p in players_array:
        var inst = player_info.instantiate()
        inst.get_node("Username").text = p["username"] + " - "
        inst.get_node("Points").text = str(p["points"])
        list.add_child(inst)

func _process(_delta):
    if Input.is_action_just_pressed("List of players"):
        self.visible = !self.visible

    # Solo el servidor sincroniza
    if not multiplayer.is_server():
        return

    # Construir arreglo de datos
    var data := []
    for player_data in Globals.players_conected:
        if is_instance_valid(player_data):
            data.append({
                "username": player_data.username,
                "points": player_data.points
            })

    # Enviar a todos
    sync_players.rpc(data)
