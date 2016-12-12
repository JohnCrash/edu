/*
* cocos2d 3.2+ÊÓÆµ²¥·Å¿Ø¼þ
*/
#include "movieview.h"
#include "AppDelegate.h"

NS_CC_BEGIN

namespace ui {
	IMPLEMENT_CLASS_GUI_INFO(MovieView)

		MovieView::MovieView() :
		_sprite(nullptr), _video(nullptr),
		width(0), height(0)
	{
		buildTexture();
		MySpace::AppDelegate_v3 * myapp = (MySpace::AppDelegate_v3 *)(CCApplication::getInstance());
		if (myapp)
			myapp->registerApphook(this);
	}

	void MovieView::buildTexture()
	{
		glGenTextures(3, _textures);
		CHECK_GL_ERROR_DEBUG();
		for (int i = 0; i < 3; i++){
			glBindTexture(GL_TEXTURE_2D, _textures[i]);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		}
		CHECK_GL_ERROR_DEBUG();
	}

	void MovieView::applicationWillEnterForeground()
	{
		glDeleteTextures(3, _textures);
		buildTexture();
		if (_prevPlayState)
			play();
	}
	
	void MovieView::applicationDidEnterBackground()
	{
		_prevPlayState = isPlaying();
		pause();
	}

	MovieView::~MovieView()
	{
		MySpace::AppDelegate_v3 * myapp = (MySpace::AppDelegate_v3 *)(CCApplication::getInstance());
		if (myapp)
			myapp->unresgisterApphook(this);
		close();
		glDeleteTextures(3, _textures);
		CHECK_GL_ERROR_DEBUG();
	}

	MovieView * MovieView::create()
	{
		MovieView * widget = new MovieView();
		if (widget && widget->init()){
			widget->autorelease();
			return widget;
		}
		CC_SAFE_DELETE(widget);
		return nullptr;
	}

	bool MovieView::init()
	{
		bool ret = true;
		do {
			if (!Widget::init()) {
				ret = false;
				break;
			}
		} while (0);
		return ret;
	}

	std::string MovieView::getDescription() const
	{
		return "MovieView";
	}

	void MovieView::initRenderer()
	{
		_sprite = YUVSprite::create();
		addProtectedChild(_sprite, -1, -1);
	}

	CCSize MovieView::getMovieSize() const
	{
		return CCSize(width, height);
	}

	void MovieView::setContentSize(const Size& contentSize)
	{
		Widget::setContentSize(contentSize);
		_sprite->setContentSize(contentSize);
	}

	bool MovieView::updateTexture(ff::YUV420P * yuv)
	{
		if (yuv->data[0] && yuv->data[1] && yuv->data[2]){
			linesize[0] = yuv->linesize[0];
			linesize[1] = yuv->linesize[1];
			linesize[2] = yuv->linesize[2];

			glBindTexture(GL_TEXTURE_2D, _textures[0]);

			glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, yuv->linesize[0], yuv->h, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, yuv->data[0]);

			glBindTexture(GL_TEXTURE_2D, _textures[1]);
			glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, yuv->linesize[1], yuv->h / 2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, yuv->data[1]);

			glBindTexture(GL_TEXTURE_2D, _textures[2]);
			glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, yuv->linesize[2], yuv->h / 2, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, yuv->data[2]);

			CHECK_GL_ERROR_DEBUG();
			return true;
		}
		return false;
	}
	static int64_t dd = 0;
	void MovieView::draw(Renderer* renderer, const Mat4 &transform, uint32_t flags)
	{
		if (_sprite && _video){
			ff::YUV420P * _yuv = (ff::YUV420P *)_video->refresh();
			if (_yuv && _yuv->w>0 && _yuv->h>0 && updateTexture(_yuv)){
				width = _yuv->w;
				height = _yuv->h;
				_sprite->update(_textures, _yuv->linesize, width, height);
				return;
			}
			else if( dd++ % 60 == 0){
				if (_yuv)
					CCLOG("MovieView::draw refresh return %dx%d",_yuv->w,_yuv->h);
				else
					CCLOG("MovieView::draw refresh return null");
			}
		}
		width = 0;
		height = 0;
	}

	bool MovieView::open(const char * name)
	{
		close();
		_video = new ff::FFVideo();
		return _video->open(name);
	}

	void MovieView::close()
	{
		if (_video){
			_video->close();
			delete _video;
			_video = nullptr;
		}
	}

	double MovieView::length()
	{
		if (_video){
			return _video->length();
		}
		else return 0;
	}

	double MovieView::cur()
	{
		if (_video){
			return _video->cur();
		}
		else return 0;
	}

	bool MovieView::seek(double t)
	{
		if (_video){
			_video->seek(t);
			return true;
		}
		else return false;
	}

	bool MovieView::pause()
	{
		if (_video){
			_video->pause();
			return true;
		}
		else return false;
	}
	bool MovieView::isOpen()
	{
		return _video ? _video->isOpen() : false;
	}
	const char * MovieView::getErrMsg()
	{
		return _video ? _video->errorMsg() : nullptr;
	}
	bool MovieView::isEnd()
	{
		return _video ? _video->isEnd() : false;
	}

	bool MovieView::isError()
	{
		return _video ? _video->isError() : false;
	}

	bool MovieView::isPause()
	{
		return _video ? _video->isPause() : false;
	}

	bool MovieView::isPlaying()
	{
		return _video ? _video->isPlaying() : false;
	}

	bool MovieView::isSeeking()
	{
		return _video ? _video->isSeeking() : false;
	}

	bool MovieView::play()
	{
		if (_video)_video->play();
		return true;
	}
}

NS_CC_END