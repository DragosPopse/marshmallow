#version 300 es

precision mediump float;

in vec4 VertexColor;
in vec3 VertexNormal;
out vec4 FragmentColor;

void main() {
    FragmentColor = vec4(VertexNormal, 1.0);
}