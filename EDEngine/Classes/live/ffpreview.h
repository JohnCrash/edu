#ifndef __FFPREVIEW__H__
#define __FFPREVIEW__H__
#include "cocos2d.h"

namespace ff{
	int ffStartPreview();
	int ffGetPreviewFrame(GLuint yuv[3], int *pw, int *ph);
	void ffStopPreview();
}
#endif