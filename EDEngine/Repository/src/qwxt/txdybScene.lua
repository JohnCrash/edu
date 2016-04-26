require "Cocos2d"
require "Cocos2dConstants"
require "qwxt/globalSettings"
require "qwxt/userInfo"
local public=require("qwxt/public")
local rank=require("qwxt/rank")

local TxdybScene=public.newScene("TxdybScene")

--加载UI
function TxdybScene:loadUi(uiFileName)
	local layout=ccs.GUIReader:getInstance():widgetFromJsonFile(uiFileName)

	--响应后退按钮
	public.buttonEvent(ccui.Helper:seekWidgetByTag(layout,3110),function(sender,event)
		self:onKeyBack()
	end)

	self.currentRank=nil
	self.currentRankView=nil

	--选择按钮监听
	local function onTouchRank(sender,event)
		if event==ccui.CheckBoxEventType.selected then
			self:onSelectRank(sender)
		end
	end

	--初始化各排行榜
	ccui.Helper:seekWidgetByTag(layout,3388):setVisible(false)
	ccui.Helper:seekWidgetByTag(layout,3408):setVisible(false)
	ccui.Helper:seekWidgetByTag(layout,3427):setVisible(false)
	ccui.Helper:seekWidgetByTag(layout,3444):setVisible(false)
	local rankButton=ccui.Helper:seekWidgetByTag(layout,4186)
	public.selectEvent(rankButton,onTouchRank)
	rankButton.createRankView=self.createLjkrView
	rankButton=ccui.Helper:seekWidgetByTag(layout,4187)
	public.selectEvent(rankButton,onTouchRank)
	rankButton.createRankView=self.createFjtxView
	rankButton=ccui.Helper:seekWidgetByTag(layout,4188)
	public.selectEvent(rankButton,onTouchRank)
	rankButton.createRankView=self.createLdtcView
	rankButton=ccui.Helper:seekWidgetByTag(layout,4189)
	public.selectEvent(rankButton,onTouchRank)
	rankButton.createRankView=self.createZtdrView
	
	return layout
end

--进入场景
function TxdybScene:onEnter()
	if not self.currentRank then
		--默认榜单
		self:onSelectRank(ccui.Helper:seekWidgetByTag(self:getChildByTag(3100),4186))
		math.randomseed(os.time())
	end
end

--返回键
function TxdybScene:onKeyBack()
	cc.Director:getInstance():popScene()
end

--选择榜单
function TxdybScene:onSelectRank(rank)
	if self.currentRank then
		self.currentRank:setSelectedState(false)
		self.currentRank:setEnabled(true)
		if self.currentRank.view then
			self.currentRank.view:setVisible(false)
			if self.currentRank.view.stopKeySchedule then self.currentRank.view.stopKeySchedule() end
		end
	end

	self.currentRank=rank
	self.currentRank:setEnabled(false)
	self.currentRank:setSelectedState(true)
	if not self.currentRank.view then
		self.currentRank.createRankView(self)
	end
	self.currentRank.view:setVisible(true)
end

--显示练级狂人榜单
function TxdybScene:createLjkrView()
	if not self.currentRank.view then
		--创建
		local rankView=ccui.Helper:seekWidgetByTag(self.layout,3388)
		local rankItem=ccui.Helper:seekWidgetByTag(rankView,3389)
		rankItem:retain()
		local viewSize=rankView:getContentSize()
		local viewPosition=cc.p(rankView:getPosition())
		local viewParent=rankView:getParent()
		rankView:removeFromParent()
		rankView=rank.createRankView(viewParent,viewPosition,viewSize,rankItem,1,{},function(item,data,index)
			ccui.Helper:seekWidgetByTag(item,3393):setString(index)
			ccui.Helper:seekWidgetByTag(item,3390):setString(data.user_name)
			ccui.Helper:seekWidgetByTag(item,3397):setString(data.user_level)
			ccui.Helper:seekWidgetByTag(item,3396):setPercent(globalSettings.level.calcPercent(data.user_level,data.user_exp))
			rank.setRankItemImage(index,ccui.Helper:seekWidgetByTag(item,3392),ccui.Helper:seekWidgetByTag(item,3393))
			rank.setRankUserImage(data.user_id,data.user_name,ccui.Helper:seekWidgetByTag(item,3394))
			ccui.Helper:seekWidgetByTag(item,31804):setSelectedState(data.isVip)
		end,function(e1,e2)
			if e1.user_exp~=e2.user_exp then
				return e1.user_exp>e2.user_exp
			else
				return e1.user_id<e2.user_id
			end
		end)

		self.currentRank.view=rankView
		self.currentRank.scrollHeight=rankItem:getContentSize().height
		rankItem:release()
	end
end

