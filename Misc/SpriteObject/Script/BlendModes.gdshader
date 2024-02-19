shader_type canvas_item;

uniform bool enabled;
uniform sampler2D image : hint_screen_texture, filter_linear_mipmap;

vec4 multiply(vec4 base, vec4 blend){
	return base * blend;
}

vec4 screen(vec4 base, vec4 blend){
	return 1.0 - (1.0 - base) * (1.0 - blend);
}

vec4 overlay(vec4 base, vec4 blend){
	vec4 limit = step(0.5, base);
	return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
}



void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 a = texture(TEXTURE, UV);
	vec4 b = textureLod(image, UV, 1);
	
	if(enabled){
		COLOR.rgb *= multiply(a, b).rgb;
	}
}

//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
