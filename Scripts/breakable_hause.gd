extends Node3D

func _ready():
    for child in get_children():
        if child is RigidBody3D:
            child.add_to_group("movable_objects")
            child.add_to_group("Pickable")
            # No sobrescribir global_transform: las piezas deben mantener sus
            # posiciones locales y heredar la escala del padre (que ya tiene
            # el transform de la casa destruida).

    await get_tree().create_timer(10).timeout

    self.queue_free()
