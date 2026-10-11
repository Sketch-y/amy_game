extends Node2D
## Game root: loads area scenes (res://scenes/areas/*.tscn), and owns the
## player, camera, UI, area transitions, interactions and quest state.

const PlayerScene := preload("res://scenes/player.tscn")
const AREA_PATH := "res://scenes/areas/%s.tscn"

const VIEW_W := 960.0
const VIEW_H := 540.0
const FLOOR_Y := 440.0

var area  # current area scene instance (scripts/area.gd)
var player: Node2D
var camera: Camera2D
var prompt: Label

var area_label: Label
var bag_label: Label
var dialog_panel: Panel
var dialog_text: Label
var fade: ColorRect

var area_id := ""
var interactables: Array[Interactable] = []
var target: Interactable = null
var dialog_lines: PackedStringArray = []
var dialog_index := 0
var busy := false
var inventory: Array[String] = []
var flags := {}


func _ready() -> void:
	player = PlayerScene.instantiate()
	add_child(player)

	prompt = Label.new()
	prompt.size = Vector2(160, 28)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 16)
	prompt.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	prompt.add_theme_constant_override("outline_size", 6)
	prompt.visible = false
	add_child(prompt)

	camera = Camera2D.new()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_bottom = int(VIEW_H)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	add_child(camera)
	camera.make_current()

	_build_ui()
	load_area("home", "", 400.0)
	say(["Mom: Good morning, Amy! Come talk to me before you head out."])


func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)

	area_label = _ui_label(ui, Vector2(16, 10), 22)
	bag_label = _ui_label(ui, Vector2(VIEW_W - 416, 12), 16)
	bag_label.size.x = 400
	bag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var help := _ui_label(ui, Vector2(16, VIEW_H - 26), 14)
	help.text = "← →  move     ↑  enter door     E  interact"
	_refresh_bag()

	dialog_panel = Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.08, 0.12, 0.93)
	sb.border_color = Color("f2e7c9")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(8)
	dialog_panel.add_theme_stylebox_override("panel", sb)
	dialog_panel.position = Vector2(40, 350)
	dialog_panel.size = Vector2(880, 140)
	dialog_panel.visible = false
	ui.add_child(dialog_panel)

	dialog_text = Label.new()
	dialog_text.position = Vector2(24, 18)
	dialog_text.size = Vector2(832, 90)
	dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_text.add_theme_font_size_override("font_size", 22)
	dialog_panel.add_child(dialog_text)
	var more := Label.new()
	more.text = "E ▸"
	more.position = Vector2(820, 106)
	dialog_panel.add_child(more)

	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.size = Vector2(VIEW_W, VIEW_H)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(fade)


func _ui_label(parent: Node, pos: Vector2, font_size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 5)
	parent.add_child(l)
	return l


# ---------------------------------------------------------------- areas

## Loads an area scene and places the player at the door named spawn_door
## (or at fallback_x if there is no such door).
func load_area(id: String, spawn_door := "", fallback_x := 0.0) -> void:
	if area:
		remove_child(area)
		area.queue_free()
	area_id = id
	area = load(AREA_PATH % id).instantiate()
	add_child(area)
	move_child(area, 0)  # environment behind player, prompt and UI

	interactables.clear()
	for n in area.find_children("*", "", true, false):
		if n is Interactable:
			interactables.append(n)
	target = null
	_apply_state()

	var width: float = area.width
	area_label.text = area.title
	var spawn_x := fallback_x
	var d: Node = area.find_child(spawn_door, true, false) if spawn_door != "" else null
	if d is Node2D:
		spawn_x = d.global_position.x
	player.position = Vector2(spawn_x, FLOOR_Y)
	player.min_x = 24.0
	player.max_x = width - 24.0
	camera.limit_right = int(width)
	camera.position = Vector2(spawn_x, VIEW_H / 2.0)
	camera.reset_smoothing()


## Reflects quest flags in freshly loaded scenes.
func _apply_state() -> void:
	if flags.has("won"):
		for it in interactables:
			if it.kind == "chest":
				_show_chest_open(it)


func _process(_delta: float) -> void:
	player.frozen = busy or dialog_panel.visible
	camera.position.x = player.position.x
	_update_target()


