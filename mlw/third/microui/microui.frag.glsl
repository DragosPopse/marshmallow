#version 330 core

in vec4 VertexColor;
in vec2 TexCoords;
out vec4 FragmentColor;

uniform sampler2D atlas;

void main() {
    //FragmentColor.rgb = texture(atlas, TexCoords).a * VertexColor.rgb;
    //FragmentColor.a = texture(atlas, TexCoords).a;
    FragmentColor = texture(atlas, TexCoords) * VertexColor;
}