require "Cocos2d"
require "Cocos2dConstants"
require "qwxt/globalSettings"
require "qwxt/userInfo"
local public=require("qwxt/public")

local zuotijieshuScene=public.newScene("ZuotijieshuScene")

--加载UI
function zuotijieshuScene:loadUi(uiFileName)
	local layout=ccs.GUIReader:getInstance():widgetFromJsonFile(uiFileName)
	--日期
	local t=os.date("*t",os.time())
	ccui.Helper:seekWidgetByTag(layout,4915):setString(string.format("%d.%d.%d",t.year,t.month,t.day))
	--累计做题
	ccui.Helper:seekWidgetByTag(layout,4923):setString(problemCount.total)
	--错题数
	ccui.Helper:seekWidgetByTag(layout,4927):setString(problemCount.wrong)
	--正确率
	local rate=100.0
	if problemCount.total>0 then
		rate=(problemCount.total-problemCount.wrong)*100/problemCount.total
		ccui.Helper:seekWidgetByTag(layout,4934):setString(string.format("%0.2f%%",rate))
	else
		ccui.Helper:seekWidgetByTag(layout,4934):setString("100%")
	end
	--文字提示
	ccui.Helper:seekWidgetByTag(layout,28622):setVisible(false)
	ccui.Helper:seekWidgetByTag(layout,28620):setVisible(false)
	ccui.Helper:seekWidgetByTag(layout,28616):setVisible(false)
	ccui.Helper:seekWidgetByTag(layout,28618):setVisible(false)
	if rate>=90 then
		ccui.Helper:seekWidgetByTag(layout,28618):setVisible(true)
	elseif rate>=80 then
		ccui.Helper:seekWidgetByTag(layout,28616):setVisible(true)
	elseif rate>=70 then
		ccui.Helper:seekWidgetByTag(layout,28620):setVisible(true)
	else
		ccui.Helper:seekWidgetByTag(layout,28622):setVisible(true)
	end
	--银币
	ccui.Helper:seekWidgetByTag(layout,4940):setString(problemCount.yinbi)
	--所得经验
	ccui.Helper:seekWidgetByTag(layout,4941):setString(problemCount.exp)
	
	--返回首页
	public.buttonEvent(ccui.Helper:seekWidgetByTag(layout,4910),function(sender,event)
		cc.Director:getInstance():popToRootScene()
	end)

	--返回单元
	local backToUnit=ccui.Helper:seekWidgetByTag(layout,4911)
	public.buttonEvent(backToUnit,function(sender,event)
		self:onKeyBack()
	end)

	--直接退出
	public.buttonEvent(ccui.Helper:seekWidgetByTag(layout,4912),function(sender,event)
		public.safeExit()
	end)
	
	return layout
end

function zuotijieshuScene:onKeyBack()
	cc.Director:getInstance():popToSceneStackLevel(3)
end

return zuotijieshuScene