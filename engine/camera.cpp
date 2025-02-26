//
//  camera.cpp
//  engine
//
//  Created by menji on 2025/2/26.
//

#include "camera.hpp"
#include <cmath>
#include "AAPLMathUtilities.h"

float Camera::lastX = 400.0f;
float Camera::lastY = 300.0f;
float Camera::yaw = -90.0f;
float Camera::pitch = 0.0f;

Camera::Camera() : R(simd::float3{1, 0, 0}),
                   U(simd::float3{0, 1, 0}),
                   F(simd::float3{0, 0, -1}),
                   P(simd::float3{0, 1, 1}) {}

simd::float4x4 Camera::getViewMatrix() const {
    return matrix_make_rows(R.x, R.y, R.z, simd::dot(-R, P),
                            U.x, U.y, U.z, simd::dot(-U, P),
                           -F.x, -F.y, -F.z, simd::dot(F, P),
                            0, 0, 0, 1);
}

simd::float4x4 Camera::getMetalMatrix() const {
    return matrix_make_rows(1, 0, 0, 0,
                            0, 1, 0, 0,
                            0, 0, -0.5, -0.5,
                            0, 0, -1, 0);
}

void Camera::updateOrientation(double xpos, double ypos) {
    float xoffset = xpos - lastX;
    float yoffset = lastY - ypos;
    lastX = xpos;
    lastY = ypos;

    float sensitivity = 0.1f;
    xoffset *= sensitivity;
    yoffset *= sensitivity;

    yaw += xoffset;
    pitch += yoffset;

    if (pitch > 89.0f) pitch = 89.0f;
    if (pitch < -89.0f) pitch = -89.0f;

    F.x = cos((M_PI / 180.0f)*(yaw)) * cos((M_PI / 180.0f)*(pitch));
    F.y = sin((M_PI / 180.0f)*(pitch));
    F.z = sin((M_PI / 180.0f)*(yaw)) * cos((M_PI / 180.0f)*(pitch));
    F = simd::normalize(F);

    R = simd::normalize(simd::cross(F, simd::float3{0, 1, 0}));
    U = simd::normalize(simd::cross(R, F));
}

float radians(float degrees) {
    return degrees * (M_PI / 180.0f);
}
