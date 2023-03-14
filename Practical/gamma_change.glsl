#version 330

// Changes gamma of windows
float gamma = 0.7; // Use values higher than 0. Change to your liking
                   

float inv_gamma = 1/gamma;

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

    // Apply power law transform
    c.x = pow(c.x, inv_gamma);
    c.y = pow(c.y, inv_gamma);
    c.z = pow(c.z, inv_gamma);
    return c;
}
