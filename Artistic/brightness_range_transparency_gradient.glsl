#version 330
// brightness value for the maximum transparency
uniform float median_brightness = 1;
// maximum brightness derivation from the median_brightness
uniform float max_derivation = 0.2;
// e.g. 0.5±0.25 -> gradient from #444 to #888 to #bbb with #888 being the least opaque
// 0±0.25 -> gradient from #000 to #444 with #000 being at min_opacity
// opacity for the median_brightness
uniform float min_opacity = 0.9;
// exponent for the gradient (e.g. 1 for linear, 2 for quadratic, etc)
uniform int power = 2;
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

    // get the brightness derivation from the median_brightness and normalize it
    float normalized_derivation = abs((c.r+c.g+c.b)/3 - median_brightness)/max_derivation;
    // only add transparency, if the pixel is not already transparent
    if (c.a == 1 && normalized_derivation < 1) {
        // apply the gradient curvature
        normalized_derivation = 1-pow(1-normalized_derivation, power);
        // apply transparency to rgb and alpha, because glx uses premultiplied alpha
        c *= min_opacity + normalized_derivation * (1-min_opacity);
    }

    return default_post_processing( c );
}
