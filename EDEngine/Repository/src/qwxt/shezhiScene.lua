require "Cocos2d"
require "Cocos2dConstants"
require "qwxt/globalSettings"
require "qwxt/userInfo"
require "qwxt/music"
local public=require("qwxt/public")

local ShezhiScene=public.newScene("ShezhiScene")

--加载UI
function ShezhiScene:loadUi(uiFileName)
	local layout=ccs.GUIReader:getInstance():widgetFromJsonFile(uiFileName)

	--响应后退按钮
	public.buttonEvent(ccui.Helper:seekWidgetByTag(layout,15697),function(sender,event)
		self:onKeyBack()
	end)

	--背景音乐开关
	local musicButton=ccui.Helper:seekWidgetByTag(layout,15725)
	musicButton:setSelectedState(not music.on)
	public.selectEvent(musicButton,function(sender,event)
		local musicOn=event~=ccui.CheckBoxEventType.selected
		music.turnOn(musicOn)
		music.playBackground()
	end)

	return layout
end

--返回键
function ShezhiScene:onKeyBack()
	cc.Director:getInstance():popScene()
end

return ShezhiScene