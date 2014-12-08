#include "Platform.h"

bool CVoiceRecord::OnRecordData(char *pBuf,int len,int nRate)
{
    if (m_pEncoder)
    {
        m_pEncoder->AddEncoderBuf(pBuf,len,nRate);
    }
    return true;
}

bool CVoiceRecord::StartRecord(int cnChannel,int nRate,int cnBitPerSample)
{
    //CCLOG("CVoiceRecord::StartRecord ");
    if (!CVoiceRecordBase::StartRecord(cnChannel,nRate,cnBitPerSample)) return false;
    
    int nRet = 0;
    //...
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

