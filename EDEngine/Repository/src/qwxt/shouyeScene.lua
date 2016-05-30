require "Cocos2d"
require "Cocos2dConstants"
require "qwxt/globalSettings"
require "qwxt/userInfo"
require "qwxt/music"
local public=require("qwxt/public")
local popup=require("qwxt/popup")
local protocol=require("qwxt/protocol")

local ShouyeScene=public.newScene("ShouyeScene")

--加载UI
function ShouyeScene:loadUi(uiFileName)
	local layout=ccs.GUIReader:getInstance():widgetFromJsonFile(uiFileName)
	self.expireDayText=ccui.Helper:seekWidgetByTag(layout,16860)
	self.vip=ccui.Helper:seekWidgetByTag(layout,31795)
	self.name=ccui.Helper:seekWidgetByTag(layout,38875)
	self.level=ccui.Helper:seekWidgetByTag(layout,38878)
	self.expBar=ccui.Helper:seekWidgetByTag(layout,38877)
	self.yinbi=ccui.Helper:seekWidgetByTag(layout,37695)
	self.name:setString("")
	self.level:setString("")
	self.expBar:setPercent(0)
	self.yinbi:setString(0)

	--响应设置按钮
	public.buttonEvent(ccui.Helper:seekWidgetByTag(layout,12),function(sender,event)
		self:onKeyMenu()
	end)

	--退出按钮
	public.buttonEvent(ccui.Helper:seekWidgetByTag(layout,7540),function(sender,event)
		self:onKeyBack()
	end)

	--充值按钮
	public.buttonEvent(ccui.Helper:seekWidgetByTag(layout,26106),function(sender,event)
		require("qwxt/recharge").expireTime(function(success)
			if success then self:showExpireDay() end
		end)
	end)

	--测试期隐藏充时间
	ccui.Helper:seekWidgetByTag(layout,26106):setVisible(false)
	ccui.Helper:seekWidgetByTag(layout,27026):setVisible(false)
	ccui.Helper:seekWidgetByTag(layout,16859):setVisible(false)
	ccui.Helper:seekWidgetByTag(layout,16860):setVisible(false)

	--暂时隐藏错题反馈
	ccui.Helper:seekWidgetByTag(layout,35841):setVisible(false)

	--充银币按钮
	public.buttonEvent(ccui.Helper:seekWidgetByTag(layout,37696),function(sender,event)
		require("qwxt/recharge").yinbi(function(success)
			if success then
				self.yinbi:setString(userInfo.yinbi)
			end
		end)
	end)

	--天下第一榜
	public.buttonEvent(ccui.Helper:seekWidgetByTag(layout,39987),function(sender,event)
		cc.Director:getInstance():pushScene(public.createScene("txdyb"))
	end)
	--我的奖状
	public.buttonEvent(ccui.Helper:seekWidgetByTag(layout,39983),function(sender,event)
		cc.Director:getInstance():pushScene(public.createScene("jiangzhuang"))
	end)
	--我的宝藏
	public.buttonEvent(ccui.Helper:seekWidgetByTag(layout,39985),function(sender,event)
		cc.Director:getInstance():pushScene(public.createScene("baozang"))
	end)
	--趣味活动
	public.buttonEvent(ccui.Helper:seekWidgetByTag(layout,39986),function(sender,event)
		cc.Director:getInstance():pushScene(public.createScene("huodong"))
	end)

	return layout
end

