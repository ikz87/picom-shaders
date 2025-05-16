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
float max_opacity = 1;
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

vec4 anim(float time) {
  vec4 c = texelFetch(tex, ivec2(texcoord), 0);
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
  return default_post_processing(anim_c);
}

