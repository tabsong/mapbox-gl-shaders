#ifdef GL_ES
precision mediump float;
#else
#define lowp
#define mediump
#define highp
#endif

#pragma mapbox: define lowp vec4 color
#pragma mapbox: define lowp float blur
#pragma mapbox: define lowp float opacity

varying vec2 v_linewidth;
varying vec2 v_normal;
varying float v_gamma_scale;

void main() {
    #pragma mapbox: initialize lowp vec4 color
    #pragma mapbox: initialize lowp float blur
    #pragma mapbox: initialize lowp float opacity

    // Calculate the distance of the pixel from the line in pixels.
    float dist = length(v_normal) * v_linewidth.s;

    // Calculate the antialiasing fade factor. This is either when fading in
    // the line in case of an offset line (v_linewidth.t) or when fading out
    // (v_linewidth.s)
    float blur2 = (blur + 1.0 / DEVICE_PIXEL_RATIO) * v_gamma_scale;
    float alpha = clamp(min(dist - (v_linewidth.t - blur2), v_linewidth.s - dist) / blur2, 0.0, 1.0);

    gl_FragColor = color * (alpha * opacity);

#ifdef OVERDRAW_INSPECTOR
    gl_FragColor = vec4(1.0);
#endif
}
