// Copyright 2025, Tim Lehmann for whynotmake.it
//
// Geometry precomputation shader for blended liquid glass shapes
// This shader pre-computes the refraction displacement and encodes it into a texture
// Only needs to be re-run when shape geometry or layout changes

precision highp float;

#include <flutter/runtime_effect.glsl>
#define MAX_SHAPES 16
#include "displacement_encoding.glsl"

layout(location = 0) uniform vec2 uSize;
layout(location = 1) uniform vec4 uOpticalProps;
layout(location = 2) uniform float uNumShapes;
layout(location = 3) uniform float uShapeData[MAX_SHAPES * 6];
#include "sdf.glsl"

float uThickness = uOpticalProps.z;
float uRefractiveIndex = uOpticalProps.x;
float uBlend = uOpticalProps.w;

layout(location = 0) out vec4 fragColor;

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;

    #ifdef IMPELLER_TARGET_OPENGLES
        vec2 screenUV = vec2(fragCoord.x / uSize.x, 1.0 - (fragCoord.y / uSize.y));
    #else
        vec2 screenUV = vec2(fragCoord.x / uSize.x, fragCoord.y / uSize.y);
    #endif

    float sd = sceneSDF(fragCoord, int(uNumShapes), uBlend);

    float foregroundAlpha = 1.0 - smoothstep(-2.0, 0.0, sd);
    if (foregroundAlpha < 0.01) {
        fragColor = vec4(0.0);
        return;
    }

    #ifdef YANJI_CAPTURED_BACKEND
        // Skia runtime effects do not expose screen-space derivatives. Measure
        // the same SDF gradient symmetrically across one physical pixel.
        vec2 halfPixel = vec2(0.5, 0.0);
        float dx = sceneSDF(fragCoord + halfPixel, int(uNumShapes), uBlend)
                 - sceneSDF(fragCoord - halfPixel, int(uNumShapes), uBlend);
        float dy = sceneSDF(fragCoord + halfPixel.yx, int(uNumShapes), uBlend)
                 - sceneSDF(fragCoord - halfPixel.yx, int(uNumShapes), uBlend);
    #else
        float dx = dFdx(sd);
        float dy = dFdy(sd);
    #endif

    float n_cos = max(uThickness + sd, 0.0) / uThickness;
    float n_sin = sqrt(max(0.0, 1.0 - n_cos * n_cos));

    vec3 normal = normalize(vec3(dx * n_cos, dy * n_cos, n_sin));

    if (sd >= 0.0 || uThickness <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }

    float x = uThickness + sd;
    float sqrtTerm = sqrt(max(0.0, uThickness * uThickness - x * x));
    float height = mix(sqrtTerm, uThickness, float(sd < -uThickness));

    // Keep the optical path local to the rim, rather than sampling distant
    // content eight thicknesses away. Thickness is in physical pixels.
    float baseHeight = uThickness * 0.75;
    vec3 incident = vec3(0.0, 0.0, -1.0);

    float invRefractiveIndex = 1.0 / uRefractiveIndex;
    vec3 baseRefract = refract(incident, normal, invRefractiveIndex);
    float baseRefractLength = (height + baseHeight) / max(0.001, abs(baseRefract.z));
    // Strong lenses need a wider optical ramp. A narrow ramp makes the UV
    // mapping fold over itself, repeating glyph pixels as colored grain.
    // Weaker outer glass retains its tighter, visible edge refraction.
    float rimWidthRatio = mix(
        0.30,
        0.80,
        smoothstep(1.45, 1.62, uRefractiveIndex)
    );
    float rimFade = smoothstep(0.0, uThickness * rimWidthRatio, -sd);
    vec2 displacement = baseRefract.xy * baseRefractLength * rimFade;

    if (uOpticalProps.y > 0.5) {
        // A moving navigation lens starts magnifying at the silhouette instead
        // of first increasing displacement from zero inside the rim. Sample
        // inward at the boundary, then smoothly return to the unshifted center.
        // The slope stays positive: q'(depth) >= 1 - 2 * .44 = .12, so glyphs
        // stretch continuously rather than fold, duplicate or compress first.
        float depth = clamp(-sd / uThickness, 0.0, 1.0);
        float strength = clamp((uRefractiveIndex - 1.0) / .62, 0.0, 1.0);
        float shift = .44 * uThickness * strength * (1.0 - depth) * (1.0 - depth);
        vec2 outward = vec2(dx, dy) / max(length(vec2(dx, dy)), .001);
        // FlutterFragCoord is top-down, while GLES dFdy follows the native
        // framebuffer's bottom-up Y. Decode into backdrop screen coordinates.
        // Keep the established default profile unchanged; this correction is
        // only for the opt-in edgeMagnification profile.
        #ifdef IMPELLER_TARGET_OPENGLES
            outward.y = -outward.y;
        #endif
        displacement = -outward * shift;
    }

    // The edge profile never exceeds .44 thicknesses. A tighter encoding
    // range gives its small glyph distortions four times the precision.
    float maxDisplacement = uThickness * (uOpticalProps.y > 0.5 ? 0.5 : 2.0);

    fragColor = encodeDisplacementData(displacement, maxDisplacement, height, uThickness, foregroundAlpha);
}
