shader_type canvas_item;

uniform bool m_disable = false;
uniform float m_rotation = 0.0;
uniform vec2 m_position = vec2(0.0,0.0);
uniform vec2 m_viewport_size = vec2(1.0,1.0);
uniform vec2 m_scale = vec2(1.0,1.0);
uniform sampler2D m_mask_texture;
uniform vec2 m_mask_global = vec2(0.0, 0.0);
uniform vec2 m_parent_global = vec2(0.0, 0.0);
varying vec4 current_color;
uniform vec4 parent_color = vec4(0.0);
uniform bool has_shader_parent = false;


vec2 rotate_uv(vec2 puv, vec2 ppivot, float protation) {
    float vcosa = cos(protation);
    float vsina = sin(protation);
    puv -= ppivot;
    return vec2(
        vcosa * puv.x - vsina * puv.y,
        vsina * puv.x + vcosa * puv.y
    ) + ppivot;
}

vec2 scale_uv(vec2 p_uv, vec2 p_proportion, vec2 p_scale){
    p_uv -= vec2(0.5,0.5);
    p_uv /= p_proportion * p_scale;
    p_uv += vec2(0.5,0.5);
    return p_uv;
}

void fragment() {
    if (!m_disable) {
        // child texture
        vec4 child_col = texture(TEXTURE, UV);
        // parent texture lookup
        vec2 v_mask_uv = UV;
        vec2 v_masked_texture_size = vec2(textureSize(TEXTURE, 0));
        vec2 v_mask_texture_size = vec2(textureSize(m_mask_texture, 0));
        vec2 v_mask_to_parent_proportion = (v_mask_texture_size / v_masked_texture_size);
        vec2 pixel_offset = (m_parent_global - m_mask_global);
        vec2 uv_offset = pixel_offset / v_masked_texture_size;
        v_mask_uv -= uv_offset;
        v_mask_uv = rotate_uv(v_mask_uv, vec2(0.5,0.5), -m_rotation);
        v_mask_uv = scale_uv(v_mask_uv, v_mask_to_parent_proportion, m_scale);

        vec4 parent_col = texture(m_mask_texture, v_mask_uv);
		if (has_shader_parent){
			parent_col = parent_color;

		};

        // Masking: multiply child alpha by parent alpha
        child_col.a *= parent_col.a;

        COLOR = child_col;
		current_color =COLOR;
    }
	current_color = COLOR;
}
