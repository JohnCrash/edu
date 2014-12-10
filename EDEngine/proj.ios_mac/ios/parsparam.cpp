//
//  parsparam.cpp
//  EDEngine
//
//  Created by john on 14/12/9.
//
//

#include "parsparam.h"
#include "cocos2d.h"
#include <string>

std::string g_Cookie;
std::string g_Launch;
std::string g_Userid;
std::string g_Mode;

typedef std::pair<std::string,std::string> tKeyV;

tKeyV getParam(std::string s)
{
    return tKeyV();
}

void ParseCommand( int argc,char *argv[] )
{
    for( int i = 1;i < argc;++i )
    {
        tKeyV kv = getParam(argv[i]);
        if( kv.first == "cookie" )
            g_Cookie = kv.second;
        else if( kv.first == "launch" )
            g_Launch = kv.second;
        else if( kv.first == "userid" )
            g_Userid = kv.second;
        else if( kv.first == "mode" )
            g_Mode = kv.second;
    }
    if( g_Mode.length() == 0 )
        g_Mode = "window";
    CCLOG("cookie=%s",g_Cookie.c_str());
    CCLOG("userid=%s", g_Userid.c_str());
    CCLOG("launch=%s", g_Launch.c_str());
    CCLOG("mode=%s", g_Mode.c_str());
}
