#ifndef __MOVIEVIEW__H__
#define __MOVIEVIEW__H__
#include "cocos2d.h"
#include "ui/UIWidget.h"
#include "YUVSprite3.h"
#include "ff.h"

NS_CC_BEGIN

namespace ui {
	class MovieView : public Widget
	{
		DECLARE_CLASS_GUI_INFO
	public:
		MovieView();

		virtual ~MovieView();
		virtual std::string getDescription() const override;

		CCSize getMovieSize() const;
		static MovieView * create();

		bool open(const char * name);
		void close();
		double length();
		double cur();
		bool seek(double t);
		bool pause();
		bool isOpen();
		bool isEnd();
		bool isError();
		bool isPause();
		bool isPlaying();
		bool isSeeking();
		const char * getErrMsg();

		virtual void setContentSize(const Size& contentSize) override;
		virtual void draw(Renderer* renderer, const Mat4 &transform, uint32_t flags) override;
	CC_CONSTRUCTOR_ACCESS:
		virtual bool init() override;
	protected:
		void initRenderer() override;
	private:
		void buildTexture();
		YUVSprite * _sprite;
		ff::FFVideo * _video;
		int width;
		int height;
		int linesize[3];
		bool updateTexture(ff::YUV420P * yuv);
		GLuint _textures[3];
	};
}

NS_CC_END

#endif