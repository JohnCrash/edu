#include "RenderTextureEx.h"
#include "errno.h"
#include "IDF.h"
#include "Files.h"

MySpaceBegin
#define min(a,b) a>b?b:a

static void StrToLower(std::string & str)
{
	for (unsigned int i = 0; i < str.length(); ++i)
	{
		str[i] = tolower(str[i]);
	}
}

CImageEx::CImageEx()
{
	m_nJpgOrientation=IMAGE_ORIENTATION_UP;
}

Image::Format CImageEx::GetImageFormat(const char *pszPathName)
{
	Image::Format ret = Image::Format::UNKOWN;

	std::string str=pszPathName;
	StrToLower(str);

	if ((std::string::npos != str.find(".jpg"))) ret = Image::Format::JPG;
	else if ((std::string::npos != str.find(".png"))) ret = Image::Format::PNG;
	else if ((std::string::npos != str.find(".tiff"))) ret = Image::Format::TIFF;

	return ret;
}

Image::Format CImageEx::GetImageFormat(const char *pBuf,int lenBuf)
{
	//png
	unsigned char *pHead=(unsigned char*)pBuf;
	if (lenBuf > 8)
	{
		if (pHead[0] == 0x89
			&& pHead[1] == 0x50
			&& pHead[2] == 0x4E
			&& pHead[3] == 0x47
			&& pHead[4] == 0x0D
			&& pHead[5] == 0x0A
			&& pHead[6] == 0x1A
			&& pHead[7] == 0x0A)
		{
			return Image::Format::PNG;
		}
	}

	// if it is a tiff file buffer.
	if (lenBuf > 2)
	{
		if ((pHead[0] == 0x49 && pHead[1] == 0x49) || (pHead[0] == 0x4d && pHead[1] == 0x4d))
		{
			return Image::Format::TIFF;
		}
	}

	// if it is a jpeg file buffer.
	if (lenBuf > 2)
	{
		if (pHead[0] == 0xff && pHead[1] == 0xd8)
		{
			return Image::Format::JPG;
		}
	}
	return Image::Format::UNKOWN;
}

bool CImageEx::LoadFromFile(const char *pszPathName)
{
	CCLOG("LoadFromFile: %s\n",pszPathName);

	int lenBuf;
	char *pBuf=ReadDataFile(pszPathName,(uint32_t *)&lenBuf);
	if (pBuf==NULL) return false;

	if (!initWithImageData((const unsigned char *)pBuf,lenBuf))
	{
		CCLOG("LoadFromFile: %s fail\n",pszPathName);
		return false;
	}

	Image::Format fmt=GetImageFormat(pBuf,lenBuf);
	CCLOG("LoadFromFile: %d x %d, fmt: %d\n",_width,_height,fmt);
	if (fmt!=Image::Format::JPG) return true;

	//jpg文件，需要根据exif信息，旋转图片
	CIDF idf;
	if (!idf.LoadIDF(pBuf,lenBuf))
	{
		CCLOG("%s, fmt: %d, no IDF",pszPathName,fmt);
		free(pBuf);
		return true;
	}
	CCLOG("%s IDF found",pszPathName);

	uint16_t *pData;
	PIDFINFO pii=idf.FindIDF(0,0x0112,(char **)&pData);
	if (pii!=NULL)
	{
		m_nJpgOrientation=*pData;
	}
	free(pBuf);

	return true;
}

bool CImageEx::InitImageData(int nWidth,int nHeight)
{
	if (nWidth<=0 || nHeight<=0) return false;

	int nBytesPerComponent=4;
	int nSize=nHeight * nWidth * nBytesPerComponent;
	unsigned char *pData=new unsigned char[nSize];
	if (pData==NULL) return false;

	CC_SAFE_DELETE_ARRAY(_data);
	_data=pData;

	//初始化
	memset(_data,0,nSize);

	//m_nBitsPerComponent=8; cocos2d 2.2
	_height=(short)nHeight;
	_width=(short)nWidth;
	//m_bHasAlpha=true; 2.2
	_preMulti=false;

	return true;
}

