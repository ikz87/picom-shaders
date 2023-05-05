#version 430
#define PI 3.1415926538
uniform float opacity;
uniform float time;

// Works best with fullscreen windows
// Made this to play retro games the way god intended

uniform float sc_freq = 0.2; // Frequency for the scanlines

uniform float sc_intensity = 0.6; // Intensity of the scanline effect

uniform bool grid = false; // Whether to also apply scanlines to x axis or not

uniform int distortion_offset = 2; // Pixel offset for red/blue distortion

uniform int downscale_factor = 2; // How many pixels of the window
                                  // make an actual "pixel" (or block)

uniform float sph_distance = 500; // Distance from the theoretical sphere 
                                  // we use for our curvature transform

uniform float curvature = 1.5; // How much the window should "curve" 

uniform float shadow_cutoff = 1; // How "early" the shadow starts affecting 
                                 // pixels close to the edges
                                 // I'd keep this value very close to 1

uniform int shadow_intensity = 1; // Intensity level of the shadow effect (from 1 to 5)

vec4 outside_color = vec4(0 ,0 ,0, opacity); // Color for the outside of the window

float flash_speed = 0; // Speed of flashing effect, set to 0 to deactivate
                         
float flash_intensity = 0.8; // Intensity of flashing effect


// You can play with different values for all the variables above

in vec2 texcoord;             // texture coordinate of the fragment

uniform sampler2D tex;        // texture of the window

ivec2 window_size = textureSize(tex, 0);
ivec2 window_center = ivec2(window_size.x/2, window_size.y/2);
float radius = (window_size.x/curvature);
int flash = int(round(flash_speed*time/(10000/window_size.y))) % window_size.y;

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
    vec2 distances_from_center = abs(window_center - coords);

    // Darken pixels close to the edges of the screen in a polynomial fashion
    float brightness = 1;
    brightness *= -pow((distances_from_center.y/window_center.y)*shadow_cutoff, 
                       (5/shadow_intensity)*2)+1;
    brightness *= -pow((distances_from_center.x/window_center.x)*shadow_cutoff, 
                       (5/shadow_intensity)*2)+1;
    color.xyz *= brightness;

    return color;
}

// Applies a transformation to our window pixels to simulate
// a curved screen
ivec2 curve_coords_spheric(vec2 coords)
{
    // Offset coords
    coords -= window_center;
    vec2 curved_coords; 

    // For this transform imagine a sphere in a 3d space with the 
    // window as a 2d plane tangent to that sphere
    // For simplicity, we center the sphere at 0,0,0
    // The coordinates of the projection share x and y with our window pixel 
    // We find Z using the formula for a sphere
    vec3 projection_coords3d = vec3(coords.x, coords.y, 
                                    sqrt(pow(radius+sph_distance,2)-
                                         pow(coords.x,2)-
                                         pow(coords.y,2)));

    // That vector goes from the center of the sphere to the projection of a pixel
    // of our window onto the sphere's surface
    // Let's scale it until it hits our window plane
    projection_coords3d *= ((radius+sph_distance)/projection_coords3d.z);
    curved_coords = projection_coords3d.xy;

    // Compensate for starting coords offset
    curved_coords += window_center;

    return ivec2(curved_coords);
}


// Gets a color for a pixel with all the coordinate and
// downscale changes
vec4 get_pixel(vec2 coords)
{
    // If pixel is at the edge of the window, return a completely black color
    if (coords.x >=window_size.x-1 || coords.y >=window_size.y-1 || 
        coords.x <=0 || coords.y <=0)
    {
        return outside_color;
    }
    vec4 color = texelFetch(tex, ivec2(coords), 0);
    return default_post_processing(color);
}

// Gets the color from a downscaled block
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
    
    // Apply curvature transform to coords
    vec2 curved_coords = curve_coords_spheric(texcoord);

    // Fetch the color
    vec4 c = get_block_color(curved_coords);
    
    // Fetch colors from close pixels to apply color distortion
    vec4 c_right = get_block_color(vec2(curved_coords.x+2, curved_coords.y));
    vec4 c_left = get_block_color(vec2(curved_coords.x-2, curved_coords.y));

    // Mix red and blue colors
    c = vec4(c_left.x, c.y, c_right.z, c.w);

    // Apply scanlines
    c.xyz *= sin(2*PI*sc_freq*(texcoord).y)/(2/sc_intensity) +
             1 - sc_intensity/2;

    // Also apply scanlines to x axis if grid is enabled
    if (grid == true)
    {
        c.xyz *= sin(2*PI*sc_freq*(texcoord).x)/(2/sc_intensity) +
                 1 - sc_intensity/2;
    }
    
    // Apply flash
    if (curved_coords.y >=flash-(window_size.y/10) && curved_coords.y <=flash)
    {
       c.xyz *= flash_intensity*(pow(((flash-curved_coords.y)/(window_size.y/10))-1,2)
                                                  + 1/flash_intensity); 
    }

    // Darken pixel
    c = darken_color(c, curved_coords);
    return (c);
}
