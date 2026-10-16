// Copyright 2025, Tim Lehmann for whynotmake.it
//
// Final rendering pass for liquid glass with pre-computed geometry
// This shader reads displacement data from a pre-computed texture and applies
// the liquid glass effect efficiently

precision highp float;

#define DEBUG_GEOMETRY 0

#include <flutter/runtime_effect.glsl>
#include "displacement_encoding.glsl"
#include "render.glsl"

uniform vec2 uSize;
uniform vec2 uGeometryOffset;
uniform vec2 uGeometrySize;

uniform vec4 uGlassColor;
uniform vec3 uOpticalProps;
uniform vec3 uLightConfig;
uniform vec2 uLightDirection;
uniform float uHighQualitySampling;
uniform float uEdgeMagnification;

float uRefractiveIndex = uOpticalProps.x;
float uChromaticAberration = uOpticalProps.y;
float uThickness = uOpticalProps.z;
float uLightIntensity = uLightConfig.x;
float uAmbientStrength = uLightConfig.y;
float uSaturation = uLightConfig.z;

#ifdef CAPTURED_BACKDROP
uniform vec4 uCaptureBounds; // physical scene crop, OHOS only
#endif
uniform sampler2D uBackgroundTexture;
uniform sampler2D uGeometryTexture;

layout(location = 0) out vec4 fragColor;

vec4 backgroundAt(vec2 uv) {
    #ifdef CAPTURED_BACKDROP
    if (uCaptureBounds.z > 0.0) {
        vec2 p = clamp(uv * uSize - uCaptureBounds.xy, vec2(0.5), uCaptureBounds.zw - 0.5);
        return texture(uBackgroundTexture, p / uCaptureBounds.zw);
    }
    #endif
    return texture(uBackgroundTexture, uv);
}

vec4 sampleBackgroundBilinear(vec2 uv) {
    vec2 size = uSize;
    vec2 pixel = clamp(uv * size - 0.5, vec2(0.0), size - 1.0);
    vec2 first = floor(pixel);
    vec2 second = min(first + 1.0, size - 1.0);
    vec2 weight = fract(pixel);
    vec4 top = mix(
        backgroundAt((first + 0.5) / size),
        backgroundAt((vec2(second.x, first.y) + 0.5) / size),
        weight.x
    );
    vec4 bottom = mix(
        backgroundAt((vec2(first.x, second.y) + 0.5) / size),
        backgroundAt((second + 0.5) / size),
        weight.x
    );
    return mix(top, bottom, weight.y);
}

vec4 sampleGeometryBilinear(vec2 uv) {
    vec2 size = uGeometrySize;
    vec2 pixel = clamp(uv * size - 0.5, vec2(0.0), size - 1.0);
    vec2 first = floor(pixel);
    vec2 second = min(first + 1.0, size - 1.0);
    vec2 weight = fract(pixel);
    vec4 top = mix(
        texture(uGeometryTexture, (first + 0.5) / size),
        texture(uGeometryTexture, (vec2(second.x, first.y) + 0.5) / size),
        weight.x
    );
    vec4 bottom = mix(
        texture(uGeometryTexture, (vec2(first.x, second.y) + 0.5) / size),
        texture(uGeometryTexture, (second + 0.5) / size),
        weight.x
    );
    return mix(top, bottom, weight.y);
}

vec4 sampleBackground(vec2 uv) {
    if (uHighQualitySampling > 0.5) {
        return sampleBackgroundBilinear(uv);
    }
    return backgroundAt(uv);
}

