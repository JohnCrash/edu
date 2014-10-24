#include "Platform.h"
#include "cocos2d.h"

#ifdef __cplusplus
extern "C" {
#endif
#include "amrnb/typedef.h"
#include "amrnb/interf_enc.h"
#include "amrnb/interf_dec.h"
#ifdef __cplusplus
}
#endif

#define AMR_MAGIC_NUMBER "#!AMR\n"
static CVoiceRecord *s_pVoiceRecord=NULL;

static void releaseTmpFile( std::string file )
{
}
static std::string allocTmpFile( std::string suffix )
{
	return suffix;
}
static char *ReadDataFile(const char * filename,uint32_t *plen)
{
	return NULL;
}
static bool IsValidParam(int cnChannel,int nRate,int cnBitPerSample)
{
	static int s_nValidRateList[]={11025,12000,8000,22050,44100,48000,32000,0};

	if (cnChannel!=1 && cnChannel!=2) return false;
	if (cnBitPerSample!=16) return false;

	for (int i=0;;i++)
	{
		if (s_nValidRateList[i]==0) return false;
		if (s_nValidRateList[i]==nRate) break;
	}
	return true;
}

static int GetModeIndex(int nMode)
{
	static const short modeConv[]={475, 515, 59, 67, 74, 795, 102, 122, 0};
	for (int i=0;;i++)
	{
		if (modeConv[i]==0) return -1;
		if (modeConv[i]==nMode) return i;
	}
}

static int ConvertToMono8000(char *pBuf,int len,int cnChannel,int nRate)
{
	if (cnChannel==1 && nRate==8000) return len;

	//总的采样数
	int cnBytePerSample=cnChannel*16/8;
	int cnTotalSample=len/cnBytePerSample;

	//统统转换为单声道，8K采样
	short int *pSrc=(short int *)pBuf;
	short int *pDst=(short int *)pBuf;
	int d=0;
	int s=0;
	int cnSample=0;
	int cnNewTotalSample=0;
	for (int i=0;i<cnTotalSample;i++)
	{
		if (cnChannel==1) s+=*pSrc++;
		else
		{
			s=pSrc[0];
			pSrc+=2;
		}
		cnSample++;
		d+=8000;
		if (d>=nRate)
		{
			*pDst++=s;
			s=0;
			cnSample=0;
			d-=nRate;
			cnNewTotalSample++;
		}
	}
	nRate=8000;
	cnChannel=1;
	len=cnNewTotalSample*2;
	return len;
}

//	mode	MR475, MR515, MR59, MR67, MR74, MR795, MR102, MR122
bool AMREncoder(int cnChannel,int nRate,int cnBitPerSample,char *pBuf,int len,const char *pszPathName,int nMode)
{
	nMode=GetModeIndex(nMode);
	if (nMode<0) return false;
	if (!IsValidParam(cnChannel,nRate,cnBitPerSample)) return false;

	len=ConvertToMono8000(pBuf,len,cnChannel,nRate);

	FILE *fp=fopen(pszPathName,"wb");
	if (fp==NULL) return false;

	void *pInterface=Encoder_Interface_init(0);

	/* write magic number to indicate single channel AMR file storage format */
	fwrite(AMR_MAGIC_NUMBER,sizeof(char),strlen(AMR_MAGIC_NUMBER),fp);

	char *pDst=pBuf;
	char *pSrc=pBuf;
	int lenDst=0;
	while (len>=160*2)
	{
		int cnByte=Encoder_Interface_Encode(pInterface,(Mode)nMode,(short *)pSrc,(unsigned char *)pDst,0);

		pSrc+=160*2;
		len-=160*2;

		pDst+=cnByte;
		lenDst+=cnByte;
	}
	Encoder_Interface_exit(pInterface);
	fwrite(pBuf,sizeof(char),lenDst,fp);
	fclose(fp);
	return true;
}

static char *WavDecoder(char *pBuf,int &len)
{
	int lenBuf=len;
	len=0;
	char *s=pBuf;

	if (lenBuf<0x2c)
	{
		free(pBuf);
		return NULL;
	}

	//magic
	if (memcmp(s,"RIFF",4)!=0)
	{
		free(pBuf);
		return NULL;
	}
	if (memcmp(s+8,"WAVEfmt",7)!=0)
	{
		free(pBuf);
		return NULL;
	}

	if (*(int *)(s+0x10)!=0x10)
	{
		free(pBuf);
		return NULL;
	}
	if (*(short *)(s+0x14)>1)
	{
		free(pBuf);
		return NULL;
	}
	int cnChannel=*(short *)(s+0x16);
	if (cnChannel!=1 && cnChannel!=2)
	{
		free(pBuf);
		return NULL;
	}
	int nFreq=*(int *)(s+0x18);
	int lenData=*(int *)(s+0x28);
	if (0x2c+lenData>lenBuf)
	{
		free(pBuf);
		return NULL;
	}
	memmove(pBuf,pBuf+0x2c,lenData);
	len=ConvertToMono8000(pBuf,lenData,cnChannel,nFreq);
	return pBuf;
}

