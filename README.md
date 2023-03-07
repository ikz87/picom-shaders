# Picom shaders
## A list of GLSL shaders meant to be use alongside the picom compositor.

### How do I run these?
From the command line:
```
picom --no-use-damage --window-shader-fg <path_to_shader>
```
From picom config: 
```
# GLX backend: Use specified GLSL fragment shader for rendering window contents.        
# See `compton-default-fshader-win.glsl` and `compton-fake-transparency-fshader-win.glsl
# in the source tree for examples.    
#    
window-shader-fg = "<path_to_shader>";
``` 

Note that `--no-use-damage` is not necessary, but recommendeed.

### How to run different shaders for different windows?
Append the following at the end of your picom config file:
```
window-shader-fg-rule = [
  "<absolute_path_to_shader>:class_g = '<window_class>'",
];
```
Then the shader at `<absolute_path_to_shader>` will be applied to all windows with class `<window_class>`.


May or may not add more fun shaders.
