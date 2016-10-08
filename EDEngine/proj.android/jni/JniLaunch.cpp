#include <jni.h>
#include <string>
#include "JniHelper.h"
#include "cocos2d.h"
#include "../../Classes/Platform.h"
#include "acr.h"

using namespace cocos2d;
UsingMySpace;

#define  CLASS_NAME "org/cocos2dx/cpp/AppActivity"
MySpaceBegin

std::string g_Launch;
std::string g_Cookie;
std::string g_Userid;
std::string g_Orientation;
std::string g_ExternalStorageDirectory;
std::string g_RecordFile;

/*
	百度语音识别,显示百度语音识别界面
*/
void showBaiduVoice()
{
	JniMethodInfo t;
	if (JniHelper::getStaticMethodInfo(t, CLASS_NAME, "showBaiduVoice", "()V")) 
	{
		t.env->CallStaticVoidMethod(t.classID,t.methodID);
		t.env->DeleteLocalRef(t.classID);
	}
}
/*
	关闭百度语音识别界面,强制关闭.
*/
void closeBaiduVoice()
{
	JniMethodInfo t;
	if (JniHelper::getStaticMethodInfo(t, CLASS_NAME, "closeBaiduVoice", "()V")) 
	{
		t.env->CallStaticVoidMethod(t.classID,t.methodID);
		t.env->DeleteLocalRef(t.classID);
	}
}
/*
	打开百度语音配置界面
*/
void showBaiduVoiceConfigure()
{
	JniMethodInfo t;
	if (JniHelper::getStaticMethodInfo(t, CLASS_NAME, "showBaiduVoiceConfigure", "()V")) 
	{
		t.env->CallStaticVoidMethod(t.classID,t.methodID);
		t.env->DeleteLocalRef(t.classID);
	}
}

static bool sWaitChangeEnd = false;
//设置屏幕方向
void setUIOrientation( int m )
{
	JniMethodInfo t;
	int w,h;
	if (JniHelper::getStaticMethodInfo(t, CLASS_NAME, "setUIOrientation", "(I)V")) 
	{
		t.env->CallStaticVoidMethod(t.classID,t.methodID,m);
		t.env->DeleteLocalRef(t.classID);
	}
/*
	android 特有的问题
		调用java 的 setUIOrientation，然后方向被改变(android旋转视图)
		旋转完视图另一个线程调用Java_org_cocos2dx_cpp_AppActivity_cocos2dChangeOrientation
		如果不等调用结束就返回，可能发生线程冲突调用setDesignResolutionSize
		比如你这么调用
		setUIOrientation(1)
		uikits.InitDR{width=960,height=540}
*/	
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID	
	sWaitChangeEnd = false;
	int count = 0;
	while( !sWaitChangeEnd )
	{
		usleep(1);
		if( count++ > 2000 )
			break;
	}
	CCLOG("setUIOrientation END		 2");
#endif	
}

int getUIOrientation()
{
	JniMethodInfo t;
	if (JniHelper::getStaticMethodInfo(t, CLASS_NAME, "getUIOrientation", "()I")) 
	{
		int ret = t.env->CallStaticIntMethod(t.classID,t.methodID);
		t.env->DeleteLocalRef(t.classID);
		return ret;
	}
	return -1;
}

bool platformOpenURL( const char *url )
{
	JniMethodInfo t;
	if (JniHelper::getStaticMethodInfo(t, CLASS_NAME, "androidOpenURL", "(Ljava/lang/String;)V")) 
	{
		jstring jstrurl=t.env->NewStringUTF(url);
		t.env->CallStaticVoidMethod(t.classID,t.methodID,jstrurl);
		t.env->DeleteLocalRef(t.classID);
		t.env->DeleteLocalRef(jstrurl);
		return true;
	}
	return false;
}

