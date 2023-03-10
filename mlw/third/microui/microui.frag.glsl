#version 330 core

in vec4 VertexColor;
in vec2 TexCoords;
in vec3 FragPos;

out vec4 FragmentColor;

uniform sampler2D atlas;

void main() {
    //FragmentColor.rgb = texture(atlas, TexCoords).a * VertexColor.rgb;
    //FragmentColor.a = texture(atlas, TexCoords).a;
    FragmentColor = texture(atlas, TexCoords) * VertexColor;
    // FragmentColor = vec4(abs(FragPos), 1);
    //FragmentColor = texture(atlas, vec2(0.0938, 0.6250));
    //FragmentColor = vec4(texture(atlas, vec2(0.02422, 1.0 - 0.6016)).aaa, 1);
    //vec4 sampleColor = texture(atlas, 1 - TexCoords);
    //FragmentColor = vec4(sampleColor.w, sampleColor.w, sampleColor.w, 1);

}