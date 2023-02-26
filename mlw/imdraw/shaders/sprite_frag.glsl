#version 330 core

in vec2 TexCoord;
in vec4 FragmentColor;
uniform sampler2D Texture;

out vec4 OutColor;

void main() 
{
    OutColor = texture(Texture, TexCoord);
}