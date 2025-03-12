// Shaders.metal
//
// Copyright (C) 2025, Celestia Development Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position  [[attribute(0)]];
    float2 texCoords [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoords;
};

[[vertex]]
VertexOut vertex_main(VertexIn in [[stage_in]])
{
    VertexOut out;
    out.position = float4(in.position, 0.0, 1.0f);
    out.texCoords = in.texCoords;
    return out;
}

[[fragment]]
float4 fragment_main(VertexOut in [[stage_in]], texture2d<float> texture [[texture(0)]])
{
    constexpr sampler environmentSampler(coord::normalized,
                                         filter::linear,
                                         mip_filter::none,
                                         address::repeat);
    float4 color = texture.sample(environmentSampler, in.texCoords);
    return color;
}
