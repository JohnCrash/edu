#ifndef __RENDERTEXTUREEX_H__
#define __RENDERTEXTUREEX_H__

#include "cocos2d.h"
//#include "misc.h"

USING_NS_CC;
/*
class CRenderTextureEx : public CCRenderTexture
{
public:
	CRenderTextureEx(void);
	~CRenderTextureEx(void);

	GLubyte *GetSubData(CCRect &rcSub,int wDst,int hDst,float fEnhanceRate,bool bFlip=true);
	GLubyte *GetData(bool bFlip);
	CCSprite *GetSubSprite(CCRect &rcSub,int wDst,int hDst,float fEnhanceRate=1.0f);
	CCSprite *GetSprite();
	CCTexture2D *GetTexture(){return m_pTexture;}

	void EnableSetAlias(bool bEnable){m_bSetAlias=bEnable;}

private:
	void SetEnhanceByte(GLubyte *p,int v,int cnDot,float fEnhanceRate);

	bool m_bSetAlias;
};
*/
#define	IMAGE_ORIENTATION_UP				1
#define	IMAGE_ORIENTATION_LEFT				6
#define	IMAGE_ORIENTATION_RIGHT				8
#define	IMAGE_ORIENTATION_DOWN				3
#define	IMAGE_ORIENTATION_MIRROR_UP			2
#define	IMAGE_ORIENTATION_MIRROR_LEFT		5
#define	IMAGE_ORIENTATION_MIRROR_RIGHT		7
#define	IMAGE_ORIENTATION_MIRROR_DOWN		4

//RGBA8888模式时使用获取或设置子图像
class CImageEx : public CCImage
{
public:
	CImageEx();

	bool LoadFromFile(const char *pszPathName);
	int GetJpgOrientation(){return m_nJpgOrientation;}

	static CCImage::EImageFormat GetImageFormat(const char *pszPathName);
	static CCImage::EImageFormat GetImageFormat(const char *pBuf,int lenBuf);
	bool InitImageData(int nWidth,int hHeight);

	unsigned char *GetData(PINTRECT prc);
	bool GetData(PINTRECT prc,unsigned char *pBuf);
	bool SetData(PINTRECT prc,unsigned char *pBuf);
	CCSprite *GetReduceSprite(int nMaxLineLength,int nOrientation);

	char *SaveToMem(int &len);
	bool SaveToFileInTextMode(const char *pszPathName,int cnBytesPerBit=4);

protected:
	int m_nJpgOrientation;
};

#endif // __RENDERTEXTUREEX_H__
