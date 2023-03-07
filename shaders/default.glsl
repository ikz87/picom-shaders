#version 330
in vec2 texcoord;             // texture coordinate of the fragment

uniform sampler2D tex;        // texture of the window

// Default window post-processing:
// 1) invert color
// 2) opacity / transparency
// 3) max-brightness clamping
// 4) rounded corners
vec4 default_post_processing(vec4 c);

// Default window shader:
// 1) fetch the specified pixel
// 2) apply default post-processing
vec4 window_shader() {
    vec4 c = texelFetch(tex, ivec2(texcoord), 0);
    return default_post_processing(c);
}
