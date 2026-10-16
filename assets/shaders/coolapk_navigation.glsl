#include <flutter/runtime_effect.glsl>
uniform vec2 uSize;
uniform vec4 uBar; // screen physical xywh
uniform vec4 uThumb; // screen physical xywh
uniform float uDpr;
uniform float uPress;
uniform float uFull;
uniform vec4 uContainer;
uniform vec4 uSelection;
uniform vec4 uOptics; // bar height/amount, Thumb height/amount, physical px
uniform float uPart; // 0: outer capsule, 1: independent Thumb
uniform float uDecorations;
uniform vec2 uCompression;
#ifdef CAPTURED_BACKDROP
uniform vec4 uCaptureBounds; // physical xywh of the sampled scene crop
#endif
uniform sampler2D uInput;
out vec4 fragColor;
#include "coolapk_optics.glsl"
void main() {
  vec2 c = FlutterFragCoord().xy;
  vec2 halfBar = uBar.zw * 0.5;
  vec2 p = c - uBar.xy - halfBar;
  float radius = min(halfBar.x,halfBar.y);
  float barSd = sdRound(p,halfBar,radius);
  vec2 halfThumb = uThumb.zw*0.5;
  vec2 t = c-uThumb.xy-halfThumb;
  float tr = min(halfThumb.x,halfThumb.y);
  // The bar input is engine-blurred page content. The Thumb input is the
  // rendered bar material inside the bar, and page content outside its edges.
  if (uPart > 0.5) {
    vec2 inputCoord = lensInputCoord(c,t,halfThumb,uPress*uFull);
    // Background-only reduction is independent of the signed edge refraction.
    // Keep the original negative amount; accent capture has no reduction.
    float amount = -uOptics.w*uFull;
    vec4 thumb = refractAt(inputCoord,t,halfThumb,tr,uOptics.z,amount,uFull);
    thumb = tint(thumb,uContainer);
    thumb = tint(thumb,vec4(uSelection.rgb,uSelection.a*(1.0-uPress)));
    fragColor = lensLighting(thumb,t,halfThumb,tr,uDpr,uPress*uDecorations);
    return;
  }
  if (barSd > 0.0) { fragColor=sourceAt(c); return; }
  vec4 bar = refractAt(c,p,halfBar,radius,uOptics.x,-uOptics.y*uFull,0.0);
  bar = tint(bar,uContainer);
  fragColor = edgeLight(bar,p,halfBar,radius,uDpr,uDecorations);
}
