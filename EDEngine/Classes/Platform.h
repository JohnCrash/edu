#ifndef _PLATFORM_H_
#define _PLATFORM_H_

#include "cocos2d.h"
#include <string>
#include <thread>
#include <mutex>

#define RETURN_TYPE_RECORDDATA 10
#define TAKE_PICTURE 1
#define PICK_PICTURE 2

#define RESULT_OK (-1)
#define RESULT_CANCEL (0)
#define RESULT_ERROR (-2)

void takeResource( int mode );
void takeResource_callback(std::string resource,int typeCode,int resultCode);

bool VoiceStartRecord(int cnChannel,int nRate,int cnBitPerSample=16);			//��ʼ¼��
bool VoiceStopRecord(char *pszSaveFile);										//ֹͣ¼�����������ݱ��浽ָ���ļ�
bool VoiceGetRecordInfo(float &fDuration,int &nCurVolume);						//��ȡ��ǰ¼�����ݣ�fDuration��ʱ����nCurVolume�ǵ�ǰ������

void OnJavaReturnBuf(int nType,int nID,int nParam1,int nParam2,int lenBuf,char *pBuf);
void OnJavaReturn(int nType,int nID,int nParam1,int nParam2);
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
#else
#endif

#endif