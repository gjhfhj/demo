//
//  main.cpp
//  engineDemo
//
//  Created by menji on 2025/2/20.
//


#include "mtl_engine.hpp"

int main() {

    MTLEngine engine;
    engine.init();
    engine.run();
    engine.cleanup();

    return 0;
}
