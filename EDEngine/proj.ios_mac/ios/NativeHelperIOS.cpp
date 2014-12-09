#include "NativeHelperIOS.h"

#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)

#include "IOSHelper.h"
#include "AppDelegateBase.h"

const char *g_pszFontNameSongTi="SongTi";
const char *g_pszFontNameHeiTi="HeiTi";

static CVoiceRecord *s_pVoiceRecord=NULL;

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
//	OnIOSReturnBuf
//
//	called from native
//-------------------------------------------------------------------------------------------------------------------------------------
void OnIOSReturnBuf(int nType,int nID,int nParam1,int nParam2,int lenBuf,char *pBuf)
{
	if (nType==RETURN_TYPE_RECORDDATA)
	{
        //record data
		if (s_pVoiceRecord) s_pVoiceRecord->OnRecordData(pBuf,lenBuf,nParam1);
		return;
	}
	g_pTheApp->OnReturnBuf(nType,nID,nParam1,nParam2,lenBuf,pBuf);
}

//-------------------------------------------------------------------------------------------------------------------------------------
//	OnIOSReturn
//
//	called from native
//-------------------------------------------------------------------------------------------------------------------------------------
void OnIOSReturn(int nType,int nID,int nParam1,int nParam2)
{
	if (nType==RETURN_TYPE_TAKEPICTURE && nParam1!=0)
	{
		std::string strTmpPathName=g_pTheApp->GetAppTmpDir()+"takephoto.jpg";
		g_pTheApp->OnReturnBuf(nType,nID,nParam1,nParam2,strTmpPathName.length()+1,(char *)strTmpPathName.c_str());
		return;
	}
	g_pTheApp->OnReturnBuf(nType,nID,nParam1,nParam2,0,NULL);
}

//-------------------------------------------------------------------------------------------------------------------------------------
//	StartApp
//-------------------------------------------------------------------------------------------------------------------------------------
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

//-------------------------------------------------------------------------------------------------------------------------------------
//	GetPackageVersion
//-------------------------------------------------------------------------------------------------------------------------------------
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

static bool NewVoice()
{
	if (s_pVoiceRecord!=NULL) return true;
    
	s_pVoiceRecord=new CVoiceRecord;
	if (s_pVoiceRecord->Init()) return true;
    
	delete s_pVoiceRecord;
	s_pVoiceRecord=NULL;
	return false;
}

//-------------------------------------------------------------------------------------------------------------------------------------
//	VoiceStartRecord
//-------------------------------------------------------------------------------------------------------------------------------------
bool VoiceStartRecord(int cnChannel,int nRate,int cnBitPerSample)
{
	if (!NewVoice()) return false;
	return s_pVoiceRecord->StartRecord(cnChannel,nRate,cnBitPerSample);
}

//-------------------------------------------------------------------------------------------------------------------------------------
//	VoiceStopRecord
//-------------------------------------------------------------------------------------------------------------------------------------
bool VoiceStopRecord(char *pszSaveFile)
{
	return s_pVoiceRecord->StopRecord(pszSaveFile);
}

//-------------------------------------------------------------------------------------------------------------------------------------
//	VoiceGetRecordInfo
//-------------------------------------------------------------------------------------------------------------------------------------
bool VoiceGetRecordInfo(float &fDuration,int &nCurVolume)
{
	if (s_pVoiceRecord==NULL) return false;
	return s_pVoiceRecord->GetRecordInfo(fDuration,nCurVolume);
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
bool VoiceStopPlay()
{
	return IOS_VoiceStopPlay();
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
