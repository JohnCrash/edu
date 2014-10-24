#include "Platform.h"

#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32
void takeResource( int mode )
{
}

CVoiceRecordHdr::CVoiceRecordHdr()
{
	m_hdr.dwFlags=0;
	m_hdr.dwLoops=0;
	m_hdr.dwBytesRecorded=0;
	m_hdr.dwBufferLength=LEN_VOICE_BUF;
	m_hdr.lpData=m_chBuf;
	m_hdr.dwUser=NULL;
}

CVoiceRecord::CVoiceRecord()
{
	m_hWave=NULL;
}

CVoiceRecord::~CVoiceRecord()
{
}

static void *_VoiceRecordThreadFunc(void *pParam)
{
	CVoiceRecord *p=(CVoiceRecord *)pParam;
	p->ThreadFunc();
	return NULL;
}

void CVoiceRecord::ThreadFunc()
{
	while (!m_bStoping)
	{
		if (m_cnNeedUnprepareHdr<=0)
		{
			Sleep(10);
			continue;
		}
		Lock();
		for (int i=0;i<COUNT_VOICE_BUF;i++)
		{
			WAVEHDR *pHdr=&m_listHdr[i].m_hdr;
			if (pHdr->dwUser)
			{
				waveInUnprepareHeader(m_hWave,pHdr,sizeof(WAVEHDR));
				pHdr->dwFlags=0;
				pHdr->dwLoops=0;
				pHdr->dwBytesRecorded=0;
				waveInPrepareHeader(m_hWave,pHdr,sizeof(WAVEHDR));
				waveInAddBuffer(m_hWave,pHdr,sizeof(WAVEHDR));

				pHdr->dwUser=NULL;
				m_cnNeedUnprepareHdr--;
			}
		}
		Unlock();
	}
	m_bRunning=false;
}

static void CALLBACK _waveInProc(HWAVEIN hWave,UINT uMsg,DWORD dwInstance,DWORD dwParam1,DWORD dwParam2)
{
	CVoiceRecord *pVoice=(CVoiceRecord *)dwInstance;
	pVoice->waveInProc(uMsg,dwParam1,dwParam2);
}

void CVoiceRecord::waveInProc(UINT uMsg,DWORD dwParam1,DWORD dwParam2)
{
	switch (uMsg)
	{
	case WIM_OPEN:
		return;
	case WIM_DATA:
		break;
	case WIM_CLOSE:
	default:
		Close();
		return;
	}
	WAVEHDR *pHdr=(WAVEHDR *)dwParam1;
	if (m_pEncoder)
	{
		m_pEncoder->AddEncoderBuf(pHdr->lpData,pHdr->dwBytesRecorded);
	}
	Lock();
	pHdr->dwUser=(DWORD_PTR)1;
	m_cnNeedUnprepareHdr++;
	Unlock();
}

bool CVoiceRecord::StartRecord(int cnChannel,int nRate,int cnBitPerSample)
{
	if (!CVoiceRecordBase::StartRecord(cnChannel,nRate,cnBitPerSample)) return false;

	memset(&m_fmtWave,0,sizeof(WAVEFORMATEX));
	m_fmtWave.wFormatTag=WAVE_FORMAT_PCM;
	m_fmtWave.nChannels=cnChannel;
	m_fmtWave.wBitsPerSample=cnBitPerSample;
	m_fmtWave.nSamplesPerSec=nRate;
	m_fmtWave.nBlockAlign=m_fmtWave.wBitsPerSample/8*cnChannel;
	m_fmtWave.nAvgBytesPerSec=nRate*m_fmtWave.nBlockAlign;
	m_fmtWave.cbSize=0;

	int nRet=waveInOpen(&m_hWave,WAVE_MAPPER,&m_fmtWave,(DWORD)_waveInProc,(DWORD_PTR)this,CALLBACK_FUNCTION);
	if (nRet!=MMSYSERR_NOERROR) return false;
	for (int i=0;i<COUNT_VOICE_BUF;i++)
	{
		waveInPrepareHeader(m_hWave,&m_listHdr[i].m_hdr,sizeof(WAVEHDR));
		waveInAddBuffer(m_hWave,&m_listHdr[i].m_hdr,sizeof(WAVEHDR));
		m_listHdr[i].m_hdr.dwUser=NULL;
	}
	m_cnNeedUnprepareHdr=0;
	m_bStoping=false;
	m_bRunning=true;
	m_pThread = new std::thread(_VoiceRecordThreadFunc,this);
	//if (!NewThread(_VoiceRecordThreadFunc,this))
	if( m_pThread )
	{
		m_bRunning=false;
		Close();
		return false;
	}

	if (waveInStart(m_hWave)!=MMSYSERR_NOERROR)
	{
		Close();
		return false;
	}
	return true;
}

bool CVoiceRecord::Close()
{
	if (m_hWave==NULL) return true;

	m_bStoping=true;
	while (m_bRunning) Sleep(10);

	waveInReset(m_hWave);
	for (int i=0;i<COUNT_VOICE_BUF;i++)
	{
		waveInUnprepareHeader(m_hWave,&m_listHdr[i].m_hdr,sizeof(WAVEHDR));
	}
	waveInStop(m_hWave);
	waveInClose(m_hWave);
	m_hWave=NULL;

	CVoiceRecordBase::Close();
	return true;
}
#endif