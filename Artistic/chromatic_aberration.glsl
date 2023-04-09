#version 330


// Offsets in pixels for each color
vec2 uvr = vec2(3,0);
vec2 uvg = vec2(0,3);
vec2 uvb = vec2(-3,0);

// Scaling of the effect. This makes the effect stronger
// on pixels further away from the center of the window 
// and weaker on pixels close to it
// Set as 0 to disable
float scaling_factor = 1;

// Base strength of the effect. To be used along the scaling_factor
// Tells how strong the effect is at the center
float base_strength = 0;

in vec2 texcoord;             // texture coordinate of the fragment

uniform sampler2D tex;        // texture of the window
ivec2 window_size = textureSize(tex, 0);
ivec2 window_center = ivec2(window_size.x/2, window_size.y/2);

// Default window post-processing:
// 1) invert color
// 2) opacity / transparency
// 3) max-brightness clamping
// 4) rounded corners
vec4 default_post_processing(vec4 c);

vec4 window_shader() {
    if (scaling_factor != 0)
    {
        // Calculate the scale for the current coordinates 
        vec2 scale; 
        scale.xy = base_strength+scaling_factor*((texcoord.xy - window_center.xy)/window_size.xy);

        // Scale offsets
        uvr.xy *= scale.xy;
        uvg.xy *= scale.xy;
        uvb.xy *= scale.xy;
    }

    // Calculate offset coords
    uvr += texcoord;
    uvg += texcoord;
    uvb += texcoord;

    // Fetch colors using offset coords
    vec3 offset_color;
    offset_color.x = texelFetch(tex, ivec2(uvr), 0).x;
    offset_color.y = texelFetch(tex, ivec2(uvg), 0).y;
    offset_color.z = texelFetch(tex, ivec2(uvb), 0).z;
    
    // Set the new color
    vec4 c;
    c.w = texelFetch(tex, ivec2(uvr), 0).w;
    c.xyz = offset_color;
    return default_post_processing(c);
}
