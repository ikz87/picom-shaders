#version 330
uniform sampler2D tex;

float scale = 0.5; // Scale of the zoom effect
                   // Values grater than 1 = zoom in
                   // Values lower than 1 = zoom out
                   
ivec2 window_size = textureSize(tex, 0); // Size of the window
ivec2 window_center = ivec2(window_size.x/2, window_size.y/2); 



in vec2 texcoord; 

vec4 default_post_processing(vec4 c);

vec4 window_shader() {
    // Displace coords around the center
    vec2 new_coords = (texcoord - window_center) * (1/scale) + window_center;
    
    // If the new coords end outside the window, return an empty pixel
    if (new_coords.x > window_size.x || new_coords.x < 0 ||
        new_coords.y > window_size.y || new_coords.y < 0)
    {
        return vec4(0);
    }
    
    // Fetch pixel with new coords
    vec4 c = texelFetch(tex, ivec2(new_coords), 0);

    return default_post_processing(c);
}
