#ifndef __YUVSPRITE3__H__
#define __YUVSPRITE3__H__

#include "cocos2d.h"
#include "2d/CCNode.h"

NS_CC_BEGIN

class YUVSprite : public Node
{
public:
	static YUVSprite* create();
	static YUVSprite* createWithTexture(GLuint yuv[3], int linesize[3], int w, int h);

	void update(GLuint yuv[3],int linesize[3],int w, int h);

CC_CONSTRUCTOR_ACCESS:
	YUVSprite(void);
	virtual ~YUVSprite(void);

	/* Initializes an empty sprite with nothing init. */
	virtual bool init(void);
	virtual bool initWithTexture(GLuint yuv[3], int linesize[3], int w, int h);

	virtual std::string getDescription() const override;

	virtual void draw(Renderer* renderer, const Mat4 &transform, uint32_t flags) override;

	void render();
protected:
private:
	CC_DISALLOW_COPY_AND_ASSIGN(YUVSprite);
	GLuint _yuv[3];
	float _border[3];
	int width;
	int height;
	GLuint textureUniformY;
	GLuint textureUniformU;
	GLuint textureUniformV;
	GLuint borderUniformY;
	GLuint borderUniformU;
	GLuint borderUniformV;
	CustomCommand _customDrawCommand;
};

NS_CC_END

#endif