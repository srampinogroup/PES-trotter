shader_type spatial;
render_mode world_vertex_coords, cull_disabled;
uniform float y_min;
uniform float y_max;
uniform bool display_iso = false;
uniform float iso_scale = 1.0;
uniform vec3[100] pos_colors;
uniform vec3[100] neg_colors;
varying vec3 color;
varying float y;

const float BRIGHTNESS = 1.0;
const float ISO_THICKNESS = 0.05;
const float POS_ISO_BRIGHTNESS = 1.3;
const float NEG_ISO_BRIGHTNESS = 1.6;

int value_to_index(float value)
{
	return clamp(int(value * 100.0), 0, 99);
}

float get_iso_modifier()
{
	float modifier = 1.0;
	if (!display_iso)
		return modifier;

	float scaled_y = y / iso_scale;
	float decimal = scaled_y - floor(scaled_y);
	if (abs(decimal) * iso_scale < ISO_THICKNESS)
		modifier = y < 0.0 ? POS_ISO_BRIGHTNESS : NEG_ISO_BRIGHTNESS;

	return modifier;
}

void vertex()
{
	y = VERTEX.y;
}

void fragment()
{
	if (y_min >= 0.0 || y_max <= 0.0)
	{
		float height = y - y_min;
		float value = height / (y_max - y_min);
		int ix = value_to_index(value);
		color = (y_min >= 0.0 ? pos_colors[ix] : neg_colors[ix]) * BRIGHTNESS;
	}
	else if (y >= 0.0)
	{
		float value = y / y_max;
		int ix = value_to_index(value);
		color = pos_colors[ix] * BRIGHTNESS;
	}
	else
	{
		float value = y / y_min;
		int ix = value_to_index(value);
		color = neg_colors[ix] * BRIGHTNESS;
	}

	float modifier = get_iso_modifier();

	ALBEDO = color * modifier;
}