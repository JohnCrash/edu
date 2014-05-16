
require "Cocos2d"
require "Cocos2dConstants"
require "Opengl"
require "OpenglConstants"
require "StudioConstants"
require "GuiConstants"
require "src/helper"
require "src/testResource"
require "src/VisibleRect"

require "src/amouse/amouse"

local LINE_SPACE = 40

local CurPos = {x = 0, y = 0}
local BeginPos = {x = 0, y = 0}


local _allTests = {
	{ isSupported = true,  name = "A Mouse"          , create_func=             AMouseMain  },
}

local TESTS_COUNT = table.getn(_allTests)

-- create scene
local function CreateTestScene(nIdx)
    cc.Director:getInstance():purgeCachedData()
    local scene = _allTests[nIdx].create_func()
    return scene
end

-- create menu
function CreateTestMenu()
    local menuLayer = cc.Layer:create()

    local function closeCallback()
        cc.Director:getInstance():endToLua()
    end

    local function menuCallback(tag)
        print(tag)
        local Idx = tag - 10000
        local testScene = CreateTestScene(Idx)
        if testScene then
            cc.Director:getInstance():replaceScene(testScene)
        end
    end

    -- add close menu
    local s = cc.Director:getInstance():getWinSize()
    local CloseItem = cc.MenuItemImage:create(s_pPathClose, s_pPathClose)
    CloseItem:registerScriptTapHandler(closeCallback)
    CloseItem:setPosition(cc.p(s.width - 90, s.height - 90))

    local CloseMenu = cc.Menu:create()
    CloseMenu:setPosition(0, 0)
    CloseMenu:addChild(CloseItem)
    menuLayer:addChild(CloseMenu)
    local targetPlatform = cc.Application:getInstance():getTargetPlatform()       
    if (cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform) then
        CloseMenu:setVisible(false)
    end

    -- add menu items for tests
    local MainMenu = cc.Menu:create()
    local index = 0
    local obj = nil
    for index, obj in pairs(_allTests) do
        local testLabel = cc.Label:createWithTTF(obj.name, s_arialPath, 24)
        testLabel:setAnchorPoint(cc.p(0.5, 0.5))
        local testMenuItem = cc.MenuItemLabel:create(testLabel)
        if not obj.isSupported then
            testMenuItem:setEnabled(false)
        end
        testMenuItem:registerScriptTapHandler(menuCallback)
        testMenuItem:setPosition(cc.p(s.width / 2, (s.height - (index+2) * LINE_SPACE)))
        MainMenu:addChild(testMenuItem, index + 10000, index + 10000)
    end

    MainMenu:setContentSize(cc.size(s.width, (TESTS_COUNT + 1) * (LINE_SPACE)))
    MainMenu:setPosition(CurPos.x, CurPos.y)
    menuLayer:addChild(MainMenu)

    -- handling touch events
    local function onTouchBegan(touch, event)
        BeginPos = touch:getLocation()
        -- CCTOUCHBEGAN event must return true
        return true
    end

    local function onTouchMoved(touch, event)
        local location = touch:getLocation()
        local nMoveY = location.y - BeginPos.y
        local curPosx, curPosy = MainMenu:getPosition()
        local nextPosy = curPosy + nMoveY
        local winSize = cc.Director:getInstance():getWinSize()
        if nextPosy < 0 then
            MainMenu:setPosition(0, 0)
            return
        end

        if nextPosy > ((TESTS_COUNT + 1) * LINE_SPACE - winSize.height) then
            MainMenu:setPosition(0, ((TESTS_COUNT + 1) * LINE_SPACE - winSize.height))
            return
        end

        MainMenu:setPosition(curPosx, nextPosy)
        BeginPos = {x = location.x, y = location.y}
        CurPos = {x = curPosx, y = nextPosy}
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
    local eventDispatcher = menuLayer:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, menuLayer)

    return menuLayer
end
