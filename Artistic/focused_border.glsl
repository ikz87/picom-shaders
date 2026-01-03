#version 330

in vec2 texcoord;
uniform sampler2D tex;
uniform float opacity;
uniform float corner_radius;

vec4 default_post_processing(vec4 c);

// Function to check if a point is inside a rounded rectangle
bool inside_rounded_rect(vec2 pos, vec2 size, float radius) {
    vec2 center = size * 0.5;
    vec2 d = abs(pos - center) - (center - radius);
    return length(max(d, 0.0)) <= radius;
}

vec4 window_shader() {
    vec4 c = texelFetch(tex, ivec2(texcoord), 0);
    c = default_post_processing(c);
    
    ivec2 window_size = textureSize(tex, 0);
    float border_width = 3.0;
    vec2 pos = vec2(texcoord.x, texcoord.y);
    vec2 size = vec2(window_size.x, window_size.y);
    float radius = corner_radius;
    
    // Check if we're inside the outer rounded rectangle (window boundary)
    bool inside_outer = inside_rounded_rect(pos, size, radius);
    
    // If we're outside the window entirely, make transparent
    if (!inside_outer) {
        return vec4(0.0, 0.0, 0.0, 0.0);
    }
    
    // Check if we're inside the inner rounded rectangle (content area)
    // The inner rectangle is smaller by border_width on all sides
    vec2 inner_size = size - vec2(border_width * 2.0);
    vec2 inner_pos = pos - vec2(border_width);
    float inner_radius = max(0.0, radius - border_width * 0.5);
    
    bool inside_inner = inside_rounded_rect(inner_pos, inner_size, inner_radius);
    
    // If we're between outer and inner rounded rectangles, we're in the border
    if (!inside_inner) {
        return vec4(1.0, 0.3, 0.9, 1.0); // Neon pink-purple
    }
    
    // Inside the content area
    return c;
}