int getNetworkState()
{
	JniMethodInfo t;
	if (JniHelper::getStaticMethodInfo(t, CLASS_NAME, "getNetworkState", "()I")) 
	{
		int ret = t.env->CallStaticIntMethod(t.classID,t.methodID);
		t.env->DeleteLocalRef(t.classID);
		return ret;
	}
	return -1;
}

void registerNetworkStateListener()
{
	JniMethodInfo jmi;

	int nRet=0;
	if (JniHelper::getStaticMethodInfo(jmi,CLASS_NAME,"registerNetworkStateListener","()I"))
	{
		nRet=jmi.env->CallStaticIntMethod(jmi.classID,jmi.methodID);
		jmi.env->DeleteLocalRef(jmi.classID);
    }
}

void unregisterNetworkStateListener()
{
	JniMethodInfo jmi;

	int nRet=0;
	if (JniHelper::getStaticMethodInfo(jmi,CLASS_NAME,"unregisterNetworkStateListener","()I"))
	{
		nRet=jmi.env->CallStaticIntMethod(jmi.classID,jmi.methodID);
		jmi.env->DeleteLocalRef(jmi.classID);
    }
}

void ShockPhonePattern( int *pattern,int n )
{
	JniMethodInfo jmi;
	if( n > 0 )
	{
		for( int i = 0;i < n;++i )
		{
			if( i == 0 )
			{
				if (JniHelper::getStaticMethodInfo(jmi,CLASS_NAME,"InitShockPattern","(I)V"))
				{
					jmi.env->CallStaticVoidMethod(jmi.classID,jmi.methodID,pattern[i]);
					jmi.env->DeleteLocalRef(jmi.classID);
				}
			}
			else
			{
				if (JniHelper::getStaticMethodInfo(jmi,CLASS_NAME,"addShockPattern","(I)V"))
				{
					jmi.env->CallStaticVoidMethod(jmi.classID,jmi.methodID,pattern[i]);
					jmi.env->DeleteLocalRef(jmi.classID);
				}			
			}
		}
		if (JniHelper::getStaticMethodInfo(jmi,CLASS_NAME,"ShockPhone","()V"))
		{
			jmi.env->CallStaticVoidMethod(jmi.classID,jmi.methodID);
			jmi.env->DeleteLocalRef(jmi.classID);
		}
	}
}

void ShockPhoneDelay( int t )
{
	JniMethodInfo jmi;

	if (JniHelper::getStaticMethodInfo(jmi,CLASS_NAME,"ShockPhoneDelay","(I)V"))
	{
		jmi.env->CallStaticVoidMethod(jmi.classID,jmi.methodID,t);
		jmi.env->DeleteLocalRef(jmi.classID);
    }
}

void takeResource( int mode )
{
	JniMethodInfo t;
	if (JniHelper::getStaticMethodInfo(t, CLASS_NAME, "takeResource", "(I)V")) 
	{
		t.env->CallStaticVoidMethod(t.classID,t.methodID,mode);
		t.env->DeleteLocalRef(t.classID);
	}
}
	
bool CVoiceRecord::OnRecordData(char *pBuf,int len,int nRate)
{
	if (m_pEncoder)
	{
//		CCLOG("CVoiceRecord::OnRecordData ");
		m_pEncoder->AddEncoderBuf(pBuf,len,nRate);
	}
	return true;
}

bool CVoiceRecord::StartRecord(int cnChannel,int nRate,int cnBitPerSample)
{
	//CCLOG("CVoiceRecord::StartRecord ");
	if (!CVoiceRecordBase::StartRecord(cnChannel,nRate,cnBitPerSample)) return false;

	//CCLOG(" after CVoiceRecordBase::StartRecord ");
	JniMethodInfo jmi;

	int nRet=0;
	if (JniHelper::getStaticMethodInfo(jmi,CLASS_NAME,"VoiceStartRecord","(III)I"))
	{
		//CCLOG(" call java.VoiceStartRecord ");
		nRet=jmi.env->CallStaticIntMethod(jmi.classID,jmi.methodID,cnChannel,nRate,cnBitPerSample);
		//CCLOG(" after java.VoiceStartRecord ");
		jmi.env->DeleteLocalRef(jmi.classID);
    }
	return nRet==1;
}

