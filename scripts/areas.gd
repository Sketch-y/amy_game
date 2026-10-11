extends RefCounted
## Area definitions. Each builder fills main's four layers with flat shapes
## (m.bg, m.bld, m.dec, m.flr), registers interactables, and returns the area width.

const VIEW_W := 960.0
const VIEW_H := 540.0
const FLOOR_Y := 440.0


static func title(id: String) -> String:
	match id:
		"home": return "Amy's House"
		"town": return "Maple Town"
		"shop": return "Pip's Provisions"
		"tower": return "Old Tower"
	return id


static func build(m, id: String) -> float:
	match id:
		"home": return _home(m)
		"town": return _town(m)
		"shop": return _shop(m)
		"tower": return _tower(m)
	push_error("Unknown area: " + id)
	return VIEW_W


# ================================================================ town

static func _town(m) -> float:
	var W := 3200.0
	var F := FLOOR_Y
	var bw: float = m.bg_width(W)

	# --- background: sky, sun, clouds, mountains, hills
	m.rect(m.bg, -20, 0, bw + 40, VIEW_H, Color("8fd0f2"))
	m.rect(m.bg, -20, 230, bw + 40, 210, Color("b5e2f7"))
	m.circle(m.bg, Vector2(700, 95), 42, Color("ffe38a"))
	for i in range(int(bw / 380.0) + 1):
		_cloud(m, Vector2(120 + i * 380, 70 + (i % 3) * 35))
	var x := -100.0
	var i := 0
	while x < bw:
		var h := 150.0 + float((i * 53) % 110)
		var apex := Vector2(x + 190, F - h)
		m.poly(m.bg, [Vector2(x, F), apex, Vector2(x + 380, F)], Color("8aa6cf"))
		m.poly(m.bg, [apex, apex + Vector2(-42, h * 0.22), apex + Vector2(42, h * 0.22)], Color("eef4fb"))
		x += 260.0
		i += 1
	x = -80.0
	while x < bw + 200:
		m.circle(m.bg, Vector2(x, F + 70), 170, Color("86c47f"), 32)
		x += 290.0

	# --- buildings
	_house(m, 180, 260, 220, Color("e8a87c"), Color("b5523b"), {target = "home", spawn = 80})
	m.text(m.bld, Vector2(255, F - 214), "HOME", 20, Color("5a2a1a"))
	_house(m, 520, 200, 170, Color("c9d6a3"), Color("6d8a4f"))
	_house(m, 880, 340, 200, Color("f1e3b3"), Color("4f7cac"), {target = "shop", spawn = 80})
	for s in 8:  # striped awning
		m.rect(m.bld, 960 + s * 22.5, F - 118, 22.5, 20, Color("d9534f") if s % 2 == 0 else Color("fafafa"))
	m.text(m.bld, Vector2(980, F - 194), "PIP'S PROVISIONS", 20, Color("2c3e50"))
	_house(m, 1400, 260, 280, Color("b8a1d9"), Color("5d4a87"))
	_house(m, 1940, 220, 190, Color("f2b8c6"), Color("a34a6a"))
	_house(m, 2340, 180, 150, Color("a7d3d0"), Color("3e7c78"))
	_tower_building(m, 2600, 220, 380)

	# --- decor
	_sign(m, 90, ["Welcome to Maple Town!", "Population: 6, plus one very aloof cat."])
	_mailbox(m, 470)
	_tree(m, 760, 1.0)
	_lamp(m, 1250)
	_bush(m, 1700)
	_fence(m, 1680, 1900)
	_bench(m, 1830)
	_lamp(m, 1920)
	_well(m, 2250)
	_bush(m, 2560)
	_tree(m, 2920, 1.2)
	_lamp(m, 2860)
	_tree(m, 3040, 0.9)
	_sign(m, 3130, ["EAST ROAD — CLOSED", "Washed out by the spring rains. Sorry!"])

	# --- npcs
	_cat(m, 1320)
	m.npc(1770, "elder", Color("7a6a55"), Color("eac7a5"), Color("dddddd"))
	m.rect(m.act, 1758, F - 90, 24, 16, Color("eeeeee"))  # beard
	m.rect(m.act, 1746, F - 62, 4, 62, Color("5a3a22"))  # cane

	_floor_stones(m, W, Color("a59f93"), Color("958f84"), Color("7d776d"))
	return W


