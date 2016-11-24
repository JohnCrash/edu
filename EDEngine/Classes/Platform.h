#ifndef _PLATFORM_H_
#define _PLATFORM_H_

#include "staticlib.h"

#include "cocos2d.h"
#include <string>
#include <thread>
#include <mutex>
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID
#include <unistd.h>
#endif

#if CC_TARGET_PLATFORM == CC_PLATFORM_IOS||CC_TARGET_PLATFORM == CC_PLATFORM_MAC
#include <unistd.h>
#endif

#define RETURN_TYPE_RECORDDATA 10
#define TAKE_PICTURE 1
#define PICK_PICTURE 2

#define RESULT_OK (-1)
#define RESULT_CANCEL (0)
#define RESULT_ERROR (-2)

MySpaceBegin

extern std::string g_Launch;
extern std::string g_Cookie;
extern std::string g_Userid;
extern std::string g_ExternalStorageDirectory;
extern std::string g_RecordFile;
extern std::string g_Orientation;

void buy(const char * str);
void showBaiduVoice();
void closeBaiduVoice();
void showBaiduVoiceConfigure();
void baiduVoiceResult( std::string text );

bool platformOpenURL( const char *url );
void setUIOrientation( int m );
int getUIOrientation();
void cocos2dChangeOrientation( int m );
void cocos2dChangeOrientationBySize(int w, int h);

void ShockPhonePattern( int *pattern,int n );
void ShockPhoneDelay( int t );

int getNetworkState();
void registerNetworkStateListener();
void unregisterNetworkStateListener();
void networkStateChange(int state);

void takeResource( int mode );
void takeResource_callback(std::string resource,int typeCode,int resultCode);

bool VoiceStartRecord(int cnChannel,int nRate,int cnBitPerSample=16);			//开始录音
bool VoiceStopRecord(char *pszSaveFile);										//停止录音，并把数据保存到指定文件
bool VoiceGetRecordInfo(float &fDuration,int &nCurVolume);						//读取当前录音数据，fDuration是时长，nCurVolume是当前的音量

bool VoiceStartPlay(const char *filename);
void VoiceStopPlay();
bool VoiceIsPlaying(const char *pszPathName);
double VoiceLongth(const char *filename);

void OnJavaReturnBuf(int nType,int nID,int nParam1,int nParam2,int lenBuf,char *pBuf);
void OnJavaReturn(int nType,int nID,int nParam1,int nParam2);

void OnIOSReturnBuf(int nType,int nID,int nParam1,int nParam2,int lenBuf,char *pBuf);
void OnIOSReturn(int nType,int nID,int nParam1,int nParam2);

//	mode	MR475, MR515, MR59, MR67, MR74, MR795, MR102, MR122
bool AMREncoder(int cnChannel,int nRate,int cnBitPerSample,char *pBuf,int len,const char *pszPathName,int nMode);
char *AMRDecoder(const char *pszPathName,int &len);

class CLockObject
{
public:
	CLockObject()
	{
	}
	void Lock()
	{
		m_Mutex.lock();
	}
	void Unlock()
	{
		m_Mutex.unlock();
	}
	void Sleep( int m )
	{
#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID
		usleep(m);
#elif CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
		::Sleep(m);
#elif CC_TARGET_PLATFORM == CC_PLATFORM_IOS || CC_TARGET_PLATFORM == CC_PLATFORM_MAC
		usleep(m);
#endif
	}
protected:
	std::mutex m_Mutex;
};

class CDynaAMREncoder : public CLockObject
{
public:
	CDynaAMREncoder();
	~CDynaAMREncoder();

	bool InitEncoder(int cnChannel,int nRate,int cnBitPerSample,int nMode);
	bool AddEncoderBuf(char *pBuf,int len,int nRate=0);
	bool CloseEncoder();

	const char *GetEncoderedPathName(){return m_strTmpFile.c_str();}
	int GetEncoderedSampleCount(){return m_cnEncoderedSample;}
	int GetCurVolume(){return m_nCurVolume;}

	void ThreadFunc();

protected:
	bool m_bRunning;
	bool m_bStoping;

	void *m_pInterfaceEncoder;
	int m_cnChannel;
	int m_nRate;
	int m_cnEncoderedSample;

	FILE *m_fpEncoder;
	int m_nMode;

	char *m_pBuf;
	int m_lenBuf;
	int m_nPos;
	int m_lenBufAlloc;

	std::string m_strTmpFile;

	int m_nCurVolume;
	uint64_t m_nVolumeSum;
	int m_cnVolumeValue;

	std::thread * m_pThread;
};

