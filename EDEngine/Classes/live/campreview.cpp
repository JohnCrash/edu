/*
 * cocos2d 3.2+ÉãÏñÔ¤ÊÓ¿Ø¼þ
 */
#include "campreview.h"
#include "ffpreview.h"

NS_CC_BEGIN

namespace ui {
	IMPLEMENT_CLASS_GUI_INFO(CamPreview)

	CamPreview::CamPreview()
	{
	}

	CamPreview::~CamPreview()
	{
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

	std::string CamPreview::getDescription() const
	{
		return "CamPreview";
	}
}

NS_CC_END