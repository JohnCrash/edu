#include <jni.h>
#include <string>
#include "JniHelper.h"
#include "cocos2d.h"
#include "../../Classes/Platform.h"

using namespace cocos2d;

#define  CLASS_NAME "org/cocos2dx/cpp/AppActivity"

std::string g_Launch;
std::string g_Cookie;
std::string g_Userid;
std::string g_ExternalStorageDirectory;
std::string g_RecordFile;
	
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
		CCLOG("CVoiceRecord::OnRecordData ");
		m_pEncoder->AddEncoderBuf(pBuf,len,nRate);
	}
	return true;
}

bool CVoiceRecord::StartRecord(int cnChannel,int nRate,int cnBitPerSample)
{
	CCLOG("CVoiceRecord::StartRecord ");
	if (!CVoiceRecordBase::StartRecord(cnChannel,nRate,cnBitPerSample)) return false;

	CCLOG(" after CVoiceRecordBase::StartRecord ");
	JniMethodInfo jmi;

	int nRet=0;
	if (JniHelper::getStaticMethodInfo(jmi,CLASS_NAME,"VoiceStartRecord","(III)I"))
	{
		CCLOG(" call java.VoiceStartRecord ");
		nRet=jmi.env->CallStaticIntMethod(jmi.classID,jmi.methodID,cnChannel,nRate,cnBitPerSample);
		CCLOG(" after java.VoiceStartRecord ");
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
		CCLOG(" call java.VoiceStopRecord ");
		nRet=jmi.env->CallStaticIntMethod(jmi.classID,jmi.methodID);
		CCLOG(" after java.VoiceStopRecord ");
		jmi.env->DeleteLocalRef(jmi.classID);
    }
	if (nRet!=1) return false;

	return CVoiceRecordBase::StopRecord(pszSaveFile);
}

extern "C" {
    JNIEXPORT void JNICALL Java_org_cocos2dx_cpp_AppActivity_launchParam(JNIEnv* env,jobject thiz,jstring launch,jstring cookie,jstring uid) 
	{
		g_Launch = cocos2d::JniHelper::jstring2string(launch);
		g_Cookie = cocos2d::JniHelper::jstring2string(cookie);
		g_Userid = cocos2d::JniHelper::jstring2string(uid);
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
}

