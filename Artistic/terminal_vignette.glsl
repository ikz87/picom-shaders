#version 330
in vec2 texcoord;             // texture coordinate of the fragment

uniform sampler2D tex;        // texture of the window

ivec2 window_size = textureSize(tex, 0); // Size of the window
ivec2 window_center = ivec2(window_size.x/2, window_size.y/2);
uniform float shadow_cutoff = 1; // How "early" the shadow starts affecting 
                                 // pixels close to the edges
                                 // I'd keep this value very close to 1
uniform int shadow_intensity = 3; // Intensity level of the shadow effect (from 1 to 5)


// Default window post-processing:
// 1) invert color
// 2) opacity / transparency
// 3) max-brightness clamping
// 4) rounded corners
vec4 default_post_processing(vec4 c);

// Darkens a pixels near the edges
vec4 calc_opacity(vec4 color, vec2 coords)
{
    // If shadow intensity is 0, change nothing
    if (shadow_intensity == 0)
    {
        return color;
    }

    // Get how far the coords are from the center
    vec2 distances_from_center = abs(window_center - coords);

    // Darken pixels close to the edges of the screen in a polynomial fashion
    float opacity = 1;
    opacity *= -pow((distances_from_center.y/window_center.y)*shadow_cutoff, 
                       (5/shadow_intensity)*2)+1;
    opacity *= -pow((distances_from_center.x/window_center.x)*shadow_cutoff, 
                       (5/shadow_intensity)*2)+1;
    color.w *= opacity;
    color.w = max(1 - color.w, 0.8);

    return color;
}


// Default window shader:
// 1) fetch the specified pixel
// 2) apply default post-processing
vec4 window_shader() {
    vec4 c = texelFetch(tex, ivec2(texcoord), 0);
    if (c.x +c.y + c.z < 0.6)
    {
        c.w = 1;
        c = calc_opacity(c,texcoord);
    }

    return default_post_processing(c);
}
