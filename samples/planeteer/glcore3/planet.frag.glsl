#version 330 core

in vec4 VertexColor;
in vec3 VertexNormal;
in vec3 ObjectSpacePosition;
out vec4 FragmentColor;

uniform vec2 ElevationMinMax;
uniform sampler2D Gradient;

float inverse_lerp(float a, float b, float value) {
    return (value - a) / (b - a);
}

void main() {
    float altitude = inverse_lerp(ElevationMinMax.x, ElevationMinMax.y, length(ObjectSpacePosition));
    FragmentColor = vec4(texture(Gradient, vec2(altitude, altitude)), 1.0);
}