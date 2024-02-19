shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform bool enabled;
uniform sampler2D Blend;  //Blending mode texture
uniform float Intensity : hint_range(0, 1) = 1.0;  //Default should be 1 but syntax doesn't allow it currently?
uniform bool outline_enabled;

uniform float line_thickness : hint_range(0, 20) = 1.0;    // thickness of the line
uniform float sin_frequency : hint_range(0.1, 2.0) = 0.5;  // frequency of the rainbow
uniform float sin_offset : hint_range(0.0, 360.0) = 0.0;   // offset of the rainbow, useful to differentiate objects using the same shader
uniform float light_offset : hint_range(0.0, 1.0) = 0.5;   // this offsets all color channels; if set to 0 only red green and blue colors will be shown.


void fragment() {
	if (enabled){
		vec4 bgColor;
		vec4 Color = texture(TEXTURE, UV);
		vec4 blendColor;
	   	vec4 output = vec4(1,1,1,1);
	
		bgColor = texture( SCREEN_TEXTURE, SCREEN_UV);
	
		output.a = Color.a;
	
		blendColor = texture( Blend, vec2(bgColor.r, Color.r) );
		output.r = blendColor.r;
		blendColor = texture( Blend, vec2(bgColor.g, Color.g) );
		output.g = blendColor.g;
		blendColor = texture( Blend, vec2(bgColor.b, Color.b) );
		output.b = blendColor.b;
	
		output.rgb = mix(Color.rgb, output.rgb, Intensity);
		COLOR = output;
		
	} else {
		COLOR = texture(TEXTURE, UV);
	}
	
	if (outline_enabled){ 
		vec2 size = TEXTURE_PIXEL_SIZE * line_thickness;
		
		float outline = texture(TEXTURE, UV + vec2(-size.x, 0)).a;
		outline += texture(TEXTURE, UV + vec2(0, size.y)).a;
		outline += texture(TEXTURE, UV + vec2(size.x, 0)).a;
		outline += texture(TEXTURE, UV + vec2(0, -size.y)).a;
		outline += texture(TEXTURE, UV + vec2(-size.x, size.y)).a;
		outline += texture(TEXTURE, UV + vec2(size.x, size.y)).a;
		outline += texture(TEXTURE, UV + vec2(-size.x, -size.y)).a;
		outline += texture(TEXTURE, UV + vec2(size.x, -size.y)).a;
		outline = min(outline, 1.0);
		
		vec4 animated_line_color = vec4(light_offset + sin(2.0*3.14*sin_frequency*TIME),
								   light_offset + sin(2.0*3.14*sin_frequency*TIME + radians(120.0)),
								   light_offset + sin(2.0*3.14*sin_frequency*TIME + radians(240.0)),
								   1.0);
		
		vec4 color = texture(TEXTURE, UV);
		COLOR = mix(color, animated_line_color, outline - color.a);
	}

	
}