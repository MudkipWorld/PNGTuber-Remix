shader_type canvas_item;

uniform vec4 line_color = vec4(1);
uniform float line_thickness = 1.0;
uniform float frequency = 10.0;
uniform float phase_speed = 1.0;

uniform vec4 base_line_color = vec4(0);

uniform bool wiggle;
uniform float rotation = 0.0;
uniform vec2 rotation_offset = vec2(0.5, 0.5);

varying vec2 rot_uv;
uniform sampler2D text : hint_default_black;


void fragment() {
	if (wiggle){
		float rotation_anchored = rotation * (1.0 - UV.y);
		mat2 rotation_mat = mat2(vec2(cos(rotation_anchored), sin(rotation_anchored)),
		vec2(-sin(rotation_anchored), cos(rotation_anchored)));
		vec2 centered_uv = UV - rotation_offset;
		vec2 rotated_uv = centered_uv * rotation_mat;
		rotated_uv = rotated_uv + rotation_offset;

		rot_uv = rotated_uv;
	}
	else {

		rot_uv = UV;
	}

	vec2 text_size = vec2(textureSize(text,0));

	vec2 size = vec2(1.0/text_size.x, 1.0/text_size.y) * line_thickness;

	float outline = texture(text, rot_uv + vec2(-size.x, 0)).a;
	outline += texture(text, rot_uv + vec2(0, size.y)).a;
	outline += texture(text, rot_uv + vec2(size.x, 0)).a;
	outline += texture(text, rot_uv + vec2(0, -size.y)).a;
	outline += texture(text, rot_uv + vec2(-size.x, size.y)).a;
	outline += texture(text, rot_uv + vec2(-size.x, size.y * 0.5)).a;
	outline += texture(text, rot_uv + vec2(size.x, size.y)).a;
	outline += texture(text, rot_uv + vec2(size.x, size.y * 0.5)).a;
	outline += texture(text, rot_uv + vec2(-size.x, -size.y)).a;
	outline += texture(text, rot_uv + vec2(-size.x, -size.y * 0.5)).a;
	outline += texture(text, rot_uv + vec2(size.x, -size.y)).a;
	outline += texture(text, rot_uv + vec2(size.x, -size.y * 0.5)).a;
//	outline = round(min(outline, 1.0));
	float mul = round(texture(text, rot_uv).a);
	 if (outline > 0.5) {
		vec2 pos = rot_uv - vec2(0.5);
		float angle = atan(pos.y, pos.x);
		if (angle < 0.0) {
		angle += 2.0 * PI;
		}
		float ring = step(0.0, sin(frequency * angle + TIME * phase_speed));
		vec4 t = mix(base_line_color, line_color, ring * line_color.a) - texture(text, rot_uv);
		vec4 v = t + t;
		COLOR = v ;
	}
}