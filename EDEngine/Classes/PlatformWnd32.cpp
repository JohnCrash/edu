#include "Platform.h"

#if CC_TARGET_PLATFORM == CC_PLATFORM_WIN32

#pragma comment (lib,"vfw32")
#pragma comment (lib,"winmm.lib")
#pragma comment (lib,"imm32.lib")

//==========================
// CCameraWin
//==========================
static float g_Scale = 1;
CCameraWin::CCameraWin()
{
	m_nCameraID = -1;
	m_hwnd = NULL;
	m_pImageBuf = NULL;
	m_bCaptured = false;
}

CCameraWin::~CCameraWin()
{
	Close();
}

void CCameraWin::Close()
{
	if (m_hwnd != NULL)
	{
		capPreview(m_hCamera, FALSE);
		capDriverDisconnect(m_hwnd);
		DestroyWindow(m_hwnd);

		m_hwnd = NULL;
		m_hCamera = NULL;
	}
	free(m_pImageBuf);
	m_pImageBuf = NULL;
}

static LRESULT WINAPI _CameraWinWndProc(HWND hwnd, UINT Msg, WPARAM wParam, LPARAM lParam)
{
	CCameraWin *pObject = (CCameraWin *)GetWindowLongA(hwnd, GWL_USERDATA);
	if (pObject == NULL) return DefWindowProc(hwnd, Msg, wParam, lParam);

	return pObject->OnWndProc(Msg, wParam, lParam);
}

void CCameraWin::OnTakePhoto()
{
	if (m_bCaptured)
	{
		SetWindowText(m_hTakePhoto, L"拍摄");
		SetWindowText(m_hFinish, L"取消");
		//处理重拍
		m_bCaptured = false;
		free(m_pImageBuf);
		m_pImageBuf = NULL;
		capPreview(m_hCamera, TRUE);
		return;
	}

	//拍摄
	if (!capGrabFrame(m_hCamera)) return;
	if (!capEditCopy(m_hCamera) || !IsClipboardFormatAvailable(CF_DIB))
	{
		capPreview(m_hCamera, TRUE);
		return;
	}

	if (OpenClipboard(m_hwnd))
	{
		HGLOBAL hClip = GetClipboardData(CF_DIB);
		if (hClip == NULL)
		{
			CloseClipboard();
			capPreview(m_hCamera, TRUE);
			return;
		}
		LPBITMAPINFO pBmp = (LPBITMAPINFO)GlobalLock(hClip);
		if (pBmp->bmiHeader.biBitCount == 24 && pBmp->bmiHeader.biPlanes == 1)
		{
			m_nSaveWidth = pBmp->bmiHeader.biWidth;
			m_nSaveHeight = pBmp->bmiHeader.biHeight;
			char *pBuf = (char *)realloc(m_pImageBuf, m_nSaveWidth * 4 * m_nSaveHeight);
			if (pBuf != NULL)
			{
				char *pSrc = (char *)(pBmp + 1);
				pSrc += m_nSaveWidth * 3 * (m_nSaveHeight - 1);

				char *pDst = pBuf;
				for (int i = 0; i<pBmp->bmiHeader.biHeight; i++)
				{
					for (int j = 0; j<pBmp->bmiHeader.biWidth; j++)
					{
						*pDst++ = *pSrc++;
						*pDst++ = *pSrc++;
						*pDst++ = *pSrc++;
						*pDst++ = (unsigned char)0xff;
					}
					pSrc -= m_nSaveWidth * 3 * 2;
				}
				m_pImageBuf = pBuf;
				m_bCaptured = true;
			}
		}
		GlobalUnlock(hClip);
		CloseClipboard();
	}
	if (!m_bCaptured)
	{
		capPreview(m_hCamera, TRUE);
	}
	else
	{
		SetWindowText(m_hTakePhoto, L"重试");
		SetWindowText(m_hFinish, L"确定");
	}
}

void CCameraWin::OnFinish()
{
	if (m_bCaptured)
	{
		//结束
		//g_pTheApp->OnReturnBuf(RETURN_TYPE_TAKEPICTUREDIB, m_nID, m_nSaveWidth, m_nSaveHeight, m_nSaveWidth * 4 * m_nSaveHeight, (char *)m_pImageBuf);
		takeResource_callback(m_pImageBuf, TAKE_PICTURE, RESULT_OK);
	}
	else
	{
		//取消
		//g_pTheApp->OnReturnBuf(RETURN_TYPE_TAKEPICTUREDIB, m_nID, 0, 0, 0, NULL);
		takeResource_callback(std::string(), TAKE_PICTURE, RESULT_CANCEL);
	}
	Close();
}