bool CImageEx::SaveToFileInTextMode(const char *pszPathName,int cnBytesPerBit)
{
	if (cnBytesPerBit!=3 && cnBytesPerBit!=4)
	{
		CCLOG("only support RGB888 or RGBA8888 format");
		return false;
	}
	if (_data==NULL)
	{
		CCLOG("load image first");
		return false;
	}

	std::string str=CCFileUtils::sharedFileUtils()->getWritablePath()+pszPathName;
	StrToLower(str);

	FILE *fp=fopen(str.c_str(),"wt");
	if (fp==NULL)
	{
		CCLOG("can not create file: %s",str.c_str());
		return false;
	}

	int cnPixel=0;
	for (int i=0;i<_height;i++)
	{
		GLubyte *pBuf=_data+(_height-i-1)*_width*cnBytesPerBit;
		for (int j=0;j<_width;j++)
		{
			GLubyte b1,b2,b3,b4;
			b1=pBuf[0];
			b2=pBuf[1];
			b3=pBuf[2];
			if (cnBytesPerBit==4) b4=pBuf[4];
			else b4=255;

			if (b1<=0x40 && b2<=0x40 && b3<=0x40)
			{
				b1=0;
				b2=0;
				b3=0;
				b4=0;
			}

			fprintf(fp,"0x%02x,0x%02x,0x%02x,0x%02x, ",b1,b2,b3,b4);
			pBuf+=cnBytesPerBit;
			cnPixel++;
			if (cnPixel>=5)
			{
				cnPixel=0;
				fprintf(fp,"\xd\xa");
			}
		}
	}
	fprintf(fp,"\xd\xa");
	fclose(fp);
	return true;
}

char *CImageEx::SaveToMem(int &len)
{
	std::string str = allocTmpFile(".png");// g_pTheApp->GetAppDataDir();
	
	if (!saveToFile(str.c_str(),false)) return NULL;

	return ReadDataFile(str.c_str(),(uint32_t *)&len);
}

bool CImageEx::GetData(PINTRECT prc,unsigned char *pBuf)
{
	if (prc->left<0 || prc->top<0 || prc->right<prc->left || prc->bottom<prc->top || prc->right>_width || prc->bottom>_height)
	{
		return false;
	}
	INTRECT rc;
	rc.left=prc->left;
	rc.right=prc->right;
	rc.top=_height-prc->bottom;
	rc.bottom=_height-prc->top;

	int w=rc.right-rc.left;
	int h=rc.bottom-rc.top;
	unsigned char *p2=pBuf+(h-1)*w*4;
//	unsigned char *p2=pBuf;
	for (int i=rc.top;i<rc.bottom;i++)
	{
		unsigned char *p1=_data+i*_width*4+rc.left*4;
		memmove(p2,p1,w*4);
		p2-=w*4;
	}
	return true;
}

unsigned char *CImageEx::GetData(PINTRECT prc)
{
	if (prc->left<0 || prc->top<0 || prc->right<prc->left || prc->bottom<prc->top || prc->right>_width || prc->bottom>_height)
	{
		return NULL;
	}

	int w=prc->right-prc->left;
	int h=prc->bottom-prc->top;
	int nSize=w*h*4;
	unsigned char *pData=new unsigned char[nSize];
	if (pData==NULL) return NULL;

	if (GetData(prc,pData)) return pData;

	delete[] pData;
	return NULL;

}

bool CImageEx::SetData(PINTRECT prc,unsigned char *pBuf)
{
	if (prc->left<0 || prc->top<0 || prc->right<prc->left || prc->bottom<prc->top || prc->right>_width || prc->bottom>_height)
	{
		return false;
	}
	INTRECT rc;
	rc.left=prc->left;
	rc.right=prc->right;
	rc.top=_height-prc->bottom;
	rc.bottom=_height-prc->top;

	int w=rc.right-rc.left;
	int h=rc.bottom-rc.top;
	unsigned char *p2=pBuf+(h-1)*w*4;
//	unsigned char *p2=pBuf;
	for (int i=rc.top;i<rc.bottom;i++)
	{
		unsigned char *p1=_data+i*_width*4+rc.left*4;
		memmove(p1,p2,w*4);
		p2-=w*4;
	}
	return true;
}

Sprite *CImageEx::GetReduceSprite(int nMaxLineLength,int nOrientation)
{
	int nWidth;
	int nHeight;
	char *pDst=ReduceRawBuf((char *)_data,_width,_height,nWidth,nHeight,nMaxLineLength,true);
	if (pDst==NULL) return NULL;

	int nAngle=0;
	bool bMirror=false;
	switch (nOrientation)
	{
	case IMAGE_ORIENTATION_LEFT:
		nAngle=90;
		bMirror=false;
		break;
	case IMAGE_ORIENTATION_RIGHT:
		nAngle=270;
		bMirror=false;
		break;
	case IMAGE_ORIENTATION_DOWN:
		nAngle=180;
		bMirror=false;
		break;
	case IMAGE_ORIENTATION_MIRROR_UP:
		nAngle=0;
		bMirror=true;
		break;
	case IMAGE_ORIENTATION_MIRROR_LEFT:
		nAngle=90;
		bMirror=true;
		break;
	case IMAGE_ORIENTATION_MIRROR_RIGHT:
		nAngle=270;
		bMirror=true;
		break;
	case IMAGE_ORIENTATION_MIRROR_DOWN:
		nAngle=1800;
		bMirror=true;
		break;
	case IMAGE_ORIENTATION_UP:
	default:
		break;
	}
	if (nAngle!=0 || bMirror)
	{
	    char *pNewBuf=AdjustRawBufOrientation((char *)pDst,&nWidth,&nHeight,nAngle,bMirror);
		if (pNewBuf!=NULL)
		{
			free(pDst);
			pDst=pNewBuf;
		}
	}
	Sprite *pSprite=SpriteFromRaw(pDst,nWidth,nHeight);
	free(pDst);
	return pSprite;
}

