#version 330 core

layout (location = 0) in vec3 aPosition;
layout (location = 1) in vec2 aTexCoord;

out vec2 TexCoord;
out vec4 FragmentColor;

uniform mat4 Model;
uniform vec4 Color;

uniform mat4 View;
uniform mat4 Projection;


void main() 
{
    gl_Position = Projection * View * Model * vec4(aPosition, 1.0);
    FragmentColor = Color;
    TexCoord = aTexCoord;
}