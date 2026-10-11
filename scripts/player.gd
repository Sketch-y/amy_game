extends Node2D
## Player character (Amy). Drawn with flat shapes; origin is at her feet.

const SPEED := 260.0
const SHIRT := Color("d9548f")
const PANTS := Color("3d4a7a")
const SKIN := Color("f2c9a0")
const HAIR := Color("6b3b1f")

var facing := 1
var walking := false
var frozen := false
var min_x := 0.0
var max_x := 1000.0
var _t := 0.0


func _process(delta: float) -> void:
	var dir := 0.0 if frozen else Input.get_axis("move_left", "move_right")
	walking = dir != 0.0
	if walking:
		facing = 1 if dir > 0.0 else -1
		position.x = clampf(position.x + dir * SPEED * delta, min_x, max_x)
		_t += delta
	else:
		_t = 0.0
	queue_redraw()


func _draw() -> void:
	var swing: float = sin(_t * 14.0) * 7.0 if walking else 0.0
	var bob: float = -absf(sin(_t * 14.0)) * 3.0 if walking else 0.0
	# legs
	draw_rect(Rect2(-11 + swing, -34, 9, 34), PANTS)
	draw_rect(Rect2(2 - swing, -34, 9, 34), PANTS)
	# body + arm
	draw_rect(Rect2(-16, -78 + bob, 32, 46), SHIRT)
	draw_rect(Rect2(-4 - swing * 0.6, -72 + bob, 8, 34), SHIRT.darkened(0.2))
	# head, hair (with ponytail on the back side), eye
	draw_circle(Vector2(0, -94 + bob), 17, SKIN)
	draw_rect(Rect2(-17, -112 + bob, 34, 10), HAIR)
	draw_rect(Rect2(-22 * facing - 4, -108 + bob, 8, 26), HAIR)
	draw_circle(Vector2(7 * facing, -96 + bob), 3, Color.BLACK)
