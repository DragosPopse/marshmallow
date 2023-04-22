#version 330 core

layout (location = 0) in vec3 aPos;
layout (location = 1) in vec4 aCol;
layout (location = 2) in vec2 aTex;

out vec4 VertexColor;
out vec2 TexCoords;
out vec3 FragPos;

uniform mat4 imdraw_MVP;


void main() 
{
    gl_Position = imdraw_MVP * vec4(aPos, 1.0);
    VertexColor = aCol;
    TexCoords = aTex;
}