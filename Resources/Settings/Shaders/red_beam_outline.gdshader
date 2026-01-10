shader_type spatial;
render_mode cull_front, unshaded;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float outline_size = 0.03;

void vertex() {
    //float radius_factor = max(length(VERTEX.xy), 0.0001);
    VERTEX += NORMAL * outline_size;
}

void fragment() {
    ALBEDO = outline_color.rgb;
}
