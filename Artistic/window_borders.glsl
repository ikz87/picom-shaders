#version 330
in vec2 texcoord;             // texture coordinate of the fragment

uniform float opacity;        // opacity of the window (0.0 - 1.0)
uniform float corner_radius;  // corner radius of the window (pixels)
// doesnt work for me:
// uniform float border_width;   // estimated border width of the window (pixels)
uniform sampler2D tex;        // texture of the window
uniform float time;           // time in milliseconds, counting from an unspecified starting point

// Define tweakable variables
vec4 border_color = vec4(1,0,0,opacity);
uniform float border_width = 5;

// Default window post-processing:
// 1) invert color
// 2) opacity / transparency
// 3) max-brightness clamping
// 4) rounded corners
vec4 default_post_processing(vec4 c);

// get window size
ivec2 window_size = textureSize(tex, 0);

// Define useful functios
bool corner(bool left, bool top, float cx, float cy) {
    return (
        ((left   && texcoord.x < cx) || (!left && texcoord.x > cx))
        && ((top && texcoord.y < cy) || (!top  && texcoord.y > cy))
        && pow(cx-texcoord.x, 2)
            + pow(cy-texcoord.y, 2) 
            > pow(corner_radius-border_width, 2)
    );
}
// use this to rotate the color of the boders (2 versions with different looks)
// source: https://gist.github.com/mairod/a75e7b44f68110e1576d77419d608786
vec3 hue_shift(vec3 color, float hue) {
    const vec3 k = vec3(0.57735, 0.57735, 0.57735);
    float cosAngle = cos(hue);
    return vec3(color * cosAngle + cross(k, color) * sin(hue) + k * dot(k, color) * (1.0 - cosAngle));
}
vec3 hue_shift2(vec3 color, float dhue) {
	float s = sin(dhue);
	float c = cos(dhue);
	return (color * c) + (color * s) * mat3(
		vec3(0.167444, 0.329213, -0.496657),
		vec3(-0.327948, 0.035669, 0.292279),
		vec3(1.250268, -1.047561, -0.202707)
	) + dot(vec3(0.299, 0.587, 0.114), color) * (1.0 - c);
}
// Default window shader:
// 1) fetch the specified pixel
// 2) apply default post-processing
vec4 window_shader() {
    vec4 c = texelFetch(tex, ivec2(texcoord), 0);
    // Apply default_post_processing before doing any changes
    // to "paint" over the original window border
    c = default_post_processing(c);

    if ( c.a == 1 && (
        // borders
        texcoord.x < border_width
        || texcoord.y < border_width
        || texcoord.x > window_size.x - border_width
        || texcoord.y > window_size.y - border_width
        // rounded corners
        || corner(true,  true,  corner_radius,               corner_radius)
        || corner(false, true,  window_size.x-corner_radius, corner_radius)
        || corner(false, false, window_size.x-corner_radius, window_size.y-corner_radius)
        || corner(true,  false, corner_radius,               window_size.y-corner_radius)
    )) 
        // c = border_color;
        // use this instead for rotating hue of the border
        c.rgb = hue_shift(
            border_color.rgb,
            6.28318*float(int(time) % 10000)/10000
        );
    return c;
}
