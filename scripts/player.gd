extends Node2D
## Player character (Amy). Origin is at her feet; visuals live in player.tscn
## and are drawn facing right (Visual is mirrored to face left).

const SPEED := 260.0

var facing := 1
var walking := false
var frozen := false
var min_x := 0.0
var max_x := 1000.0
var _t := 0.0

@onready var _visual: Node2D = $Visual
@onready var _leg_l: Node2D = $Visual/LegL
@onready var _leg_r: Node2D = $Visual/LegR
@onready var _upper: Node2D = $Visual/Upper
@onready var _arm: Node2D = $Visual/Upper/Arm


func _process(delta: float) -> void:
	var dir := 0.0 if frozen else Input.get_axis("move_left", "move_right")
	walking = dir != 0.0
	if walking:
		facing = 1 if dir > 0.0 else -1
		position.x = clampf(position.x + dir * SPEED * delta, min_x, max_x)
		_t += delta
	else:
		_t = 0.0
	_animate()


func _animate() -> void:
	var swing := sin(_t * 14.0) * 7.0 if walking else 0.0
	var bob := -absf(sin(_t * 14.0)) * 3.0 if walking else 0.0
	_visual.scale.x = facing
	_leg_l.position.x = swing
	_leg_r.position.x = -swing
	_upper.position.y = bob
	_arm.position.x = -swing * 0.6
