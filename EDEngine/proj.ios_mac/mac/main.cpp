/****************************************************************************
 Copyright (c) 2010 cocos2d-x.org
 
 http://www.cocos2d-x.org
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 ****************************************************************************/

#include "AppDelegate.h"
#include "cocos2d.h"

USING_NS_CC;

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

int main(int argc, char *argv[])
{
    AppDelegate app;
    ParseCommand( argc,argv );
    return Application::getInstance()->run();
}
