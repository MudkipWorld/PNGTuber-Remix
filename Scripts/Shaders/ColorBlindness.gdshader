shader_type canvas_item;
render_mode blend_premul_alpha;

// Color Vision Deficiency (CVD) Simulation Shader
// ------------------------------------------------
// This shader simulates different types of color blindness:
// Protanopia, Deuteranopia, Tritanopia and Achromatopsia.
//
// It supports two scientific models:
// - Brettel et al. (1997): Generally good implementation.
// - Viénot et al. (1999): Faster and behaves a bit better with extreme values.
//
// WARNING: Viénot 1999 is not accurate for tritanopia. Use Brettel 1997 instead.
//
// Usefull links and references:
// - https://daltonlens.org/colorblindness-simulator (online implementation)
// - https://daltonlens.org/opensource-cvd-simulation (explanation)
// - https://github.com/DaltonLens/libDaltonLens (my implementation based on this)
// - Brettel, H., Viénot, F., & Mollon, J. D. (1997). Computerized simulation of color appearance for dichromats. Journal of the Optical Society of America. A, Optics, Image Science, and Vision, 14(10), 2647–2655. https://doi.org/10.1364/josaa.14.002647
// - Viénot, F., Brettel, H., & Mollon, J. D. (1999). Digital video colourmaps for checking the legibility of displays by dichromats. Color Research & Application, 24(4), 243–252. https://vision.psychol.cam.ac.uk/jdmollon/papers/colourmaps.pdf
// - https://github.com/ubisoft/Chroma (solution for detecting color blindness-related issues in games, developed by Ubisoft)
// - https://www.itu.int/rec/R-REC-BT.601-7-201103-I (tough staff with standarts; there is a formula to calculate lightness from color)

// Uncomment one of the following define to use this algorithm:

 //#define PROTAN_BRETTEL   // Red-blindness (Brettel 1997)
 //#define DEUTAN_BRETTEL   // Green-blindness (Brettel 1997)
 //#define TRITAN_BRETTEL   // Blue-blindness (Brettel 1997)

 //#define PROTAN_VIENOT    // Red-blindness (Viénot 1999)
 //#define DEUTAN_VIENOT    // Green-blindness (Viénot 1999)
 //#define TRITAN_VIENOT    // Blue-blindness (Viénot 1999) — not accurate!

 //#define ACHROMATOPSIA    // Luminance from ITU-R BT.601

/** A severity of 1 means full protanopia/deuteranopia/tritanopia. */
uniform float severity: hint_range(0.0, 1.0) = 1.0;
uniform int effect : hint_range(0, 4, 1) = 0;



// Brettel Protanopia
const mat3 brettel_protan_1 = mat3(
    vec3(0.14980, 0.10764, 0.00384),
    vec3(1.19548, 0.84864, -0.00540),
    vec3(-0.34528, 0.04372, 1.00156)
);
const mat3 brettel_protan_2 = mat3(
    vec3(0.14570, 0.10816, 0.00386),
    vec3(1.16172, 0.85291, -0.00524),
    vec3(-0.30742, 0.03892, 1.00139)
);
const vec3 brettel_protan_plane_normal = vec3(0.00048, 0.00393, -0.00441);

// Brettel Deuteranopia
const mat3 brettel_deutan_1 = mat3(
    vec3(0.36477, 0.26294, -0.02006),
    vec3(0.86381, 0.64245, 0.02728),
    vec3(-0.22858, 0.09462, 0.99278)
);
const mat3 brettel_deutan_2 = mat3(
    vec3(0.37298, 0.25954, -0.01980),
    vec3(0.88166, 0.63506, 0.02784),
    vec3(-0.25464, 0.10540, 0.99196)
);
const vec3 brettel_deutan_plane_normal = vec3(-0.00281, -0.00611, 0.00892);

// Brettel Tritanopia
const mat3 brettel_tritan_1 = mat3(
    vec3(1.01277, -0.01243, 0.07589),
    vec3(0.13548,  0.86812, 0.80500),
    vec3(-0.14826, 0.14431, 0.11911)
);
const mat3 brettel_tritan_2 = mat3(
    vec3(0.93678, 0.06154, -0.37562),
    vec3(0.18979, 0.81526,  1.12767),
    vec3(-0.12657, 0.12320,  0.24796)
);
const vec3 brettel_tritan_plane_normal = vec3(0.03901, -0.02788, -0.01113);

// Vienot Protanopia
const mat3 vienot_protan = mat3(
	vec3(0.11238, 0.11238, 0.00401),
	vec3(0.88762, 0.88762, -0.00401),
	vec3(0.00000, -0.00000, 1.00000)
);

// Vienot Deuteranopia
const mat3 vienot_deutan = mat3(
	vec3(0.29275, 0.29275, -0.02234),
	vec3(0.70725, 0.70725,  0.02234),
	vec3(0.00000, -0.00000, 1.00000)
);

// Vienot Tritanopia
// WARNING: Viénot 1999 is not accurate for tritanopia. Use Brettel 1997 instead.
const mat3 vienot_tritan = mat3(
	vec3(1.00000, 0.00000, -0.00000),
	vec3(0.14461, 0.85924, 0.85924),
	vec3(-0.14461, 0.14076, 0.14076)
);

// This is Godot implementation, which I took from this issue:
// https://github.com/godotengine/godot-proposals/issues/9150
vec3 linear_to_srgb(vec3 color) {
	// If going to srgb, clamp from 0 to 1.
	color = clamp(color, vec3(0.0), vec3(1.0));
	const vec3 a = vec3(0.055f);
	return mix(
		(vec3(1.0f) + a) * pow(color.rgb, vec3(1.0f / 2.4f)) - a,
		12.92f * color.rgb,
		lessThan(color.rgb, vec3(0.0031308f))
	);
}
vec3 srgb_to_linear(vec3 color) {
	return mix(
		pow((color.rgb + vec3(0.055)) * (1.0 / (1.0 + 0.055)), vec3(2.4)),
		color.rgb * (1.0 / 12.92),
		lessThan(color.rgb, vec3(0.04045))
	);
}

vec3 apply_brettel_filter(vec3 color, mat3 m1, mat3 m2, vec3 plane_normal) {
	float d = dot(color, plane_normal);
	mat3 m = d >= 0.0 ? m1 : m2;
	return clamp(m * color, 0.0, 1.0);
}

vec3 apply_vienot_filter(vec3 color, mat3 m) {
	return m * color;
}

void fragment() {
	if (effect == 0){

		COLOR = texture(TEXTURE, UV);

	}
	else if (effect == 1){
		COLOR.rgb = vec3(0.299 * COLOR.r + 0.587 * COLOR.g + 0.114 * COLOR.b);
	}
	else if (effect == 2){
		vec3 lin_rgb = srgb_to_linear(COLOR.rgb);
		vec3 rgb_cvd = vienot_deutan * lin_rgb;
		COLOR.rgb = linear_to_srgb(rgb_cvd);
	}
	else if (effect == 3){
		vec3 lin_rgb = srgb_to_linear(COLOR.rgb);
		vec3 rgb_cvd = vienot_protan * lin_rgb;
		COLOR.rgb = linear_to_srgb(rgb_cvd);
	}
	else if (effect == 4){
		vec3 lin_rgb = srgb_to_linear(COLOR.rgb);

		float d = dot(lin_rgb, brettel_tritan_plane_normal);
		mat3 m = d >= 0.0 ? brettel_tritan_1 : brettel_tritan_2;
		vec3 rgb_cvd = clamp(m * lin_rgb, 0.0, 1.0);

		COLOR.rgb = linear_to_srgb(rgb_cvd);
	}
}