//
//  timer.cpp
//  engine
//
//  Created by menji on 2025/5/12.
//

#include "timer.hpp"

void Timer::init() {
    startTime = std::chrono::high_resolution_clock::now();
    lastFrameTime = startTime;
}

void Timer::update() {
    auto now = std::chrono::high_resolution_clock::now();
    deltaTime = std::chrono::duration<float>(now - lastFrameTime).count();
    totalTime = std::chrono::duration<float>(now - startTime).count();
    lastFrameTime = now;
}

float Timer::getCurrentTime() const {
    auto now = std::chrono::high_resolution_clock::now();
    return std::chrono::duration<float>(now - startTime).count();
}

float Timer::getDeltaTime() const {
    return deltaTime;
}

float Timer::getTotalTime() const {
    return totalTime;
}

float Timer::getFPS() const {
    return deltaTime > 0.0f ? 1.0f / deltaTime : 0.0f;
}
