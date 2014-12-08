//
//  PlatformApple.cpp
//  EDEngine
//
//  Created by john on 14/12/8.
//
//

#include "PlatformApple.h"


void takeResource( int mode )
{
    
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
    
    int nRet=0;
    return nRet==1;
}

bool CVoiceRecord::StopRecord(char *pszSaveFile)
{
    
    int nRet=0;
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
    int nRet=0;
    return nRet ? true : false;
}

//-------------------------------------------------------------------------------------------------------------------------------------
//	VoiceStopPlay
//-------------------------------------------------------------------------------------------------------------------------------------
void VoiceStopPlay()
{
}

//-------------------------------------------------------------------------------------------------------------------------------------
//	VoiceIsPlaying
//-------------------------------------------------------------------------------------------------------------------------------------
bool VoiceIsPlaying(const char *pszPathName)
{
    
    if (pszPathName==NULL) pszPathName="";
    
    int nRet=0;
    return nRet ? true : false;
}