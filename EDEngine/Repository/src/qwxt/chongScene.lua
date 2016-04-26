require "Cocos2d"
require "Cocos2dConstants"
local public=require("qwxt/public")

local RechargeHelpScene=public.newScene("RechargeHelpScene")

--加载UI
function RechargeHelpScene:loadUi(uiFileName)
	local layout=ccs.GUIReader:getInstance():widgetFromJsonFile(uiFileName)

	--返回按钮
	public.buttonEvent(ccui.Helper:seekWidgetByTag(layout,35046),function(sender,event)
		self.onKeyBack()
	end)

	return layout
end

function RechargeHelpScene:onKeyBack()
	cc.Director:getInstance():popScene()
end

return RechargeHelpScene