#ifndef __CAMPREVIEW__H__
#define __CAMPREVIEW__H__
#include "cocos2d.h"
#include "ui/UIWidget.h"
#include "YUVSprite3.h"

NS_CC_BEGIN

namespace ui {

	class CamPreview : public Widget
	{
		DECLARE_CLASS_GUI_INFO
	public:
		CamPreview();

		virtual ~CamPreview();
		virtual std::string getDescription() const override;

		static CamPreview * create();

	CC_CONSTRUCTOR_ACCESS:
		virtual bool init() override;
	protected:
		void initRenderer() override;
	private:
		YUVSprite * _sprite;
	};
}

NS_CC_END

#endif