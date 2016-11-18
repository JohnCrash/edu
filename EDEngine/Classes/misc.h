#ifndef __LJMISC_H__
#define __LJMISC_H__

//³£ÓÃº¯Êý¿â
#include "staticlib.h"
#include "cocos2d.h"

MySpaceBegin

USING_NS_CC;

struct INTRECT
{
	int top;
	int left;
	int bottom;
	int right;
};
typedef INTRECT* PINTRECT;

Sprite *SpriteFromImage(Image *pImage);
Sprite *SpriteFromRaw(char *pBuf, int nWidth, int nHeight);
char *AdjustRawBufOrientation(char *pSrcBuf,int *pWidth,int *pHeight,int nAngle,bool bMirror);
char *ReduceRawBuf(char *pSrc,int nSrcWidth,int nSrcHeight,int &nDstWidth,int &nDstHeight,int nMaxLineLength,bool bHasAlpha);


MySpaceEnd
#endif // __LJMISC_H__
