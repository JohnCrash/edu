#ifndef __RENDERTEXTUREEX_H__
#define __RENDERTEXTUREEX_H__
#include "staticlib.h"
#include "cocos2d.h"
#include "misc.h"
#include <string>

MySpaceBegin

USING_NS_CC;

class CRenderTextureEx : public RenderTexture
{
public:
	CRenderTextureEx(void);
	~CRenderTextureEx(void);

	GLubyte *GetSubData(Rect &rcSub,int wDst,int hDst,float fEnhanceRate,bool bFlip=true);
	GLubyte *GetData(bool bFlip);
	Sprite *GetSubSprite(Rect &rcSub,int wDst,int hDst,float fEnhanceRate=1.0f);
	Sprite *GetSprite();
	Texture2D *GetTexture(){ return _texture; }

	void EnableSetAlias(bool bEnable){m_bSetAlias=bEnable;}

private:
	void SetEnhanceByte(GLubyte *p,int v,int cnDot,float fEnhanceRate);

	bool m_bSetAlias;
};

#define	IMAGE_ORIENTATION_UP				1
#define	IMAGE_ORIENTATION_LEFT				6
#define	IMAGE_ORIENTATION_RIGHT				8
#define	IMAGE_ORIENTATION_DOWN				3
#define	IMAGE_ORIENTATION_MIRROR_UP			2
#define	IMAGE_ORIENTATION_MIRROR_LEFT		5
#define	IMAGE_ORIENTATION_MIRROR_RIGHT		7
#define	IMAGE_ORIENTATION_MIRROR_DOWN		4


//RGBA8888模式时使用获取或设置子图像
class CImageEx : public Image
{
public:
	CImageEx();

	bool LoadFromFile(const char *pszPathName);
	int GetJpgOrientation(){return m_nJpgOrientation;}

	static Image::Format GetImageFormat(const char *pszPathName);
	static Image::Format GetImageFormat(const char *pBuf, int lenBuf);
	bool InitImageData(int nWidth,int hHeight);

	unsigned char *GetData(PINTRECT prc);
	bool GetData(PINTRECT prc, unsigned char *pBuf);
	bool SetData(PINTRECT prc, unsigned char *pBuf);
	Sprite *GetReduceSprite(int nMaxLineLength,int nOrientation);

	bool ReduceAndSaveToFile(std::string filename,int nMaxLineLength, int nOrientation);
	char *SaveToMem(int &len);
	bool SaveToFileInTextMode(const char *pszPathName,int cnBytesPerBit=4);
	std::string GetTmpFile(){ return mTmpFile;  }
protected:
	int m_nJpgOrientation;
	std::string mTmpFile;
};

MySpaceEnd
#endif // __RENDERTEXTUREEX_H__
