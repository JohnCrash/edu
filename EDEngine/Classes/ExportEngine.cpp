//
//  ExportEngine.cpp
//  EDEngine
//
//  Created by john on 14/12/31.
//
//
#include "staticlib.h"
#include "ExportEngine.h"
#include "CCEAGLView.h"
#include "cocos2d.h"
#include "AppDelegate.h"

USING_NS_CC;
UsingMySpace;

static AppDelegate_v3 sAppInstance;

int launchEdengine( void *eaglview )
{
    GLView *glview = GLView::createWithEAGLView(eaglview);
    Director::getInstance()->setOpenGLView(glview);
    return Application::getInstance()->run();
}
