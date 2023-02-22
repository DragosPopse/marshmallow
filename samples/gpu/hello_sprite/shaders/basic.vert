#version 330 core

layout (location = 0) in vec3 aPos;
layout (location = 1) in vec2 aTexCoord;

out vec4 VertexColor;
out vec2 TexCoord;


void main() 
{
    gl_Position =  vec4(aPos.xyz, 1.0);
    VertexColor = vec4(1.0, 1.0, 1.0, 1.0);
    TexCoord = aTexCoord;
}