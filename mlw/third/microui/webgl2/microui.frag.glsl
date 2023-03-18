#version 300 es

precision mediump float;

in vec4 VertexColor;
in vec2 TexCoords;

out vec4 FragmentColor;

uniform sampler2D atlas;

void main() {
    FragmentColor = texture(atlas, TexCoords) * VertexColor;
}