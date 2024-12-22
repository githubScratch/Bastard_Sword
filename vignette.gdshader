shader_type canvas_item;

render_mode blend_mix;

uniform float outerRadius : hint_range(0.0, 5.0) = 1.0;  // Radius of the vignette
uniform float MainAlpha : hint_range(0.0, 1.0) = 1.0;    // Overall opacity
uniform float RedTint : hint_range(0.0, 1.0) = 0.0;      // Red channel value

void fragment() {
    float x = abs(UV.x - 0.5) * 2.0;
    float y = abs(UV.y - 0.5) * 2.0;
    float v = (sqrt((x * x) + (y * y)) / outerRadius);

    // Use the RedTint uniform to set the red channel dynamically
    COLOR = vec4(RedTint, 0.0, 0.0, v * MainAlpha);  // Dynamically adjusted red channel
}
