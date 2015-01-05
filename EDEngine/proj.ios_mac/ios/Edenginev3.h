//
//  Edenginev3.h
//  EDEngine
//
//  Created by john on 14/12/31.
//
//

#ifndef EDEngine_Edenginev3_h
#define EDEngine_Edenginev3_h
#include <string>

typedef void (*ONEXIT_t)();

void * createV3EAGLView( void * window);
void *createV3Controller();
void runV3Engine( void *eaglview,ONEXIT_t func );
void shutdownV3Engine();
void pauseV3Engine();
void resumeV3Engine();
void backgroundV3Engine();
void foregroundV3Engine();
void setLaunchParam(const std::string& appname,
                    const std::string& userid,
                    const std::string& cookie,
                    const std::string& mode,
                    const std::string& orientation);
#endif
