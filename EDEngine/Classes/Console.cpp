#include "Console.h"

MySpaceBegin

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
	if(Layer::init())
	{/*
		cocos2d::Size size;

		size = cocos2d::Director::getInstance()->getVisibleSize();
		_richText = cocos2d::ui::RichText::create();
		_richText->setSize(size);
        
        cocos2d::ui::RichElementText* re1 = cocos2d::ui::RichElementText::create(1, cocos2d::Color3B::WHITE, 255, "This color is white. ", "Helvetica", 20);
        cocos2d::ui::RichElementText* re2 = cocos2d::ui::RichElementText::create(2, cocos2d::Color3B::YELLOW, 255, "And this is yellow. ", "Helvetica", 20);
        cocos2d::ui::RichElementText* re3 = cocos2d::ui::RichElementText::create(3, cocos2d::Color3B::BLUE, 255, "This one is blue. ", "Helvetica", 10);
        cocos2d::ui::RichElementText* re4 = cocos2d::ui::RichElementText::create(4, cocos2d::Color3B::GREEN, 255, "And green. ", "Helvetica", 10);
        cocos2d::ui::RichElementText* re5 = cocos2d::ui::RichElementText::create(5, cocos2d::Color3B::RED, 255, "Last one is red ", "Helvetica", 10);
        
     //   cocos2d::ui::RichElementImage* reimg = cocos2d::ui::RichElementImage::create(6, cocos2d::Color3B::WHITE, 255, "cocosui/sliderballnormal.png");
        
     //   cocos2d::ui::RichElementCustomNode* recustom = cocos2d::ui::RichElementCustomNode::create(1, cocos2d::Color3B::WHITE, 255, pAr);
        cocos2d::ui::RichElementText* re6 = cocos2d::ui::RichElementText::create(7, cocos2d::Color3B::ORANGE, 255, "Have fun!! ", "Helvetica", 10);
        _richText->pushBackElement(re1);
        _richText->insertElement(re2, 1);
        _richText->pushBackElement(re3);
        _richText->pushBackElement(re4);
        _richText->pushBackElement(re5);
      //  _richText->insertElement(reimg, 2);
     //   _richText->pushBackElement(recustom);
        _richText->pushBackElement(re6);
		//_richText->setAnchorPoint(cocos2d::Point(0,0));
		_richText->setPosition(cocos2d::Point(size.width/2,size.height/2));
//        _richText->setLocalZOrder(10);
		this->addChild(_richText);
		*/
	}
	return true;
}

MySpaceEnd
