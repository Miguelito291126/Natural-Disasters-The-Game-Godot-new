extends StaticBody3D

@onready var door = $hause/Room/Pivot
@onready var door_collision_shape = $DoorCollision
@onready var door_frame_collision_shape = $DoorFrameCollision
@export var door_open_sound: AudioStreamPlayer3D
@export var door_close_sound: AudioStreamPlayer3D

@export var door_open = false
@export var destrolled = false

var bokenhause = preload("res://Scenes/Breakable hause.tscn")

@rpc("any_peer", "call_local")
func open_door():
	Globals.print_role("Open the door!!")
	door.rotation.y = deg_to_rad(145)
	door_collision_shape.disabled = true
	door_frame_collision_shape.disabled = true
	if not door_open_sound.playing:
		door_open_sound.play()
	door_open = true

@rpc("any_peer", "call_local")
func close_door():
	Globals.print_role("Close the door!!")
	door.rotation.y = deg_to_rad(0)
	door_collision_shape.disabled = false
	door_frame_collision_shape.disabled = false
	if not door_close_sound.playing:
		door_close_sound.play()
	door_open = false


func Interact():
	if Globals.is_networking:
		if not door_open:
			open_door.rpc()
		else:
			close_door.rpc()
	else:
		if not door_open:
			open_door()
		else:
			close_door()

@rpc("any_peer", "call_local")
func destroy():
	if destrolled:
		return

	var Broken_Hause = bokenhause.instantiate()
	Broken_Hause.global_position = self.global_position
	get_parent().add_child(Broken_Hause)
	destrolled = true
    # Guardar path en Globals
	Globals.add_destrolled_nodes(self.get_path())
	self.queue_free()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Meteor"):
		if Globals.is_networking:
			destroy.rpc()
		else:
			destroy()
			


func _on_area_3d_area_entered(area: Area3D) -> void:
	if area.is_in_group("Tornado") or area.is_in_group("Tsunami") or area.is_in_group("Explosion"):
		if Globals.is_networking:
			destroy.rpc()
		else:
			destroy()


