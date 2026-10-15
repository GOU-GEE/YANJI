// Legacy single-tree colour mask. The current dock uses separate Visible
// and AccentCapture trees; retained as a compatible registered asset.
#version 460 core
#include <flutter/runtime_effect.glsl>
uniform vec4 uThumb; // ShaderMask local logical coordinates, not filter pixels
uniform vec4 uAccent;
uniform vec4 uNormal;
out vec4 fragColor;
void main() {
  vec2 halfSize = uThumb.zw * 0.5;
  vec2 p = FlutterFragCoord().xy - uThumb.xy - halfSize;
  float radius = min(halfSize.x, halfSize.y);
  vec2 q = abs(p) - (halfSize - vec2(radius));
  float sd = length(max(q, 0.0)) - radius + min(max(q.x, q.y), 0.0);
  float coverage = 1.0 - smoothstep(-0.25, 0.25, sd);
  fragColor = mix(uNormal, uAccent, coverage);
}
