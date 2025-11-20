extends Node3D

var explosion_force = 100
var explosion_damage = 100
@onready var explosion_radius = $Area3D/CollisionShape3D.shape.radius
@onready var smoke = $Smoke
@onready var smoke_shockwave_explosion = $"Smoke shock"
@onready var sparks = $Sparks
@onready var sparks_shock = $"Sparks shock"

# Called when the node enters the scene tree for the first time.
func _ready():
	sparks.emitting = true
	smoke_shockwave_explosion.emitting = true
	smoke.emitting = true
	sparks_shock.emitting = true



func _on_finished():
	self.queue_free()
