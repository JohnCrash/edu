require "Cocos2d"
require "Cocos2dConstants"
require "qwxt/globalSettings"
local public=require("qwxt/public")

local LoadingScene=public.newScene("LoadingScene")

--加载UI
function LoadingScene:loadUi(uiFileName)
	local layout=ccs.GUIReader:getInstance():widgetFromJsonFile(uiFileName)

	--文字效果
	local text=ccui.Helper:seekWidgetByTag(layout,8981)
	local action1=cc.TintBy:create(0.5,255,255,255)
	local action2=action1:reverse()
	text:runAction(cc.RepeatForever:create(cc.Sequence:create(action1,action2)))

	return layout
end

function LoadingScene:onEnterTransitionFinish()
	local id=nil
	local i=0
	local function tick()
		if not coroutine.resume(self.loadCoroutine) then
			--取消定时任务
			cc.Director:getInstance():getScheduler():unscheduleScriptEntry(id)
			--执行回调
			if self.callback then
				self.callback()
			end
		end
	end

	id=cc.Director:getInstance():getScheduler():scheduleScriptFunc(tick,0,false)
end

function LoadingScene:setLoading(load,callback)
	if type(load)~="function" then return end
	self.loadCoroutine=coroutine.create(load)
	self.callback=callback
end

return LoadingScene
