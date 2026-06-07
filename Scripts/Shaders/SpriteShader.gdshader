shader_type canvas_item;
//render_mode blend_premul_alpha;
uniform bool enabled;

uniform sampler2D Blend;
uniform float Intensity : hint_range(0, 1) = 1.0;  //Default should be 1 but syntax doesn't allow it currently?

uniform bool wiggle;
uniform float rotation = 0.0;
uniform vec2 rotation_offset = vec2(0.5, 0.5);

varying vec4 modulate;
varying vec2 rot_uv;

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
}