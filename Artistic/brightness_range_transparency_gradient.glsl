#version 330
in vec2 texcoord;             // texture coordinate of the fragment

uniform sampler2D tex;        // texture of the window

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

    /*### define tweakable variables ###*/
    // brightness value for the maximum transparency
    float medianBrightness = 1;
    // maximum brightness derivation from the medianBrightness
    float maxDerivation = 0.2;
    // e.g. 0.5±0.25 -> gradient from #444 to #888 to #bbb with #888 being the least opaque
    // 0±0.25 -> gradient from #000 to #444 with #000 being at minOpacity
    // opacity for the medianBrightness
    float minOpacity = 0.9;
    // exponent for the gradient (e.g. 1 for linear, 2 for quadratic, etc)
    int power = 2;

    /*### do the thing ###*/
    // get the brightness derivation from the medianBrightness and normalize it
    float normalizedDerivation = abs((c.r+c.g+c.b)/3 - medianBrightness)/maxDerivation;
    // only add transparency, if the pixel is not already transparent
    if (c.a == 1 && normalizedDerivation < 1) {
        // apply the gradient curvature
        normalizedDerivation = (1-pow(1-normalizedDerivation, power));
        // apply transparency to rgb and alpha, because glx uses premultiplied alpha
        c *= minOpacity + normalizedDerivation * (1-minOpacity);
    }

    return default_post_processing( c );
}
