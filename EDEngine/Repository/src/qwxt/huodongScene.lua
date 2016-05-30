require "Cocos2d"
require "Cocos2dConstants"
require "qwxt/globalSettings"
require "qwxt/userInfo"
local public=require("qwxt/public")
local popup=require("qwxt/popup")
local protocol=require("qwxt/protocol")
local rank=require("qwxt/rank")
local cache=require("cache")

local HuodongScene=public.newScene("HuodongScene")

--加载UI
function HuodongScene:loadUi(uiFileName)
	local layout=ccs.GUIReader:getInstance():widgetFromJsonFile(uiFileName)

	self.text=ccui.Helper:seekWidgetByTag(layout,36874)
	self.noActivity=ccui.Helper:seekWidgetByTag(layout,36882)
	self.main=ccui.Helper:seekWidgetByTag(layout,36893)
	self.awardView=ccui.Helper:seekWidgetByTag(layout,37387)
	self.rankView=ccui.Helper:seekWidgetByTag(layout,37602)
	self.awardButton=ccui.Helper:seekWidgetByTag(layout,37491)

	--用tableview替换掉listview
	local function refreshRank(tableView)
		if self.currentActivity==nil then
			tableView:setData(nil)
			return
		end
		tableView.text="我的排名：未上榜"
		self.text:setString(tableView.text)
		protocol.getActivityRank(self.currentActivity.activity_id,function(success,obj)
			if success and obj then
				if #obj<=0 then
					tableView:setData(nil)
					return
				end
				for i=1,#obj do
					if obj[i].user_id==userInfo.uid then
						tableView.text="我的排名："..i
						self.text:setString(tableView.text)
						break
					end
				end
				tableView:setData(obj)
			end
			tableView:setBounceable(true)
		end,{node=tableView:getParent(),text="正在刷新......"})
	end
	--连对
	local listView=ccui.Helper:seekWidgetByTag(self.rankView,37375)
	local item=ccui.Helper:seekWidgetByTag(listView,37376)
	self.rankView.liandui=rank.createRankView(listView:getParent(),cc.p(listView:getPosition()),listView:getContentSize(),item,nil,nil,function(item,data,index)
		ccui.Helper:seekWidgetByTag(item,37379):setString(index)
		ccui.Helper:seekWidgetByTag(item,37377):setString(data.user_name)
		ccui.Helper:seekWidgetByTag(item,37384):setString(data.liandui)
		local t=os.date("*t",public.dateTimeFromString("(%d+)/(%d+)/(%d+)%s+(%d+):(%d+):(%d+)",data.update_time))
		ccui.Helper:seekWidgetByTag(item,37385):setString(string.format("%d.%d.%d",t.year,t.month,t.day))
		ccui.Helper:seekWidgetByTag(item,37386):setString(globalSettings.subjectName[data.subject_id])
		rank.setRankItemImage(index,ccui.Helper:seekWidgetByTag(item,37378),ccui.Helper:seekWidgetByTag(item,37379))
		rank.setRankUserImage(data.user_id,data.user_name,ccui.Helper:seekWidgetByTag(item,37380))
		ccui.Helper:seekWidgetByTag(item,37382):setSelectedState(data.isVip)
	end,nil,nil,nil,refreshRank)
	listView:removeFromParent()
	--累计做对
	listView=ccui.Helper:seekWidgetByTag(self.rankView,37437)
	item=ccui.Helper:seekWidgetByTag(listView,37438)
	self.rankView.zuodui=rank.createRankView(listView:getParent(),cc.p(listView:getPosition()),listView:getContentSize(),item,nil,nil,function(item,data,index)
		ccui.Helper:seekWidgetByTag(item,37441):setString(index)
		ccui.Helper:seekWidgetByTag(item,37439):setString(data.user_name)
		ccui.Helper:seekWidgetByTag(item,37446):setString(data.right_count)
		rank.setRankItemImage(index,ccui.Helper:seekWidgetByTag(item,37440),ccui.Helper:seekWidgetByTag(item,37441))
		rank.setRankUserImage(data.user_id,data.user_name,ccui.Helper:seekWidgetByTag(item,37442))
		ccui.Helper:seekWidgetByTag(item,37444):setSelectedState(data.isVip)
	end,nil,nil,nil,refreshRank)
	listView:removeFromParent()
	--经验
	listView=ccui.Helper:seekWidgetByTag(self.rankView,37481)
	item=ccui.Helper:seekWidgetByTag(listView,37482)
	self.rankView.jingyan=rank.createRankView(listView:getParent(),cc.p(listView:getPosition()),listView:getContentSize(),item,nil,nil,function(item,data,index)
		ccui.Helper:seekWidgetByTag(item,37485):setString(index)
		ccui.Helper:seekWidgetByTag(item,37483):setString(data.user_name)
		ccui.Helper:seekWidgetByTag(item,37490):setString(data.exp)
		rank.setRankItemImage(index,ccui.Helper:seekWidgetByTag(item,37484),ccui.Helper:seekWidgetByTag(item,37485))
		rank.setRankUserImage(data.user_id,data.user_name,ccui.Helper:seekWidgetByTag(item,37486))
		ccui.Helper:seekWidgetByTag(item,37488):setSelectedState(data.isVip)
	end,nil,nil,nil,refreshRank)
	listView:removeFromParent()

	--先隐藏起来
	self.noActivity:setVisible(false)
	self.main:setVisible(false)
	self.awardView:setVisible(false)
	self.rankView:setVisible(false)
	self.rankView.liandui:setVisible(false)
	self.rankView.zuodui:setVisible(false)
	self.rankView.jingyan:setVisible(false)
	self.awardButton:setVisible(false)

	--退出按钮
	public.buttonEvent(ccui.Helper:seekWidgetByTag(layout,36873),function(sender,event)
		self:onKeyBack()
	end)

	--查看奖品按钮
	public.buttonEvent(self.awardButton,function(sender,event)
		if self.currentActivity==nil then return end

		local waiting=true
		cache.request_resources({urls={[1]={url=self.currentActivity.award_url}}},function(rtable,index,success)
			if success then
				local img=ccui.Helper:seekWidgetByTag(layout,37400)
				img:loadTexture(cache.get_name(self.currentActivity.award_url))
				self.awardView:setVisible(true)
				self.awardButton:setVisible(false)
				self.rankView:setVisible(false)
				self.text:setString(self.currentActivity.activity_name.."的奖品")
				if self.rankView.current then
					self.rankView.current:setTouchEnabled(false)
				end
			end
			waiting=false
		end)
		public.showWaiting(nil,function()
			while waiting do
				coroutine.yield()
			end
		end)
	end)

	return layout
