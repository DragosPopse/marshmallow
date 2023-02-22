#version 330 core

in vec4 VertexColor;
in vec2 TexCoord;
out vec4 oFragColor;

uniform vec3 u_Color;
uniform sampler2D u_Tex1;
//uniform sampler2D u_Tex2;

void main() 
{
    vec4 someColor = VertexColor * vec4(u_Color, 1.0);
    //someColor += 1.0;
    //oFragColor =  someColor * mix(texture(u_Tex1, TexCoord), texture(u_Tex2, TexCoord), 0.2);
    oFragColor = someColor * texture(u_Tex1, TexCoord);
}