static func _house(m, x: float, w: float, h: float, wall: Color, roof: Color, door := {}) -> void:
	var F := FLOOR_Y
	m.rect(m.bld, x, F - h, w, h, wall)
	m.poly(m.bld, [Vector2(x - 16, F - h), Vector2(x + w / 2, F - h - 70), Vector2(x + w + 16, F - h)], roof)
	var y := F - h + 28
	while y + 50 < F - 100:
		_window(m, x + 24, y)
		_window(m, x + w - 64, y)
		y += 70
	if not door.is_empty():
		m.door(x + w / 2, door.target, door.spawn, Color("6b4226"), door.get("requires", ""), door.get("locked", ""))


static func _window(m, x: float, y: float) -> void:
	m.rect(m.bld, x, y, 40, 46, Color("5c4033"))
	m.rect(m.bld, x + 4, y + 4, 32, 38, Color("fff3b0"))
	m.rect(m.bld, x + 18, y + 4, 4, 38, Color("5c4033"))


static func _tower_building(m, x: float, w: float, h: float) -> void:
	var F := FLOOR_Y
	var stone := Color("8c8c99")
	m.rect(m.bld, x, F - h, w, h, stone)
	for c in 5:  # crenellations
		m.rect(m.bld, x + c * (w / 4.5), F - h - 24, w / 9.0, 24, stone)
	for r in 4:
		m.rect(m.bld, x + w / 2 - 9, F - h + 40 + r * 70, 18, 38, Color("2e2e3a"))
	m.door(x + w / 2, "tower", 80, Color("4a3020"), "Brass Key",
		"A heavy door with a brass keyhole. It won't budge.")


# ================================================================ home

static func _home(m) -> float:
	var W := 1100.0
	var F := FLOOR_Y
	var bw: float = m.bg_width(W)
	# background: wallpaper
	m.rect(m.bg, -20, 0, bw + 40, VIEW_H, Color("f3dcc2"))
	var x := 0.0
	while x < bw:
		m.rect(m.bg, x, 0, 14, VIEW_H, Color("ebcca9"))
		x += 44.0
	# buildings: wainscot, window, fireplace, bookshelf
	_wainscot(m, W, Color("c99a6e"))
	m.rect(m.bld, 330, 140, 150, 130, Color("8b5a2b"))
	m.rect(m.bld, 338, 148, 134, 114, Color("9ad4f5"))
	m.rect(m.bld, 402, 148, 6, 114, Color("8b5a2b"))
	m.rect(m.bld, 338, 202, 134, 6, Color("8b5a2b"))
	m.rect(m.bld, 600, F - 170, 150, 170, Color("9a948c"))
	m.rect(m.bld, 588, F - 180, 174, 14, Color("7d776f"))
	m.rect(m.bld, 630, F - 90, 90, 90, Color("2b2220"))
	m.circle(m.bld, Vector2(675, F - 18), 24, Color("f08a24"))
	m.circle(m.bld, Vector2(675, F - 14), 13, Color("ffd34d"))
	_bookshelf(m, 870, 220)
	m.door(80, "town", 310)
	# decor: bed, plant, rug-ish mat, picture
	m.rect(m.dec, 300, F - 50, 200, 30, Color("8b5a2b"))
	m.rect(m.dec, 300, F - 20, 10, 20, Color("6e4420"))
	m.rect(m.dec, 490, F - 20, 10, 20, Color("6e4420"))
	m.rect(m.dec, 300, F - 90, 14, 70, Color("8b5a2b"))
	m.rect(m.dec, 314, F - 66, 50, 18, Color("ffffff"))
	m.rect(m.dec, 360, F - 66, 140, 22, Color("6fa8dc"))
	_plant(m, 800)
	m.rect(m.dec, 180, 170, 70, 56, Color("8b5a2b"))
	m.rect(m.dec, 186, 176, 58, 44, Color("a3d9a5"))
	m.circle(m.dec, Vector2(215, 204), 10, Color("f6c85f"))
	m.add_interactable({kind = "flavor", x = 400, top = F - 100, verb = "Look",
		lines = ["Your bed. Still a little warm."]})
	m.add_interactable({kind = "flavor", x = 675, top = F - 190, verb = "Look",
		lines = ["The fire crackles cheerfully."]})
	m.add_interactable({kind = "flavor", x = 925, top = F - 230, verb = "Read",
		lines = ["A book: 'Flat Shapes & Bold Colors'.", "A timeless classic."]})
	m.npc(220, "mom", Color("5fa86e"), Color("f2c9a0"), Color("8a4b2a"), 1)
	m.rect(m.act, 206, F - 66, 28, 32, Color("f5f0e6"))  # apron
	_floor_planks(m, W, Color("b07a4a"), Color("8f5f36"))
	return W


# ================================================================ shop