end

--进入场景
function HuodongScene:onEnterTransitionFinish()
	--获取活动列表
	protocol.getActivityList(function(success,obj)
		if success then
			if obj then
				local serverTime=public.dateTimeFromString("(%d+)-(%d+)-(%d+).(%d+):(%d+):(%d+)",obj.serverTime)
				local list=ccui.Helper:seekWidgetByTag(self.main,36903)
				list:setBounceEnabled(true)
				local item=ccui.Helper:seekWidgetByTag(self.main,36900)
				item:retain()
				list:removeAllChildren()
				for _,v in ipairs(obj.activityList) do
					local newItem=item:clone()
					list:pushBackCustomItem(newItem)
					ccui.Helper:seekWidgetByTag(newItem,37170):setString(v.activity_name)
					if v.activity_type==1 or v.activity_type==4 then
						ccui.Helper:seekWidgetByTag(newItem,37092):loadTexture("qwxt/activity/hdxx01.png")
					elseif v.activity_type==2 then
						ccui.Helper:seekWidgetByTag(newItem,37092):loadTexture("qwxt/activity/hdxx02.png")
					elseif v.activity_type==3 then
						ccui.Helper:seekWidgetByTag(newItem,37092):loadTexture("qwxt/activity/hdxx03.png")
					end
					ccui.Helper:seekWidgetByTag(newItem,37168):setTouchEnabled(false)
					public.buttonEvent(ccui.Helper:seekWidgetByTag(newItem,36901),function(sender,event)
						self:showRank(v)
					end)
					local startTime=public.dateTimeFromString("(%d+)-(%d+)-(%d+).(%d+):(%d+):(%d+)",v.start_time)
					local endTime=public.dateTimeFromString("(%d+)-(%d+)-(%d+).(%d+):(%d+):(%d+)",v.end_time)
					if serverTime<startTime then
						ccui.Helper:seekWidgetByTag(newItem,36913):setString("活动开始时间")
						local t=os.date("*t",startTime)
						ccui.Helper:seekWidgetByTag(newItem,36915):setString(string.format("%d年%d月%d日 %02d:%02d",t.year,t.month,t.day,t.hour,t.min))
						local diff=startTime-serverTime
						local days,left=math.modf(diff/(24*3600))
						local hours=math.modf(left*24)
						ccui.Helper:seekWidgetByTag(newItem,36917):setString(string.format("离开始还有%d天%d小时",days,hours))
						ccui.Helper:seekWidgetByTag(newItem,36901):setTouchEnabled(false)
						ccui.Helper:seekWidgetByTag(newItem,38782):setVisible(false)
					else
						if serverTime>endTime then
							ccui.Helper:seekWidgetByTag(newItem,36913):setString("活动已经结束")
							ccui.Helper:seekWidgetByTag(newItem,36915):setVisible(false)
						else
							ccui.Helper:seekWidgetByTag(newItem,36913):setString("离活动结束还有")
							local diff=endTime-serverTime
							local days,left=math.modf(diff/(24*3600))
							local hours=math.modf(left*24)
							ccui.Helper:seekWidgetByTag(newItem,36915):setString(string.format("%d天%d小时",days,hours))
						end
						ccui.Helper:seekWidgetByTag(newItem,38782):setString(v.user_count.."人参与")
					end
				end
				self.main:setVisible(true)
				item:release()
			else
				self.noActivity:setVisible(true)
			end
		end
	end,{node=self.layout,text="正在获取数据......"})
