// Equations transcribed from the supplied 16.6.2 ik8/q6f/oh6 AGSL evidence.
float sdRound(vec2 p, vec2 halfSize, float radius) {
  vec2 q = abs(p) - (halfSize - vec2(radius));
  return length(max(q, 0.0)) - radius + min(max(q.x, q.y), 0.0);
}
vec2 gradRound(vec2 p, vec2 halfSize, float radius) {
  vec2 q = abs(p) - (halfSize - vec2(radius));
  if (q.x >= 0.0 || q.y >= 0.0) {
    vec2 v = max(q, 0.0);
    return sign(p) * v / max(length(v), 0.00001);
  }
  float x = step(q.y, q.x);
  return sign(p) * vec2(x, 1.0 - x);
}
vec2 lensShift(vec2 p, vec2 halfSize, float radius, float height, float amount) {
  float sd = sdRound(p, halfSize, radius);
  if (height <= 0.0 || -sd >= height) return vec2(0.0);
  float t = clamp(1.0 + min(sd, 0.0) / height, 0.0, 1.0);
  float d = (1.0 - sqrt(max(0.0, 1.0 - t * t))) * amount;
  float gr = min(radius * 1.5, min(halfSize.x, halfSize.y));
  return d * gradRound(p, halfSize, gr);
}
vec4 rawSourceAt(vec2 coord) {
  // The local engine's backdrop input is already screen-oriented on GLES.
  // This is verified by the red-top/blue-bottom acceptance scene.
  return texture(uInput, clamp(coord, vec2(0.5), uSize - 0.5) / uSize);
}
vec4 sourceAt(vec2 coord) {
  vec4 c = rawSourceAt(coord);
#ifdef GLYPH_INPUT_ACCENT
  if (uAccent.a > 0.0) c = vec4(uAccent.rgb * c.a, c.a);
#endif
  return c;
}
vec2 lensInputCoord(vec2 c, vec2 p, vec2 halfSize, float press) {
  // Cross-axis compression is even in p: top/bottom (or left/right in a
  // vertical dock) contract equally around the bar/lens common centre.
  bool vertical = halfSize.x < halfSize.y;
  float along = vertical ? p.y / halfSize.y : p.x / halfSize.x;
  float envelope = 1.0 - smoothstep(0.25, 1.0, abs(along));
  float compression = uCompression.y * press * envelope;
  // Shrink the captured end caps too, so their boundary sits inside the lens.
  float alongCompression = uCompression.x * press;
  return c + p * (vertical ? vec2(compression, alongCompression)
                          : vec2(alongCompression, compression));
}
vec4 refractAt(vec2 c, vec2 p, vec2 halfSize, float radius,
               float height, float amount, float chroma) {
  vec2 shift = lensShift(p, halfSize, radius, height, amount);
  vec2 r = c + shift;
  if (chroma == 0.0 || dot(shift,shift) < 0.000001) return sourceAt(r);
  // Original signed quadrant product controls chromatic dispersion direction.
  vec2 spread = shift * chroma * p.x * p.y / (halfSize.x * halfSize.y);
  vec4 red = sourceAt(r + spread);
  vec4 orange = sourceAt(r + spread * (2.0/3.0));
  vec4 yellow = sourceAt(r + spread / 3.0);
  vec4 green = sourceAt(r);
  vec4 cyan = sourceAt(r - spread / 3.0);
  vec4 blue = sourceAt(r - spread * (2.0/3.0));
  vec4 purple = sourceAt(r - spread);
  return vec4((red.r+orange.r+yellow.r)/3.5 + purple.r/7.0,
              orange.g/7.0+(yellow.g+green.g+cyan.g)/3.5,
              (cyan.b+blue.b+purple.b)/3.0,
              (red.a+orange.a+yellow.a+green.a+cyan.a+blue.a+purple.a)/7.0);
}
vec4 tint(vec4 c, vec4 overlay) {
  return vec4(overlay.rgb * overlay.a, overlay.a) + c * (1.0-overlay.a);
}
vec4 edgeLight(vec4 c, vec2 p, vec2 halfSize, float radius, float dpr, float alpha) {
  float sd = sdRound(p, halfSize, radius);
  float band = 1.0-smoothstep(0.25*dpr, 0.75*dpr, -sd);
  vec2 g = gradRound(p, halfSize, min(radius*1.5,min(halfSize.x,halfSize.y)));
  float d = dot(g, vec2(0.70710678,0.70710678));
  float intensity = pow(abs(d), 1.0) * band * alpha;
  return vec4(min(vec3(c.a),c.rgb+vec3(0.5*intensity*c.a)),c.a);
}
vec4 lensLighting(vec4 c, vec2 p, vec2 halfSize, float radius,
                     float dpr, float press) {
  float depth = max(-sdRound(p, halfSize, radius), 0.0);
  vec2 g = gradRound(p, halfSize, min(radius * 1.5, min(halfSize.x, halfSize.y)));
  // yx6: one 8dp inner shadow, zero offset, black .15 * press.
  // A Gaussian half-plane approximation; no secondary concentric shoulder.
  float sigma = max(8.0 * dpr * press * 0.5, 0.001);
  float x = depth / sigma;
  float tail = 0.5 * exp(-0.5*x*x) / (1.0 + 0.8*x);
  c.rgb *= 1.0 - 0.15 * press * tail;
  // kh6/oh6: .5dp highlight, .25dp feather, angle45/falloff1, Plus white.5.
  return edgeLight(c,p,halfSize,radius,dpr,press);
}