static func _shop(m) -> float:
	var W := 1300.0
	var F := FLOOR_Y
	var bw: float = m.bg_width(W)
	m.rect(m.bg, -20, 0, bw + 40, VIEW_H, Color("dff0d8"))
	var x := 0.0
	while x < bw:
		m.rect(m.bg, x, 0, 20, VIEW_H, Color("cfe6c6"))
		x += 60.0
	_wainscot(m, W, Color("7a9a6a"))
	m.text(m.bld, Vector2(520, 70), "PIP'S PROVISIONS", 32, Color("2f4f2f"))
	# shelves with jars
	var jar_cols := [Color("e05a5a"), Color("f2a541"), Color("7cc576"), Color("8e7cc3"), Color("f6d55c")]
	for s in 2:
		var sx := 260.0 + s * 520.0
		for row in 3:
			var sy := 150.0 + row * 70.0
			m.rect(m.bld, sx, sy + 46, 300, 8, Color("8b5a2b"))
			for j in 7:
				m.rect(m.bld, sx + 12 + j * 41, sy + 14, 26, 32, jar_cols[(j + row + s) % jar_cols.size()])
				m.rect(m.bld, sx + 10 + j * 41, sy + 8, 30, 8, Color("ddd7c8"))
	m.door(80, "town", 1050)
	# decor: shopkeeper behind counter, barrels, crates, plant
	_plant(m, 200)
	m.npc(650, "shopkeeper", Color("e3a33d"), Color("d9a77c"), Color("2b2b2b"), -1, m.dec)
	m.rect(m.dec, 630, F - 132, 40, 16, Color("ffffff"))  # chef-ish hat
	m.rect(m.dec, 520, F - 64, 280, 64, Color("8b5a2b"))
	m.rect(m.dec, 510, F - 72, 300, 12, Color("a46c38"))
	m.rect(m.dec, 560, F - 92, 30, 20, Color("e05a5a"))  # apples on counter
	m.circle(m.dec, Vector2(740, F - 82), 10, Color("d64545"))
	m.circle(m.dec, Vector2(758, F - 82), 10, Color("7cc576"))
	for b in 2:
		m.rect(m.dec, 1020 + b * 70, F - 70, 56, 70, Color("9a6a3a"))
		m.rect(m.dec, 1020 + b * 70, F - 50, 56, 6, Color("5a3a1a"))
		m.rect(m.dec, 1020 + b * 70, F - 24, 56, 6, Color("5a3a1a"))
	m.rect(m.dec, 1180, F - 50, 60, 50, Color("c49a6c"))
	m.rect(m.dec, 1190, F - 90, 40, 40, Color("b08656"))
	m.add_interactable({kind = "flavor", x = 410, top = F - 300, verb = "Look",
		lines = ["Jars of jam in every color imaginable.", "...and a few unimaginable ones."]})
	m.add_interactable({kind = "flavor", x = 1090, top = F - 80, verb = "Look",
		lines = ["Barrels of pickles. So many pickles."]})
	_floor_planks(m, W, Color("c9a27a"), Color("a37f58"))
	return W


# ================================================================ tower

static func _tower(m) -> float:
	var W := 1000.0
	var F := FLOOR_Y
	var bw: float = m.bg_width(W)
	# background: brick wall
	m.rect(m.bg, -20, 0, bw + 40, VIEW_H, Color("4a4a58"))
	for row in range(int(VIEW_H / 30.0)):
		var off := 0.0 if row % 2 == 0 else 40.0
		var x := -40.0 + off
		while x < bw + 40:
			m.rect(m.bg, x + 2, row * 30 + 2, 76, 26, Color("55556a"))
			x += 80.0
	# buildings: pillars and arched windows
	for p in 3:
		var px := 260.0 + p * 240.0
		m.rect(m.bld, px - 22, 60, 44, F - 60, Color("6d6d80"))
		m.rect(m.bld, px - 32, 50, 64, 18, Color("7f7f94"))
		if p < 2:
			m.rect(m.bld, px + 90, 110, 60, 110, Color("1d2340"))
			m.circle(m.bld, Vector2(px + 120, 110), 30, Color("1d2340"))
			m.circle(m.bld, Vector2(px + 108, 150), 3, Color("ffffff"))
	m.door(80, "town", 2710, Color("4a3020"))
	# decor: torches, pedestal + chest
	for p in 3:
		_torch(m, 260.0 + p * 240.0)
	var cx := 860.0
	m.rect(m.dec, cx - 60, F - 30, 120, 30, Color("6e6e7a"))
	m.rect(m.dec, cx - 40, F - 80, 80, 50, Color("8b5a2b"))
	var lid = m.rect(m.dec, cx - 44, F - 100, 88, 22, Color("a0522d"))
	m.rect(m.dec, cx - 6, F - 84, 12, 14, Color("e8c547"))
	m.add_interactable({kind = "chest", x = cx, top = F - 110, verb = "Open", lid = lid})
	if m.flags.has("won"):
		lid.color = Color("5a3418")
	_floor_stones(m, W, Color("5e5e6e"), Color("53536a"), Color("3e3e4e"))
	return W


