#include "IDF.h"
#include "MD5.h"

MySpaceBegin

CIDFList::CIDFList()
{
	m_pBuf=NULL;
	m_lenBuf=0;
	m_lenBufAlloc=0;
}

CIDFList::~CIDFList()
{
	Free();
}

void CIDFList::Free()
{
	free(m_pBuf);
	m_pBuf=NULL;
	m_lenBuf=0;
	m_lenBufAlloc=0;

	m_listIDF.clear();
}

PIDFINFO CIDFList::FindIDF(uint16_t wID,char **ppData)
{
	if (m_pBuf==NULL || m_listIDF.empty()) return NULL;

	PIDFINFO pii;
	int i;
	for (i=0;i<(int)m_listIDF.size();i++)
	{
		pii=&m_listIDF.at(i);
		if (pii->wID==wID) break;
	}
	if (i>=(int)m_listIDF.size()) return NULL;
	if (ppData!=NULL) *ppData=m_pBuf+pii->nOffset;
	return pii;
}

bool CIDFList::DeleteIDF(uint16_t wID)
{
	for (int i=0;i<(int)m_listIDF.size();i++)
	{
		PIDFINFO pii=&m_listIDF.at(i);
		if (pii->wID==wID)
		{
			m_listIDF.erase(m_listIDF.begin()+i);
			return true;
		}
	}
	return false;
}

int CIDFList::GetIDFDataLen(PIDFINFO pii)
{
	int lenData=0;
	switch (pii->wDataType)
	{
	case FMT_BYTE:
	case FMT_SBYTE:
	case FMT_STRING:
	case FMT_UNDEFINED:
		lenData=pii->cnVar;
		break;
	case FMT_USHORT:
	case FMT_SSHORT:
		lenData=pii->cnVar*2;
		break;
	case FMT_ULONG:
	case FMT_SLONG:
	case FMT_SINGLE:
		lenData=pii->cnVar*4;
		break;
	case FMT_URATIONAL:
	case FMT_SRATIONAL:
	case FMT_DOUBLE:
		lenData=pii->cnVar*8;
		break;
	}
	return lenData;
}

bool CIDFList::AddIDF(PIDFINFO pii,const char *pData)
{
	CCLog("AddIDF: %d(%04x), %d, %d",(int)pii->wID,(int)pii->wID,(int)pii->wDataType,(int)pii->nOffset);
	DeleteIDF(pii->wID);

	int lenData=GetIDFDataLen(pii);
	if (lenData==0) return false;

	//缓冲区不足
	if (m_lenBuf+lenData>m_lenBufAlloc)
	{
		int lenNew=m_lenBuf+lenData+10240;
		char *pBuf=(char *)realloc(m_pBuf,lenNew);
		if (pBuf==NULL) return false;
		m_pBuf=pBuf;
		m_lenBufAlloc=lenNew;
	}
	memmove(m_pBuf+m_lenBuf,pData,lenData);
	pii->nOffset=m_lenBuf;
	m_lenBuf+=lenData;

	m_listIDF.push_back(*pii);
	return true;
}

bool CIDFList::AddIDF(uint16_t wID,uint16_t wDataType,int cnVar,const char *pData)
{
	IDFINFO ei;
	ei.wID=wID;
	ei.wDataType=wDataType;
	ei.cnVar=cnVar;
	return AddIDF(&ei,pData);
}

bool CIDFList::AddIDF(uint16_t wID,const char *pszStr)
{
	IDFINFO ei;
	ei.wID=wID;
	ei.wDataType=2;
	ei.cnVar=strlen(pszStr)+1;
	return AddIDF(&ei,pszStr);
}

int CIDFList::GetIDFTableLen()
{
	if (m_listIDF.empty()) return 0;

	int len=2+m_listIDF.size()*12+4;
	for (int i=0;i<(int)m_listIDF.size();i++)
	{
		PIDFINFO pii=&m_listIDF.at(i);
		int n=GetIDFDataLen(pii);
		if (n>4) len+=n;
	}
	return len;
}

