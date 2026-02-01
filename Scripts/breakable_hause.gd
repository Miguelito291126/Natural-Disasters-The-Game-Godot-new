extends Node3D

@export var gravity_multiplier := 4.5

func _ready():
    for child in get_children():
        if child is RigidBody3D:
            child.gravity_scale = gravity_multiplier

    await get_tree().create_timer(10).timeout

    self.queue_free()
