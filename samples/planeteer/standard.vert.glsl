#version 330 core

layout (location = 0) in vec3 aPos;

out vec4 VertexColor;



void main() 
{
    gl_Position = vec4(aPos, 1.0);
    VertexColor = vec4(1.0, 1.0, 1.0, 1.0);
}