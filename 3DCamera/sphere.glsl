#version 430
#define PI 3.14159265

// These shaders work by using a pinhole camera and raycasting
// The window 3d objects will always be (somewhat) centered at (0, 0, 0)
struct pinhole_camera
{
    float focal_offset; // Distance along the Z axis between the camera 
                        // center and the focal point. Use negative values
                        // so the image doesn't flip
                        // This kinda works like FOV in games

    // Transformations 
    // Use these to modify the coordinate system of the camera plane
    vec3 rotations; // Rotations in radians around each axis 
                    // The camera plane rotates around 
                    // its center point, not the origin

    vec3 translations; // Translations in pixels along each axis

    vec3 deformations; // Deforms the camera. Higher values on each axis
                       // means the window will be squashed in that axis

    // ---------------------------------------------------------------// 
    
    // "Aftervalues" 
    // These will be set later with setup_camera(), leave them as 0
    vec3 base_x;
    vec3 base_y;
    vec3 base_z;
    vec3 center_point;
    vec3 focal_point;
};

in vec2 texcoord;             // texture coordinate of the fragment

uniform sampler2D tex;        // texture of the window


uniform float time; // Time in miliseconds.
      
float time_cyclic = mod(time/10000,2); // Like time, but in seconds and resets to 
                                       // 0 when it hits 2. Useful for using it in 
                                       // periodic functions like cos and sine

// Time variables can be used to change transformations over time


ivec2 window_size = textureSize(tex, 0); // Size of the window

float window_diagonal = length(window_size); // Diagonal of the window
                                             //
int wss = min(window_size.x, window_size.y); // Window smallest side, useful when squaring windows
// Try to keep focal offset and translations proportional to window_size components 
// or window_diagonal as you see fit

pinhole_camera camera = 
pinhole_camera(-window_size.y/2,   // Focal offset
               vec3(0,0,0), // Rotations
               vec3(0,0,0), // Translations
               vec3(1,1,1), // Deformations
               // Leave the rest as 0
               vec3(0),
               vec3(0),
               vec3(0),
               vec3(0),
               vec3(0));

// Here are some presets you can use

// Moves the camera up and down
pinhole_camera bobbing = 
pinhole_camera(-window_size.y/2,
               vec3(0,0,0),
               vec3(0,cos(time_cyclic*PI)*window_size.y/16,-window_size.y/4),
               vec3(1,1,1),
               vec3(0),
               vec3(0),
               vec3(0),
               vec3(0),
               vec3(0));

// Rotates camera around the origin
// Makes the window rotate around the Y axis from the camera's POV
// (if the window is centered)
pinhole_camera rotate_around_origin = 
pinhole_camera(-wss,
               vec3(PI/6*sin(2*time_cyclic*PI),-time_cyclic*PI-PI/2,0),
               vec3(cos(time_cyclic*PI)*wss,
                    wss/2*sin(2*time_cyclic*PI),
                    sin(time_cyclic*PI)*wss),
               vec3(1,1,1),
               vec3(0),
               vec3(0),
               vec3(0),
               vec3(0),
               vec3(0));

// Rotate camera around its center
pinhole_camera rotate_around_itself = 
pinhole_camera(-wss,
               vec3(0,-time_cyclic*PI-PI/2,0),
               vec3(0,0,-wss),
               vec3(1,1,1),
               vec3(0),
               vec3(0),
               vec3(0),
               vec3(0),
               vec3(0));

// Here you can select the preset to use
pinhole_camera window_cam = rotate_around_origin;



ivec2 window_center = ivec2(window_size.x/2, window_size.y/2); 

// Default window post-processing:
// 1) invert color
// 2) opacity / transparency
// 3) max-brightness clamping
// 4) rounded corners
vec4 default_post_processing(vec4 c);

