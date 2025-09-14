extends Node3D

func _ready():
    for child in get_children():
        if child is RigidBody3D:
            child.add_to_group("movable_objects")
            child.add_to_group("Pickable")

    await get_tree().create_timer(10).timeout

    self.queue_free()
