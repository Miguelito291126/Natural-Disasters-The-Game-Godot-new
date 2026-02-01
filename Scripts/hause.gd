extends StaticBody3D

@onready var door = $hause/pivot
@onready var door_collision_shape = $DoorCollision
@onready var hause_model = $hause
@export var door_open_sound: AudioStreamPlayer3D
@export var door_close_sound: AudioStreamPlayer3D

@export var door_open = false
@export var destrolled = false

@export var bokenhause = preload("res://Scenes/breakable_hause.tscn")
## Factor extra de escala para las piezas destruidas. Las mallas del Breakable
## están en unidades más pequeñas que la casa; aumenta si se ven diminutas.
@export var breakable_scale_factor: float = 2.6

@rpc("any_peer", "call_local")
func open_door():
	Globals.print_role("Open the door")
	door.rotation.y = deg_to_rad(145)
	door_collision_shape.disabled = true
	if not door_open_sound.playing:
		door_open_sound.play()
	door_open = true

@rpc("any_peer", "call_local")
func close_door():
	Globals.print_role("Close the door")
	door.rotation.y = deg_to_rad(0)
	door_collision_shape.disabled = false
	if not door_close_sound.playing:
		door_close_sound.play()
	door_open = false


func Interact():

	if not door_open:
		open_door.rpc()
	else:
		close_door.rpc()


@rpc("any_peer", "call_local")
func destroy():
	if destrolled:
		return

	var Broken_Hause = bokenhause.instantiate()
	get_parent().add_child(Broken_Hause)
	Broken_Hause.global_transform = hause_model.global_transform
	destrolled = true
	# Guardar path en Globals
	Globals.add_destrolled_nodes(self.get_path())
	self.queue_free()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Meteor"):
		destroy.rpc()

			


func _on_area_3d_area_entered(area: Area3D) -> void:
	if area.is_in_group("Tornado") or area.is_in_group("Tsunami") or area.is_in_group("Explosion"):
		destroy.rpc()
