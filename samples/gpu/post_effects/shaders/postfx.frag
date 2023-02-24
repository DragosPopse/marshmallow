#version 330 core

in vec4 VertexColor;
in vec2 TexCoord;
out vec4 oFragColor;

uniform sampler2D u_Tex1;

void main() 
{
    oFragColor = texture(u_Tex1, TexCoord);
}