static func gem(m, x: float) -> void:
	var y := FLOOR_Y - 140
	m.poly(m.dec, [Vector2(x, y - 22), Vector2(x + 18, y), Vector2(x, y + 22), Vector2(x - 18, y)], Color("7fe3ff"))
	m.poly(m.dec, [Vector2(x, y - 12), Vector2(x + 8, y), Vector2(x, y + 12), Vector2(x - 8, y)], Color("e8fbff"))


# ================================================================ shared pieces

static func _floor_stones(m, W: float, base: Color, alt: Color, edge: Color) -> void:
	var F := FLOOR_Y
	m.rect(m.flr, 0, F, W, VIEW_H - F, base)
	var x := 0.0
	var k := 0
	while x < W:
		m.rect(m.flr, x + 3, F + (16 if k % 2 == 0 else 50), 58, 28, alt)
		x += 64.0
		k += 1
	m.rect(m.flr, 0, F, W, 8, edge)


static func _floor_planks(m, W: float, base: Color, seam: Color) -> void:
	var F := FLOOR_Y
	m.rect(m.flr, 0, F, W, VIEW_H - F, base)
	for row in 4:
		var y := F + row * 25.0
		m.rect(m.flr, 0, y, W, 2, seam)
		var x := float(row * 70)
		while x < W:
			m.rect(m.flr, x, y, 3, 25, seam)
			x += 210.0
	m.rect(m.flr, 0, F, W, 6, seam.darkened(0.3))


static func _wainscot(m, W: float, col: Color) -> void:
	m.rect(m.bld, 0, FLOOR_Y - 70, W, 70, col)
	m.rect(m.bld, 0, FLOOR_Y - 76, W, 8, col.darkened(0.25))


static func _cloud(m, c: Vector2) -> void:
	var white := Color(1, 1, 1, 0.9)
	m.circle(m.bg, c, 26, white)
	m.circle(m.bg, c + Vector2(30, 6), 20, white)
	m.circle(m.bg, c + Vector2(-30, 8), 18, white)


static func _tree(m, x: float, s: float) -> void:
	var F := FLOOR_Y
	m.rect(m.dec, x - 10 * s, F - 100 * s, 20 * s, 100 * s, Color("7a4e2d"))
	m.circle(m.dec, Vector2(x - 36 * s, F - 110 * s), 38 * s, Color("3f8f4a"))
	m.circle(m.dec, Vector2(x + 36 * s, F - 110 * s), 38 * s, Color("3f8f4a"))
	m.circle(m.dec, Vector2(x, F - 145 * s), 50 * s, Color("4ea85a"))


static func _bush(m, x: float) -> void:
	var F := FLOOR_Y
	m.circle(m.dec, Vector2(x - 20, F - 16), 22, Color("4f9d4f"))
	m.circle(m.dec, Vector2(x + 18, F - 14), 20, Color("4f9d4f"))
	m.circle(m.dec, Vector2(x, F - 28), 24, Color("5cb85c"))


static func _lamp(m, x: float) -> void:
	var F := FLOOR_Y
	m.rect(m.dec, x - 3, F - 150, 6, 150, Color("333a44"))
	m.rect(m.dec, x - 12, F - 172, 24, 6, Color("333a44"))
	m.circle(m.dec, Vector2(x, F - 156), 11, Color("ffe9a0"))


static func _fence(m, x0: float, x1: float) -> void:
	var F := FLOOR_Y
	var col := Color("f2efe6")
	m.rect(m.dec, x0, F - 40, x1 - x0, 6, col)
	m.rect(m.dec, x0, F - 20, x1 - x0, 6, col)
	var x := x0
	while x <= x1:
		m.rect(m.dec, x - 4, F - 50, 8, 50, col)
		x += 28.0


static func _bench(m, x: float) -> void:
	var F := FLOOR_Y
	var wood := Color("9c6b3c")
	m.rect(m.dec, x - 40, F - 30, 80, 8, wood)
	m.rect(m.dec, x - 40, F - 52, 80, 8, wood)
	m.rect(m.dec, x - 36, F - 30, 6, 30, Color("444444"))
	m.rect(m.dec, x + 30, F - 30, 6, 30, Color("444444"))


