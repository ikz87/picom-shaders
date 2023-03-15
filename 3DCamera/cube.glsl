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
pinhole_camera(-window_diagonal,
               vec3(0,-time_cyclic*PI-PI/2,0),
               vec3(cos(time_cyclic*PI)*window_diagonal,
                    sin(time_cyclic*PI*2)*window_diagonal/2,
                    sin(time_cyclic*PI)*window_diagonal),
               vec3(1,1,1),
               vec3(0),
               vec3(0),
               vec3(0),
               vec3(0),
               vec3(0));

// Rotate camera around its center
pinhole_camera rotate_around_itself = 
pinhole_camera(-window_diagonal,
               vec3(0,-time_cyclic*PI-PI/2,0),
               vec3(0,0,-window_diagonal),
               vec3(1,1,1),
               vec3(0),
               vec3(0),
               vec3(0),
               vec3(0),
               vec3(0));

// Here you can select the preset to use
pinhole_camera window_cam = rotate_around_origin;



ivec2 window_center = ivec2(window_size.x/2, window_size.y/2); 
int wss = min(window_size.x, window_size.y);

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
    // Z axis:
    tmp.x =  camera.base_y.x * cosz - camera.base_y.y * sinz;
    tmp.y =  camera.base_y.x * sinz + camera.base_y.y * cosz;
    camera.base_y = tmp;

    // Rotations for base_z: 
    tmp = camera.base_z;
    // Y axis:
    tmp.x =  camera.base_z.x * cosy + camera.base_z.z * siny;
    tmp.z = -camera.base_z.x * siny + camera.base_z.z * cosy;
    camera.base_z = tmp;
    // X axis:
    tmp.y =  camera.base_z.y * cosx - camera.base_z.z * sinx;
    tmp.z =  camera.base_z.y * sinx + camera.base_z.z * cosx;
    camera.base_z = tmp;

    // Now that we have our transformed 3d orthonormal base 
    // we can calculate our focal point 
    camera.focal_point = camera.center_point + camera.base_z * camera.focal_offset;

    // Return our set up camera
    return camera;
}

// Gets a pixel from the end of a ray projected to an axis
vec4 get_pixel_from_projection(float t, int face, pinhole_camera camera, vec3 focal_vector)
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
    vec2 cam_coords;
    switch (face) 
    {
        case 0:
            cam_coords = intersection.xy;
            break;
        case 1:
            cam_coords = intersection.xy;
            break;
        case 2:
            cam_coords = intersection.zy;
            break;
        case 3:
            cam_coords = intersection.zy;
            break;
        case 4:
            cam_coords = intersection.zx;
            break;
        case 5:
            cam_coords = intersection.zx;
            break;
    }
    
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
    // return a completely transparent color
    if (cam_coords.x >=window_size.x-1 || 
        cam_coords.y >=window_size.y-1 ||
        cam_coords.x <=0 || cam_coords.y <=0)
    {
        return vec4(0);
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

    // We need 6 planes, one for each face of the cube, they all follow the plane EQ
    // ax + by + cz + d
    float a[] = {0,0,
                 1,1,
                 0,0};
    float b[] = {0,0,
                 0,0,
                 1,1};
    float c[] = {1,1,
                 0,0,
                 0,0};
    float d[] = {-wss/2.0,wss/2.0,
                 -wss/2.0,wss/2.0,
                 -wss/2.0,wss/2.0};
    // Then there's a line going from our focal point to each of the planes 
    // which we can describe as:
    // x(t) = focal_point.x + focal_vector.x * t
    // y(t) = focal_point.y + focal_vector.y * t
    // z(t) = focal_point.z + focal_vector.z * t
    // We substitute x, y and z with x(t), y(t) and z(t) in the plane EQ
    // Solving for t we get:
    vec2 t[6]; // we use a vec2 to also store the plane that was hit
    for (int i = 0; i < t.length(); i++)
    {
        t[i].x = (d[i] 
                - a[i]*camera.focal_point.x 
                - b[i]*camera.focal_point.y 
                - c[i]*camera.focal_point.z)
            / (a[i]*focal_vector.x 
                    + b[i]*focal_vector.y 
                    + c[i]*focal_vector.z);
        t[i].y = i;
    }
    
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
                                                          int(t[i].y),
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
