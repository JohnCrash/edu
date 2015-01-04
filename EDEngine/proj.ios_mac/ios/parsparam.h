//
//  parsparam.h
//  EDEngine
//
//  Created by john on 14/12/9.
//
//

#ifndef __EDEngine__parsparam__
#define __EDEngine__parsparam__
#include "staticlib.h"
#include <string>

MySpaceBegin

extern std::string g_Cookie;
extern std::string g_Launch;
extern std::string g_Userid;
extern std::string g_Mode;
extern std::string g_Goback;

extern int g_OrientationMode;
extern bool g_bAutorotate;

void ParseCommand( int argc,char *argv[] );

void set_launch_by_url(const char *url);

MySpaceEnd

#endif /* defined(__EDEngine__parsparam__) */