static func _well(m, x: float) -> void:
	var F := FLOOR_Y
	m.rect(m.dec, x - 45, F - 50, 90, 50, Color("9a9aa6"))
	m.rect(m.dec, x - 50, F - 56, 100, 10, Color("80808c"))
	m.rect(m.dec, x - 42, F - 130, 6, 76, Color("7a4e2d"))
	m.rect(m.dec, x + 36, F - 130, 6, 76, Color("7a4e2d"))
	m.poly(m.dec, [Vector2(x - 60, F - 126), Vector2(x, F - 166), Vector2(x + 60, F - 126)], Color("b5523b"))
	m.rect(m.dec, x - 8, F - 100, 16, 18, Color("6b6b6b"))
	m.add_interactable({kind = "flavor", x = x, top = F - 170, verb = "Look",
		lines = ["You drop a pebble into the well.", "...", "Plunk."]})


static func _sign(m, x: float, lines: Array) -> void:
	var F := FLOOR_Y
	m.rect(m.dec, x - 4, F - 70, 8, 70, Color("7a4e2d"))
	m.rect(m.dec, x - 34, F - 92, 68, 36, Color("c8955a"))
	m.rect(m.dec, x - 26, F - 82, 52, 4, Color("7a4e2d"))
	m.rect(m.dec, x - 26, F - 72, 40, 4, Color("7a4e2d"))
	m.add_interactable({kind = "sign", x = x, top = F - 96, verb = "Read", lines = lines})


static func _mailbox(m, x: float) -> void:
	var F := FLOOR_Y
	m.rect(m.dec, x - 3, F - 60, 6, 60, Color("555555"))
	m.rect(m.dec, x - 18, F - 80, 36, 22, Color("3b6fb6"))
	m.rect(m.dec, x + 14, F - 92, 4, 14, Color("d9534f"))


static func _plant(m, x: float) -> void:
	var F := FLOOR_Y
	m.poly(m.dec, [Vector2(x - 20, F - 40), Vector2(x + 20, F - 40), Vector2(x + 14, F), Vector2(x - 14, F)], Color("c0663a"))
	m.circle(m.dec, Vector2(x, F - 60), 24, Color("4ea85a"))
	m.circle(m.dec, Vector2(x - 16, F - 50), 14, Color("3f8f4a"))
	m.circle(m.dec, Vector2(x + 16, F - 50), 14, Color("3f8f4a"))


static func _bookshelf(m, x: float, h: float) -> void:
	var F := FLOOR_Y
	m.rect(m.bld, x, F - h, 110, h, Color("6e4420"))
	var book_cols := [Color("d9534f"), Color("5bc0de"), Color("f0ad4e"), Color("5cb85c"), Color("8e7cc3")]
	for row in 4:
		var y := F - h + 12 + row * 52
		m.rect(m.bld, x + 6, y + 40, 98, 6, Color("4e2e14"))
		for b in 6:
			m.rect(m.bld, x + 10 + b * 15, y + 6 + (b % 3) * 3, 12, 34 - (b % 3) * 3, book_cols[(b + row) % book_cols.size()])


static func _torch(m, x: float) -> void:
	var y := 220.0
	m.rect(m.dec, x - 4, y, 8, 34, Color("5a3a22"))
	m.circle(m.dec, Vector2(x, y - 8), 12, Color("f08a24"))
	m.circle(m.dec, Vector2(x, y - 5), 6, Color("ffd34d"))


static func _cat(m, x: float) -> void:
	var F := FLOOR_Y
	var fur := Color("3a3a44")
	m.rect(m.act, x - 22, F - 26, 44, 20, fur)
	m.rect(m.act, x - 20, F - 8, 6, 8, fur)
	m.rect(m.act, x + 12, F - 8, 6, 8, fur)
	m.rect(m.act, x - 36, F - 44, 6, 26, fur)  # tail
	m.circle(m.act, Vector2(x + 24, F - 32), 12, fur)
	m.poly(m.act, [Vector2(x + 14, F - 38), Vector2(x + 16, F - 52), Vector2(x + 24, F - 42)], fur)
	m.poly(m.act, [Vector2(x + 24, F - 42), Vector2(x + 32, F - 52), Vector2(x + 34, F - 38)], fur)
	m.circle(m.act, Vector2(x + 29, F - 34), 2.5, Color("c6f25a"))
	m.add_interactable({kind = "npc", id = "cat", x = x, top = F - 60, verb = "Pet"})