char *AMRDecoder(const char *pszPathName,int &len)
{
	len=0;
	int lenAlloc=0;
	char *pBuf=NULL;

	CCLOG("AMRDecoder: %s",pszPathName);

	uint32_t lenSrc;
	char *pSrcBuf=ReadDataFile(pszPathName,&lenSrc);
	if (pSrcBuf==NULL) return NULL;
	char *pSrc=pSrcBuf;
	int lenHeader=strlen(AMR_MAGIC_NUMBER);
	if (memcmp(pSrc,AMR_MAGIC_NUMBER,lenHeader)!=0)
	{
		len=lenSrc;
		return WavDecoder(pSrcBuf,len);
	}
	pSrc+=lenHeader;
	lenSrc-=lenHeader;

	void *pInterface=Decoder_Interface_init();

	short int anOutBlock[160];
	static short block_size[16]={ 12, 13, 15, 17, 19, 20, 26, 31, 5, 0, 0, 0, 0, 0, 0, 0 };
	while ((int)lenSrc>1)
	{
		int nMode=((*pSrc>>3) & 0xf);
		int lenBlock=block_size[nMode];
		if (lenBlock>(int)lenSrc) break;
	
		Decoder_Interface_Decode(pInterface,(unsigned char *)pSrc,anOutBlock,0);
		pSrc+=lenBlock+1;
		lenSrc-=lenBlock+1;
		if (lenAlloc-len<sizeof(anOutBlock))
		{
			char *pTmp=(char *)realloc(pBuf,lenAlloc+100*1024);
			if (pTmp==NULL)
			{
				free(pBuf);
				free(pSrcBuf);
				return NULL;
			}
			pBuf=pTmp;
			lenAlloc=lenAlloc+100*1024;
		}
		memmove(pBuf+len,anOutBlock,sizeof(anOutBlock));
		len+=sizeof(anOutBlock);
	}
	Decoder_Interface_exit(pInterface);
	free(pSrcBuf);
	return pBuf;
}

CDynaAMREncoder::CDynaAMREncoder()
{
	m_bRunning=false;
	m_bStoping=false;

	m_pInterfaceEncoder=NULL;
	m_fpEncoder=NULL;

	m_nCurVolume=0;
	m_cnEncoderedSample=0;

	m_pBuf=NULL;
	m_lenBuf=0;
	m_lenBufAlloc=0;
}

CDynaAMREncoder::~CDynaAMREncoder()
{
	CloseEncoder();
	if (m_pBuf!=NULL) free(m_pBuf);
	if (!m_strTmpFile.empty()) 
	{
		//g_pTheApp->ReleaseTmpFile(m_strTmpFile.c_str());
		releaseTmpFile(m_strTmpFile);
	}
}

static void *_EncoderThreadFunc(void *pParam)
{
	CDynaAMREncoder *p=(CDynaAMREncoder *)pParam;
	p->ThreadFunc();
	return NULL;
}

void CDynaAMREncoder::ThreadFunc()
{
	m_nPos=0;

	short anEncoderList[160];
	unsigned char szCoderBuf[64];
	int lenBlock=sizeof(anEncoderList);

	while (!m_bStoping)
	{
		Lock();
		if (m_lenBuf-m_nPos<lenBlock)
		{
			//没有足够数据
			Unlock();
			Sleep(10);
			continue;
		}
		//压缩一个块
		memmove(anEncoderList,m_pBuf+m_nPos,lenBlock);
		m_nPos+=lenBlock;
		if (m_lenBuf-m_nPos<lenBlock)
		{
			//末尾数据很少了，重新调整指针位置，避免缓冲区无限制扩张
			memmove(m_pBuf,m_pBuf+m_nPos,m_lenBuf-m_nPos);
			m_lenBuf-=m_nPos;
			m_nPos=0;
		}
		Unlock();

		//需要做字节顺序检测
		//fwrite(anEncoderList,sizeof(unsigned char),sizeof(anEncoderList),m_fpEncoder);
		int cnByte=Encoder_Interface_Encode(m_pInterfaceEncoder,(Mode)m_nMode,anEncoderList,szCoderBuf,0);
		fwrite(szCoderBuf,sizeof(unsigned char),cnByte,m_fpEncoder);
		m_cnEncoderedSample+=160;
	}
	//已经没有在压缩了
	m_bRunning=false;
}

