#version 330 core

layout (location = 0) in vec3 aPos; // Encapsulates both position and rotation
layout (location = 1) in vec4 aCol;
layout (location = 2) in vec2 aTex;
layout (location = 3) in vec2 aCenter;

out vec4 VertexColor;
out vec2 TexCoords;
out vec3 FragPos;

uniform mat4 imdraw_MVP;

mat4 rotate(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat4(c, s, 0.0, 0.0,
        -s, c, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0);
}

mat4 translate(vec2 pos) {
    return mat4(1.0, 0.0, 0.0, 0.0,
            0.0, 1.0, 0.0, 0.0,
            0.0, 0.0, 1.0, 0.0,
            pos.x, pos.y, 0.0, 1.0);
}



void main() {
    vec4 position = vec4(aPos.xy, 0.0, 1.0);
    position.xy -= aCenter;
    position = rotate(aPos.z) * position;
    position.xy += aCenter;
    gl_Position = imdraw_MVP * position;
    VertexColor = aCol;
    TexCoords = aTex;
}