#version 330

in vec2 texcoord;             // texture coordinate of the fragment

uniform sampler2D tex;        // texture of the window


ivec2 window_size = textureSize(tex, 0); // Size of the window
ivec2 window_center = ivec2(window_size.x/2, window_size.y/2);

/*
These shaders use a sorta hacky way to use the changing
window opacity you might set on picom.conf animation rules
to perform animations.

Basically, when a window get's destroyed, usually it's alpha would
go from 1 to 0, so, using the default_post_processing to get that alpha
we can do 1-alpha to get a variable going from 0 (start of destroying animation)
to 1 (end of destroying animation)
*/

// Default window post-processing:
// 1) invert color
// 2) opacity / transparency
// 3) max-brightness clamping
// 4) rounded corners
vec4 default_post_processing(vec4 c);

vec4 destroy_anim(float time) {
    vec4 c = texelFetch(tex, ivec2(texcoord), 0);
    return c;
}

// Default window shader:
// 1) fetch the specified pixel
// 2) apply default post-processing
vec4 window_shader() {
    vec4 c = texelFetch(tex, ivec2(texcoord), 0);
    float alpha = default_post_processing(c).w;
    float destroy_time = 1.0-alpha;
    if (destroy_time > 0.0)
    {
        c = destroy_anim(destroy_time);
    }
    return default_post_processing(c);
}
