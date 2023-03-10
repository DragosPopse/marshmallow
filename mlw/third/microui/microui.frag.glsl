#version 330 core

in vec4 VertexColor;
in vec2 TexCoords;
out vec4 FragmentColor;

uniform sampler2D atlas;

void main() {
    //FragmentColor.rgb = texture(atlas, TexCoords).a * VertexColor.rgb;
    //FragmentColor.a = texture(atlas, TexCoords).a;
    FragmentColor = texture(atlas, TexCoords) * VertexColor;
    //FragmentColor = texture(atlas, vec2(0.0938, 0.6250));
    //FragmentColor = vec4(texture(atlas, vec2(0.02422, 1.0 - 0.6016)).aaa, 1);
}