/*
 * cocos2d-x 3.2+ °æ±¾µÄyuv sprite
 */
#include "YUVSprite3.h"

NS_CC_BEGIN

#define ATTRIB_VERTEX 3
#define ATTRIB_TEXTURE 4
static const GLfloat squareVertices[] = {
	-1.0f, -1.0f,
	1.0f, -1.0f,
	-1.0f, 1.0f,
	1.0f, 1.0f,
};
static const GLfloat coordVertices[] = {
	0.0f, 1.0f,
	1.0f, 1.0f,
	0.0f, 0.0f,
	1.0f, 0.0f,
};
static const char * _vshader = "\
attribute vec4 position;\n\
attribute vec2 TexCoordIn;\n\
varying vec2 TexCoordOut;\n\
void main(void)\n\
{\n\
	gl_Position = CC_MVPMatrix * position;\n\
	TexCoordOut = TexCoordIn;\n\
}";
static const char * _fshader = "\
varying vec2 TexCoordOut;\n\
uniform sampler2D tex_y;\n\
uniform sampler2D tex_u;\n\
uniform sampler2D tex_v;\n\
uniform float yborder;\n\
uniform float uborder;\n\
uniform float vborder;\n\
void main(void)\n\
{\n\
	vec3 yuv;\n\
	vec3 rgb;\n\
	yuv.x = texture2D(tex_y, vec2(TexCoordOut.x*yborder,TexCoordOut.y)).r;\n\
	yuv.y = texture2D(tex_u, vec2(TexCoordOut.x*uborder,TexCoordOut.y)).r - 0.5;\n\
	yuv.z = texture2D(tex_v, vec2(TexCoordOut.x*vborder,TexCoordOut.y)).r - 0.5;\n\
	rgb = mat3( 1,       1,         1,\n\
				0,       -0.39465,  2.03211,\n\
				1.13983, -0.58060,  0) * yuv;\n\
				gl_FragColor = vec4(rgb, 1);\n\
}";
static const char * _yuv420pShaderName = "yuv420p_shader";

static GLProgram * getYUV420pShader()
{
	GLProgram * prog;
	GLProgramCache * glp = GLProgramCache::getInstance();
	if (glp){
		prog = glp->programForKey(_yuv420pShaderName);
		if (prog && glIsProgram(prog->getProgram()))
			return prog;

		if (!prog)
			prog = new GLProgram();
		else
			prog->reset();
		if (prog->initWithVertexShaderByteArray(_vshader, _fshader)){
			prog->addAttribute("position", ATTRIB_VERTEX);
			prog->addAttribute("TexCoordIn", ATTRIB_TEXTURE);
			if (prog->link()){
				prog->updateUniforms();
				glp->addGLProgram(prog, _yuv420pShaderName);
				prog->release();
				CHECK_GL_ERROR_DEBUG();
				return prog;
			}
		}
	}
	CCLOG("yuv420p shader program init failed");
	CHECK_GL_ERROR_DEBUG();
	return NULL;
}

YUVSprite::YUVSprite(void)
{
}

YUVSprite::~YUVSprite(void)
{
}

bool YUVSprite::init(void)
{
	return initWithTexture(NULL,NULL,0,0);
}

void YUVSprite::update(GLuint yuv[3], int linesize[3],int w, int h)
{
	if (yuv){
		_yuv[0] = yuv[0];
		_yuv[1] = yuv[1];
		_yuv[2] = yuv[2];

		GLProgram * prog = getYUV420pShader();
		if (prog){
			textureUniformY = glGetUniformLocation(prog->getProgram(), "tex_y");
			textureUniformU = glGetUniformLocation(prog->getProgram(), "tex_u");
			textureUniformV = glGetUniformLocation(prog->getProgram(), "tex_v");

			borderUniformY = glGetUniformLocation(prog->getProgram(), "yborder");
			borderUniformU = glGetUniformLocation(prog->getProgram(), "uborder");
			borderUniformV = glGetUniformLocation(prog->getProgram(), "vborder");

			CHECK_GL_ERROR_DEBUG();

			_border[0] = (float)w / (float)linesize[0];
			_border[1] = (float)w / (2.0f*linesize[1]);
			_border[2] = (float)w / (2.0f*linesize[2]);

			width = w;
			height = h;

			setContentSize(CCSize(w, h));
			return;
		}
	}
	width = 0;
	height = 0;
}

bool YUVSprite::initWithTexture(GLuint yuv[3], int linesize[3], int w, int h)
{
	update(yuv, linesize,w, h);
	return true;
}

YUVSprite* YUVSprite::create()
{
	YUVSprite *sprite = new YUVSprite();
	if (sprite && sprite->init())
	{
		sprite->autorelease();
		return sprite;
	}
	CC_SAFE_DELETE(sprite);
	return nullptr;
}

YUVSprite* YUVSprite::createWithTexture(GLuint yuv[3], int linesize[3], int w, int h)
{
	YUVSprite *sprite = new YUVSprite();
	if (sprite && sprite->initWithTexture(yuv,linesize,w,h))
	{
		sprite->autorelease();
		return sprite;
	}
	CC_SAFE_DELETE(sprite);
	return nullptr;
}

std::string YUVSprite::getDescription() const
{
	return "YUVSprite";
}

void YUVSprite::draw(Renderer* renderer, const Mat4 &transform, uint32_t flags)
{
	if (width > 0 && height > 0){
		GLProgram * prog = getYUV420pShader();
		if (!prog)return;

		prog->use();
		prog->setUniformsForBuiltins();

		ccGLBindTexture2DN(0, _yuv[0]);
		glUniform1i(textureUniformY, 0);

		ccGLBindTexture2DN(1, _yuv[1]);
		glUniform1i(textureUniformU, 1);

		ccGLBindTexture2DN(2, _yuv[2]);
		glUniform1i(textureUniformV, 2);

		glUniform1f(borderUniformY, _border[0]);
		glUniform1f(borderUniformU, _border[1]);
		glUniform1f(borderUniformV, _border[2]);


	}
}

NS_CC_END