void CIDFList::PutIDFTable(char *pTiffHeader,char *pIDF)
{
	if (m_listIDF.empty()) return;

	char *s=pIDF;
	//cnRecord
	*(uint16_t *)s=m_listIDF.size();
	s+=2;
	char *pData=s+m_listIDF.size()*12+4;
	for (int i=0;i<(int)m_listIDF.size();i++)
	{
		PIDFINFO pii=&m_listIDF.at(i);
		*(uint16_t *)s=pii->wID;
		s+=2;
		*(uint16_t *)s=pii->wDataType;
		s+=2;
		*(uint32_t *)s=pii->cnVar;
		s+=4;

		char *pDataSrc=m_pBuf+pii->nOffset;

		int len=GetIDFDataLen(pii);
		if (len<=4)
		{
			pii->nOffset=0;
			memmove(&pii->nOffset,pDataSrc,len);
		}
		else
		{
			pii->nOffset=pData-pTiffHeader;
			memmove(pData,pDataSrc,len);
			pData+=len;
		}
		*(uint32_t *)s=pii->nOffset;
		s+=4;
	}
	*(uint32_t *)s=0;
}

CIDF::CIDF()
{
	m_bModified=false;
}

CIDF::~CIDF()
{
	Free();
}

void CIDF::Free()
{
	m_listIDF.Free();
	m_listIDFExif.Free();
	m_listIDFGPS.Free();

	m_bModified=false;
}

uint16_t CIDF::XchgByteOrder(uint16_t w)
{
	return ((w & 0xff)<<8)+(w>>8);
}

uint32_t CIDF::XchgByteOrder(uint32_t dw)
{
	unsigned char *s=(unsigned char *)&dw;
	return (s[0]<<24) + (s[1]<<16) + (s[2]<<8) + s[3];
}

uint16_t CIDF::GetWord(uint16_t *pw)
{
	uint16_t w=*pw;
	if (m_bXchg) w=XchgByteOrder(w);
	return w;
}

void CIDF::PutWord(uint16_t *pw,uint16_t w)
{
	if (m_bXchg) w=XchgByteOrder(w);
	*pw=w;
}

uint32_t CIDF::GetDword(uint32_t *pdw)
{
	uint32_t dw=*pdw;
	if (m_bXchg) dw=XchgByteOrder(dw);
	return dw;
}

void CIDF::PutDword(uint32_t *pdw,uint32_t dw)
{
	if (m_bXchg) dw=XchgByteOrder(dw);
	*pdw=dw;
}

CIDFList *CIDF::GetIDFList(uint16_t wMainID)
{
	switch (wMainID)
	{
	case 0:
		return &m_listIDF;
	case IDF_NO_EXIF:
		return &m_listIDFExif;
	case IDF_NO_GPS:
		return &m_listIDFGPS;
	}
	return NULL;
}

bool CIDF::LoadIDFTable(uint16_t wMainID,int nOffset)
{
	//没有后续段了
	if (nOffset<2) return true;

	CIDFList *pList=GetIDFList(wMainID);
	if (pList==NULL) return true;

	unsigned char * s=(unsigned char *)m_pTiffHeader+nOffset;
	int cnRecord=GetWord((uint16_t *)s);
	s+=2;
	for (int i=0;i<cnRecord;i++)
	{
		IDFINFO ei;
		ei.wID=GetWord((uint16_t *)s);
		s+=2;
		ei.wDataType=GetWord((uint16_t *)s);
		s+=2;
		ei.cnVar=GetDword((uint32_t *)s);
		s+=4;
		ei.nOffset=*(int *)s;
		s+=4;
		if (ei.wID==IDF_NO_EXIF || ei.wID==IDF_NO_GPS)
		{
			ei.nOffset=GetDword((uint32_t *)&ei.nOffset);
			if (!LoadIDFTable(ei.wID,ei.nOffset)) return false;
			continue;
		}

		char *pData;
		int len=CIDFList::GetIDFDataLen(&ei);
		if (len<=4)
		{
			//数据就在nOffset
			pData=(char *)&ei.nOffset;
		}
		else
		{
			ei.nOffset=GetDword((uint32_t *)&ei.nOffset);
			pData=m_pTiffHeader+ei.nOffset;
		}
		if (m_bXchg)
		{
			char *ss=pData;
			int i;
			//转换数据
			switch (ei.wDataType)
			{
			case FMT_USHORT:
			case FMT_SSHORT:
				for (i=0;i<ei.cnVar;i++)
				{
					*(uint16_t *)ss=GetWord((uint16_t *)ss);
					ss+=2;
				}
				break;
			case FMT_ULONG:
			case FMT_SLONG:
			case FMT_SINGLE:
				for (i=0;i<ei.cnVar;i++)
				{
					*(uint32_t *)ss=GetDword((uint32_t *)ss);
					ss+=4;
				}
				break;
			case FMT_URATIONAL:
			case FMT_SRATIONAL:
			case FMT_DOUBLE:
				//每个变量需要转换两个uint32_t
				for (i=0;i<ei.cnVar;i++)
				{
					*(uint32_t *)ss=GetDword((uint32_t *)ss);
					ss+=4;
					//在小米3下有问题
					//*(uint32_t *)ss=GetDword((uint32_t *)ss);
					ss+=4;
				}
				break;
			}
		}
		pList->AddIDF(&ei,pData);
	}
	//下一个Entry的地点
	nOffset=GetDword((uint32_t *)s);
	return LoadIDFTable(wMainID,nOffset);
}