class CVoiceRecordBase : public CLockObject
{
public:
	CVoiceRecordBase();
	~CVoiceRecordBase();

	virtual bool Init();

	virtual bool StartRecord(int cnChannel,int nRate,int cnBitPerSample=16);
	virtual bool StopRecord(char *pszSaveFile);
	virtual bool GetRecordInfo(float &fDuration,int &nCurVolume);
	virtual bool Close();

protected:
	CDynaAMREncoder *m_pEncoder;
	int m_nMode;
};

#if CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID
class CVoiceRecord : public CVoiceRecordBase
{
public:
	virtual bool StartRecord(int cnChannel,int nRate,int cnBitPerSample=16);
	virtual bool StopRecord(char *pszSaveFile);

	bool OnRecordData(char *pBuf,int len,int nRate);
};
#elif CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
#include "mmsystem.h"
#include "vfw.h"

#define WM_LJSHELL_URIFLAG    0xEFBF8B62
#define WM_LJSHELL_CLASSNAME  "ljShellWin32"
typedef struct tagljRunParam
{
	HWND  hWnd;
	char  szURI[1024];
}LJRUNPARAM, *PLJRUNPARAM;
typedef struct tagljRunResParam
{
	int    nRes;
	char  szParam[1024];
}LJRUNRESPARAM, *PLJRUNRESPARAM;

class CCameraWin
{
public:
	CCameraWin();
	~CCameraWin();

public:
	bool Open(int nID, HWND hwndParent = NULL);
	void Close();
	LRESULT OnWndProc(UINT Msg, WPARAM wParam, LPARAM lParam);
	LRESULT OnCameraCallback(LPVIDEOHDR lpVHdr);

protected:
	HWND CreateButton(const wchar_t *pwszText, int x, int y, int w, int h);
	void OnTakePhoto();
	void OnFinish();

protected:
	int m_nID;
	int m_nCameraID;

	HINSTANCE m_hInstance;
	HWND m_hwnd;
	HWND m_hCamera;
	HWND m_hTakePhoto;
	HWND m_hFinish;

	int m_nSaveWidth;
	int m_nSaveHeight;

	char *m_pImageBuf;
	bool m_bCaptured;
};

#define LEN_VOICE_BUF		2048
#define	COUNT_VOICE_BUF		3
class CVoiceRecordHdr
{
public:
	CVoiceRecordHdr();

	bool IsPrepared(){return (m_hdr.dwFlags & WHDR_PREPARED)!=0;}

	WAVEHDR m_hdr;
	char m_chBuf[LEN_VOICE_BUF];
};

class CVoiceRecord : public CVoiceRecordBase
{
public:
	CVoiceRecord();
	~CVoiceRecord();

	virtual bool StartRecord(int cnChannel,int nRate,int cnBitPerSample=16);
	bool Close();

	void waveInProc(UINT uMsg,DWORD dwParam1,DWORD dwParam2);
	void ThreadFunc();

protected:
	WAVEFORMATEX m_fmtWave;
	HWAVEIN m_hWave;
	CVoiceRecordHdr m_listHdr[COUNT_VOICE_BUF];
	int m_cnNeedUnprepareHdr;

	bool m_bStoping;
	bool m_bRunning;
	std::thread * m_pThread;
};

//=============================================
//	CVoicePlay
//=============================================
class CVoicePlay
{
public:
	CVoicePlay();
	~CVoicePlay();

	bool Init();
	void waveOutProc(UINT uMsg, DWORD dwParam1, DWORD dwParam2);
	bool StartPlay(const char *pszPathName);
	bool IsPlaying(const char *pszPathName);
	bool StopPlay();

	void ThreadFunc();

protected:
	void Lock(){ EnterCriticalSection(&m_cs); }
	void Unlock(){ LeaveCriticalSection(&m_cs); }

	bool CloseWave();

protected:
	CRITICAL_SECTION m_cs;

	HWAVEOUT m_hWave;
	bool m_bPlaying;
	bool m_bStoping;

	CVoiceRecordHdr m_hdr1, m_hdr2;

	char *m_pBuf;
	int m_lenBuf;
	int m_lenPlayed;
	std::thread *m_pThread;
	std::string m_strPathName;
};

#elif CC_TARGET_PLATFORM == CC_PLATFORM_IOS
//IOS
class CVoiceRecord : public CVoiceRecordBase
{
public:
    virtual bool StartRecord(int cnChannel,int nRate,int cnBitPerSample=16);
    virtual bool StopRecord(char *pszSaveFile);
    
    bool OnRecordData(char *pBuf,int len,int nRate);
};

#endif
MySpaceEnd
#endif
