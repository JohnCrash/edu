#include "Platform.h"
#include "NativeHelperIOS.h"

#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)

#include "IOSHelper.h"
#include "cocos2d.h"
USING_NS_CC;

//#include "AppDelegateBase.h"

const char *g_pszFontNameSongTi="SongTi";
const char *g_pszFontNameHeiTi="HeiTi";

static CCPoint s_ptRoot=CCPointZero;

CCPoint &GetRootPoint()
{
    return s_ptRoot;
}

void SetRootPoint(CCPoint pt)
{
    s_ptRoot=pt;
}

bool IsPhone()
{
    return IOS_IsIPhone();
}

//-------------------------------------------------------------------------------------------------------------------------------------
//	StartApp
//-------------------------------------------------------------------------------------------------------------------------------------

/*
 CURI
bool StartApp(const char *pszURI)
{
	CURI uri(pszURI);
	std::string strPackage=uri.GetPackage();
	std::string strParam=uri.GetParam("Param");
    
    //such as: ljshell://com.lj.ljshell
    strParam+="://";
    strParam+=strPackage;
	return IOS_StartApp(strParam.c_str());
}

bool StartAppStore(const char *pszURI)
{
	CURI uri(pszURI);
	std::string strID=uri.GetParam("id");
	if (strID.empty()) return false;

	char szURL[256];
	sprintf(szURL,"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=%s",strID.c_str());
	return IOS_StartApp(szURL);
}

bool StartAppStoreForRank(const char *pszURI)
{
	CURI uri(pszURI);
	std::string strID=uri.GetParam("id");
	if (strID.empty()) return false;

	char szURL[256];
	sprintf(szURL,"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%s",strID.c_str());
	return IOS_StartApp(szURL);
}
*/
//-------------------------------------------------------------------------------------------------------------------------------------
//	GetPackageVersion
//-------------------------------------------------------------------------------------------------------------------------------------
/*
int GetPackageVersion(const char *pszURI)
{
	CURI uri(pszURI);
	std::string strPackage=uri.GetPackage();
	std::string strParam=uri.GetParam("Param");

	//没有ID就相当于没有上线
	std::string strID=uri.GetParam("id");
	if (strID.empty()) return -1;
    
    //such as: ljshell://com.lj.ljshell
    strParam+="://";
    strParam+=strPackage;
    //we do not have idea to get the app's version, so we return 0 always, ljshell will deal it
	if (IOS_IsPackageExist(strParam.c_str())) return 0;
    
    return -1;
}
*/
//-------------------------------------------------------------------------------------------------------------------------------------
//	InstallPackage
//-------------------------------------------------------------------------------------------------------------------------------------
bool InstallPackage(const char *pszProgramPathName)
{
    return false;
}

//-------------------------------------------------------------------------------------------------------------------------------------
//	BackToTheHome
//-------------------------------------------------------------------------------------------------------------------------------------
bool BackToTheHome()
{
	return 0;
}

void takeResource( int mode )
{
    if( mode == TAKE_PICTURE )
    {
        TakePhoto();
    }
    else if(mode == PICK_PICTURE )
    {
        PickPicture();
    }
    else
    {
        takeResource_callback("iOS takeResource can't support mode",mode,RESULT_ERROR);
    }
}

//-------------------------------------------------------------------------------------------------------------------------------------
//	TakePhoto
//
//	implemented in mm file
//-------------------------------------------------------------------------------------------------------------------------------------

//-------------------------------------------------------------------------------------------------------------------------------------
//	PickPhoto
//
//	implemented in mm file
//-------------------------------------------------------------------------------------------------------------------------------------

//-------------------------------------------------------------------------------------------------------------------------------------
//	implemented in mm file
//-------------------------------------------------------------------------------------------------------------------------------------
int SavePictureToSystemFolder(const char *pszPathName,char *pszPrompt);

//-------------------------------------------------------------------------------------------------------------------------------------
//	SavePictureToSystemFolder
//-------------------------------------------------------------------------------------------------------------------------------------
int SavePictureToSystemFolder(const char *pszPathName,std::string &strPrompt)
{
	char szPrompt[256];
	int nRet=SavePictureToSystemFolder(pszPathName,szPrompt);
	strPrompt=szPrompt;
	return nRet;
}

int SaveDocFileToSystemFolder(const char *pszDownloadName,const char *pszFileName,std::string &strPrompt,std::string &strSaveFileName)
{
	strPrompt="@error_savedocfileios";
	return 1;
}

bool OpenDocFile(const char *pszPathName)
{
	return false;
}

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
	if (!CVoiceRecordBase::StartRecord(cnChannel,nRate,cnBitPerSample)) return false;
    return IOS_VoiceStartRecord(cnChannel,nRate,cnBitPerSample);
}

bool CVoiceRecord::StopRecord(char *pszSaveFile)
{
    if (!IOS_VoiceStopRecord()) return false;
	return CVoiceRecordBase::StopRecord(pszSaveFile);
}

//-------------------------------------------------------------------------------------------------------------------------------------
//	VoiceStartPlay
//-------------------------------------------------------------------------------------------------------------------------------------
bool VoiceStartPlay(const char *pszPathName)
{
    int lenBuf;
	char *pBuf=AMRDecoder(pszPathName,lenBuf);
	if (pBuf==NULL)
	{
		return false;
	}
    bool bRet=IOS_VoiceStartPlay(pBuf,lenBuf);
    free(pBuf);
    return bRet;
}

//-------------------------------------------------------------------------------------------------------------------------------------
//	VoiceIsPlaying
//-------------------------------------------------------------------------------------------------------------------------------------
bool VoiceIsPlaying(const char *pszPathName)
{
    return IOS_VoiceIsPlaying();
}

//-------------------------------------------------------------------------------------------------------------------------------------
//	VoiceStopPlay
//-------------------------------------------------------------------------------------------------------------------------------------
void VoiceStopPlay()
{
    if( !IOS_VoiceStopPlay() )
    {
        CCLOG("IOS_VoiceStopPlay return false!");
    }
}

//-------------------------------------------------------------------------------------------------------------------------------------
//	SetInputFocusPosition
//-------------------------------------------------------------------------------------------------------------------------------------
bool SetInputFocusPosition(int x,int y,bool bAttachIME)
{
	return false;
}

//-------------------------------------------------------------------------------------------------------------------------------------
//	GetNetStatus
//-------------------------------------------------------------------------------------------------------------------------------------
int GetNetStatus()
{
	return 3;
}

//-------------------------------------------------------------------------------------------------------------------------------------
//	DoVibrator
//-------------------------------------------------------------------------------------------------------------------------------------
bool DoVibrator()
{
	return false;
}

//-------------------------------------------------------------------------------------------------------------------------------------
//	HasVibrator
//-------------------------------------------------------------------------------------------------------------------------------------
bool HasVibrator()
{
    return IOS_IsIPhone();
}

//-------------------------------------------------------------------------------------------------------------------------------------
//	CopyToClipboard
//-------------------------------------------------------------------------------------------------------------------------------------
bool CopyToClipboard(const char *pszText)
{
    return IOS_CopyToClipboard(pszText);
}

//-------------------------------------------------------------------------------------------------------------------------------------
//	CopyFromClipboard
//-------------------------------------------------------------------------------------------------------------------------------------
std::string CopyFromClipboard()
{
    return IOS_CopyFromClipboard();
}

int PickDocFile()
{
}

bool SendSMSMsg(const char *pszPhoneNo,const char *pszMsg)
{
	return false;
}

bool StartPhoneCall(const char *pszPhoneNo)
{
	return false;
}

#endif