bool CIDF::LoadIDF(char *pBuf,int lenBuf)
{
	if (pBuf==NULL) return false;

	m_listIDF.Free();
	m_listIDFExif.Free();
	m_listIDFGPS.Free();

	unsigned char *s=(unsigned char *)pBuf+2;
	while (true)
	{
		if (*s!=0xff) return false;
		//没有找到APP段
		if ((s[1] & 0xe0)!=0xe0) return false;
		//长度，固定motorola格式
		m_bXchg=IsLittleEndian();
		uint16_t w=GetWord((uint16_t *)(s+2));
		if (s[1]!=0xe1)
		{
			//不是IDF段
			CCLog("not IDF segment: %d (%04x)",w,w);
			s+=2;
			s+=w;
			continue;
		}
		CCLog("IDF segment: %d (%04x), s: %02x,%02x,%02x,%02x,%02x,%02x,%02x,%02x",w,w,s[0],s[1],s[2],s[3],s[4],s[5],s[6],s[7]);

		m_pIDFHeader=(char *)s;
		m_lenIDF=w;

		//IDF段
		unsigned char *ss=s+4;
		if (strcmp((char *)ss,"Exif")!=0) return false;
		ss+=6;
		m_pTiffHeader=(char *)ss;
		m_bXchg=(*ss!='I');
		if (!IsLittleEndian()) m_bXchg=!m_bXchg;
		ss+=2;
		if (GetWord((uint16_t *)ss)!=0x2a) return false;
		ss+=2;

		int nOffset=GetDword((uint32_t *)ss);
		if (!LoadIDFTable(0,nOffset)) return false;
		break;
	}
	return true;
}

PIDFINFO CIDF::FindIDF(uint16_t wMainID,uint16_t wID,char **ppData)
{
	CIDFList *pList=GetIDFList(wMainID);
	if (pList==NULL) return NULL;

	return pList->FindIDF(wID,ppData);
}

bool CIDF::AddIDF(uint16_t wMainID,uint16_t wID,uint16_t wDataType,int cnVar,const char *pData)
{
	if (m_listIDF.GetCount()==0) return false;

	CIDFList *pList=GetIDFList(wMainID);
	if (pList==NULL) return false;

	if (!pList->AddIDF(wID,wDataType,cnVar,pData)) return false;

	m_bModified=true;
	return true;
}

void CIDF::DoubleToDMS(double d,int &nDegree,int &nMinute,int &nSecond100)
{
	nDegree=(int)d;
	d-=nDegree;
	d=d*60;
	nMinute=(int)d;
	d-=nMinute;
	d=d*60;
	nSecond100=(int)(d*100);
}

