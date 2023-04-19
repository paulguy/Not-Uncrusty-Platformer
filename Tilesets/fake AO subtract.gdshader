shader_type canvas_item;
render_mode blend_mix;

void fragment() {
	COLOR = vec4(1.0, 1.0, 1.0, COLOR.r);
}
