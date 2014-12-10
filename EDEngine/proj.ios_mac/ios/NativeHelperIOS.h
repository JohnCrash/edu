#ifndef  _NATIVE_HELPER_IOS_H_
#define  _NATIVE_HELPER_IOS_H_

//#include "NativeHelper.h"
#include "Platform.h"

#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)

//#include "ClientBase.h"
//#include "../AMR/AMR.h"

bool StartAppStore(const char *pszURI);
bool StartAppStoreForRank(const char *pszURI);

//-------------------------------------------------------------------------------------------------------------------------------------
//	support
//-------------------------------------------------------------------------------------------------------------------------------------
/*
 Define in PlateForm.h
class CVoiceRecord : public CVoiceRecordBase
{
public:
	virtual bool StartRecord(int cnChannel,int nRate,int cnBitPerSample=16);
	virtual bool StopRecord(char *pszSaveFile);
    
	bool OnRecordData(char *pBuf,int len,int nRate);
};
 */
#endif

#endif // _NATIVE_HELPER_IOS_H_
