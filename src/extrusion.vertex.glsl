#ifdef GL_ES
precision highp float;
#else
#define lowp
#define mediump
#define highp
#endif

attribute vec2 a_pos;
attribute vec3 a_normal;
attribute float a_edgedistance;
uniform mat4 u_matrix;
uniform lowp vec3 u_lightdir;
uniform vec3 u_lightcolor;
uniform lowp float u_lightintensity;
uniform lowp vec4 u_outline_color;
varying vec4 v_color;

#ifndef MAPBOX_GL_JS
attribute float minH;
attribute float maxH;
#else
#pragma mapbox: define lowp float minH
#pragma mapbox: define lowp float maxH
#endif

#pragma mapbox: define lowp vec4 color

void main() {
#ifdef MAPBOX_GL_JS
    #pragma mapbox: initialize lowp float minH
    #pragma mapbox: initialize lowp float maxH
#endif
    #pragma mapbox: initialize lowp vec4 color

    float ed = a_edgedistance; // use each attrib in order to not trip a VAO assert
    float t = mod(a_normal.x, 2.0);

    gl_Position = u_matrix * vec4(a_pos, t > 0.0 ? maxH : minH, 1);

#ifdef OUTLINE
    color = u_outline_color;
#endif

    vec3 lightcolor = u_lightcolor;

    // How dark/bright is the surface color?
    float colorvalue = (color.r + color.g + color.b) / 3.0;

    v_color = vec4(0.0, 0.0, 0.0, 1.0);

    // Add slight ambient lighting so no extrusions are totally black
    // TODO: include the lightintensity in the calculation?
    vec4 ambientlight = vec4(0.03, 0.03, 0.03, 1.0);
    color += ambientlight;

    // Calculate cos(theta), where theta is the angle between surface normal and diffuse light ray
    //float directional = clamp(dot(a_normal / 32768.0, u_lightdir), 0.0, 1.0);
    float directional = clamp(dot(a_normal / 16384.0, u_lightdir), 0.0, 1.0);

    // Adjust directional so that
    // the range of values for highlight/shading is narrower
    // with lower light intensity
    // and with lighter/brighter surface colors
    //directional = mix((1.0 - lightintensity), max((2.0 - colorvalue + lightintensity), 1.0), directional);
    directional = mix((1.0 - u_lightintensity), max((1.0 - colorvalue + u_lightintensity), 1.0), directional);

    // Add gradient along z axis of side surfaces
    // Still needs a bit of work before usable
    if (a_normal.y != 0.0) {
        directional *= clamp((t + minH) * pow(maxH / 150.0, 0.5), mix(0.7, 0.98, 1.0 - u_lightintensity), 1.0);
    }

    // Assign final color based on surface + ambient light color, diffuse light directional, and light color
    // with lower bounds adjusted to hue of light
    // so that shading is tinted with the complementary (opposite) color to the light color
    v_color.r += clamp(color.r * directional * lightcolor.r, mix(0.0, 0.3, 1.0 - lightcolor.r), 1.0);
    v_color.g += clamp(color.g * directional * lightcolor.g, mix(0.0, 0.3, 1.0 - lightcolor.g), 1.0);
    v_color.b += clamp(color.b * directional * lightcolor.b, mix(0.0, 0.3, 1.0 - lightcolor.b), 1.0);
}
