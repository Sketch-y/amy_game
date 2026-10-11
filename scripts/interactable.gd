@tool
class_name Interactable
extends Node2D
## Something the player can use: a door, NPC, sign, chest or flavor object.
## Place the node where it stands on the floor; its child shapes are its visuals.

@export_enum("door", "npc", "sign", "flavor", "chest") var kind := "flavor":
	set(v):
		kind = v
		queue_redraw()
## Prompt label text, e.g. "Talk", "Read", "Enter".
@export var verb := "Look"
## How far above this node the "[E] Look" prompt appears.
@export var prompt_height := 100.0:
	set(v):
		prompt_height = v
		queue_redraw()
## Horizontal distance from which the player can use it.
@export var reach := 48.0:
	set(v):
		reach = v
		queue_redraw()
## Text shown for signs and flavor objects (one dialog page per line).
@export_multiline var lines: PackedStringArray

@export_group("NPC")
## Dialogue key handled in main.gd (_talk).
@export var npc_id := ""

@export_group("Door")
## Area scene name in res://scenes/areas/ (without .tscn).
@export var target_area := ""
## Name of the door node in the target area to arrive at.
@export var target_door := ""
## Inventory item needed to open this door (empty = unlocked).
@export var requires_item := ""
@export var locked_text := "It's locked."


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	# Editor-only guides: reach along the floor, and the prompt anchor.
	var c := Color(1, 0.8, 0.2, 0.9)
	draw_line(Vector2(-reach, 0), Vector2(reach, 0), c, 3)
	draw_circle(Vector2(0, -prompt_height), 5, c)
