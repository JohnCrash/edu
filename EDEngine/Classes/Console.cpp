#include "Console.h"

Console::Console()
{
}

Console::~Console()
{
}

Console* Console::create()
{
	Console* _con = new Console();
	if(_con && _con->init())
	{
		_con->autorelease();
		return _con;
	}
	CC_SAFE_DELETE(_con);
	return nullptr;
}

bool Console::init()
{
	if(Scene::init())
	{
        // Add the alert
     //   auto *alert = cocos2d::ui::Text::create("RichText", "fonts/Marker Felt.ttf", 30);
     //   alert->setColor(cocos2d::Color3B(159, 168, 176));
     //   alert->setPosition(cocos2d::Point(100 / 2.0f, 100 / 2.0f - alert->getSize().height * 3.125));

		_richText = cocos2d::ui::RichText::create();
		_richText->setSize(cocos2d::Size(100,100));
	}
	return true;
}

