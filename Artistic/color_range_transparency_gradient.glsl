#version 330
in vec2 texcoord;             // texture coordinate of the fragment

uniform sampler2D tex;        // texture of the window

// Default window post-processing:
// 1) invert color
// 2) opacity / transparency
// 3) max-brightness clamping
// 4) rounded corners
vec4 default_post_processing(vec4 c);

// use mean for a different effect
float getFloat (vec3 c) {
    // maximum
    return max(max(c.r,c.g),c.b);
    // mean
    // return (v.r + v.g + v.b)/3;
}
// Default window shader:
// 1) fetch the specified pixel
// 2) apply default post-processing
vec4 window_shader() {
    vec4 c = texelFetch(tex, ivec2(texcoord), 0);

    /*### define tweakable variables ###*/
    // rgb value for the maximum transparency
    vec3 medianColor = vec3(1);
    // maximum derivation from the medianColor of each color channel (rgb)
    vec3 maxDerivation = vec3(0.2);
    // e.g. (1,0,0)±(0.2,0.2,0.2) -> gradient from #c00 to #f00 to #f33 with #f00 being the least opaque
    // (0,0,0)±(0.25,0.25,0,25) -> gradient from #000 to #444 with #000 being at minOpacity
    // opacity for the medianColor
    float minOpacity = 0.9;
    // exponent for the gradient (e.g. 1 for linear, 2 for quadratic, etc)
    int power = 2;

    /*### do the thing ###*/
    // get the each colorchannels derivation from the medianColor channels and normalize them
    vec3 normalizedDerivation = abs(c.rgb - medianColor)/maxDerivation;
    // only add transparency, if the pixel is not already transparent
    if (c.a == 1 && getFloat(normalizedDerivation) < 1) {
        // apply the gradient curvature
        normalizedDerivation = vec3(1)-pow(vec3(1)-normalizedDerivation, vec3(power));
        // apply transparency to rgb and alpha, because glx uses premultiplied alpha
        c *= minOpacity + getFloat(normalizedDerivation) * (1-minOpacity);
    }

    return default_post_processing( c );
}
