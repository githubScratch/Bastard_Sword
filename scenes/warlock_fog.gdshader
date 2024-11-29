shader_type canvas_item;

uniform float fog_strength : hint_range(0.0, 1.0) = 0.0; // Controls the fog intensity

void fragment() {
	vec2 uv = SCREEN_UV;
	float distance_from_center = length(uv - vec2(0.5));

	// Calculate darkness and fog based on distance from center
	float fog_factor = smoothstep(0.3, 1.0, distance_from_center); // Adjust these values for intensity
	COLOR = mix(COLOR, vec4(0.0, 0.0, 0.0, 1.0), fog_factor * fog_strength);
}
