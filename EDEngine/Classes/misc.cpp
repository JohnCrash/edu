#include "misc.h"
#include "errno.h"

Sprite *SpriteFromImage(Image *pImage)
{
	Texture2D *pTexture = new Texture2D();
	pTexture->initWithImage(pImage);
	return Sprite::createWithTexture(pTexture);
}

Sprite *SpriteFromRaw(char *pBuf, int nWidth, int nHeight)
{
	Image *pImage = new Image;
	if (pImage == NULL) return NULL;

	if (!pImage->initWithRawData((const unsigned char *)pBuf, nWidth * 4 * nHeight, nWidth, nHeight,8))
	{
		delete pImage;
		return NULL;
	}
	Sprite *pSprite = SpriteFromImage(pImage);
	delete pImage;
	return pSprite;
}

char *ReduceRawBuf(char *pSrc,int nSrcWidth,int nSrcHeight,int &nDstWidth,int &nDstHeight,int nMaxLineLength,bool bHasAlpha)
{
	int nWidth;
	int nHeight;
	unsigned char *pDst;

	if (nSrcWidth<nMaxLineLength && nSrcHeight<nMaxLineLength)
	{
		//原图像比要求的还小
		nWidth=nSrcWidth;
		nHeight=nSrcHeight;
		pDst=(unsigned char *)malloc(nWidth*nHeight*4);
		if (pDst==NULL) return NULL;

		unsigned char *pDstTmp=pDst;
		for (int i=0;i<nSrcHeight;i++)
		{
			for (int j=0;j<nSrcWidth;j++)
			{
				*pDstTmp++=*pSrc++;
				*pDstTmp++=*pSrc++;
				*pDstTmp++=*pSrc++;
				if (bHasAlpha) *pDstTmp++=*pSrc++;
				else *pDstTmp++=255;
			}
		}
	}
	else
	{
		//超过要求的了
		float fScale;
		if (nSrcWidth>=nSrcHeight) fScale=((float)nMaxLineLength)/nSrcWidth;
		else fScale=((float)nMaxLineLength)/nSrcHeight;

		//算出返回图像的尺寸
		nWidth=(int)nSrcWidth*fScale;
		nHeight=(int)nSrcHeight*fScale;

		pDst=(unsigned char *)malloc(nWidth*nHeight*4);
		if (pDst==NULL) return NULL;

		uint32_t *pTmpLine=(uint32_t *)malloc(nWidth*4*sizeof(uint32_t));
		if (pTmpLine==NULL)
		{
			free(pDst);
			return NULL;
		}
		unsigned char *pDstTmp=pDst;

		int cnLine=0;
		int dy=0;
		uint32_t *pTmpDot;

		int cnDot;
		int dx;
		uint32_t tmpDot[4];
		for (int i=0;i<nSrcHeight;i++)
		{
			if (cnLine==0)
			{
				//行临时缓冲区，由于要有好几行的数据相加，因此类型为int
				memset(pTmpLine,0,sizeof(int)*nWidth*4);
			}

			pTmpDot=pTmpLine;
			cnDot=0;
			dx=0;
			tmpDot[0]=0;
			tmpDot[1]=0;
			tmpDot[2]=0;
			tmpDot[3]=0;
			for (int j=0;j<nSrcWidth;j++)
			{
				cnDot++;
				dx+=nWidth;

				tmpDot[0]+=(unsigned char)pSrc[0];
				tmpDot[1]+=(unsigned char)pSrc[1];
				tmpDot[2]+=(unsigned char)pSrc[2];
				if (bHasAlpha) tmpDot[3]+=(unsigned char)pSrc[3];
				else tmpDot[3]+=255;
				pSrc+=3;
				if (bHasAlpha) pSrc++;

				if (dx>=nSrcWidth)
				{
					//平均值
					pTmpDot[0]+=tmpDot[0]/cnDot;
					pTmpDot[1]+=tmpDot[1]/cnDot;
					pTmpDot[2]+=tmpDot[2]/cnDot;
					pTmpDot[3]+=tmpDot[3]/cnDot;
					pTmpDot+=4;

					cnDot=0;
					dx-=nSrcWidth;
					tmpDot[0]=0;
					tmpDot[1]=0;
					tmpDot[2]=0;
					tmpDot[3]=0;
				}
			}
			cnLine++;
			dy+=nHeight;
			if (dy>=nSrcHeight)
			{
				int n=nWidth*4;
				for (int j=0;j<n;j++)
				{
					*pDstTmp++=(unsigned char)(pTmpLine[j]/cnLine);
				}
				cnLine=0;
				dy-=nSrcHeight;
			}
		}
		free(pTmpLine);
	}
	nDstWidth=nWidth;
	nDstHeight=nHeight;
	return (char *)pDst;
}

char *AdjustRawBufOrientation(char *pSrcBuf,int *pWidth,int *pHeight,int nAngle,bool bMirror)
{
	if (nAngle==0 && !bMirror) return NULL;
    nAngle %= 360;
    if (nAngle!=0 && nAngle!=90 && nAngle!=180 && nAngle!=270) return NULL;

    int nWidth=*pWidth;
    int nHeight=*pHeight;
	int len=nWidth*nHeight*4;
	char *pDstBuf=(char *)malloc(len);
	if (pDstBuf==NULL) return NULL;

    memmove(pDstBuf,pSrcBuf,len);
    int nDstWidth=nWidth;
    int nDstHeight=nHeight;
	if (nAngle==90 || nAngle==270)
	{
        nDstWidth=nHeight;
        nDstHeight=nWidth;
	}
    
	int x,y;
	for (int i=0;i<nHeight;i++)
	{
		char *s=pSrcBuf+i*nWidth*4;
		for (int j=0;j<nWidth;j++)
		{
			x=j;
			y=i;
			if (!bMirror)
			{
				if (nAngle==90)
				{
					y=j;
					x=nHeight-i-1;
				}
				else if (nAngle==180)
				{
					x=nWidth-j-1;
					y=nHeight-i-1;
				}
				else if (nAngle==270)
				{
					y=nWidth-j-1;
					x=i;
				}
			}
			else
			{
				if (nAngle==0)
				{
					x=nWidth-j-1;
					y=i;
				}
				else if (nAngle==90)
				{
					y=nWidth-j-1;
					x=nHeight-i-1;
				}
				else if (nAngle==180)
				{
					x=j;
					y=nHeight-i-1;
				}
				else if (nAngle==270)
				{
					y=j;
					x=i;
				}
			}
			*(int *)(pDstBuf+(y*nDstWidth+x)*4)=*(int *)(s+j*4);
        }
	}
    *pWidth=nDstWidth;
    *pHeight=nDstHeight;
	return pDstBuf;
}

