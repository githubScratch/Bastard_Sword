shader_type canvas_item;

uniform float desaturation_amount : hint_range(0.0, 1.0) = 1.5;

void fragment() {
	vec4 color = texture(TEXTURE, UV);

	// Calculate grayscale value using luminance
	float gray = dot(color.rgb, vec3(0.3, 0.59, 0.11));

	// Mix between the original color and grayscale based on desaturation amount
	color.rgb = mix(color.rgb, vec3(gray), desaturation_amount);

	// Set the output color
	COLOR = color;
}
