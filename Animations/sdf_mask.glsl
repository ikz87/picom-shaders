#version 330

in vec2 texcoord;             // texture coordinate of the fragment

uniform sampler2D tex;        // texture of the window


ivec2 window_size = textureSize(tex, 0); // Size of the window
ivec2 window_center = ivec2(window_size.x/2, window_size.y/2);

/*
These shaders use a sorta hacky way to use the changing
window opacity you might set on picom.conf animation rules
to perform animations.

Basically, when a window get's mapped, we make it's alpha 
go from 0 to 1, so, using the default_post_processing to get that alpha
we can get a variable going from 0 (start of mapping animation)
to 1 (end of mapping animation)

You can also set up your alpha value to go from 1 to 0 in picom when
a window is closed, effectively reversing the animations described here
*/

// Default window post-processing:
// 1) invert color
// 2) opacity / transparency
// 3) max-brightness clamping
// 4) rounded corners
vec4 default_post_processing(vec4 c);

//  If you have semitransparent windows (like a terminal)
// You can use the below function to add an opacity threshold where the
// animation won't apply. For example, if you had your terminal
// configured to have 0.8 opacity, you'd set the below variable to 0.8
float max_opacity = 0.8;
float opacity_threshold(float opacity)
{
  // if statement jic?
  if (opacity >= max_opacity)
  {
    return 1.0;
  }
  else 
  {
    return min(1, opacity/max_opacity);
  }

}

// NEW anim function: Morphing Distance-Field Mask (Wobbly Circle)
vec4 anim(float progress) {

    vec4 c = texelFetch(tex, ivec2(texcoord), 0);

    // Early exit for fully transparent or fully opaque states
    if (progress <= 0.001) { // Beginning of reveal / End of conceal
        c.a = 0.0;
        return c;
    }
    if (progress >= 0.999) { // End of reveal / Beginning of conceal
        return c; // Original alpha, effect is complete
    }

    vec2 p_centered = texcoord - vec2(window_center); // Pixel coords relative to center

    // --- SDF Parameters ---
    // Max radius needed to cover the window from the center to a corner
    float max_coverage_radius = length(vec2(window_size) * 0.5) * 1.05; // 5% margin

    // Easing for progress (e.g., ease-in: starts slow, speeds up)
    float eased_progress = progress * progress;
    // float eased_progress = sqrt(progress); // Alternative: ease-out
    // float eased_progress = progress; // Alternative: linear

    float base_radius = eased_progress * max_coverage_radius;

    // --- Wobble Parameters ---
    float angle = atan(p_centered.y, p_centered.x); // Angle of pixel from center

    float spatial_freq = 7.0; // Number of wobbles around circumference
    float wobble_anim_speed = 10.0; // How fast wobbles change with progress
    // Wobble amplitude (as a factor of base_radius), decreases as reveal completes
    float wobble_amplitude_factor = 0.15 * (1.0 - eased_progress * 0.7);

    // Wobble animation phase based on progress
    float wobble_phase = progress * wobble_anim_speed;
    
    float radius_offset = sin(angle * spatial_freq + wobble_phase) *
                          base_radius * wobble_amplitude_factor;
    
    float effective_radius = base_radius + radius_offset;

    // --- SDF Calculation (Circle) ---
    // Distance from current pixel to the center of the coordinate system (p_centered)
    float dist_from_center = length(p_centered);
    // SDF value: negative inside the shape, positive outside
    float sdf_value = dist_from_center - effective_radius;

    // --- Alpha Masking ---
    float edge_softness = 15.0; // Softness of the mask edge in pixels

    // Create mask: 1.0 inside (visible), 0.0 outside (transparent)
    // smoothstep transitions from 0 to 1 as sdf_value goes from 0 to edge_softness
    // So, for sdf_value < 0 (inside), mask is 1.0.
    // For sdf_value > edge_softness (far outside), mask is 0.0.
    float mask = 1.0 - smoothstep(0.0, edge_softness, sdf_value);

    c.a *= mask; // Apply the mask to the original alpha

    return c;
}

// Default window shader:
// 1) fetch the specified pixel
// 2) apply default post-processing
vec4 window_shader() {
  vec4 c = texelFetch(tex, ivec2(texcoord), 0);
  c = default_post_processing(c);
  float opacity = opacity_threshold(c.w);
  if (opacity == 0.0)
  {
    return c;
  }
  vec4 anim_c = anim(opacity);
  if (anim_c.w < max_opacity)
  {
    return vec4(0);
  }
  return default_post_processing(anim_c);
}
