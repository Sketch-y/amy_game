extends Node2D
## Game root: owns the four environment layers, the player, camera, UI,
## area loading, interactions and simple quest state.

const Areas := preload("res://scripts/areas.gd")
const PlayerScript := preload("res://scripts/player.gd")

const BG_SCROLL := 0.35  # background scroll speed relative to the other layers
const REACH := 48.0  # default interaction distance

# Environment layers, back to front.
var bg: Parallax2D
var bld: Node2D
var dec: Node2D
var flr: Node2D
var act: Node2D  # NPCs (in front of the environment, behind the player)

var player: Node2D
var camera: Camera2D
var prompt: Label

var area_label: Label
var bag_label: Label
var dialog_panel: Panel
var dialog_text: Label
var fade: ColorRect

var area_id := ""
var area_width := 0.0
var interactables: Array = []
var target = null
var dialog_lines: Array = []
var dialog_index := 0
var busy := false
var inventory: Array[String] = []
var flags := {}


func _ready() -> void:
	bg = Parallax2D.new()
	bg.name = "Background"
	bg.scroll_scale = Vector2(BG_SCROLL, 1.0)
	add_child(bg)
	bld = _make_layer("Buildings")
	dec = _make_layer("Decor")
	flr = _make_layer("Floor")
	act = _make_layer("Actors")

	player = PlayerScript.new()
	player.name = "Player"
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
	camera.limit_bottom = int(Areas.VIEW_H)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	add_child(camera)
	camera.make_current()

	_build_ui()
	load_area("home", 400)
	say(["Mom: Good morning, Amy! Come talk to me before you head out."])


func _make_layer(layer_name: String) -> Node2D:
	var n := Node2D.new()
	n.name = layer_name
	add_child(n)
	return n


func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)

	area_label = _ui_label(ui, Vector2(16, 10), 22)
	bag_label = _ui_label(ui, Vector2(Areas.VIEW_W - 416, 12), 16)
	bag_label.size.x = 400
	bag_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var help := _ui_label(ui, Vector2(16, Areas.VIEW_H - 26), 14)
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
	fade.size = Vector2(Areas.VIEW_W, Areas.VIEW_H)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(fade)


func _ui_label(parent: Node, pos: Vector2, font_size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 5)
	parent.add_child(l)
	return l


# ---------------------------------------------------------------- areas

func load_area(id: String, spawn_x: float) -> void:
	for layer in [bg, bld, dec, flr, act]:
		for c in layer.get_children():
			c.queue_free()
	interactables.clear()
	target = null
	area_id = id
	area_width = Areas.build(self, id)
	area_label.text = Areas.title(id)

	player.position = Vector2(spawn_x, Areas.FLOOR_Y)
	player.min_x = 24.0
	player.max_x = area_width - 24.0
	camera.limit_right = int(area_width)
	camera.position = Vector2(spawn_x, Areas.VIEW_H / 2.0)
	camera.reset_smoothing()


## Width the background layer must span so it never runs out while scrolling.
func bg_width(w: float) -> float:
	return Areas.VIEW_W + (w - Areas.VIEW_W) * BG_SCROLL + 40.0


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
		var d := absf(player.position.x - it.x)
		if d <= it.reach and d < best:
			best = d
			target = it
	prompt.visible = target != null
	if target:
		var key := "↑" if target.kind == "door" else "E"
		prompt.text = "[%s] %s" % [key, target.verb]
		prompt.position = Vector2(target.x - prompt.size.x / 2.0, minf(target.top, Areas.FLOOR_Y - 122.0) - 30.0)


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


func _use_door(d: Dictionary) -> void:
	if d.requires != "" and not inventory.has(d.requires):
		say([d.locked_text])
		return
	busy = true
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.25)
	tw.tween_callback(load_area.bind(d.target, d.spawn_x))
	tw.tween_property(fade, "color:a", 0.0, 0.25)
	tw.tween_callback(func(): busy = false)


# ---------------------------------------------------------------- dialog

func say(lines: Array) -> void:
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

func _interact(it: Dictionary) -> void:
	match it.kind:
		"npc":
			_talk(it.id)
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


func _open_chest(it: Dictionary) -> void:
	if flags.has("won"):
		say(["The chest is empty."])
		return
	flags["won"] = true
	_give("Star Gem")
	it.lid.color = Color("5a3418")
	Areas.gem(self, it.x)
	say([
		"* The chest creaks open... *",
		"* You found the Star Gem! *",
		"Thanks for playing! (Feel free to keep exploring.)",
	])


func _give(item: String) -> void:
	inventory.append(item)
	_refresh_bag()


func _refresh_bag() -> void:
	bag_label.text = "Bag: " + (", ".join(inventory) if inventory.size() > 0 else "(empty)")


# ---------------------------------------------------------------- shape helpers (used by areas.gd)

func poly(layer: Node, pts: Array, col: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array(pts)
	p.color = col
	layer.add_child(p)
	return p


func rect(layer: Node, x: float, y: float, w: float, h: float, col: Color) -> Polygon2D:
	return poly(layer, [Vector2(x, y), Vector2(x + w, y), Vector2(x + w, y + h), Vector2(x, y + h)], col)


func circle(layer: Node, c: Vector2, r: float, col: Color, seg := 24) -> Polygon2D:
	var pts := []
	for i in seg:
		var a := TAU * i / seg
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return poly(layer, pts, col)


func text(layer: Node, pos: Vector2, s: String, font_size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = s
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	layer.add_child(l)
	return l


func add_interactable(d: Dictionary) -> void:
	d.merge({reach = REACH, lines = [], id = "", requires = "", locked_text = "It's locked."})
	interactables.append(d)


func door(cx: float, target_area: String, spawn_x: float, col := Color("6b4226"),
		requires := "", locked_text := "It's locked.") -> void:
	var F := Areas.FLOOR_Y
	rect(bld, cx - 28, F - 92, 56, 92, col.darkened(0.35))
	rect(bld, cx - 23, F - 87, 46, 87, col)
	circle(bld, Vector2(cx + 13, F - 42), 3.5, Color("e8c547"))
	add_interactable({kind = "door", x = cx, top = F - 92, verb = "Enter",
		target = target_area, spawn_x = spawn_x, requires = requires, locked_text = locked_text})


func npc(x: float, id: String, body_col: Color, skin: Color, hair: Color,
		facing := -1, layer: Node = null, verb := "Talk") -> void:
	var L: Node = layer if layer else act
	var F := Areas.FLOOR_Y
	rect(L, x - 11, F - 34, 9, 34, body_col.darkened(0.45))
	rect(L, x + 2, F - 34, 9, 34, body_col.darkened(0.45))
	rect(L, x - 16, F - 78, 32, 46, body_col)
	circle(L, Vector2(x, F - 94), 17, skin)
	rect(L, x - 17, F - 112, 34, 10, hair)
	circle(L, Vector2(x + 7 * facing, F - 96), 3, Color.BLACK)
	add_interactable({kind = "npc", id = id, x = x, top = F - 115, verb = verb})
