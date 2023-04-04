shader_type canvas_item;
render_mode blend_disabled;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	COLOR = COLOR - (texture(SCREEN_TEXTURE, SCREEN_UV) * 0.15);
}
