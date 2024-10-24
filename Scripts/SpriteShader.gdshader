shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;
uniform bool enabled;

uniform vec4 line_color = vec4(1);
uniform float line_thickness = 1.0;
uniform float frequency = 10.0;
uniform float phase_speed = 1.0;

uniform vec4 base_line_color = vec4(0);



uniform sampler2D Blend;  //Blending mode texture
uniform float Intensity : hint_range(0, 1) = 1.0;  //Default should be 1 but syntax doesn't allow it currently?

uniform bool wiggle;
uniform float rotation = 0.0;
uniform vec2 rotation_offset = vec2(0.5, 0.5);

varying vec4 modulate;
varying vec2 rot_uv;

uniform bool marshing_ants = false;
varying vec3 output_1 ;

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
	else {

		rot_uv = UV;
	}

	if (enabled){
		vec4 bgColor;
		vec4 Color;
		if(wiggle) {

			Color = texture(TEXTURE, rot_uv);
			bgColor = texture(TEXTURE, rot_uv);
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
		output_1 = output.rgb;

	}
	else{

		output_1 = COLOR.rgb;

	}

	if (marshing_ants){
	vec2 text_size = vec2(textureSize(TEXTURE,0));

	vec2 size = vec2(1.0/text_size.x, 1.0/text_size.y) * line_thickness;

	float outline = texture(TEXTURE, rot_uv + vec2(-size.x, 0)).a;
	outline += texture(TEXTURE, rot_uv + vec2(0, size.y)).a;
	outline += texture(TEXTURE, rot_uv + vec2(size.x, 0)).a;
	outline += texture(TEXTURE, rot_uv + vec2(0, -size.y)).a;
	outline += texture(TEXTURE, rot_uv + vec2(-size.x, size.y)).a;
	outline += texture(TEXTURE, rot_uv + vec2(-size.x, size.y * 0.5)).a;
	outline += texture(TEXTURE, rot_uv + vec2(size.x, size.y)).a;
	outline += texture(TEXTURE, rot_uv + vec2(size.x, size.y * 0.5)).a;
	outline += texture(TEXTURE, rot_uv + vec2(-size.x, -size.y)).a;
	outline += texture(TEXTURE, rot_uv + vec2(-size.x, -size.y * 0.5)).a;
	outline += texture(TEXTURE, rot_uv + vec2(size.x, -size.y)).a;
	outline += texture(TEXTURE, rot_uv + vec2(size.x, -size.y * 0.5)).a;
	outline = round(min(outline, 1.0));
	float mul = round(texture(TEXTURE, rot_uv).a);
	if (mul > 0.5) {
		COLOR = texture(TEXTURE, rot_uv);
		COLOR.rgb = output_1;
	}else if (outline > 0.5) {
		vec2 pos = rot_uv - vec2(0.5);
		float angle = atan(pos.y, pos.x);
		if (angle < 0.0) {
		angle += 2.0 * PI;
		}
		float ring = step(0.0, sin(frequency * angle + TIME * phase_speed));
		vec4 t = mix(base_line_color, line_color, ring * line_color.a);
		COLOR.rgb = output_1;
		COLOR = t;

		}
	}

}