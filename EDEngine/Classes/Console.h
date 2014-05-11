#ifndef __Console__H__
#define __Console__H__

#include "cocos2d.h"
//#include "extensions/cocos-ext.h"
//#include "ui/CocosGUI.h"

class Console:public cocos2d::Layer
{
public:
	Console();
	~Console();
	bool init();
	static Console* create();
private:
//	cocos2d::ui::RichText* _richText;
};

#endif