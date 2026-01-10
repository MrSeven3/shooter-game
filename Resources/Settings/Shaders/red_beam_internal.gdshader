shader_type spatial;

uniform vec4 base_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float emission_strength = 2.5;

void fragment() {
    ALBEDO = base_color.rgb;
    EMISSION = base_color.rgb * emission_strength;
}
