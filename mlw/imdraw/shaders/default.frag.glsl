#version 330 core

in vec4 VertexColor;
in vec2 TexCoords;

out vec4 FragmentColor;

// If you want to customize the fragment shader, this will be your first texture. You must include this.
uniform sampler2D imdraw_Atlas;

void main() {
    FragmentColor = texture(imdraw_Atlas, TexCoords) * VertexColor;
}