bool CVoiceRecord::StopRecord(char *pszSaveFile)
{
	JniMethodInfo jmi;

	int nRet=0;
	if (JniHelper::getStaticMethodInfo(jmi,CLASS_NAME,"VoiceStopRecord","()I"))
	{
		//CCLOG(" call java.VoiceStopRecord ..");
		nRet=jmi.env->CallStaticIntMethod(jmi.classID,jmi.methodID);
		//CCLOG(" after java.VoiceStopRecord --");
		jmi.env->DeleteLocalRef(jmi.classID);
    }
	//CCLOG(" after java.VoiceStopRecord 2");
	if (nRet!=1) return false;
	//CCLOG(" after java.VoiceStopRecord 3");
	bool b = CVoiceRecordBase::StopRecord(pszSaveFile);
	//CCLOG(" after java.VoiceStopRecord 4");
	return b;
}

//-------------------------------------------------------------------------------------------------------------------------------------
//	VoiceStartPlay
//-------------------------------------------------------------------------------------------------------------------------------------
bool VoiceStartPlay(const char *pszPathName)
{
	JniMethodInfo jmi;
	int nRet=0;
	if (JniHelper::getStaticMethodInfo(jmi,CLASS_NAME,"VoiceStartPlay","(Ljava/lang/String;)I"))
	{
		jstring jstrPathName=jmi.env->NewStringUTF(pszPathName);
		nRet=jmi.env->CallStaticIntMethod(jmi.classID,jmi.methodID,jstrPathName);
		jmi.env->DeleteLocalRef(jmi.classID);
		jmi.env->DeleteLocalRef(jstrPathName);
    }
	return nRet ? true : false;
}

//-------------------------------------------------------------------------------------------------------------------------------------
//	VoiceStopPlay
//-------------------------------------------------------------------------------------------------------------------------------------
void VoiceStopPlay()
{
	JniMethodInfo jmi;

	int nRet=0;
	if (JniHelper::getStaticMethodInfo(jmi,CLASS_NAME,"VoiceStopPlay","()I"))
	{
		nRet=jmi.env->CallStaticIntMethod(jmi.classID,jmi.methodID);
		jmi.env->DeleteLocalRef(jmi.classID);
    }
}
//-------------------------------------------------------------------------------------------------------------------------------------
//	VoiceIsPlaying
//-------------------------------------------------------------------------------------------------------------------------------------
bool VoiceIsPlaying(const char *pszPathName)
{
	JniMethodInfo jmi;

	if (pszPathName==NULL) pszPathName="";

	int nRet=0;
	if (JniHelper::getStaticMethodInfo(jmi,CLASS_NAME,"VoiceIsPlaying","(Ljava/lang/String;)I"))
	{
		jstring jstrPathName=jmi.env->NewStringUTF(pszPathName);
		nRet=jmi.env->CallStaticIntMethod(jmi.classID,jmi.methodID,jstrPathName);
		jmi.env->DeleteLocalRef(jmi.classID);
		jmi.env->DeleteLocalRef(jstrPathName);
    }
	return nRet ? true : false;
}

void buy(const char * str)
{
	JniMethodInfo jmi;

	if (str==NULL) str="";

	int nRet=0;
	if (JniHelper::getStaticMethodInfo(jmi,CLASS_NAME,"Buy","(Ljava/lang/String;)V"))
	{
		jstring itemName=jmi.env->NewStringUTF(str);
		jmi.env->CallStaticVoidMethod(jmi.classID,jmi.methodID,itemName);
		jmi.env->DeleteLocalRef(jmi.classID);
		jmi.env->DeleteLocalRef(itemName);
    }
}
MySpaceEnd

