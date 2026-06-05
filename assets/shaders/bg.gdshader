shader_type canvas_item;

uniform sampler2D tex : repeat_enable;
uniform vec2 move;

void fragment() {
    vec4 color = texture(tex, UV + TIME * move);
    COLOR = color;
}
