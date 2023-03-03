#version 330 core

layout (location = 0) in vec3 aPos;
layout (location = 1) in vec2 aTexCoord;
layout (location = 2) in vec3 aOffset;

out vec4 VertexColor;
out vec2 TexCoord;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;


void main() 
{
    vec3 pos = aPos * (gl_InstanceID / 100.0);
    gl_Position = projection * view * model * vec4(pos + aOffset, 1.0);
    VertexColor = vec4(1.0, 1.0, 1.0, 1.0);
    TexCoord = aTexCoord;
}