--显示用户信息
function ShouyeScene:showUserInfo()
	--加载头像
	local function showImage()
		if not self.logoLoaded then
			public.getBigLogo(userInfo.uid,function(fileName)
				userInfo.image=fileName
				ccui.Helper:seekWidgetByTag(self.layout,1398):loadTexture(userInfo.image)
				self.logoLoaded=true
			end)
		end
	end

	if not self.loaded then
		--从服务器获取数据
		local msgBoxParam=nil
		local forceOk=false
		local onMsg=nil
		local buttonImage=nil
		protocol.getUserInfo(function(success,obj)
			if success then
				--用户数据保存下来
				userInfo.name=obj.name
				userInfo.xueduan=obj.xueduan
				userInfo.expireDays=obj.expireDays
				userInfo.yinbi=obj.yinbi
				userInfo.level=obj.level
				userInfo.exp=obj.exp
				userInfo.baozangCount=obj.baozangCount
				userInfo.jiangzhuangCount=obj.jiangzhuangCount
				userInfo.shuangbei=obj.shuangbei
				music.on=obj.bgMusic.musicOn
				music.zuotiOn=obj.bgMusic.zuotiOn
				music.playBackground()
				if userInfo.xueduan<0 then
					userInfo.xueduan=2
					popup.tip("获取班级信息失败，现在使用小学学科数据进入趣味学堂")
				end
				--显示科目列表
				local layout=self.layout
				local pageView=ccui.Helper:seekWidgetByTag(layout,906)
				--根据年级确定科目列表
				local settings=globalSettings.subjectSettings
				local subjectList=settings.xueduan[userInfo.xueduan].list
				if subjectList==nil then
					popup.msgBox({text="用户数据异常！"},function(ok)
						cc.Director:getInstance():endToLua()
					end,true)
					return;
				end
				--计算图标行列
				local viewSize=pageView:getContentSize()
				local row=((#subjectList<=6 and #subjectList>4) and 3) or math.min(4,#subjectList)
				local line=((#subjectList>4) and 2) or 1
				local lineSpace=(viewSize.height-settings.imgHeight*line)/(line+1)
				local rowSpace=(viewSize.width-settings.imgWidth*row)/(row+1)
				--插入页和科目图标
				pageView:removeAllPages()
				local page=ccui.Layout:create()
				pageView:addPage(page)
				local x,y=-settings.imgWidth,viewSize.height-lineSpace-settings.imgHeight
				local t=0
				for k,v in ipairs(subjectList) do
					local fileName=v.img
					if cc.FileUtils:getInstance():isFileExist(fileName) then
						t=t+1
						if t>row then
							t=1
							x=rowSpace
							y=y-lineSpace-settings.imgHeight
							if y<=0 then
								page=ccui.Layout:create()
								y=viewSize.height-lineSpace-settings.imgHeight
								pageView:addPage(page)
							end
						else
							x=x+rowSpace+settings.imgWidth
						end
						local btn=ccui.Button:create(fileName)
						btn.data=v
						public.buttonEvent(btn,function(sender,event)
							userInfo.selectSubject(sender.data)
							cc.Director:getInstance():pushScene(public.createScene("jinrukemu"))
						end)
						btn:setAnchorPoint(0,0)
						btn:setPosition(x,y)
						page:addChild(btn)
					end
				end
				--显示页指示器
				public.addPageControl(pageView,layout)
				--登录结束了
				self.loaded=true
				self:showUserInfo()

				if obj.notStudent then
					userInfo.notStudent=true
					local s="您的成绩无法记录并参与学生排行和成绩分析！请使用学生帐号登录！"
					if obj.children then
						s=s.."关联的学生账号如下：\n"
						for _,v in ipairs(obj.children) do
							s=s.." "..v
						end
					end
					msgBoxParam={text=s,title="您使用了非学生帐号登录了‘趣味学堂’！"}
					onMsg=function(ok)
						if not ok then
							public.safeExit()
						end
					end
					buttonImage={ok="qwxt/buttons/jxtiyan.png",cancel="qwxt/buttons/genghzh.png"}
				end
			else
				msgBoxParam={text=obj}
				forceOk=true
				onMsg=function(ok)
					public.safeExit()
				end
				return true
			end
		end,{node=self.layout,text="正在获取用户资料......",onFinished=function()
			--会员有效期提示
			if userInfo.expireDays>0 and userInfo.expireDays<=3 then
				popup.msgBox({text="你的会员有效期只剩下"..userInfo.expireDays.."天了！\n\n现在就去充值吗？",title="温馨提示"},function(ok)
					if ok then
						require("qwxt/recharge").expireTime(function(success)
							if success then self:showExpireDay() end
						end)
					end
				end)
			end
			--登录提示
			if msgBoxParam~=nil then
				popup.msgBox(msgBoxParam,function(ok)
					onMsg(ok)
				end,forceOk,buttonImage)
			end
		end})
	else
		--更新会员有效期
		self:showExpireDay()
		--显示头像
		showImage()
		self.name:setString(userInfo.name)
		self.level:setString(userInfo.level.."级")
		self.expBar:setPercent(globalSettings.level.calcPercent(userInfo.level,userInfo.exp))
		self.yinbi:setString(userInfo.yinbi)
	end
end

--显示会员有效期剩余天数
function ShouyeScene:showExpireDay()
	if userInfo.expireDays>0 then
		self.vip:setSelectedState(true)
		self.expireDayText:setString(tostring(userInfo.expireDays).."天")
	else
		self.vip:setSelectedState(false)
		self.expireDayText:setString("已过期")
	end
end

--进入场景
function ShouyeScene:onEnterTransitionFinish()
	self:showUserInfo()
	self:showExpireDay()
end

--按钮响应
function ShouyeScene:onButton(id,data)
end

--菜单键和设置按钮
function ShouyeScene:onKeyMenu()
	cc.Director:getInstance():pushScene(public.createScene("shezhi"))
end

--返回键
function ShouyeScene:onKeyBack()
	popup.msgBox({title="温馨提示",text="你真的要离开了么，我会非常想你的！"},function(ok)
		if ok then
			public.safeExit()
		end
	end,false)
end

return ShouyeScene
