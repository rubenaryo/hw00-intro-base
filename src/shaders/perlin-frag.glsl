#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

#define NUM_CELLS 8

float rand(vec3 pos)
{
    return fract(sin(dot(pos, vec3(64.25375463, 23.27536534, 86.29678483))) * 59482.7542);
}

vec3 get_worley_point(ivec3 cellCoord)
{
    vec3 cell = vec3(cellCoord / NUM_CELLS);
    float noiseX = rand(vec3(cell));
    float noiseY = rand(vec3(cell.yxz));
    float noiseZ = rand(vec3(cell.zyx));
    return cell + (0.5 + 1.5*vec3(noiseX, noiseY, noiseZ)) / float(NUM_CELLS);
}

float worley(vec3 coord)
{
    ivec3 cell = ivec3(coord * float(NUM_CELLS));
    float dist = 1.0;

    for (int x = -2; x < 3; ++x)
    {
        for (int y = -2; y < 3; ++y)
        {
            for (int z = -2; z < 3; ++z)
            {
                vec3 neighbor_cell = get_worley_point(cell + ivec3(x, y, z));
                dist = min(dist, distance(neighbor_cell, coord));
            }
        }
    }

    dist /= length(vec3(1.0 / float(NUM_CELLS)));
    dist = 1.0 - dist;
    return dist;
}

float perlin3d(vec3 pos)
{
    float total = 0.0;
    float persistence = 1.0 / 2.0;

    for (int i = 0; i < 8; i++)
    {
        float freq = pow(2.0, float(i));
        float amp = pow(persistence, float(i));

        total += rand(pos.xyz);
    }
    
    return total;
}

void main()
{
    // Material base color (before shading)
    vec4 diffuseColor = u_Color;

    // Calculate the diffuse term for Lambert shading
    float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
    // Avoid negative lighting values
    // diffuseTerm = clamp(diffuseTerm, 0, 1);

    float ambientTerm = 0.2;

    float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

    // Compute final shaded color
    out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);

    float worley = worley(fs_Pos.zyz);
    out_Col = vec4(worley, worley, worley, 1);
}
