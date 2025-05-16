#version 430

// Source: https://github.com/yshui/picom/issues/295#issuecomment-592077997

in vec2 texcoord;

uniform float opacity;
uniform bool invert_color;
uniform sampler2D tex;
uniform float time;

ivec2 window_size = textureSize(tex, 0);

float amt = 10000.0;

vec4 default_post_processing(vec4 c);

vec4 window_shader() {
    float pct = mod(time, amt) / amt * 1000;
    float factor = float(max(window_size.x, window_size.y));
    pct *= factor / 150.0;
    vec2 pos = texcoord;
	vec4 c = texelFetch(tex, ivec2(texcoord), 0);

    if (pos.x + pos.y < pct * 4.0 && pos.x + pos.y > pct * 4.0 - .5 * pct
        || pos.x + pos.y < pct * 4.0 - .8 * pct && pos.x + pos.y > pct * 3.0)
       c *= vec4(2, 2, 2, 1);
    if (invert_color)
    	c = vec4(vec3(c.a, c.a, c.a) - vec3(c), c.a);

	c *= opacity;
	return default_post_processing(c);
}
