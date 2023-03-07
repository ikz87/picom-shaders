#version 330

// Changes brightness of windows
float brightness_level = 0.5; // Value between 0.0 and 1.0. Change to your liking

in vec2 texcoord;             // texture coordinate of the fragment

uniform sampler2D tex;        // texture of the window
                            

// Default window post-processing:
// 1) invert color
// 2) opacity / transparency
// 3) max-brightness clamping
// 4) rounded corners
vec4 default_post_processing(vec4 c);

vec4 window_shader() {
    vec4 c = texelFetch(tex, ivec2(texcoord), 0);

    c = default_post_processing(c);

    // Multipply all color values with brightness_level
    c.x *= brightness_level;
    c.y *= brightness_level;
    c.z *= brightness_level;
    return c;
}
