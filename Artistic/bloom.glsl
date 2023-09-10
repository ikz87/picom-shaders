#version 430

in vec2 texcoord;// texture coordinate of the fragment

uniform sampler2D tex;// texture of the window

uniform float cutoff = 0.55;// Brightness value that should be considered as a "bright" pixel

uniform float light_brightness = 1;// Scaling value for the brightness of the bloom effect

uniform float base_brightness = 1.2;// Scaling value for the brightness of the bright pixels

// Here are some kerneles you can use for the gaussian blur
uniform float kernel1[5][5] = { { 0.003, 0.013, 0.022, 0.013, 0.003 },
{ 0.013, 0.059, 0.097, 0.059, 0.013 },
{ 0.022, 0.097, 0.159, 0.097, 0.022 },
{ 0.013, 0.059, 0.097, 0.059, 0.013 },
{ 0.003, 0.013, 0.022, 0.013, 0.003 } };

uniform float kernel2[7][7] = {
{ 0.0051, 0.0094, 0.0135, 0.0153, 0.0135, 0.0094, 0.0051 },
{ 0.0094, 0.0173, 0.0250, 0.0282, 0.0250, 0.0173, 0.0094 },
{ 0.0135, 0.0250, 0.0361, 0.0407, 0.0361, 0.0250, 0.0135 },
{ 0.0153, 0.0282, 0.0407, 0.0461, 0.0407, 0.0282, 0.0153 },
{ 0.0135, 0.0250, 0.0361, 0.0407, 0.0361, 0.0250, 0.0135 },
{ 0.0094, 0.0173, 0.0250, 0.0282, 0.0250, 0.0173, 0.0094 },
{ 0.0051, 0.0094, 0.0135, 0.0153, 0.0135, 0.0094, 0.0051 },
};

uniform float kernel3[15][15] = {
{ 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0001, 0.0001, 0.0001, 0.0001, 0.0001, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000 },
{ 0.0000, 0.0000, 0.0000, 0.0001, 0.0002, 0.0003, 0.0004, 0.0005, 0.0004, 0.0003, 0.0002, 0.0001, 0.0000, 0.0000, 0.0000 },
{ 0.0000, 0.0000, 0.0001, 0.0003, 0.0006, 0.0011, 0.0016, 0.0018, 0.0016, 0.0011, 0.0006, 0.0003, 0.0001, 0.0000, 0.0000 },
{ 0.0000, 0.0001, 0.0003, 0.0008, 0.0018, 0.0034, 0.0049, 0.0055, 0.0049, 0.0034, 0.0018, 0.0008, 0.0003, 0.0001, 0.0000 },
{ 0.0000, 0.0002, 0.0006, 0.0018, 0.0043, 0.0079, 0.0115, 0.0130, 0.0115, 0.0079, 0.0043, 0.0018, 0.0006, 0.0002, 0.0000 },
{ 0.0001, 0.0003, 0.0011, 0.0034, 0.0079, 0.0146, 0.0211, 0.0239, 0.0211, 0.0146, 0.0079, 0.0034, 0.0011, 0.0003, 0.0001 },
{ 0.0001, 0.0004, 0.0016, 0.0049, 0.0115, 0.0211, 0.0305, 0.0345, 0.0305, 0.0211, 0.0115, 0.0049, 0.0016, 0.0004, 0.0001 },
{ 0.0001, 0.0005, 0.0018, 0.0055, 0.0130, 0.0239, 0.0345, 0.0390, 0.0345, 0.0239, 0.0130, 0.0055, 0.0018, 0.0005, 0.0001 },
{ 0.0001, 0.0004, 0.0016, 0.0049, 0.0115, 0.0211, 0.0305, 0.0345, 0.0305, 0.0211, 0.0115, 0.0049, 0.0016, 0.0004, 0.0001 },
{ 0.0001, 0.0003, 0.0011, 0.0034, 0.0079, 0.0146, 0.0211, 0.0239, 0.0211, 0.0146, 0.0079, 0.0034, 0.0011, 0.0003, 0.0001 },
{ 0.0000, 0.0002, 0.0006, 0.0018, 0.0043, 0.0079, 0.0115, 0.0130, 0.0115, 0.0079, 0.0043, 0.0018, 0.0006, 0.0002, 0.0000 },
{ 0.0000, 0.0001, 0.0003, 0.0008, 0.0018, 0.0034, 0.0049, 0.0055, 0.0049, 0.0034, 0.0018, 0.0008, 0.0003, 0.0001, 0.0000 },
{ 0.0000, 0.0000, 0.0001, 0.0003, 0.0006, 0.0011, 0.0016, 0.0018, 0.0016, 0.0011, 0.0006, 0.0003, 0.0001, 0.0000, 0.0000 },
{ 0.0000, 0.0000, 0.0000, 0.0001, 0.0002, 0.0003, 0.0004, 0.0005, 0.0004, 0.0003, 0.0002, 0.0001, 0.0000, 0.0000, 0.0000 },
{ 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0001, 0.0001, 0.0001, 0.0001, 0.0001, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000 }
};

float blur_kernel[7][7] = kernel2;// Kernel to use for the gaussian blur

// Default window post-processing:
// 1) invert color
// 2) opacity / transparency
// 3) max-brightness clamping
// 4) rounded corners
vec4 default_post_processing(vec4 c);

// Returns the brightness of a pixel
float get_brightness(vec4 color)
{
    return (color.x+color.y+color.z)/3;
}

// Default window shader:
// 1) fetch the specified pixel
// 2) apply default post-processing
vec4 window_shader() {
    // Variable where we will store the sum from the convolution with the kernel
    vec4 total = vec4(0);

    // Radius of the kernel
    int radius = int(floor(blur_kernel[0].length()/2));

    // Apply convolution
    for (int y = -radius; y <=radius; y++)
    {
        for (int x = -radius; x <=radius; x++)
        {
            // Fetch pixel
            vec4 c = texelFetch(tex, ivec2(texcoord.x+x, texcoord.y+y), 0);
            c = default_post_processing(c);

            // If the brightness is below our cutoff, set the pixel
            // as an empty one
            if (get_brightness(c) < cutoff)
            {
                c = vec4(0);
            }

            // Convolve and multiply by the light brightness
            c *= blur_kernel[x+radius][y+radius];
            c.xyz *= light_brightness;
            total.xyzw += c;
        }
    }

    // Scale the brightness of the pixel with clamping
    vec4 c = texelFetch(tex, ivec2(texcoord), 0);
    if (get_brightness(c) >= cutoff)
    {
        c.xyz = min(c.xyz*base_brightness, 1);
    }

    // Apply screen blending mode
    c.xyzw = 1-(1-total.xyzw)*(1-c.xyzw);
    return default_post_processing(c);
}
