shader_type canvas_item;

uniform sampler2D mask_sampler;
uniform vec2 mask_offset = vec2(0,0);


void fragment() {
	ivec2 orig_size = textureSize(TEXTURE,0);
	ivec2 mask_size = textureSize(mask_sampler,0);
	vec2 orig_size_to_mask_size_ratio = vec2(orig_size)/vec2(mask_size);
	vec2 mask_offset_pixel_converted = mask_offset * TEXTURE_PIXEL_SIZE * orig_size_to_mask_size_ratio * -1.0;
	vec4 mask_color = texture(mask_sampler, UV * orig_size_to_mask_size_ratio + mask_offset_pixel_converted);
	vec4 orig_color = texture(TEXTURE, UV);
	float alpha = clamp(orig_color.a - mask_color.a, 0.0, 1.0);
	COLOR.a = alpha;
	COLOR.rgb = orig_color.rgb;
}