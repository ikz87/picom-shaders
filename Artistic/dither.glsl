#version 430

bool monochrome = false; // Whether to apply a black & white filter to the window

// You can modify the list of patterns to whatever you like, the code will
// adapt to it as long as it is a list of equally sized 2D arrays 
// This example shows a dither pattern list that uses numbers other than
// 0 and 1 for more color variation
// Dither patterns
float dither [][][] = { {{0  , 0  },
                         {0  , 0  }},

                        {{0.5, 0  },
                         {0  , 0  }},

                        {{0.5, 0  },
                         {0  , 0.5}},

                        {{0.5, 0.5},
                         {0  , 0.5}},

                        {{0.5, 0.5},
                         {0.5, 0.5}},

                        {{1  , 0.5},
                         {0.5,0.5}},

                        {{1  , 0.5},
                         {0.5, 1  }},

                        {{1  , 1  },
                         {0.5, 1  }},

                        {{1  , 1  },
                         {1  , 1  }} };

// Some more props that depend on the dither patterns
float bit_depth = dither.length() - 1.0;
int block_size = dither[0].length();

in vec2 texcoord;       // texture coordinate of the fragment

uniform sampler2D tex;  // texture of the window
                    
// Default window post-processing:
// 1) invert color
// 2) opacity / transparency
// 3) max-brightness clamping
// 4) rounded corners
vec4 default_post_processing(vec4 c);

// Returns a monochromatic pixel
vec4 to_monochrome (vec4 pixel)
{
    float brightness = (pixel.x + pixel.y + pixel.z)/3;
    return vec4(vec3(brightness), pixel.w);
}

vec4 window_shader() {
    // Alpha for the current pixel
    float alpha;

    // Relative block position
    ivec2 block_pos;
    block_pos.x = int(texcoord.x) % block_size;
    block_pos.y = int(texcoord.y) % block_size;
    
    // Current block total color
    vec3 block_color = vec3(0,0,0);
    
    // We will iterate over all the pixels in the block 
    // and save it to this variable
    vec4 pixel;
    for (int y = 0; y < block_size; y += 1)
    {
        for (int x = 0; x < block_size; x += 1)
        {
            // Apply default post processing picom things and
            // add color values after.
            pixel = texelFetch(tex, ivec2(texcoord.x+x-block_pos.x,texcoord.y+y-block_pos.y), 0);
            pixel = default_post_processing(pixel);
            if (monochrome)
            {
                pixel = to_monochrome(pixel);
                block_color.x += pixel.x;
            }
            else
            {
                block_color.x += pixel.x;
                block_color.y += pixel.y;
                block_color.z += pixel.z;
            }

            // If we are on the current pixel, save the alpha value
            if (x == 0 && y == 0)
            {
                alpha = pixel.w;
            }
        }
    }
    // Normalize block colors and quantify them
    block_color.x = block_color.x/float(block_size*block_size);
    block_color.x = round(block_color.x*bit_depth);

    // Get the pixel colors using our dither pattern
    block_color.x = dither[int(block_color.x)][block_pos.y][block_pos.x];

    if (monochrome)
    {
        block_color.yz = block_color.xx;
    }
    else
    {
        block_color.y = block_color.y/float(block_size*block_size);
        block_color.y = round(block_color.y*bit_depth);

        block_color.z = block_color.z/float(block_size*block_size);
        block_color.z = round(block_color.z*bit_depth);
    
        block_color.y = dither[int(block_color.y)][block_pos.y][block_pos.x];
        block_color.z = dither[int(block_color.z)][block_pos.y][block_pos.x];
    }

    // Set the final value for our pixel
    pixel = vec4(block_color.x, block_color.y, block_color.z, alpha);
    return pixel;
}
