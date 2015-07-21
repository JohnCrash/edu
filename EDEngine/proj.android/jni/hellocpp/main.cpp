#include "staticlib.h"
#include "AppDelegate.h"
#include "cocos2d.h"
#include "CCEventType.h"
#include "platform/android/jni/JniHelper.h"
#include <jni.h>
#include <android/log.h>
#include "acr.h"

#define  LOG_TAG    "main"
#define  LOGD(...)  __android_log_print(ANDROID_LOG_DEBUG,LOG_TAG,__VA_ARGS__)

USING_NS_CC;
UsingMySpace;

void cocos_android_app_init (JNIEnv* env, jobject thiz) {
	initACR();
    LOGD("cocos_android_app_init");
    AppDelegate_v3 *pAppDelegate = new AppDelegate_v3();
}
