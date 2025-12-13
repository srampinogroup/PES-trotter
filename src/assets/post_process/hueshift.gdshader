shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap; 
uniform bool rotate_hue;
uniform bool swap_hue;

void fragment() {
	vec4 px = texture(SCREEN_TEXTURE, SCREEN_UV);
	
	if (rotate_hue)
		px = px.gbra;
	
	if (swap_hue)
		px = px.rbga;
		
	COLOR = px;
}