// Sets up a camera by applying transformations and 
// calculating xyz vector basis 
pinhole_camera setup_camera(pinhole_camera camera)
{
    // Apply translations
    camera.center_point += camera.translations;

    // Apply rotations 
    // We initialize our vector basis as normalized vectors
    // in each axis * our deformations vector
    camera.base_x = vec3(camera.deformations.x, 0, 0);
    camera.base_y = vec3(0, camera.deformations.y, 0);
    camera.base_z = vec3(0, 0, camera.deformations.z);


    // Then we rotate them around following our rotations vector:
    // First save these values to avoid redundancy
    float cosx = cos(camera.rotations.x);
    float cosy = cos(camera.rotations.y);
    float cosz = cos(camera.rotations.z);
    float sinx = sin(camera.rotations.x);
    float siny = sin(camera.rotations.y);
    float sinz = sin(camera.rotations.z);
    
    // Declare a buffer vector we will use to apply multiple changes at once
    vec3 tmp = vec3(0);

    // Rotations for base_x:
    tmp = camera.base_x;
    // X axis:
    tmp.y =  camera.base_x.y * cosx - camera.base_x.z * sinx;
    tmp.z =  camera.base_x.y * sinx + camera.base_x.z * cosx;
    camera.base_x = tmp;
    // Y axis:
    tmp.x =  camera.base_x.x * cosy + camera.base_x.z * siny;
    tmp.z = -camera.base_x.x * siny + camera.base_x.z * cosy;
    camera.base_x = tmp;
    // Z axis:
    tmp.x =  camera.base_x.x * cosz - camera.base_x.y * sinz;
    tmp.y =  camera.base_x.x * sinz + camera.base_x.y * cosz;
    camera.base_x = tmp;

    // Rotations for base_y:
    tmp = camera.base_y;
    // X axis:
    tmp.y =  camera.base_y.y * cosx - camera.base_y.z * sinx;
    tmp.z =  camera.base_y.y * sinx + camera.base_y.z * cosx;
    camera.base_y = tmp;
    // Y axis:
    tmp.x =  camera.base_y.x * cosy + camera.base_y.z * siny;
    tmp.z = -camera.base_y.x * siny + camera.base_y.z * cosy;
    camera.base_y = tmp;
    // Z axis:
    tmp.x =  camera.base_y.x * cosz - camera.base_y.y * sinz;
    tmp.y =  camera.base_y.x * sinz + camera.base_y.y * cosz;
    camera.base_y = tmp;

    // Rotations for base_z: 
    tmp = camera.base_z;
    // X axis:
    tmp.y =  camera.base_z.y * cosx - camera.base_z.z * sinx;
    tmp.z =  camera.base_z.y * sinx + camera.base_z.z * cosx;
    camera.base_z = tmp;
    // Y axis:
    tmp.x =  camera.base_z.x * cosy + camera.base_z.z * siny;
    tmp.z = -camera.base_z.x * siny + camera.base_z.z * cosy;
    camera.base_z = tmp;
    // Z axis:
    tmp.x =  camera.base_z.x * cosz - camera.base_z.y * sinz;
    tmp.y =  camera.base_z.x * sinz + camera.base_z.y * cosz;
    camera.base_z = tmp;

    // Now that we have our transformed 3d orthonormal base 
    // we can calculate our focal point 
    camera.focal_point = camera.center_point + camera.base_z * camera.focal_offset;

    // Return our set up camera
    return camera;
}

// Gets a pixel from the end of a ray projected to an axis
vec4 get_pixel_from_projection(float t, pinhole_camera camera, vec3 focal_vector)
{
    // If the point we end up in is behind our camera, don't "render" it
    if (t < 1)
    {
        return vec4(0);
    }

    // Then we multiply our focal vector by t and add our focal point to it
    // to end up in a point inside the window plane 
    vec3 intersection = focal_vector * t + camera.focal_point;
    

    // Save necessary coordinates
    vec2 cam_coords = intersection.xy;
    
    // Square window trickery
    if (window_size.x > window_size.y)
    {
        cam_coords.x /= window_size.y/float(window_size.x);
        cam_coords.xy += window_center.xy;
    }
    else if (window_size.x < window_size.y)
    {
        cam_coords.y /= window_size.x/float(window_size.y);
        cam_coords.xy += window_center.xy;
    }

    // If pixel is outside of our window region
    // return a dimmed pixel with the window's border color
    if (cam_coords.x >=window_size.x-1 || 
        cam_coords.y >=window_size.y-1 ||
        cam_coords.x <=0 || cam_coords.y <=0)
    {
        cam_coords.x = 0;
        cam_coords.y = window_center.y;
        vec4 pixel = texelFetch(tex, ivec2(cam_coords), 0);
        pixel *= 0.5;
        return pixel;
    }

    // Fetch the pixel
    vec4 pixel = texelFetch(tex, ivec2(cam_coords), 0);

    return pixel;
}

