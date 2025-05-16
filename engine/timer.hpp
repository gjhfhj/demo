//
//  Timer.hpp
//  engine
//
//  Created by menji on 2025/5/12.
//

#pragma once
#include <chrono>

class Timer {
public:
    void init();
    void update();
    float getCurrentTime() const;
    float getDeltaTime() const;
    float getTotalTime() const;
    float getFPS() const;

private:
    std::chrono::time_point<std::chrono::high_resolution_clock> startTime;
    std::chrono::time_point<std::chrono::high_resolution_clock> lastFrameTime;
    float deltaTime = 0.0f;
    float totalTime = 0.0f;
};
