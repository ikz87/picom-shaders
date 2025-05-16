For these shaders to work as intended, in the same rule you set the shader (see [the wiki](https://github.com/ikz87/picom-shaders/wiki/How-to-use#from-picoms-config-file)) you should also set an animation that changes opacity from 0 to 1 linearly.
You might use this as a base:
```
  match = "window_type = 'normal'";
  shader = "<picom-shaders-dir>/Animations/<animation-shader>.glsl";
  animations = ({
  opacity-duration = 0.5;
  triggers = ["open", "show"];
  opacity-curve = {
        curve = "cubic-bezier(0.5, 0.5, 0.5, 0.5)";
        start = 0;
        end = 1;
        duration = "opacity-duration";
        }
  opacity = "opacity-curve";
  }, {
  opacity-duration = 0.2;
  triggers = ["close", "hide"];
  opacity-curve = {
        curve = "cubic-bezier(0.5, 0.5, 0.5, 0.5)";
        start = 1;
        end = 0;
        duration = "opacity-duration";
        }
  opacity = "opacity-curve";
  }
)
```

If you're curious, you can see a more complex custom animation in my [picom config file](https://github.com/ikz87/dots-2.0/blob/personal/Configs/picom.conf)
