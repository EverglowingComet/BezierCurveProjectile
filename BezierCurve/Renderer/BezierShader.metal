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

bool checkLineOld(float2 coord, float2 point0, float2 point1, float width) {
    float y = point0.y + (point1.y - point0.y) * (coord.x - point0.x) / (point1.x - point0.x);
    if ((point0.x > point1.x && coord.x >= point1.x && coord.x <= point0.x) || (point0.x < point1.x && coord.x >= point0.x && coord.x <= point1.x)) {
        return checkCircle(float2(coord.x, y), coord, width);
    }
    return false;
}

float2 vector2d(float2 p1, float2 p2) {
    return float2(p2.x - p1.x, p2.y - p1.y);
}

float dotAA(float2 u, float2 v) {
    return u.x * v.x + u.y * v.y;
}

bool checkLine(float2 coord, float2 point0, float2 point1, float width) {
    float alpha = atan((point1.y - point0.y) / (point1.x - point0.x));
    float d = width / 2;
    float2 A = float2(point0.x - d * sin(alpha), point0.y + d * cos(alpha));
    float2 B = float2(point0.x + d * sin(alpha), point0.y - d * cos(alpha));
    float2 C = float2(point1.x - d * sin(alpha), point1.y + d * cos(alpha));
    //float2 D = float2(point1.x + d * sin(alpha), point1.y - d * cos(alpha));
    
    float2 AB = vector2d(A, B);
    float2 AM = vector2d(A, coord);
    float2 BC = vector2d(B, C);
    float2 BM = vector2d(B, coord);
    float dotABAM = dotAA(AB, AM);
    float dotABAB = dotAA(AB, AB);
    float dotBCBM = dotAA(BC, BM);
    float dotBCBC = dotAA(BC, BC);
    float minX = min(point0.x - width / 2, point1.x - width /2);
    float minY = min(point0.y - width / 2, point1.y - width /2);
    float maxX = max(point0.x + width / 2, point1.x + width /2);
    float maxY = max(point0.y + width / 2, point1.y + width /2);
    if (coord.x < minX || coord.y < minY || coord.x > maxX || coord.y > maxY) return false;
    return 0 <= dotABAM && dotABAM <= dotABAB && 0 <= dotBCBM && dotBCBM <= dotBCBC;
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
                        device const float *target [[ buffer(7) ]],
                        uint2 gid [[ thread_position_in_grid ]])
{
    float2 fragCoord = float2(gid);
    float4 orig = inTexture.read(gid);
    float4 white = float4(1.0, 1.0, 1.0, 1.0);
    float4 pointColor = float4(1.0, 0.3, 1.0, 1.0);
    float4 lineAlpha = float4(0.5, 0.0, 0.0, 0.0);
    float4 lineColor = float4(1.0,
                              orig[1] * (1.0 - lineAlpha[0]) + lineAlpha[1] * lineAlpha[0],
                              orig[2] * (1.0 - lineAlpha[0]) + lineAlpha[2] * lineAlpha[0],
                              orig[3] * (1.0 - lineAlpha[0]) + lineAlpha[3] * lineAlpha[0]);
    float4 redColor = float4(1.0, 1.0, 0.0, 0.0);
    float2 startPoint = float2(*start, *(start + 1));
    float2 endPoint = float2(*end, *(end + 1));
    float2 targetPoint = float2(*target, *(target+ 1));
    
    if (checkCircle(fragCoord, startPoint, *radius)) {
        outTexture.write(white, gid);
    } else if (checkCircle(fragCoord, endPoint, *radius)) {
        outTexture.write(pointColor, gid);
    } else if (checkCircle(fragCoord, targetPoint, *radius)) {
        outTexture.write(white, gid);
    } else if (checkPoints(fragCoord, points, *width, *pointCount)) {
        outTexture.write(redColor, gid);
    } else if (checkLine(fragCoord, float2(*start, *(start + 1)), float2(*line, *(line + 1)), *width)) {
        outTexture.write(lineColor, gid);
    } else {
        outTexture.write(orig, gid);
    }
    
}