// Combines colors using alpha
// Got this from https://stackoverflow.com/questions/64701745/how-to-blend-colours-with-transparency
// Not sure how it works honestly lol
vec4 alpha_composite(vec4 color1, vec4 color2)
{
    float ar = color1.w + color2.w - (color1.w * color2.w);
    float asr = color2.w / ar;
    float a1 = 1 - asr;
    float a2 = asr * (1 - color1.w);
    float ab = asr * color1.w;
    vec4 outcolor;
    outcolor.xyz = color1.xyz * a1 + color2.xyz * a2 + color2.xyz * ab;
    outcolor.w = ar;
    return outcolor;
}

// Gets a pixel through the camera using coords as coordinates in
// the camera plane
vec4 get_pixel_through_camera(vec2 coords, pinhole_camera camera)
{
    // Offset coords
    coords -= window_center;

    // Find the pixel 3d position using the camera vector basis
    vec3 pixel_3dposition =   camera.center_point 
                            + coords.x * camera.base_x 
                            + coords.y * camera.base_y;

    // Get the vector going from the focal point to the pixel in 3d sapace
    vec3 focal_vector = pixel_3dposition - camera.focal_point;

    // Following the sphere EQ (with Y axis as center)
    // x^2 + y^2 + z^2 = r^2
    float r = min(window_size.x, window_size.y)/(PI/2);

    // Then there's a line going from our focal point to the cylinder
    // which we can describe as:
    // x(t) = focal_point.x + focal_vector.x * t
    // y(t) = focal_point.y + focal_vector.y * t
    // z(t) = focal_point.z + focal_vector.z * t
    // We substitute x, y and z with x(t) and z(t) in the cylinder EQ
    // Solving for t we get a cuadratic EQ which we solve with the 
    // cuadratic formula:

    // We calculate focal vector and focal point values squared 
    // to avoid redundancy
    vec3 fvsqr;
    vec3 fpsqr;

    fvsqr.x = pow(focal_vector.x,2);
    fvsqr.y = pow(focal_vector.y,2);
    fvsqr.z = pow(focal_vector.z,2);

    fpsqr.x = pow(camera.focal_point.x,2);
    fpsqr.y = pow(camera.focal_point.y,2);
    fpsqr.z = pow(camera.focal_point.z,2);

    // Coeficients of our EQ
    float a = fvsqr.x + fvsqr.y + fvsqr.z;
    float b = 2*(camera.focal_point.x*focal_vector.x
                +camera.focal_point.y*focal_vector.y
                +camera.focal_point.z*focal_vector.z);
    float c = fpsqr.x + fpsqr.y + fpsqr.z - pow(r,2);

    // If there are no real roots, then there's no intersection and we 
    // return an empty pixel
    float formulasqrt = pow(b,2)-4*a*c;
    if (formulasqrt < 0) 
    {
        return vec4(0);
    }

    vec2 t[2]; // A float should be used for this instead, but the shader
               // isn't rendered correctly when I use a float
               // Cursed, but it works

    // Solve with general formula
    t[0].x = (-b + sqrt(formulasqrt))/(2*a);
    t[1].x = (-b - sqrt(formulasqrt))/(2*a);
    t[0].y = 0;
    t[1].y = 0;
    

    // Bubble sort to know which intersections happen first
    for (int i = 0; i < t.length(); i++)
    {
        for (int j = 0; j < t.length(); j++)
        {
            if (t [j].x > t[j+1].x)
            {
                vec2 tmp = t[j];
                t[j] = t[j+1];
                t[j+1] = tmp;
            }
        }
    }

    // Then we go through each one of the intersections in order 
    // and mix pixels together using alpha
    vec4 blended_pixels = vec4(0);
    for (int i = 0; i < t.length(); i++)
    {
        // We get the pixel through projection
        vec4 projection_pixel = get_pixel_from_projection(t[i].x, 
                                                          camera,
                                                          focal_vector);
        if (projection_pixel.w > 0.0)
        {
            // Blend the pixel using alpha
            blended_pixels = alpha_composite(projection_pixel, blended_pixels);
        }
    }
    return blended_pixels;
}

// Main function
vec4 window_shader() {
    pinhole_camera transformed_cam = setup_camera(window_cam);
    return(get_pixel_through_camera(texcoord, transformed_cam));
}