extern "C" {
    JNIEXPORT void JNICALL Java_org_cocos2dx_cpp_AppActivity_launchParam(JNIEnv* env,jobject thiz,jstring launch,jstring cookie,jstring uid,jstring orientation) 
	{
		g_Launch = cocos2d::JniHelper::jstring2string(launch);
		g_Cookie = cocos2d::JniHelper::jstring2string(cookie);
		g_Userid = cocos2d::JniHelper::jstring2string(uid);
		g_Orientation = cocos2d::JniHelper::jstring2string(orientation);
    }

    JNIEXPORT void JNICALL Java_org_cocos2dx_cpp_AppActivity_setExternalStorageDirectory(JNIEnv* env,jobject thiz,jstring dir) 
	{
		g_ExternalStorageDirectory = cocos2d::JniHelper::jstring2string(dir);
    }	

	JNIEXPORT void JNICALL Java_org_cocos2dx_cpp_AppActivity_sendTakeResourceResult(JNIEnv* env,jobject thiz,int t,int r,jstring res)
	{
		std::string df = JniHelper::jstring2string(res);
		takeResource_callback(df,t,r);
	}
		
	JNIEXPORT void JNICALL Java_org_cocos2dx_cpp_AppActivity_sendVoiceRecordData(JNIEnv *env,jobject thiz,jint nType,jint nID,jint nParam1,jint nParam2,jint len,jbyteArray buf)
	{
		int lenBuf=len;
		if (lenBuf==0)
		{
			OnJavaReturnBuf(nType,nID,nParam1,nParam2,0,NULL);
		}
		else
		{
/*			jbyte *data=(jbyte *)env->GetByteArrayElements(buf,0);
			char *pBuf=(char*)malloc(lenBuf+1);
			if (pBuf!=NULL)
			{
				memcpy(pBuf,data,lenBuf);
				pBuf[lenBuf]=0;
	    		OnJavaReturnBuf(nType,nID,nParam1,nParam2,lenBuf,pBuf);
				free(pBuf);
            }
			env->ReleaseByteArrayElements(buf,data,0);
*/
    		char *pBuf=(char *)env->GetByteArrayElements(buf,0);
    		OnJavaReturnBuf(nType,nID,nParam1,nParam2,len,pBuf);
    		env->ReleaseByteArrayElements(buf,(signed char *)pBuf,0);
    	}
	}	
	JNIEXPORT void JNICALL Java_org_cocos2dx_cpp_AppActivity_networkStateChangeEvent(JNIEnv *env,jobject thiz,int state)
	{
		networkStateChange(state);
	}
	JNIEXPORT void JNICALL Java_org_cocos2dx_cpp_AppActivity_cocos2dChangeOrientation(JNIEnv *env,jobject thiz,int state,int w,int h)
	{
		CCLOG("Java_org_cocos2dx_cpp_AppActivity_cocos2dChangeOrientation 1");
		if( state == 1 )
		{
			cocos2dChangeOrientationBySize(w,h);
			CCLOG("Java_org_cocos2dx_cpp_AppActivity_cocos2dChangeOrientation 2");
		}
		CCLOG("Java_org_cocos2dx_cpp_AppActivity_cocos2dChangeOrientation 3");
		sWaitChangeEnd = true;
	}	
	JNIEXPORT void JNICALL Java_org_cocos2dx_cpp_AppActivity_setBaiduResult(JNIEnv *env,jobject thiz,jstring text)
	{
		std::string str = cocos2d::JniHelper::jstring2string(text);
		baiduVoiceResult( str );
	}		
	JNIEXPORT void JNICALL Java_org_cocos2dx_cpp_AppActivity_writeACRLog(JNIEnv *env,jobject thiz,jstring dir)
	{
		std::string str = cocos2d::JniHelper::jstring2string(dir);
		acr_write_log(str.c_str());
	}			
}

