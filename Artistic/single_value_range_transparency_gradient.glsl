#version 330
// value for the maximum transparency
uniform float median = 1;
// maximum derivation from the median
uniform float max_derivation = 0.2;
// e.g. when using brightness as value (see used_value below to change behaviour):
// 0.5±0.25 -> gradient from #444 to #888 to #bbb with #888 being the least opaque
// 0.0±0.25 -> gradient from #000 to #444 with #000 being at min_opacity
// opacity for the median
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

// found here: https://gist.github.com/983/e170a24ae8eba2cd174f
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// found here: https://gist.github.com/mattdesl/e40d3189717333293813626cbdb2c1d1
// made more compact
vec4 rgb2cmyk (vec3 rgb) {
    float k = min(1.0 - rgb.r, min(1.0 - rgb.g, 1.0 - rgb.b));
    vec3 cmy = vec3(0);
    if (1 - k != 0.0)
        cmy = (vec3(1) - rgb - vec3(k)) / (1 - k);
    return clamp(vec4(cmy, k), 0, 1);
}

// Default window shader:
// 1) fetch the specified pixel
// 2) apply default post-processing
vec4 window_shader() {
    vec4 c = texelFetch(tex, ivec2(texcoord), 0);

    // comment out brightness and uncomment any other value to use it instead
    float used_value = 
        (c.r+c.g+c.b)/3; // brightness/lightness
        // c.r // red
        // c.g // green
        // c.b // blue
        // rgb2hsv(c.rgb).x; // hue
        // rgb2hsv(c.rgb).y; // saturation
        // rgb2hsv(c.rgb).z; // intensity/value
        // rgb2cmyk(c.rgb).x // cyan
        // rgb2cmyk(c.rgb).y // magenta
        // rgb2cmyk(c.rgb).z // yellow
        // rgb2cmyk(c.rgb).w // cmyk-key


    // get the derivation from the median and normalize it
    float normalized_derivation = abs(used_value - median)/max_derivation;
    // only add transparency, if the pixel is not already transparent
    if (c.a == 1 && normalized_derivation < 1) {
        // apply the gradient curvature
        normalized_derivation = 1-pow(1-normalized_derivation, power);
        // apply transparency to rgb and alpha, because glx uses premultiplied alpha
        c *= min_opacity + normalized_derivation * (1-min_opacity);
    }

    return default_post_processing( c );
}
