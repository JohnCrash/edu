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

		CCSize getPreviewSize();
		bool startPreview();
		void stopPreview();
		static CamPreview * create();

		CCSize getPreviewSize() const;
		virtual void setPosition(const Vec2 &pos) override;
		virtual void setContentSize(const Size& contentSize) override;
		virtual void draw(Renderer* renderer, const Mat4 &transform, uint32_t flags) override;
	CC_CONSTRUCTOR_ACCESS:
		virtual bool init() override;
	protected:
		void initRenderer() override;
	private:
		YUVSprite * _sprite;
		int width;
		int height;
	};
}

NS_CC_END

#endif