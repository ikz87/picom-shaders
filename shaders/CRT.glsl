#version 430
#define PI 3.1415926538

// Works best with fullscreen windows

uniform float sc_freq = 0.2; // Frequency for the scanlines
uniform float sc_intensity = 0.35; // Intensity of the scanline effect
uniform bool grid = false; // Wether to also apply scanlines to x axis or not
uniform int downscale_factor = 2; // How many pixels of the window
                                  // make an actual "pixel" (or block)
uniform vec2 curvature = vec2(2.4, 2.1); // How much the window should "curve" 
                                         // along each axis
uniform int distortion_offset = 2; // pixel offset for red/blue distortion
uniform float shadow_cutoff = 0.98; // How "early" the shadow starts affecting 
                                 // pixels close to the edges
                                 // I'd keep this value very close to 1
uniform int shadow_intensity = 1; // Intensity level of the shadow effect (from 1 to 5)

in vec2 texcoord;             // texture coordinate of the fragment

uniform sampler2D tex;        // texture of the window

ivec2 window_size = textureSize(tex, 0);
ivec2 middle = ivec2(window_size.x/2, window_size.y/2);
vec2 radius = vec2(window_size.x/curvature.x, window_size.y/curvature.y);

// Default window post-processing:
// 1) invert color
// 2) opacity / transparency
// 3) max-brightness clamping
// 4) rounded corners
vec4 default_post_processing(vec4 c);

// Darkens a pixels near the edges
vec4 darken_color(vec4 color, vec2 coords)
{
    // If shadow intensity is 0, change nothing
    if (shadow_intensity == 0)
    {
        return color;
    }

    // Get how far the coords are from the center
    vec2 distances_from_center = middle - coords;
    float abs_distance = sqrt(pow(distances_from_center.x, 2) +
                              pow(distances_from_center.y, 2));

    // Darken pixels polinomically (there is probs a better way to do this)
    float brightness = -pow((abs_distance/middle.x)*shadow_cutoff, (5/shadow_intensity)*2)+1;
    color.xyz *= brightness;

    // Also darken a bit pixels close to the top and bottom so the effect
    // doesn't look terrible
    brightness = -pow((distances_from_center.y/middle.y)*shadow_cutoff, (5/shadow_intensity)*2)+1;
    color.xyz *= brightness;

    return color;
}


// Apply curvature transform to given coordinates
ivec2 curve_coords(vec2 coords)
{
    ivec2 curved_coords = ivec2(round(asin((coords.xy - middle.xy)/radius)*radius + middle.xy));
    return curved_coords;
}


// Gets a color for a pixel with all the coordinate and
// downscale changes
vec4 get_pixel(vec2 coords)
{
    ivec2 curved_coords = curve_coords(coords);
    if (curved_coords.x > window_size.x || curved_coords.y > window_size.y ||
        curved_coords.x < 0 || curved_coords.y < 0)
    {
        return vec4(0, 0, 0, 1);
    }
    else
    {
        vec4 color = texelFetch(tex, curved_coords, 0);
        return (color);
    }
}


vec4 get_block_color(vec2 coords)
{
    // If downscale is set to 1, just return a pixel
    if (downscale_factor < 2)
    {
        return get_pixel(coords);
    }

    // Relative position of pixel inside the block
    ivec2 relative_position;
    relative_position.xy = ivec2(coords).xy % downscale_factor;

    // Average all colors from pixels inside the block
    vec4 average = vec4(0, 0 , 0, 0);
    for (int i = 0; i < downscale_factor; i++)
    {
       for (int j = 0; j < downscale_factor; j++)
       {
           average.xyzw += get_pixel(vec2(coords.x + i - relative_position.x,
                                          coords.y + j - relative_position.y));
       }
    }
    average /= pow(downscale_factor, 2);

    return average;
}


// Main shader function
vec4 window_shader() {
    // Fetch the color
    vec4 c = get_block_color(texcoord);
    
    // Fetch colors from close pixels to apply color distortion
    vec4 c_right = get_block_color(vec2(texcoord.x+2, texcoord.y));
    vec4 c_left = get_block_color(vec2(texcoord.x-2, texcoord.y));

    // Mix red and blue colors
    c = vec4(c_left.x, c.y, c_right.z, c.w);

    c.xyz *= sin(2*PI*sc_freq*texcoord.y)/(2/sc_intensity) +
             1 - sc_intensity/2;

    if (grid == true)
    {
        c.xyz *= sin(2*PI*sc_freq*texcoord.x)/(2/sc_intensity) +
                 1 - sc_intensity/2;
    }

    c = darken_color(c, curve_coords(texcoord));
    return (c);
}
