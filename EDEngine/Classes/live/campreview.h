#ifndef __CAMPREVIEW__H__
#define __CAMPREVIEW__H__
#include "cocos2d.h"
#include "ui/UIWidget.h"

NS_CC_BEGIN

namespace ui {

	class CamPreview : public Widget
	{
		DECLARE_CLASS_GUI_INFO
	public:
		CamPreview();

		virtual ~CamPreview();

		static CamPreview * create();

	CC_CONSTRUCTOR_ACCESS:
		virtual bool init() override;
	};
}

NS_CC_END

#endif