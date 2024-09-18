shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;
uniform bool enabled;


uniform bool selected = false;
uniform vec4 ant_color_1: source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 ant_color_2: source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float ant_width = 2.0;
uniform float ant_length = 10.0;
uniform float ant_speed = 30.0;



uniform sampler2D Blend;  //Blending mode texture
uniform float Intensity : hint_range(0, 1) = 1.0;  //Default should be 1 but syntax doesn't allow it currently?

uniform bool wiggle;
uniform float rotation = 0.0;
uniform vec2 rotation_offset = vec2(0.5, 0.5);

varying vec4 modulate;
varying vec2 rot_uv;

void vertex(){
	modulate = COLOR;

}


void fragment() {
	if (wiggle){
		float rotation_anchored = rotation * (1.0 - UV.y);
		mat2 rotation_mat = mat2(vec2(cos(rotation_anchored), sin(rotation_anchored)),
		vec2(-sin(rotation_anchored), cos(rotation_anchored)));
		vec2 centered_uv = UV - rotation_offset;
		vec2 rotated_uv = centered_uv * rotation_mat;
		rotated_uv = rotated_uv + rotation_offset;

		COLOR = texture(TEXTURE, rotated_uv)*modulate;
		rot_uv = rotated_uv;
	}

	if (enabled){
		vec4 bgColor;
		vec4 Color;
		if(wiggle) {

			Color = texture(TEXTURE, rot_uv);
			bgColor = texture(TEXTURE, UV);
		}
		else{
			Color = texture(TEXTURE, UV);
			bgColor = texture(TEXTURE, UV);
		}
		vec4 blendColor;
	   	vec4 output = vec4(1,1,1,1);



		blendColor = texture( Blend, vec2(bgColor.r, Color.r) );
		output.r = blendColor.r;
		blendColor = texture( Blend, vec2(bgColor.g, Color.g) );
		output.g = blendColor.g;
		blendColor = texture( Blend, vec2(bgColor.b, Color.b) );
		output.b = blendColor.b;

		output = mix(Color, output, Intensity)* modulate;

		// needs fix, uauauau
		COLOR.rgb = output.rgb;

	}
	
	
	if (selected){
	vec2 uv = UV;
	vec2 fw = fwidth(uv);
	float adjusted_ant_width = min(ant_width, min(0.5 / fw.x, 0.5 / fw.y));
	vec2 aw = fw * adjusted_ant_width;

	vec2 cond = (sign(abs(uv - 0.5) - 0.5 + aw) + 1.0) * 0.5 * ceil(((sign(uv.yx - aw.yx) + 1.0) * 0.5 * (sign(uv - 0.5) * vec2(0.5, -0.5) + 0.5) * 0.5 + (sign(1.0 - aw.yx - uv.yx) + 1.0) * 0.5 * (sign(uv - 0.5) * vec2(-0.5, 0.5)+ 0.5) * 0.5));
	float dir = dot(vec2(cond.y, -cond.x), sign(uv.yx - 0.5) * uv / aw);
	float ant_type = round(fract((dir * adjusted_ant_width + TIME * ant_speed) * 0.5 / ant_length));
	vec4 ant_color = mix(ant_color_1, ant_color_2, ant_type);
	COLOR += (cond.x + cond.y) * ant_color;

	}


}


