//
//  mtl_implementation.cpp
//  engine
//
//  Created by menji on 2025/2/20.
//

//  mtl_implementation.cpp
#define NS_PRIVATE_IMPLEMENTATION
#define CA_PRIVATE_IMPLEMENTATION
#define MTL_PRIVATE_IMPLEMENTATION
#include <Foundation/Foundation.hpp>
#include <Metal/Metal.hpp>
#include <QuartzCore/QuartzCore.hpp>



//为什么在另外一个文件里头弄这个，main里头就只需要include <Metal/Metal.hpp>了？

/*
 “Apple's metal-cpp guide tells us that we need to define the metal-cpp implementation in only one of our .cpp files. We're going to create a new file called mtl_implementation.cpp to do this for us, fill it with the necessary define and include statements:
 
 
 //  mtl_implementation.cpp
 #define NS_PRIVATE_IMPLEMENTATION
 #define CA_PRIVATE_IMPLEMENTATION
 #define MTL_PRIVATE_IMPLEMENTATION
 #include <Foundation/Foundation.hpp>
 #include <Metal/Metal.hpp>
 #include <QuartzCore/QuartzCore.hpp>
”
 */
