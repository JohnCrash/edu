/*
 * cocos2d 3.2+ÉãÏñÔ¤ÊÓ¿Ø¼þ
 */
#include "campreview.h"
#include "ffpreview.h"
#include "AppDelegate.h"

NS_CC_BEGIN

namespace ui {
	IMPLEMENT_CLASS_GUI_INFO(CamPreview)

	CamPreview::CamPreview() :_sprite(nullptr)
	{
		MySpace::AppDelegate_v3 * myapp = (MySpace::AppDelegate_v3 *)(CCApplication::getInstance());
		if (myapp)
			myapp->registerApphook(this);
		width = 0;
		height = 0;
		ff::ffStartPreview();
	}
	void CamPreview::applicationWillEnterForeground()
	{
		ff::ffStartPreview();
	}
	void CamPreview::applicationDidEnterBackground()
	{
		ff::ffStopPreview();
	}
	CamPreview::~CamPreview()
	{
		MySpace::AppDelegate_v3 * myapp = (MySpace::AppDelegate_v3 *)(CCApplication::getInstance());
		if (myapp)
			myapp->unresgisterApphook(this);
		ff::ffStopPreview();
	}

	CamPreview * CamPreview::create()
	{
		CamPreview * widget = new CamPreview();
		if (widget && widget->init()){
			widget->autorelease();
			return widget;
		}
		CC_SAFE_DELETE(widget);
		return nullptr;
	}

	bool CamPreview::init()
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

	bool CamPreview::startPreview()
	{
		return ff::ffStartPreview();
	}

	void CamPreview::stopPreview()
	{
		ff::ffStopPreview();
	}

	std::string CamPreview::getDescription() const
	{
		return "CamPreview";
	}

	void CamPreview::initRenderer()
	{
		_sprite = YUVSprite::create();
		addProtectedChild(_sprite, -1, -1);
	}

	CCSize CamPreview::getPreviewSize() const
	{
		return CCSize(width, height);
	}

	void CamPreview::setContentSize(const Size& contentSize)
	{
		Widget::setContentSize(contentSize);
		_sprite->setContentSize(contentSize);
	}

	void CamPreview::draw(Renderer* renderer, const Mat4 &transform, uint32_t flags)
	{
		if (_sprite){
			GLuint yuv[3];
			int linesize[3];
			int w, h;
			if (ff::ffGetPreviewFrame(yuv, linesize, &w, &h)){
				width = w;
				height = h;
				_sprite->update(yuv, linesize, w, h);
			}
			else{
				width = 0;
				height = 0;
			}
		}
	}
}

NS_CC_END