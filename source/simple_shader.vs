#version 410

uniform float size;
uniform vec3 position;
in vec2 vertex;
#define M_PI 3.1415926535897932384626433832795
void main(){
     float angle = 2 * M_PI / 8;
     vec4 p = vec4(vertex * size,0,1);
     p.y += position.y  + (position.z + position.x) * cos(angle);
    
     p.x += (position.x - position.z) * sin(angle);
     p.xy *= 0.3;
     p.y *= -1;
     gl_Position = p;
}