--显示富甲天下榜单
function TxdybScene:createFjtxView()
	if not self.currentRank.view then
		--创建
		local rankView=ccui.Helper:seekWidgetByTag(self.layout,3408)
		local rankItem=ccui.Helper:seekWidgetByTag(rankView,3409)
		rankItem:retain()
		local viewSize=rankView:getContentSize()
		local viewPosition=cc.p(rankView:getPosition())
		local viewParent=rankView:getParent()
		rankView:removeFromParent()
		rankView=rank.createRankView(viewParent,viewPosition,viewSize,rankItem,2,{},function(item,data,index)
			ccui.Helper:seekWidgetByTag(item,3412):setString(index)
			ccui.Helper:seekWidgetByTag(item,3410):setString(data.user_name)
			ccui.Helper:seekWidgetByTag(item,3414):setString(data.yinbi)
			rank.setRankItemImage(index,ccui.Helper:seekWidgetByTag(item,3411),ccui.Helper:seekWidgetByTag(item,3412))
			rank.setRankUserImage(data.user_id,data.user_name,ccui.Helper:seekWidgetByTag(item,3413))
			ccui.Helper:seekWidgetByTag(item,31805):setSelectedState(data.isVip)
		end,function(e1,e2)
			if e1.yinbi~=e2.yinbi then
				return e1.yinbi>e2.yinbi
			else
				return e1.user_id<e2.user_id
			end
		end)

		self.currentRank.view=rankView
		self.currentRank.scrollHeight=rankItem:getContentSize().height
		rankItem:release()
	end
end

--显示连对天才榜单
function TxdybScene:createLdtcView()
	if not self.currentRank.view then
		--创建
		local rankView=ccui.Helper:seekWidgetByTag(self.layout,3427)
		local rankItem=ccui.Helper:seekWidgetByTag(rankView,3428)
		rankItem:retain()
		local viewSize=rankView:getContentSize()
		local viewPosition=cc.p(rankView:getPosition())
		local viewParent=rankView:getParent()
		rankView:removeFromParent()
		rankView=rank.createRankView(viewParent,viewPosition,viewSize,rankItem,3,{},function(item,data,index)
			ccui.Helper:seekWidgetByTag(item,3431):setString(index)
			ccui.Helper:seekWidgetByTag(item,3429):setString(data.user_name)
			ccui.Helper:seekWidgetByTag(item,3434):setString(data.liandui)
			local t=os.date("*t",data.timestamp)
			ccui.Helper:seekWidgetByTag(item,3435):setString(string.format("%d.%d.%d",t.year,t.month,t.day))
			ccui.Helper:seekWidgetByTag(item,17118):setString(globalSettings.subjectName[data.subject_id])
			rank.setRankItemImage(index,ccui.Helper:seekWidgetByTag(item,3430),ccui.Helper:seekWidgetByTag(item,3431))
			rank.setRankUserImage(data.user_id,data.user_name,ccui.Helper:seekWidgetByTag(item,3432))
			ccui.Helper:seekWidgetByTag(item,31806):setSelectedState(data.isVip)
		end,function(e1,e2)
			if e1.liandui~=e2.liandui then
				return e1.liandui>e2.liandui
			elseif e1.timestamp~=e2.timestamp then
				return e1.timestamp<e2.timestamp
			else
				return e1.user_id<e2.user_id
			end
		end,function(data)
			local fmt="(%d+)/(%d+)/(%d+)%s+(%d+):(%d+):(%d+)"
			for _,v in ipairs(data) do
				v.timestamp=public.dateTimeFromString(fmt,v.update_time)
			end
		end)

		self.currentRank.view=rankView
		self.currentRank.scrollHeight=rankItem:getContentSize().height
		rankItem:release()
	end
end

--显示做题达人榜单
function TxdybScene:createZtdrView()
	if not self.currentRank.view then
		--创建
		local rankView=ccui.Helper:seekWidgetByTag(self.layout,3444)
		local rankItem=ccui.Helper:seekWidgetByTag(rankView,3445)
		rankItem:retain()
		local viewSize=rankView:getContentSize()
		local viewPosition=cc.p(rankView:getPosition())
		local viewParent=rankView:getParent()
		rankView:removeFromParent()
		rankView=rank.createRankView(viewParent,viewPosition,viewSize,rankItem,4,{},function(item,data,index)
			ccui.Helper:seekWidgetByTag(item,3448):setString(index)
			ccui.Helper:seekWidgetByTag(item,3446):setString(data.user_name)
			ccui.Helper:seekWidgetByTag(item,3451):setString(data.right_count)
			rank.setRankItemImage(index,ccui.Helper:seekWidgetByTag(item,3447),ccui.Helper:seekWidgetByTag(item,3448))
			rank.setRankUserImage(data.user_id,data.user_name,ccui.Helper:seekWidgetByTag(item,3449))
			ccui.Helper:seekWidgetByTag(item,31807):setSelectedState(data.isVip)
		end,function(e1,e2)
			if e1.right_count~=e2.right_count then
				return e1.right_count>e2.right_count
			else
				return e1.user_id<e2.user_id
			end
		end)

		self.currentRank.view=rankView
		self.currentRank.scrollHeight=rankItem:getContentSize().height
		rankItem:release()
	end
end

return TxdybScene