//
//  camera.hpp
//  engine
//
//  Created by menji on 2025/2/26.
//

#pragma once
#include <simd/simd.h>
#include <GLFW/glfw3.h>

class Camera {
public:
    Camera();
    simd::float4x4 getViewMatrix() const;
    simd::float4x4 getMetalMatrix() const;
    simd::float3 getP();
    simd::float3 getF();
    simd::float3 getU();
    simd::float3 getR();
    float getLastX();
    float getLastY();
    void setP(simd::float3 vector);
    void setF(simd::float3 vector);
    void setU(simd::float3 vector);
    void setR(simd::float3 vector);
    void updateOrientation(double xpos, double ypos);
    float radians(float degress);
private:
    simd::float3 P;
    simd::float3 F;
    simd::float3 U;
    simd::float3 R;
    static float lastX;
    static float lastY;
    static float yaw;
    static float pitch;
};
