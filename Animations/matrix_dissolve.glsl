#version 330

in vec2 texcoord;             // texture coordinate of the fragment

uniform sampler2D tex;        // texture of the window


ivec2 window_size = textureSize(tex, 0); // Size of the window
ivec2 window_center = ivec2(window_size.x/2, window_size.y/2);

/*
These shaders use a sorta hacky way to use the changing
window opacity you might set on picom.conf animation rules
to perform animations.

Basically, when a window get's mapped, we make it's alpha 
go from 0 to 1, so, using the default_post_processing to get that alpha
we can get a variable going from 0 (start of mapping animation)
to 1 (end of mapping animation)

You can also set up your alpha value to go from 1 to 0 in picom when
a window is closed, effectively reversing the animations described here
*/

// Default window post-processing:
// 1) invert color
// 2) opacity / transparency
// 3) max-brightness clamping
// 4) rounded corners
vec4 default_post_processing(vec4 c);
// Pseudo-random function
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

// Creates vertical scanlines
float scanline(vec2 uv, float time) {
    return sin(uv.y * 200.0 + time * 10.0) * 0.5 + 0.5;
}

vec4 anim(float time) {
    vec2 uv = texcoord / vec2(window_size);
    
    // Adjust square size (smaller number = more squares)
    float square_size = 10.0;
    
    // Calculate grid position
    vec2 square_pos = floor(texcoord / square_size);
    
    // Generate random value for this square
    float index = random(square_pos);
    
    // Get original color
    vec4 c = texelFetch(tex, ivec2(texcoord), 0);
    
    // Create threshold for dissolve
    float threshold = (1.0 - time) * 1.2; // The 1.2 creates a slight overlap
    
    // If the random index is greater than our threshold, make pixel transparent
    if (index > threshold) {
        c.a = 0.0;
    }
    
    return c;
}

// Default window shader:
// 1) fetch the specified pixel
// 2) apply default post-processing
vec4 window_shader() {
    vec4 c = texelFetch(tex, ivec2(texcoord), 0);
    c = default_post_processing(c);
    if (c.w != 1.0)
    {
        c = anim(1.0-c.w);
    }
    return default_post_processing(c);
}
