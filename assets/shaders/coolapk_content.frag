#version 460 core
#include <flutter/runtime_effect.glsl>
uniform vec2 uSize;
uniform vec4 uThumb; // local physical xywh of lens inside isolated glyph input
uniform float uPress;
uniform vec2 uOptics; // height/amount, physical px
uniform vec4 uAccent;
uniform float uCaptureOnly;
uniform vec2 uCompression;
uniform sampler2D uInput;
out vec4 fragColor;
#define GLYPH_INPUT_ACCENT
#include "coolapk_optics.glsl"
void main() {
  vec2 c = FlutterFragCoord().xy;
  vec2 halfSize = uThumb.zw*0.5;
  vec2 p = c-uThumb.xy-halfSize;
  float radius = min(halfSize.x,halfSize.y);
  if (sdRound(p,halfSize,radius)>0.0) {
    fragColor = uCaptureOnly > 0.5 ? vec4(0.0) : rawSourceAt(c);
    return;
  }
  vec2 inputCoord = lensInputCoord(c,p,halfSize,uPress);
  fragColor=refractAt(inputCoord,p,halfSize,radius,uOptics.x*uPress,-uOptics.y*uPress,1.0);
}
