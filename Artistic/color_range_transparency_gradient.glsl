#version 330
// rgb value for the maximum transparency
uniform vec3 median_color = vec3(1);
// maximum derivation from the median_color of each color channel (rgb)
uniform vec3 max_derivation = vec3(0.2);
// e.g. (1,0,0)±(0.2,0.2,0.2) -> gradient from #c00 to #f00 to #f33 with #f00 being the least opaque
// (0,0,0)±(0.25,0.25,0,25) -> gradient from #000 to #444 with #000 being at min_opacity
// opacity for the median_color
uniform float min_opacity = 0.9;
// exponent for the gradient (e.g. 1 for linear, 2 for quadratic, etc)
uniform int power = 2;
// use mean for a different effect
float get_float (vec3 c) {
    // maximum
    return max(max(c.r,c.g),c.b);
    // mean
    // return (v.r + v.g + v.b)/3;
}
// tweak the above variables and functions for your needs

// texture coordinate of the fragment
in vec2 texcoord;
// texture of the window
uniform sampler2D tex;
// Default window post-processing:
// 1) invert color
// 2) opacity / transparency
// 3) max-brightness clamping
// 4) rounded corners
vec4 default_post_processing(vec4 c);


// Default window shader:
// 1) fetch the specified pixel
// 2) apply default post-processing
vec4 window_shader() {
    vec4 c = texelFetch(tex, ivec2(texcoord), 0);

    // get the each colorchannels derivation from the median_color channels and normalize them
    vec3 normalized_derivation = abs(c.rgb - median_color)/max_derivation;
    // only add transparency, if the pixel is not already transparent
    if (c.a == 1 && get_float(normalized_derivation) < 1) {
        // apply the gradient curvature
        normalized_derivation = vec3(1)-pow(vec3(1)-normalized_derivation, vec3(power));
        // apply transparency to rgb and alpha, because glx uses premultiplied alpha
        c *= min_opacity + get_float(normalized_derivation) * (1-min_opacity);
    }

    return default_post_processing( c );
}