//初始化
bool CDynaAMREncoder::InitEncoder(int cnChannel,int nRate,int cnBitPerSample,int nMode)
{
	//检查参数是否正确
	if (!IsValidParam(cnChannel,nRate,cnBitPerSample)) return false;

	//压缩率选择
	m_nMode=GetModeIndex(nMode);
	if (m_nMode<0) return false;

	m_cnChannel=cnChannel;
	m_nRate=nRate;
	//已压缩的帧数
	m_cnEncoderedSample=0;

	m_nCurVolume=0;
	m_nVolumeSum=0;
	m_cnVolumeValue=0;

	if (!CloseEncoder()) return false;

	if (m_strTmpFile.empty())
	{
		//char szPathName[256];
		//g_pTheApp->AllocTmpFile(szPathName,".amr");
		m_strTmpFile = allocTmpFile(".amr");
		//m_strTmpFile=szPathName;
	}
	m_pInterfaceEncoder=Encoder_Interface_init(0);
	m_fpEncoder=fopen(m_strTmpFile.c_str(),"wb");
	if (m_fpEncoder==NULL) return false;

	//文件头
	fwrite(AMR_MAGIC_NUMBER, sizeof(char),strlen(AMR_MAGIC_NUMBER),m_fpEncoder);
	m_lenBuf=0;
	m_bStoping=false;
	m_bRunning=true;
/*
	{
		uint32_t len;
		std::string strTest=g_pTheApp->GetAppTmpDir()+"tmp1.pcm";
		char *pBuf=ReadDataFile(strTest.c_str(),&len);
		CCLOG("tmp1.pcm: %d",len);
		if (pBuf)
		{
			AddEncoderBuf(pBuf,len);
			free(pBuf);
		}
	}
*/
	//启动压缩线程
	m_pThread = new std::thread(_EncoderThreadFunc,this);
	//if (!NewThread(_EncoderThreadFunc,this))
	if( m_pThread )
	{
		m_bRunning=false;
		return false;
	}
	return true;
}

//增加原始数据，nRate不为0，表示实际nRate值
bool CDynaAMREncoder::AddEncoderBuf(char *pBuf,int len,int nRate)
{
	if (!m_bRunning) return false;

	if (nRate!=0) m_nRate=nRate;

	Lock();
	if (m_lenBufAlloc-m_lenBuf<len)
	{
		//缓冲区不足，一次申请10倍
		int lenNeed=m_lenBufAlloc+len*10;
		char *pTmp=(char *)realloc(m_pBuf,lenNeed);
		if (pTmp==NULL)
		{
			//Unlock();
			return false;
		}
		m_pBuf=pTmp;
		m_lenBufAlloc=lenNeed;
	}
	char *s=m_pBuf+m_lenBuf;
	memmove(s,pBuf,len);
	//保护原数据，转换为单声道8000HZ
	len=ConvertToMono8000(s,len,m_cnChannel,m_nRate);

	//计算当前音量
	for (int i=0;i<len/2;i++)
	{
		int nThis=*(short int *)(s+i*2);
		m_nVolumeSum+=abs(nThis);
		m_cnVolumeValue++;
	}
	//200ms计算一次
	if (m_cnVolumeValue*1000/8000>=200)
	{
		m_nCurVolume=m_nVolumeSum/m_cnVolumeValue;
		m_cnVolumeValue=0;
		m_nVolumeSum=0;
	}

	m_lenBuf+=len;
	Unlock();
	return true;
}

bool CDynaAMREncoder::CloseEncoder()
{
	//如果线程还在运行，需要先停止它
	m_bStoping=true;
	while (m_bRunning) Sleep(10);
	m_bStoping=false;

	if (m_pInterfaceEncoder!=NULL)
	{
		Encoder_Interface_exit(m_pInterfaceEncoder);
		m_pInterfaceEncoder=NULL;
	}
	if (m_fpEncoder!=NULL)
	{
		fclose(m_fpEncoder);
		m_fpEncoder=NULL;
	}
	return true;
}

CVoiceRecordBase::CVoiceRecordBase()
{
	m_pEncoder=NULL;
	//压缩率选择
	//m_nMode=795;
	m_nMode=122;
	//static const short modeConv[]={475, 515, 59, 67, 74, 795, 102, 122, 0};
}

CVoiceRecordBase::~CVoiceRecordBase()
{
	Close();
	if (m_pEncoder!=NULL) delete m_pEncoder;
}

bool CVoiceRecordBase::Init()
{
	return true;
}

bool CVoiceRecordBase::Close()
{
	if (m_pEncoder && !m_pEncoder->CloseEncoder()) return false;
	return true;
}

bool CVoiceRecordBase::StartRecord(int cnChannel,int nRate,int cnBitPerSample)
{
	if (!Close()) return false;
	if (!IsValidParam(cnChannel,nRate,cnBitPerSample)) return false;

	if (m_pEncoder==NULL)
	{
		m_pEncoder=new CDynaAMREncoder;
		if (m_pEncoder==NULL) return false;
	}
	if (!m_pEncoder->CloseEncoder() || !m_pEncoder->InitEncoder(cnChannel,nRate,cnBitPerSample,m_nMode))
	{
		delete m_pEncoder;
		m_pEncoder=NULL;
		return false;
	}
	return true;
}

bool CVoiceRecordBase::StopRecord(char *pszSaveFile)
{
	if (pszSaveFile!=NULL) *pszSaveFile=0;
	Close();
	if (pszSaveFile!=NULL && m_pEncoder) strcpy(pszSaveFile,m_pEncoder->GetEncoderedPathName());
	return true;
}

bool CVoiceRecordBase::GetRecordInfo(float &fDuration,int &nCurVolume)
{
	nCurVolume=0;
	fDuration=0;
	//没有运行
	if (m_pEncoder==NULL) return false;

	nCurVolume=m_pEncoder->GetCurVolume();
	fDuration=((float)m_pEncoder->GetEncoderedSampleCount())/8000;
	return true;
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