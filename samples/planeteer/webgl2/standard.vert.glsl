#version 300 es

layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aNormal;

out vec4 VertexColor;
out vec3 VertexNormal;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;


void main() 
{
    gl_Position = projection * view * model * vec4(aPos, 1.0);
    //VertexColor = vec4(1.0, 1.0, 1.0, 1.0);
    VertexColor = gl_Position;
    VertexNormal = aNormal;
}