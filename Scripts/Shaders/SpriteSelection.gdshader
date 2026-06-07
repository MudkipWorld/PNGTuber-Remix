shader_type canvas_item;

uniform vec4 line_color = vec4(1); // Outline color
uniform float line_thickness = 1.0; // Thickness of the outline
uniform float frequency = 10.0; // Marching ants frequency
uniform float phase_speed = 1.0; // Speed of marching ants effect

uniform vec4 base_line_color = vec4(0); // Base color of outline
uniform bool wiggle;
uniform float rotation = 0.0;
uniform vec2 rotation_offset = vec2(0.5, 0.5);
uniform bool add_margins = true;

uniform float alpha_threshold = 0.1; // Minimum alpha to detect an edge

varying vec2 rot_uv;

void fragment() {
    COLOR.a = 0.0;

    if (wiggle) {
        float rotation_anchored = rotation * (1.0 - UV.y);
        mat2 rotation_mat = mat2(vec2(cos(rotation_anchored), sin(rotation_anchored)),
                                 vec2(-sin(rotation_anchored), cos(rotation_anchored)));
        vec2 centered_uv = UV - rotation_offset;
        vec2 rotated_uv = centered_uv * rotation_mat;
        rot_uv = rotated_uv + rotation_offset;
    } else {
        rot_uv = UV;
    }

    vec2 text_size = vec2(textureSize(TEXTURE, 0));
    vec2 size = vec2(1.0 / text_size.x, 1.0 / text_size.y) * line_thickness;

    // Improved outline detection using alpha threshold
    float outline = 0.0;
    outline += step(alpha_threshold, texture(TEXTURE, rot_uv + vec2(-size.x, 0)).a);
    outline += step(alpha_threshold, texture(TEXTURE, rot_uv + vec2(0, size.y)).a);
    outline += step(alpha_threshold, texture(TEXTURE, rot_uv + vec2(size.x, 0)).a);
    outline += step(alpha_threshold, texture(TEXTURE, rot_uv + vec2(0, -size.y)).a);
    outline += step(alpha_threshold, texture(TEXTURE, rot_uv + vec2(-size.x, size.y)).a);
    outline += step(alpha_threshold, texture(TEXTURE, rot_uv + vec2(-size.x, size.y * 0.5)).a);
    outline += step(alpha_threshold, texture(TEXTURE, rot_uv + vec2(size.x, size.y)).a);
    outline += step(alpha_threshold, texture(TEXTURE, rot_uv + vec2(size.x, size.y * 0.5)).a);
    outline += step(alpha_threshold, texture(TEXTURE, rot_uv + vec2(-size.x, -size.y)).a);
    outline += step(alpha_threshold, texture(TEXTURE, rot_uv + vec2(-size.x, -size.y * 0.5)).a);
    outline += step(alpha_threshold, texture(TEXTURE, rot_uv + vec2(size.x, -size.y)).a);
    outline += step(alpha_threshold, texture(TEXTURE, rot_uv + vec2(size.x, -size.y * 0.5)).a);

    if (outline > 0.5 && texture(TEXTURE, rot_uv).a < alpha_threshold) {
        vec2 pos = rot_uv - vec2(0.5);
        float angle = atan(pos.y, pos.x);
        if (angle < 0.0) {
            angle += 2.0 * PI;
        }
        float ring = step(0.0, sin(frequency * angle + TIME * phase_speed));

        COLOR = mix(base_line_color, line_color, ring * line_color.a);
    }
}