//
bool CImageEx::ReduceAndSaveToFile(std::string filename, int nMaxLineLength, int nOrientation)
{
	int nWidth;
	int nHeight;
	if (_width < nMaxLineLength && _height < nMaxLineLength)
	{
		mTmpFile = filename;
		return true; //不需要调整
	}
	char *pDst = ReduceRawBuf((char *)_data, _width, _height, nWidth, nHeight, nMaxLineLength, false);
	if (pDst == NULL)
	{
		CCLOG("CImageEx::ReduceAndSaveToFile ReduceRawBuf return NULL");
		return false;
	}

	int nAngle = 0;
	bool bMirror = false;
	switch (nOrientation)
	{
	case IMAGE_ORIENTATION_LEFT:
		nAngle = 90;
		bMirror = false;
		break;
	case IMAGE_ORIENTATION_RIGHT:
		nAngle = 270;
		bMirror = false;
		break;
	case IMAGE_ORIENTATION_DOWN:
		nAngle = 180;
		bMirror = false;
		break;
	case IMAGE_ORIENTATION_MIRROR_UP:
		nAngle = 0;
		bMirror = true;
		break;
	case IMAGE_ORIENTATION_MIRROR_LEFT:
		nAngle = 90;
		bMirror = true;
		break;
	case IMAGE_ORIENTATION_MIRROR_RIGHT:
		nAngle = 270;
		bMirror = true;
		break;
	case IMAGE_ORIENTATION_MIRROR_DOWN:
		nAngle = 1800;
		bMirror = true;
		break;
	case IMAGE_ORIENTATION_UP:
	default:
		break;
	}
	if (nAngle != 0 || bMirror)
	{
		char *pNewBuf = AdjustRawBufOrientation((char *)pDst, &nWidth, &nHeight, nAngle, bMirror);
		if (pNewBuf != NULL)
		{
			free(pDst);
			pDst = pNewBuf;
		}
	}
	int len = nWidth*nHeight*4;
	//Sprite *pSprite = SpriteFromRaw(pDst, nWidth, nHeight);
	Image *pimg = new Image();
	if (pimg)
	{
		pimg->initWithRawData((unsigned char *)pDst, len, nWidth, nHeight, 8);
		mTmpFile = allocTmpFile(".jpg");
		pimg->saveToFile(mTmpFile);
		pimg->release();
	}
	else
	{
		CCLOG("CImageEx::ReduceAndSaveToFile new Image return 0");
		free(pDst);
		return false;
	}
	free(pDst);
	return true;
}

CRenderTextureEx::CRenderTextureEx(void)
{
	m_bSetAlias=true;
}

CRenderTextureEx::~CRenderTextureEx(void)
{
}