LRESULT CCameraWin::OnWndProc(UINT Msg, WPARAM wParam, LPARAM lParam)
{
	switch (Msg)
	{
	case WM_COMMAND:
		if (wParam >> 16 == BN_CLICKED)
		{
			HWND hwnd = (HWND)lParam;
			if (hwnd == m_hTakePhoto)
			{
				OnTakePhoto();
				return (LRESULT)true;
			}
			else if (hwnd == m_hFinish)
			{
				OnFinish();
				return (LRESULT)true;
			}
		}
		break;
	default:
		break;
	}
	return DefWindowProc(m_hwnd, Msg, wParam, lParam);
}

LRESULT CALLBACK _CameraCallback(HWND hwnd, LPVIDEOHDR lpVHdr)
{
	CCameraWin *pObject = (CCameraWin *)GetWindowLongA(hwnd, GWL_USERDATA);
	if (pObject == NULL) return (LRESULT)true;

	return pObject->OnCameraCallback(lpVHdr);
}

LRESULT CCameraWin::OnCameraCallback(LPVIDEOHDR lpVHdr)
{
	return (LRESULT)true;
}

HWND CCameraWin::CreateButton(const wchar_t *pwszText, int x, int y, int w, int h)
{
	return CreateWindow(L"BUTTON", pwszText, WS_VISIBLE | WS_CHILD | BS_DEFPUSHBUTTON, x, y, w, h, m_hwnd, NULL, m_hInstance, NULL);
}

static const wchar_t *pwszCameraWndClassName = L"LJCameraWnd";
static const wchar_t *pwszCameraWndTitle = L"照片拍摄";

//摄像头数目，10个足够了
#define	MAX_VFW_DEVICES	10

bool CCameraWin::Open(int nID, HWND hwndParent)
{
	if (m_hwnd != NULL) Close();

	m_nID = nID;
	m_hInstance = GetModuleHandle(NULL);
	//窗口背景
	HBRUSH hbrBackground = CreateSolidBrush(RGB(192, 192, 192));

	WNDCLASS wc;
	wc.style = 0;
	wc.lpfnWndProc = _CameraWinWndProc;
	wc.cbClsExtra = 0;
	wc.cbWndExtra = 0;
	wc.hInstance = m_hInstance;
	wc.hIcon = LoadIcon(NULL, IDI_WINLOGO);
	wc.hCursor = LoadCursor(NULL, IDC_ARROW);
	wc.hbrBackground = hbrBackground;
	wc.lpszMenuName = NULL;
	wc.lpszClassName = pwszCameraWndClassName;

	//创建失败，或者已经创建过了
	if (RegisterClass(&wc) == NULL && GetLastError() != 1410)
	{
		return false;
	}

	m_hwnd = CreateWindow(
		pwszCameraWndClassName,							//classname
		pwszCameraWndTitle,								//title
		WS_CAPTION | WS_POPUPWINDOW | WS_VISIBLE,		//styles
		0, 0, 0, 0,										//position
		hwndParent,										//Parent Window
		NULL,											//No Menu
		m_hInstance,									//Instance
		NULL
		);
	if (m_hwnd == NULL) return false;
	SetWindowLong(m_hwnd, GWL_USERDATA, (LONG)this);

	//创建窗口
	m_hCamera = capCreateCaptureWindowA("LJ", WS_CHILD | WS_VISIBLE, 0, 0, 0, 0, m_hwnd, 0);
	if (m_hCamera == NULL)
	{
		Close();
		return false;
	}
	SetWindowLong(m_hCamera, GWL_USERDATA, (LONG)this);
	capSetCallbackOnFrame(m_hCamera, _CameraCallback);

	char szDeviceName[80];
	char szDeviceVersion[80];
	m_nCameraID = -1;
	for (int i = 0; i<MAX_VFW_DEVICES; i++)
	{
		if (capGetDriverDescriptionA(i, szDeviceName, sizeof(szDeviceName), szDeviceVersion, sizeof(szDeviceVersion)))
		{
			for (int j = 0; j<5; j++)
			{
				if (capDriverConnect(m_hCamera, i))
				{
					m_nCameraID = i;
					break;
				}
			}
			if (m_nCameraID >= 0) break;
		}
	}
	if (m_nCameraID<0)
	{
		//没有连接到摄像头
		Close();
		return false;
	}
	CAPSTATUS status;
	if (!capGetStatus(m_hCamera, &status, sizeof(status)))
	{
		Close();
		return false;
	}
	int wImage = status.uiImageWidth;
	int hImage = status.uiImageHeight;
	int nBottomHeight = 70 * g_Scale;//g_pTheApp->GetMainScaleY();

	RECT rc;
	GetWindowRect(hwndParent, &rc);

	int wFrame = rc.right - rc.left;
	int hFrame = rc.bottom - rc.top;
	POINT pt;
	pt.x = wImage;
	pt.y = hImage + nBottomHeight;
	ClientToScreen(m_hwnd, &pt);

	MoveWindow(m_hwnd, rc.left, rc.top, pt.x, pt.y, true);

	MoveWindow(m_hCamera, 0, 0, wImage, hImage, true);
	capPreviewRate(m_hCamera, 30);
	capPreview(m_hCamera, TRUE);

	int x, y;
	int w, h;

	w = 80 * g_Scale;// g_pTheApp->GetMainScaleY();
	int nGap = 20 * g_Scale;//g_pTheApp->GetMainScaleY();
	x = wImage - nGap - w;

	h = 40 * g_Scale;// g_pTheApp->GetMainScaleY();
	y = hImage + (nBottomHeight - h) / 2;

	m_hFinish = CreateButton(L"取消", x, y, w, h);
	if (m_hTakePhoto == NULL)
	{
		Close();
		return false;
	}
	x -= (w + nGap);
	m_hTakePhoto = CreateButton(L"拍摄", x, y, w, h);
	if (m_hFinish == NULL)
	{
		Close();
		return false;
	}

	m_bCaptured = false;
	ShowWindow(m_hwnd, SW_SHOW);
	return true;
}