func _update_target() -> void:
	target = null
	if busy or dialog_panel.visible:
		prompt.visible = false
		return
	var best := INF
	for it in interactables:
		var d := absf(player.position.x - it.global_position.x)
		if d <= it.reach and d < best:
			best = d
			target = it
	prompt.visible = target != null
	if target:
		var key := "↑" if target.kind == "door" else "E"
		var top := target.global_position.y - target.prompt_height
		prompt.text = "[%s] %s" % [key, target.verb]
		prompt.position = Vector2(target.global_position.x - prompt.size.x / 2.0,
			minf(top, FLOOR_Y - 122.0) - 30.0)


func _unhandled_input(event: InputEvent) -> void:
	if busy:
		return
	if event.is_action_pressed("interact"):
		if dialog_panel.visible:
			_advance_dialog()
		elif target and target.kind != "door":
			_interact(target)
	elif event.is_action_pressed("move_up"):
		if not dialog_panel.visible and target and target.kind == "door":
			_use_door(target)


func _use_door(d: Interactable) -> void:
	if d.requires_item != "" and not inventory.has(d.requires_item):
		say([d.locked_text])
		return
	busy = true
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.25)
	tw.tween_callback(load_area.bind(d.target_area, d.target_door))
	tw.tween_property(fade, "color:a", 0.0, 0.25)
	tw.tween_callback(func(): busy = false)


# ---------------------------------------------------------------- dialog

func say(lines: PackedStringArray) -> void:
	if lines.is_empty():
		return
	dialog_lines = lines
	dialog_index = 0
	dialog_text.text = lines[0]
	dialog_panel.visible = true


func _advance_dialog() -> void:
	dialog_index += 1
	if dialog_index >= dialog_lines.size():
		dialog_panel.visible = false
	else:
		dialog_text.text = dialog_lines[dialog_index]


# ---------------------------------------------------------------- interactions / quest

func _interact(it: Interactable) -> void:
	match it.kind:
		"npc":
			_talk(it.npc_id)
		"chest":
			_open_chest(it)
		_:
			say(it.lines)


func _talk(id: String) -> void:
	match id:
		"mom":
			if flags.has("won"):
				say(["Mom: The Star Gem?! Amy, you're amazing!"])
			else:
				say([
					"Mom: Elder Rowan was rambling about the old tower again.",
					"Mom: He's usually sitting on the bench in town. Go say hi!",
				])
		"elder":
			if flags.has("got_key"):
				say(["Elder Rowan: That key opens the old tower at the east end of town."])
			elif inventory.has("Apple"):
				inventory.erase("Apple")
				_give("Brass Key")
				flags["got_key"] = true
				say([
					"Elder Rowan: Is that an apple? For me? Bless you, child.",
					"Elder Rowan: Take this. It opens the old tower to the east.",
					"* You received the Brass Key. *",
				])
			else:
				say([
					"Elder Rowan: Hm? Oh, hello Amy. I'm too hungry to tell stories today...",
					"Elder Rowan: If only someone would bring me an apple.",
				])
		"shopkeeper":
			if flags.has("got_apple"):
				say(["Pip: Come back anytime!"])
			else:
				flags["got_apple"] = true
				_give("Apple")
				say([
					"Pip: Welcome to Pip's Provisions!",
					"Pip: You look like someone who needs an apple. On the house!",
					"* You received an Apple. *",
				])
		"cat":
			say(["Cat: Mrrrow.", "* The cat ignores you magnificently. *"])
		_:
			push_warning("No dialogue for npc_id '%s'" % id)


func _open_chest(it: Interactable) -> void:
	if flags.has("won"):
		say(["The chest is empty."])
		return
	flags["won"] = true
	_give("Star Gem")
	_show_chest_open(it)
	say([
		"* The chest creaks open... *",
		"* You found the Star Gem! *",
		"Thanks for playing! (Feel free to keep exploring.)",
	])


## Expects the chest scene to have "Lid" and (hidden) "Gem" children.
func _show_chest_open(chest: Node) -> void:
	var lid := chest.get_node_or_null("Lid") as Polygon2D
	if lid:
		lid.color = Color("5a3418")
	var gem := chest.get_node_or_null("Gem") as CanvasItem
	if gem:
		gem.visible = true


func _give(item: String) -> void:
	inventory.append(item)
	_refresh_bag()


func _refresh_bag() -> void:
	bag_label.text = "Bag: " + (", ".join(inventory) if inventory.size() > 0 else "(empty)")