bool CIDF::AddGPSInfo(double dLatitude,double dLongitude,double nAltitude)
{
	int nDegree;
	int nMinute;
	int nSecond100;

	bool bNorth=true;
	if (dLatitude<0)
	{
		bNorth=false;
		dLatitude=-dLatitude;
	}
	bool bEast=true;
	if (dLongitude<0)
	{
		bEast=false;
		dLongitude=-dLongitude;
	}

	int an[6];
	char szStr[12];

	DoubleToDMS(dLatitude,nDegree,nMinute,nSecond100);
	an[0]=nDegree;
	an[1]=1;
	an[2]=nMinute;
	an[3]=1;
	an[4]=nSecond100;
	an[5]=100;
	szStr[0]=bNorth ? 'N' : 'S';
	szStr[1]=0;
	AddIDF(IDF_NO_GPS,1,2,2,szStr);
	AddIDF(IDF_NO_GPS,2,5,3,(char *)an);

	DoubleToDMS(dLongitude,nDegree,nMinute,nSecond100);
	an[0]=nDegree;
	an[1]=1;
	an[2]=nMinute;
	an[3]=1;
	an[4]=nSecond100;
	an[5]=100;
	szStr[0]=bEast ? 'E' : 'W';
	AddIDF(IDF_NO_GPS,3,2,2,szStr);
	AddIDF(IDF_NO_GPS,4,5,3,(char *)an);

	an[0]=(int)(nAltitude*100);
	an[1]=100;
	AddIDF(IDF_NO_GPS,6,5,1,(char *)an);

	return true;
}
/*
bool CIDF::SaveFile()
{
	if (!m_bModified) return false;

	char szTmp[_MAX_PATH];
	strcpy(szTmp,m_szPathName);
	gpExtractFilePath(szTmp);
	strcat(szTmp,"\\WithGPS");
	mkdir(szTmp);
	char szNewPathName[_MAX_PATH];
	strcpy(szNewPathName,szTmp);
	strcat(szNewPathName,"\\");
	strcpy(szTmp,m_szPathName);
	strcat(szNewPathName,gpExtractFileName(szTmp));

	FILE *fp=fopen(szNewPathName,"wb");
	if (fp==NULL) return false;

	//写入段之前的数据，包括
	fwrite(m_pBuf,1,m_pIDFHeader-m_pBuf,fp);

	uint32_t dw=0;
	if (m_listIDFExif.GetCount())
	{
		m_listIDF.AddIDF(IDF_NO_EXIF,FMT_ULONG,1,(char *)&dw);
	}
	if (m_listIDFGPS.GetCount())
	{
		m_listIDF.AddIDF(IDF_NO_GPS,FMT_ULONG,1,(char *)&dw);
	}

	int len=m_listIDF.GetIDFTableLen();
	int lenExif=m_listIDFExif.GetIDFTableLen();
	int lenGPS=m_listIDFGPS.GetIDFTableLen();

	//修改两个附加表起始地址
	if (m_listIDFExif.GetCount())
	{
		dw=2+2+4+len;
		m_listIDF.AddIDF(IDF_NO_EXIF,FMT_ULONG,1,(char *)&dw);
	}
	if (m_listIDFGPS.GetCount())
	{
		dw=2+2+4+len+lenExif;
		m_listIDF.AddIDF(IDF_NO_GPS,FMT_ULONG,1,(char *)&dw);
	}

	//不需要
	//0xff,0xe1		2
	//lenSegment	2		包括自己，永远mororola顺序
	//IDF,0,0		6
	//II (or MM)	2
	//0x2a			2
	//nOffset		4
	//cnRecord		2
	//EntryIndex	cnRecord*12
	//0000			4
	//Entry Value

	int lenSegment=2+2+6+2+2+4+len+lenExif+lenGPS;
	char *pBuf=(char *)malloc(lenSegment);
	if (pBuf==NULL) return false;

	char *s=pBuf;
	*s++=(char)0xff;
	*s++=(char)0xe1;
	{
		uint16_t w=lenSegment-2;
		w=XchgByteOrder(w);
		*(uint16_t *)s=w;
	}
	s+=2;
	*s++='E';
	*s++='x';
	*s++='i';
	*s++='f';
	*s++=0;
	*s++=0;
	char *pTiffHeader=s;
	//新的永远是Intel顺序
	*s++='I';
	*s++='I';
	*(uint16_t *)s=0x2a;
	s+=2;
	*(uint32_t *)s=8;
	s+=4;

	m_listIDF.PutIDFTable(pTiffHeader,s);
	s+=len;
	m_listIDFExif.PutIDFTable(pTiffHeader,s);
	s+=lenExif;
	m_listIDFGPS.PutIDFTable(pTiffHeader,s);
	s+=lenGPS;
	fwrite(pBuf,1,lenSegment,fp);
	fwrite(m_pIDFHeader+2+m_lenIDF,1,m_lenBuf-(m_pIDFHeader+2+m_lenIDF-m_pBuf),fp);
	fclose(fp);
	return true;
}
*/
MySpaceEnd