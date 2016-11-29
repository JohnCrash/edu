#include "ffcommon.h"
#include "sharegl.h"

#if defined(__APPLE__)
#elif defined(__ANDROID__)
#else
#include "cocos2d.h"
#include "glfw3.h"

//glfw3二进制兼容代码
typedef struct _GLFWcontextWGL
{
	HDC       dc;            
	HGLRC     context;       
} _GLFWcontextWGL;
#define WGLCONTEXT_OFFSET 0x218
#endif

namespace ff
{
#if defined(__APPLE__)
	int ffInitShare(){
		return 0;
	}
	void ffShareMakeCurrent()
	{
	}
#elif defined(__ANDROID__)
	int ffInitShare(){
		return 0;
	}
	void ffShareMakeCurrent()
	{
	}
#else
	static HGLRC glrc = NULL;
	static HDC gldc = NULL;
	int ffInitShare(){
		cocos2d::Director *director = cocos2d::Director::getInstance();
		if (!director){
			cocos2d::log("ffInitShare @cocos2d::Director::getInstance return nullptr");
			return 0;
		}
		cocos2d::GLView * glview = director->getOpenGLView();
		if (!glview){
			cocos2d::log("ffInitShare @getOpenGLView return nullptr");
			return 0;
		}
		GLFWwindow * glfw = (GLFWwindow *)glview->getWindow();
		if (!glfw){
			cocos2d::log("ffInitShare @GLView::getWindow return nullptr");
			return 0;
		}
		//cocos2d 3.2 二进制兼容代码
		_GLFWcontextWGL *wgl = (_GLFWcontextWGL *)((char *)glfw + WGLCONTEXT_OFFSET);
		if (glrc && gldc == wgl->dc){
			//已经初始化
			return 1;
		}
		else if (glrc){
			wglDeleteContext(glrc);
		}
		glrc = wglCreateContext(wgl->dc);
		if (!glrc){
			cocos2d::log("ffInitShare @wglCreateContext return nullptr");
			return 0;
		}
		if (!wglShareLists(wgl->context,glrc)){
			DWORD errorCode = GetLastError();
			wglDeleteContext(glrc);
			glrc = NULL;
			cocos2d::log("ffInitShare @wglShareLists failed , %d", errorCode);
			return 0;
		}
		gldc = wgl->dc;
		return 1;
	}

	void ffReleaseShare(){
		if (glrc)wglDeleteContext(glrc);
		glrc = NULL;
	}

	int ffShareMakeCurrent()
	{
		if (glrc && gldc){
			wglMakeCurrent(gldc, glrc);
			return 1;
		}
		return 0;
	}
	void ffShareMakeCurrentClear()
	{
		wglMakeCurrent(NULL, NULL);
	}
#endif
}