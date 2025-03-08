#version 330 compatibility

//
// Per-fragment lighting (Blinn-Phong or Phong-style).
// Also includes the ChromaDepth extra credit if desired.
//

uniform vec4  uColor;         // base color
uniform float uKa;            // ambient coefficient
uniform float uKd;            // diffuse coefficient
uniform float uKs;            // specular coefficient
uniform float uShininess;     // specular exponent

// For ChromaDepth extra credit:
uniform bool  uUseChromaDepth;
uniform float uRedDepth;      // near-plane (eye-coord) at which color is red
uniform float uBlueDepth;     // far-plane (eye-coord) at which color is blue

in vec3   gN;   // normal (already normalized in geometry, but let's be sure)
in vec3   gL;   // vector from point to light
in vec3   gE;   // vector from point to eye
in float  gZ;   // negative eye-coordinate z (only used if uUseChromaDepth)

out vec4  fragColor;


// Optional: A small "rainbow" function for ChromaDepth
// This version uses a 0→1 input where 0 is red, 1 is blue, 
// but we ramp through green in the middle. 

vec3 Rainbow( float t )
{
    t = clamp( t, 0., 1. ); // 0 => red, ~0.33 => green, ~0.67 => blue

    float r = 1.;
    float g = 0.;
    float b = 1. - 6. * ( t - (5./6.) );

    if( t <= (5./6.) )
    {
        r = 6. * ( t - (4./6.) );
        g = 0.;
        b = 1.;
    }
    if( t <= (4./6.) )
    {
        r = 0.;
        g = 1. - 6. * ( t - (3./6.) );
        b = 1.;
    }
    if( t <= (3./6.) )
    {
        r = 0.;
        g = 1.;
        b = 6. * ( t - (2./6.) );
    }
    if( t <= (2./6.) )
    {
        r = 1. - 6. * ( t - (1./6.) );
        g = 1.;
        b = 0.;
    }
    if( t <= (1./6.) )
    {
        r = 1.;
        g = 6. * t;
        b = 0.;
    }

    return vec3(r, g, b);
}

void main( )
{
    // Re-normalize just in case:
    vec3 N = normalize(gN);
    vec3 L = normalize(gL);
    vec3 E = normalize(gE);

    // Compute standard diffuse and specular:
    float d = max( 0., dot(N,L) );

    vec3 H = normalize( L + E );
    float s = pow( max( 0., dot(N, H) ), uShininess );

    // Combine them:
    vec3 baseColor = uColor.rgb;
    vec3 ambient   = uKa * baseColor;
    vec3 diffuse   = uKd * d * baseColor;
    vec3 specular  = uKs * s * vec3(1.,1.,1.);

    vec3 finalColor = ambient + diffuse + specular;

    // // Extra Credit: ChromaDepth 
    // // If turned on, override the final color based on eye-space depth
    if( uUseChromaDepth )
    {
        float t = (2./3.) * ( abs(gE.z) - uRedDepth ) / ( uBlueDepth - uRedDepth );
        t = clamp( t, 0., 2./3. );
        finalColor = Rainbow( t );
    }

    fragColor = vec4( finalColor, uColor.a );
}
