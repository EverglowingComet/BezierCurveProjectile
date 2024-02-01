//
//  BezierShader.metal
//  BezierCurve
//
//  Created by Comet on 2/1/24.
//

#include <metal_stdlib>
using namespace metal;

bool checkCircle(float2 coord, float2 point, float radius) {
    float dx = coord.x - point.x;
    float dy = coord.y - point.y;
    
    return radius * radius > dx * dx + dy * dy;
}

bool checkLine(float2 coord, float2 point0, float2 point1, float width) {
    float y = point0.y + (point1.y - point0.y) * (coord.x - point0.x) / (point1.x - point0.x);
    if ((point0.x > point1.x && coord.x >= point1.x && coord.x <= point0.x) || (point0.x < point1.x && coord.x >= point0.x && coord.x <= point1.x)) {
        return checkCircle(float2(coord.x, y), coord, width);
    }
    return false;
}

bool checkPoints(float2 coord, device const float* points, float width, int pointCount) {
    for (int i = 0; i < pointCount - 1; i ++) {
        if (checkLine(coord, float2(*(points + 2 * i), *(points + 2 * i + 1)), float2(*(points + 2 * i + 2), *(points + 2 * i + 3)), width)) {
            return true;
        }
    }
    return false;
}

kernel void bezierCompute(texture2d<float, access::read> inTexture [[ texture(0) ]],
                        texture2d<float, access::write> outTexture [[ texture(1) ]],
                        device const float *radius [[ buffer(0) ]],
                        device const float *width [[ buffer(1) ]],
                        device const float *start [[ buffer(2) ]],
                        device const float *end [[ buffer(3) ]],
                        device const float *line [[ buffer(4) ]],
                        device const float *points [[ buffer(5) ]],
                        device const int *pointCount [[ buffer(6) ]],
                        uint2 gid [[ thread_position_in_grid ]])
{
    float2 fragCoord = float2(gid);
    float4 orig = inTexture.read(gid);
    float4 white = float4(1.0, 1.0, 1.0, 1.0);
    float4 pointColor = float4(0.0, 1.0, 1.0, 1.0);
    float4 lineColor = float4(0.0, 0.0, 0.0, 1.0);
    float4 redColor = float4(1.0, 0.0, 0.0, 1.0);
    
    if (checkCircle(fragCoord, float2(*start, *(start + 1)), *radius)) {
        outTexture.write(white, gid);
    } else if (checkCircle(fragCoord, float2(*end, *(end + 1)), *radius)) {
        outTexture.write(pointColor, gid);
    } else if (checkPoints(fragCoord, points, *width, *pointCount)) {
        outTexture.write(redColor, gid);
    } else if (checkLine(fragCoord, float2(*start, *(start + 1)), float2(*line, *(line + 1)), *width)) {
        outTexture.write(lineColor, gid);
    } else {
        outTexture.write(orig, gid);
    }
    
}