GLubyte *CRenderTextureEx::GetSubData(Rect &rcSub,int wDst,int hDst,float fEnhanceRate,bool bFlip)
{
	Size size=rcSub.size;
	int wSrc=(int)size.width;
	int hSrc=(int)size.height;
	//只处理缩小的情况
	if (wSrc<wDst || hSrc<hDst) return NULL;
	bool bDup=false;
	if (wSrc==wDst && hSrc==hDst) bDup=true;

	GLubyte *pBufSrc=(GLubyte *)malloc(wSrc*hSrc*4);
	if (pBufSrc==NULL) return NULL;
	//由于第一遍先压缩的是宽度，所有高度要保留原尺寸
	GLubyte *pBufDst=(GLubyte *)malloc(wDst*hDst*4);
	if (pBufDst==NULL)
	{
		free(pBufSrc);
		return NULL;
	}

	begin();
	glPixelStorei(GL_PACK_ALIGNMENT,1);
	glReadPixels(rcSub.origin.x,rcSub.origin.y,wSrc,hSrc,GL_RGBA,GL_UNSIGNED_BYTE,pBufSrc);
	end();

	if (!bDup)
	{
		//处理压缩的事情，和求平均值
		GLubyte *p1=pBufSrc;
		GLubyte *p2=pBufSrc;
		unsigned int b[4];
		for (int i=0;i<hSrc;i++)
		{
			int v=0;
			int cnDot=0;
			b[0]=0;
			b[1]=0;
			b[2]=0;
			b[3]=0;

			for (int j=0;j<wSrc;j++)
			{
				b[0]+=p1[0];
				b[1]+=p1[1];
				b[2]+=p1[2];
				b[3]+=p1[3];
				p1+=4;

				v+=wDst;
				cnDot++;
				if (v>=wSrc)
				{
					p2[0]=b[0]/cnDot;
					p2[1]=b[1]/cnDot;
					p2[2]=b[2]/cnDot;
					p2[3]=b[3]/cnDot;
					p2+=4;

					v-=wSrc;
					cnDot=0;
					b[0]=0;
					b[1]=0;
					b[2]=0;
					b[3]=0;
				}
			}
		}
		for (int i=0;i<wDst;i++)
		{
			int v=0;
			int cnDot=0;
			b[0]=0;
			b[1]=0;
			b[2]=0;
			b[3]=0;

			p1=pBufSrc+i*4;
			if (bFlip) p2=pBufDst+(wDst*(hDst-1)*4)+i*4;
			else p2=pBufDst+i*4;
			for (int j=0;j<hSrc;j++)
			{
				b[0]+=p1[0];
				b[1]+=p1[1];
				b[2]+=p1[2];
				b[3]+=p1[3];
				p1+=wDst*4;

				v+=hDst;
				cnDot++;
				if (v>=hSrc)
				{
					if (fEnhanceRate==1.0f)
					{
						p2[0]=b[0]/cnDot;
						p2[1]=b[1]/cnDot;
						p2[2]=b[2]/cnDot;
						p2[3]=b[3]/cnDot;
					}
					else
					{
						SetEnhanceByte(p2,b[0],cnDot,fEnhanceRate);
						SetEnhanceByte(p2+1,b[1],cnDot,fEnhanceRate);
						SetEnhanceByte(p2+2,b[2],cnDot,fEnhanceRate);
						SetEnhanceByte(p2+3,b[3],cnDot,fEnhanceRate);
					}

					if (bFlip) p2-=wDst*4;
					else p2+=wDst*4;
					v-=hSrc;
					cnDot=0;
					b[0]=0;
					b[1]=0;
					b[2]=0;
					b[3]=0;
				}
			}
		}
	}
	else
	{
		for (int i=0;i<hSrc;++i)
		{
			if (bFlip) memcpy(pBufDst+i*wSrc*4,pBufSrc+(hSrc-i-1)*wSrc*4,wSrc*4);
			else memcpy(pBufDst+i*wSrc*4,pBufSrc+i*wSrc*4,wSrc*4);
		}
	}
	free(pBufSrc);
	return pBufDst;
}

void CRenderTextureEx::SetEnhanceByte(GLubyte *p,int v,int cnDot,float fEnhanceRate)
{
	v=min(v*fEnhanceRate,cnDot*255);
	v/=cnDot;
	*p=v;
}

Sprite *CRenderTextureEx::GetSubSprite(Rect &rcSub,int wDst,int hDst,float fEnhanceRate)
{
	GLubyte *pBuf=GetSubData(rcSub,wDst,hDst,fEnhanceRate);
	if (pBuf==NULL) return NULL;

	Texture2D *pTexture=new Texture2D;
	Size size;
	size.width=wDst;
	size.height=hDst;
	if (m_bSetAlias) pTexture->setAliasTexParameters();
	int len = wDst * hDst * 4;
	if (pTexture == NULL || !pTexture->initWithData(pBuf, len,Texture2D::PixelFormat::RGBA8888, wDst, hDst, size))
	{
		pTexture->release();
		free(pBuf);
		return NULL;
	}
	free(pBuf);
	if (m_bSetAlias) pTexture->setAliasTexParameters();
	Sprite *pNewSprite=Sprite::createWithTexture(pTexture);
	pTexture->release();
	if (m_bSetAlias) pNewSprite->getTexture()->setAliasTexParameters();
	return pNewSprite;
}

Sprite *CRenderTextureEx::GetSprite()
{
	const Size &size = _texture->getContentSizeInPixels();
	Rect rc(0,0,size.width,size.height);
	return GetSubSprite(rc,(int)size.width,(int)size.height);
}

GLubyte *CRenderTextureEx::GetData(bool bFlip)
{
	const Size &size=_texture->getContentSizeInPixels();
	Rect rc(0,0,size.width,size.height);
	return GetSubData(rc,(int)size.width,(int)size.height,1.0f);
}
MySpaceEnd