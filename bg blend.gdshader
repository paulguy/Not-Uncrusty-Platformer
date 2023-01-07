shader_type canvas_item;
render_mode blend_disabled;

void fragment() {
	COLOR = COLOR - (texture(SCREEN_TEXTURE, SCREEN_UV) * 0.15);
}
