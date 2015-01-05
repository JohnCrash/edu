//
//  staticlib.h
//  EDEngine
//
//  Created by john on 14/12/30.
//
//

#ifndef EDEngine_staticlib_h
#define EDEngine_staticlib_h

#define Cococs2d_2_2_Embed

#ifdef Cococs2d_2_2_Embed
namespace MySpace {}
#define UsingMySpace using namespace MySpace
#define MySpaceBegin namespace MySpace{
#define MySpaceEnd }
#else
#define MySpaceBegin
#define MySpaceEnd
#endif
#endif