//==========================
// takeResource
//==========================
static CCameraWin *s_pCameraWin = NULL;
static int s_nCurID = 0;
extern HWND g_hMainWnd;
bool bTaking = false;
void takeResource( int mode )
{
	if (mode == TAKE_PICTURE) //cam
	{
		if (s_pCameraWin != NULL)
		{
			delete s_pCameraWin;
			s_pCameraWin = NULL;
		}
		s_pCameraWin = new CCameraWin;
		if (s_pCameraWin == NULL)
		{
			takeResource_callback("Create CCameraWin memory out", PICK_PICTURE, RESULT_ERROR);
			return;
		}
		if (!s_pCameraWin->Open(s_nCurID, g_hMainWnd))
		{
			takeResource_callback("Can't find cameras device", PICK_PICTURE, RESULT_ERROR);
			return;
		}

		s_nCurID++;
	}
	else if (mode == PICK_PICTURE) //photo
	{
		if (bTaking)
		{
			return;
		}
		bTaking = true;
		char szPathName[_MAX_PATH];
		std::string strDir = "";// CCUserDefault::sharedUserDefault()->getStringForKey("PickDir", "");

		OPENFILENAMEA ofn;
		memset(&ofn, 0, sizeof(ofn));
		ofn.lStructSize = sizeof(ofn);
		ofn.Flags = OFN_EXPLORER;
		szPathName[0] = 0;
		ofn.lpstrFile = szPathName;
		ofn.lpstrInitialDir = strDir.c_str();
		ofn.nMaxFile = sizeof(szPathName);
		ofn.lpstrFilter = "Image file (*.jpg; *.jpeg; *.png; *.bmp; *.tiff)\0*.jpg;*.jpeg;*.png;*.bmp;*.tiff;*.tif\0\0";
		if (!GetOpenFileNameA(&ofn))
		{
			takeResource_callback(szPathName, PICK_PICTURE, RESULT_CANCEL);
			bTaking = false;
			return;
		}

		takeResource_callback(szPathName, PICK_PICTURE, RESULT_OK);
		bTaking = false;
		//g_pTheApp->OnReturnBuf(RETURN_TYPE_PICKPICTURE, s_nCurID, 1, 0, strlen(szPathName) + 1, (char *)szPathName);

		char *s = szPathName + strlen(szPathName) - 1;
		while (s>szPathName && *s != '\\' && *s != '/') s--;
		if (*s == '\\' || *s == '/')
		{
			*s = 0;
			//CCUserDefault::sharedUserDefault()->setStringForKey("PickDir", szPathName);
		}
		s_nCurID++;
	}
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