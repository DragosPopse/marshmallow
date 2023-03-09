#version 330 core

layout (location = 0) in vec3 aPos;
layout (location = 1) in vec4 aCol;
layout (location = 2) in vec2 aTex;

out vec4 VertexColor;
out vec2 TexCoords;

uniform mat4 modelview;
uniform mat4 projection;


void main() 
{
    gl_Position = projection * modelview * vec4(aPos, 1.0);
    VertexColor = aCol;
    TexCoords = aTex;
}