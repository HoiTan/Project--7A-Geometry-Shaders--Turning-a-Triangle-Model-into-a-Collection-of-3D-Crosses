#version 330 compatibility
#extension GL_EXT_gpu_shader4 : enable
#extension GL_EXT_geometry_shader4 : enable

layout(triangles) in;
layout(line_strip, max_vertices=78) out; 

uniform int   uLevel;          // number of triangle subdivisions
uniform float uQuantize;       // how strong the snapping is
uniform float uSize;           // size of each 3D Cross
uniform float uLightX, uLightY, uLightZ;

out vec3  gN;    // normal
out vec3  gL;    // vector from point to light
out vec3  gE;    // vector from point to eye

out float gZ;    // eye-coordinate negative-z (depth in eye space)

in  vec3  vN[3]; // the original normal from the vertex shader

vec3 V0, V1, V2;   // the incoming triangle vertex positions
vec3 V01, V02;     // edges from V0->V1 and V0->V2
vec3 N0, N1, N2;   // the incoming triangle normals
vec3 N01, N02;     // edges from N0->N1 and N0->N2

vec3 LIGHTPOSITION;

float
Quantize( float f )
{
    f *= uQuantize;
    int fi = int( f );
    f = float( fi ) / uQuantize;
    return f;
}

vec3
Quantize( vec3 v )
{
    return vec3( Quantize(v.x), Quantize(v.y), Quantize(v.z) );
}

//
// ProduceCrosses( float s, float t ) 
//   1. Interpolates the position in the subdivided triangle
//   2. Quantizes that position
//   3. Creates a 3D Cross in x, y, z directions
//   4. Outputs lines with per-fragment lighting data
//
void ProduceCrosses( float s, float t )
{
    // Interpolate the vertex position (before quantizing):
    vec3 v = V0 + s*V01 + t*V02;
    // Interpolate the normal:
    vec3 n = N0 + s*N01 + t*N02;

    v = Quantize( v );

    gN = normalize( gl_NormalMatrix * n );

    vec4 ECposition = gl_ModelViewMatrix * vec4(v, 1.);

    gE = normalize( -ECposition.xyz );


    vec4 ECLight = gl_ModelViewMatrix * vec4(LIGHTPOSITION, 1.);
    gL = normalize( ECLight.xyz - ECposition.xyz );

    gZ = -ECposition.z;
    
    
    // === X CROSS ===
    // Move "left" in x:
    vec3 crossLeft = v;
    crossLeft.x -= uSize;
    gl_Position = gl_ModelViewProjectionMatrix * vec4(crossLeft, 1.);
    EmitVertex();
    
    // Move "right" in x:
    vec3 crossRight = v;
    crossRight.x += uSize;
    gl_Position = gl_ModelViewProjectionMatrix * vec4(crossRight, 1.);
    EmitVertex();
    
    EndPrimitive();

    // === Y CROSS ===
    // Move "down" in y:
    vec3 crossDown = v;
    crossDown.y -= uSize;
    gl_Position = gl_ModelViewProjectionMatrix * vec4(crossDown, 1.);
    EmitVertex();
    
    // Move "up" in y:
    vec3 crossUp = v;
    crossUp.y += uSize;
    gl_Position = gl_ModelViewProjectionMatrix * vec4(crossUp, 1.);
    EmitVertex();

    EndPrimitive();

    // === Z CROSS ===
    // Move "backward" in z:
    vec3 crossBack = v;
    crossBack.z -= uSize;
    gl_Position = gl_ModelViewProjectionMatrix * vec4(crossBack, 1.);
    EmitVertex();
    
    // Move "forward" in z:
    vec3 crossForward = v;
    crossForward.z += uSize;
    gl_Position = gl_ModelViewProjectionMatrix * vec4(crossForward, 1.);
    EmitVertex();
    
    EndPrimitive();
}

void main( )
{
    V0 = gl_PositionIn[0].xyz;
    V1 = gl_PositionIn[1].xyz;
    V2 = gl_PositionIn[2].xyz;
    V01 = V1 - V0;
    V02 = V2 - V0;

    N0  = vN[0].xyz;
    N1  = vN[1].xyz;
    N2  = vN[2].xyz;
    N01 = N1 - N0;
    N02 = N2 - N0;

    // 3) Convert the user-specified light position (World Space) to a vec3
    LIGHTPOSITION = vec3(uLightX, uLightY, uLightZ);

    // 4) Subdivide:
    //    We use a scheme where uLevel is the exponent for the number of layers.
    //    if uLevel = 3 => numLayers = 2^3 = 8 layers
    int numLayers = 1 << uLevel;   // 2^uLevel

    float dt = 1.0 / float(numLayers);
    float t  = 1.0;

    for( int it = 0; it <= numLayers; it++ )
    {
        float smax = 1.0 - t;
        int nums = it + 1;
        // If it=0 => t=1 => smax=0 => only 1 vertex at V0
        // If it=numLayers => t=0 => smax=1 => we have (numLayers+1) vertices along bottom edge

        float ds = (nums > 1) ? smax / float(nums - 1) : 0.;
        float s  = 0.0;
        
        for( int is = 0; is < nums; is++ )
        {
            ProduceCrosses( s, t );
            s += ds;
        }
        t -= dt;
    }
}