void main() {
    // FlutterFragCoord() returns logical pixels, but our geometry texture is in physical pixels
    // So we need to scale by devicePixelRatio to work in physical pixel space
    vec2 fragCoord = FlutterFragCoord().xy;

    vec2 screenUV = vec2(fragCoord.x / uSize.x, fragCoord.y / uSize.y);

    // ImageFilter.shader supplies its backdrop in Flutter's screen coordinate
    // orientation on Impeller OpenGLES too. Flipping this UV mirrored the whole
    // screen vertically, so a dock at the bottom refracted content at the top.

    vec2 geometryUV = (fragCoord - uGeometryOffset) / uGeometrySize;
    #ifdef IMPELLER_TARGET_OPENGLES
        geometryUV.y = 1.0 - geometryUV.y;
    #endif

    vec4 geometryData = uHighQualitySampling > 0.5
        ? sampleGeometryBilinear(geometryUV)
        : texture(uGeometryTexture, geometryUV);

    #if DEBUG_GEOMETRY
        fragColor = geometryData;
        return;
    #endif

    if (geometryData.a < 0.01) {
        fragColor = vec4(0);
        return;
    }

    // The geometry matte is premultiplied when Flutter composites its
    // picture. Decode the optical channels in straight color space so the
    // partially covered edge cannot turn into a large false displacement.
    geometryData.rgb /= geometryData.a;

    float maxDisplacement = uThickness * (uEdgeMagnification > 0.5 ? 0.5 : 2.0);
    vec2 displacement = decodeDisplacement(geometryData, maxDisplacement);

    vec2 invUSize = 1.0 / uSize;

    vec4 refractColor;
    if (uChromaticAberration < 0.01) {
        vec2 refractedUV = screenUV + displacement * invUSize;
        refractColor = sampleBackground(refractedUV);
    } else {
        // Keep the full green-channel refraction, but cap the separation of
        // red and blue to a fraction of one physical pixel. Large refractive
        // displacements should not paint rainbow outlines around text.
        vec2 dispersion = displacement * min(
            uChromaticAberration * 0.5,
            0.18 / max(length(displacement), 0.001)
        );
        vec2 redOffset = displacement + dispersion;
        vec2 blueOffset = displacement - dispersion;

        vec2 redUV = screenUV + redOffset * invUSize;
        vec2 greenUV = screenUV + displacement * invUSize;
        vec2 blueUV = screenUV + blueOffset * invUSize;

        float red = sampleBackground(redUV).r;
        vec4 greenSample = sampleBackground(greenUV);
        float blue = sampleBackground(blueUV).b;

        refractColor = vec4(red, greenSample.g, blue, greenSample.a);
    }

    vec4 finalColor = applyGlassColor(refractColor, uGlassColor);
    finalColor.rgb = applySaturation(finalColor.rgb, uSaturation);

    // Compute edge lighting
    float normalizedHeight = geometryData.b;

    float thicknessScale = clamp(40.0 / max(uThickness, 1.0), 1.0, 4.0);
    float edgeThreshold = mix(0.8, 0.5, 1.0 / thicknessScale);
    float edgeFactor = 1.0 - smoothstep(0.0, edgeThreshold, normalizedHeight);

    if (edgeFactor > 0.01) {
        vec2 normalXY = normalize(displacement);

        float mainLight = max(0.0, dot(normalXY, uLightDirection));
        float oppositeLight = max(0.0, dot(normalXY, -uLightDirection));

        float totalInfluence = mainLight + oppositeLight * 0.8;

        float directional = pow(totalInfluence, 1.5) * uLightIntensity * 3.0;
        float ambient = uAmbientStrength * 0.5;

        float brightness = (directional + ambient) * edgeFactor * thicknessScale * 0.8;

        vec3 bgColor = refractColor.rgb;
        float bgLuminance = dot(bgColor, LUMA_WEIGHTS);
        vec3 highlightColor;

        vec3 saturatedBg = bgColor / max(bgLuminance, 0.001);
        saturatedBg = mix(bgColor, saturatedBg, 0.8);
        float colorfulness = length(bgColor - vec3(bgLuminance));
        float colorMix = clamp(colorfulness * 1.0 + 0.5, 0.5, 1.0);
        highlightColor = mix(vec3(1.0), saturatedBg, colorMix);


        finalColor.rgb = mix(finalColor.rgb, highlightColor, brightness);
    }

    float alpha = geometryData.a;
    fragColor = vec4(finalColor.rgb * alpha, alpha);
}
