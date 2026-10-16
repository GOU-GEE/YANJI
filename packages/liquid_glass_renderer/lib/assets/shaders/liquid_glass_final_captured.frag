// Copyright 2025, Tim Lehmann for whynotmake.it
//
// Final rendering pass for liquid glass with pre-computed geometry
// This shader reads displacement data from a pre-computed texture and applies
// the liquid glass effect efficiently

#version 460 core
#define CAPTURED_BACKDROP
#include "liquid_glass_render.glsl"
