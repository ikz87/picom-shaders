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

// Pseudo-random function (from original shader)
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

float PI = 3.1415926535;
float TWO_PI = 2.0 * PI;

// NEW anim function: Glass-Shard Shatter
vec4 anim(float animation_progress) {
    vec4 out_color = vec4(0.0); // Default to transparent

    // --- Shard Parameters ---
    float num_shards = 20.0; // Number of angular shards
    vec2 impact_point = window_center;

    // --- Fragment's Relation to Impact Point & Shard ID ---
    vec2 vec_frag_to_impact = texcoord - impact_point;
    float dist_frag_to_impact = length(vec_frag_to_impact);
    float angle_frag = atan(vec_frag_to_impact.y, vec_frag_to_impact.x); // Range: -PI to PI
    if (angle_frag < 0.0) {
        angle_frag += TWO_PI; // Normalize to 0 to 2*PI
    }
    float shard_id = floor(angle_frag / (TWO_PI / num_shards));

    // --- Staggered Animation Timing for each Shard ---
    // Use random for a less ordered shatter
    float shard_delay_normalized = random(vec2(shard_id, shard_id * 0.31)); 
    // float shard_delay_normalized = shard_id / num_shards; // For a sweep

    float individual_shard_anim_duration = 0.7; // How long each shard takes to animate
    float ripple_spread_factor = 1.0 - individual_shard_anim_duration;
    
    float stagger_start_progress = shard_delay_normalized * ripple_spread_factor;
    float stagger_end_progress = stagger_start_progress + individual_shard_anim_duration;

    // shard_anim_progress: 0.0 (shard starts moving in) -> 1.0 (shard is in place)
    float shard_anim_progress = smoothstep(stagger_start_progress, stagger_end_progress, animation_progress);

    if (shard_anim_progress < 0.001) { // Shard is not yet visible or fully shattered away
        return vec4(0.0); // Fully transparent
    }

    // --- Shard Transformation Parameters ---
    // current_displacement_factor: 1.0 (max shatter) -> 0.0 (assembled)
    float current_displacement_factor = 1.0 - shard_anim_progress;

    // Max translation (e.g., 30% of half window width)
    float max_translation_dist = length(vec2(window_size) * 0.5) * 0.3; 
    // Max rotation (e.g., 25 degrees)
    float max_rotation_angle_rad = (PI / 180.0) * 25.0 * random(vec2(shard_id * 0.7, shard_id)); // Add some randomness to rotation

    // Direction for this shard (center angle of the shard sector)
    float shard_center_angle = (shard_id + 0.5) * (TWO_PI / num_shards);
    vec2 shard_radial_dir = vec2(cos(shard_center_angle), sin(shard_center_angle));

    vec2 translation_offset = shard_radial_dir * max_translation_dist * current_displacement_factor;
    float current_rotation = max_rotation_angle_rad * current_displacement_factor;

    // --- Inverse Transformation for Sampling ---
    // We are at `texcoord` on screen. Find where this point came from on the original texture.
    // 1. Undo translation
    vec2 p1_translated_back = texcoord - translation_offset;

    // 2. Undo rotation around impact_point
    vec2 p1_rel_to_impact = p1_translated_back - impact_point;
    float cos_rot = cos(current_rotation); // Rotate by +angle to undo shatter rotation by -angle
    float sin_rot = sin(current_rotation); // (or vice-versa, depends on convention)
                                           // Let's assume shatter rotates by -current_rotation
                                           // So to undo, rotate by +current_rotation
    mat2 rot_matrix = mat2(cos_rot, -sin_rot, sin_rot, cos_rot);
    vec2 p2_rotated_back = rot_matrix * p1_rel_to_impact;
    vec2 sample_coord = p2_rotated_back + impact_point;

    // --- Boundary Check & Texture Fetch ---
    if (sample_coord.x >= 0.0 && sample_coord.x < float(window_size.x) &&
        sample_coord.y >= 0.0 && sample_coord.y < float(window_size.y)) {
        
        // --- Chromatic Aberration ---
        float ca_strength = 0.008 * current_displacement_factor; // Stronger when more shattered
        vec2 ca_offset_dir = shard_radial_dir; // Radial aberration
        // vec2 ca_offset_dir = vec2(-shard_radial_dir.y, shard_radial_dir.x); // Tangential

        vec2 r_sample = sample_coord + ca_offset_dir * ca_strength * float(window_size.x);
        vec2 b_sample = sample_coord - ca_offset_dir * ca_strength * float(window_size.x);

        out_color.r = texelFetch(tex, ivec2(r_sample), 0).r;
        out_color.g = texelFetch(tex, ivec2(sample_coord), 0).g; // Green channel from center
        out_color.b = texelFetch(tex, ivec2(b_sample), 0).b;
        out_color.a = texelFetch(tex, ivec2(sample_coord), 0).a; // Base alpha from original texture

    } else {
        out_color.a = 0.0; // Sampled point is outside original texture
    }

    // Modulate final alpha by shard's animation progress
    out_color.a *= shard_anim_progress;
    return out_color;
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
  return default_post_processing(anim_c);
}
