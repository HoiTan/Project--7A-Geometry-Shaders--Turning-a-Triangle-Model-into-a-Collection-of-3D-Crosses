#version 330 compatibility

out vec3	vN;

void
main( )
{
	vN = gl_Normal;
	gl_Position = gl_Vertex;
}