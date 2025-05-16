#version 330

in vec2 texcoord;             // texture coordinate of the fragment

uniform sampler2D tex;        // texture of the window

uniform float u_burn_size = 0.03;  // hint_range(0.0, 1.0, 0.01)
uniform vec4 u_burn_color = vec4(1.0, 0.5, 0.0, 1.0); // source_color, e.g., (1.0, 0.5, 0.0, 1.0) for orange
uniform float u_noise_zoom = 5.0;; // New: Controls the "zoom" of the noise pattern.

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

// 1. Basic Pseudo-Random Number Generator (same as before)
float rand(vec2 co) {
  return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

// 2. Value Noise function
//    Generates smooth noise by interpolating random values on a grid.
float value_noise(vec2 p) {
    vec2 i = floor(p); // Integer part of p (grid cell)
    vec2 f = fract(p); // Fractional part of p (position within cell)

    // Smooth interpolation factor (smoothstep: f*f*(3.0-2.0*f))
    vec2 u = f * f * (3.0 - 2.0 * f);

    // Get random values for the 4 corners of the cell
    float val_a = rand(i + vec2(0.0, 0.0)); // Bottom-left
    float val_b = rand(i + vec2(1.0, 0.0)); // Bottom-right
    float val_c = rand(i + vec2(0.0, 1.0)); // Top-left
    float val_d = rand(i + vec2(1.0, 1.0)); // Top-right

    // Bilinear interpolation:
    // Interpolate along x for bottom and top edges
    float bottom_interp = mix(val_a, val_b, u.x);
    float top_interp = mix(val_c, val_d, u.x);
    // Interpolate along y between the two edge interpolations
    return mix(bottom_interp, top_interp, u.y);
}

// 3. Fractal Brownian Motion (fBm)
//    Combines multiple layers (octaves) of value_noise for a richer texture.
#define FBM_OCTAVES 4        // Number of noise layers to combine
#define FBM_PERSISTENCE 0.5  // How much detail is added or removed at each octave
#define FBM_LACUNARITY 2.0   // How much detail is added or removed at each octave

float fbm(vec2 p) {
    float total = 0.0;
    float frequency = 1.0;
    float amplitude = 0.5; // Start with 0.5 amplitude for normalization
    float max_value = 0.0; // Used to normalize the result to [0,1]

    for (int i = 0; i < FBM_OCTAVES; i++) {
        total += amplitude * value_noise(p * frequency);
        max_value += amplitude;
        amplitude *= FBM_PERSISTENCE;
        frequency *= FBM_LACUNARITY;
    }

    if (max_value == 0.0) return 0.0; // Avoid division by zero
    return total / max_value; // Normalize
}

vec4 anim(float time) { // time = 0.0 (dissolved) to 1.0 (revealed)
  vec4 main_texture = texelFetch(tex, ivec2(texcoord), 0);

  // Normalize pixel coordinates to [0,1] range
  vec2 uv = texcoord / vec2(window_size);

  // Generate smooth noise using FBM
  // u_noise_zoom controls how many noise features appear across the window.
  float noise_val = fbm(uv * u_noise_zoom);

  float dissolve_progress = time;

  float actual_burn_size = u_burn_size;
  if (dissolve_progress < 0.001 || dissolve_progress > 0.999) {
    actual_burn_size = 0.0;
  }

  float alpha_val = smoothstep(
    noise_val - actual_burn_size,
    noise_val,
    dissolve_progress
  );

  float border_mix = smoothstep(
    noise_val,
    noise_val + actual_burn_size,
    dissolve_progress
  );

  vec4 animated_color = main_texture;
  animated_color.rgb = mix(u_burn_color.rgb, main_texture.rgb, border_mix);
  animated_color.a *= alpha_val;

  return animated_color;
}

//  If you have semitransparent windows (like a terminal)
// You can use the below function to add an opacity threshold where the
// animation won't apply. For example, if you had your terminal
// configured to have 0.8 opacity, you'd set the below variable to 0.8
float max_opacity = 0.94;
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

// Default window shader:
// 1) fetch the specified pixel
// 2) apply default post-processing
vec4 window_shader() {
  vec4 c = texelFetch(tex, ivec2(texcoord), 0);
  c = default_post_processing(c);
  float opacity = opacity_threshold(c.w);
  if (opacity >= max_opacity)
  {
    return c;
  }
  if (opacity == 0.0)
  {
    return vec4(0);
  }
  vec4 anim_c = anim(opacity);
  if (anim_c.w < max_opacity)
  {
    return vec4(0);
  }
  anim_c = default_post_processing(anim_c);
  if (anim_c.w > 0.01)
  {
    anim_c.w = max_opacity;
  }
  return anim_c;
}

