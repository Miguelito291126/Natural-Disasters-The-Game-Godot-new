extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.visible = is_multiplayer_authority()

	if not is_multiplayer_authority():
		return

	self.visible = true
