// Repeating flat-color tile pattern (bricks, stripes, stones, planks).
// Put on a ColorRect; the pattern is measured in the rect's local pixels,
// so resizing the rect extends the pattern instead of stretching it.
shader_type canvas_item;

// Color between tiles (mortar, seams, wallpaper background).
uniform vec4 base_color : source_color = vec4(0.29, 0.29, 0.35, 1.0);
uniform vec4 tile_color : source_color = vec4(0.33, 0.33, 0.42, 1.0);
// Size of one repeat cell, tile + gap, in pixels.
uniform vec2 cell_size = vec2(80.0, 30.0);
// Space between neighbouring tiles, in pixels.
uniform vec2 gap = vec2(4.0, 4.0);
// Horizontal shift per row as a fraction of cell width (0.5 = brick bond).
uniform float row_shift : hint_range(0.0, 1.0) = 0.5;
// Moves the whole pattern, in pixels.
uniform vec2 offset = vec2(0.0);

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec2 p = local_pos - offset;
	float row = floor(p.y / cell_size.y);
	p.x += row * row_shift * cell_size.x;
	vec2 c = mod(p, cell_size);
	vec2 half_gap = gap * 0.5;
	bool in_tile = all(greaterThanEqual(c, half_gap)) && all(lessThan(c, cell_size - half_gap));
	COLOR = in_tile ? tile_color : base_color;
}