end

--返回键
function HuodongScene:onKeyBack()
	if self.awardView:isVisible() then
		self.awardView:setVisible(false)
		self.awardButton:setVisible(true)
		self.rankView:setVisible(true)
		if self.rankView.current then
			self.rankView.current:setTouchEnabled(true)
		end
		self.text:setString(self.rankView.current.text)
	elseif self.rankView:isVisible() then
		self.rankView:setVisible(false)
		self.awardButton:setVisible(false)
		self.main:setVisible(true)
		self.text:setString("趣味活动")
		if self.rankView.current then
			self.rankView.current:setTouchEnabled(false)
		end
	else
		cc.Director:getInstance():popScene()
	end
end

--显示排行榜
function HuodongScene:showRank(data)
	self.rankView.liandui:setVisible(false)
	self.rankView.jingyan:setVisible(false)
	self.rankView.zuodui:setVisible(false)
	if data.activity_type==1 or data.activity_type==4 then
		self.rankView.current=self.rankView.liandui
	elseif data.activity_type==2 then
		self.rankView.current=self.rankView.jingyan
	else
		self.rankView.current=self.rankView.zuodui
	end

	if self.currentActivity~=data then
		self.currentActivity=data
		self.rankView.current:refresh()
	else
		self.text:setString(self.rankView.current.text)
	end

	self.rankView.current:setVisible(true)
	self.rankView.current:setTouchEnabled(true)
	self.rankView:setVisible(true)
	self.awardButton:setVisible(true)
	self.main:setVisible(false)
end

return HuodongScene
