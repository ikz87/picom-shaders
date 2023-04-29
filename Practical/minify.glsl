#version 330
uniform sampler2D tex;

in vec2 texcoord; 

vec4 default_post_processing(vec4 c);

vec4 window_shader() {
    ivec2 window_size = textureSize(tex, 0); // Size of the window
    ivec2 window_center = ivec2(window_size.x/2, window_size.y/2); 
    vec2 new_coords = (texcoord - window_center) * 1.5 + window_center;
    vec4 c = texelFetch(tex, ivec2(new_coords), 0);
    return default_post_processing(c);
}
