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

MySpaceBegin

std::string g_Cookie;
std::string g_Launch;
std::string g_Userid;
std::string g_Mode;
std::string g_Goback;
std::string g_Orientation;
/*
 1 横屏
 2 竖屏
 */
int g_OrientationMode = 1;
bool g_bAutorotate = true;

typedef std::pair<std::string,std::string> tKeyV;

tKeyV getParam(std::string s)
{
    std::string::size_type it = s.find('=');
    if( it != std::string::npos )
    {
        std::string::size_type len = s.length();
        return tKeyV( s.substr(0,it),s.substr(it+1,len-it-1) );
    }
    else
        return tKeyV( s,std::string() );
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

void set_launch_by_url(const char *url)
{
    std::string strURL(url);
    //edengine:\\cookie=asdfasdf&userid=asdfadf&launch=asdfasdf&mode=window
    std::string::size_type it = strURL.find(':');
    std::string::size_type len = strURL.length();
    std::string::size_type start;
    if( it != std::string::npos )
    {
        it++;
        while( it < len )
        {
            if( strURL.at(it) == '/' )
                it++;
            else
                break;
        }
        start = it;
        for( std::string::size_type  i = it;i < len;++i )
        {
            if( strURL[i] == '&' || i == len-1 )
            {
                if( i == len-1 )
                    i = len;
                tKeyV kv = getParam(strURL.substr(start,i-start));
                if( kv.first == "cookie" )
                    g_Cookie = kv.second;
                else if(kv.first == "launch" )
                    g_Launch = kv.second;
                else if(kv.first == "userid" )
                    g_Userid = kv.second;
                else if(kv.first == "mode" )
                    g_Mode = kv.second;
                else if(kv.first == "goback" )
                    g_Goback = kv.second;
                else
                    CCLOG("ERROR : handleURL unknow augment %s = %s",kv.first.c_str(),kv.second.c_str() );
                
                start = i + 1;
            }
        }
    }
    else
    {
        CCLOG("ERROR : handleURL invalide url %s",url );
    }
}

MySpaceEnd