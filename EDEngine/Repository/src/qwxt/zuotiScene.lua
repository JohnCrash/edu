require "Cocos2d"
require "Cocos2dConstants"
require "qwxt/globalSettings"
require "qwxt/userInfo"
require "qwxt/music"
local public=require("qwxt/public")
local popup=require("qwxt/popup")
local uikits=require("uikits")
local topics=require("topics/topics")
local protocol=require("qwxt/protocol")
local cache=require("cache")

local regretPrice=0
local tip100=3

local ZuotiScene=public.newScene("ZuotiScene")

local function enableButton(button,enabled)
	button:setEnabled(enabled)
	button:setBright(enabled)
end

--加载UI
function ZuotiScene:loadUi(uiFileName)
	local layout=ccs.GUIReader:getInstance():widgetFromJsonFile(uiFileName)
	tip100=3
	
	--背景
	public.safeSetBackground(layout,"qwxt/background/zuoti/"..math.random(1,12)..".jpg")

	--名字
	ccui.Helper:seekWidgetByTag(layout,891):setString(userInfo.name)
	--头像
	local image=ccui.Helper:seekWidgetByTag(layout,894)
	if userInfo.image and cc.FileUtils:getInstance():isFileExist(userInfo.image) then
		image:loadTexture(userInfo.image)
	else
		public.getBigLogo(userInfo.uid,function(fileName)
			userInfo.image=fileName
			image:loadTexture(userInfo.image)
		end)
	end
	self.vip=ccui.Helper:seekWidgetByTag(layout,31803)
	self.vip:setSelectedState(userInfo.expireDays>0)
	self.pt=self:convertToNodeSpace(image:convertToWorldSpace(cc.p(image:getPosition())))

	self.expBar=ccui.Helper:seekWidgetByTag(layout,896)
	self.level=ccui.Helper:seekWidgetByTag(layout,915)
	self.yinbi=ccui.Helper:seekWidgetByTag(layout,903)
	self.progress=ccui.Helper:seekWidgetByTag(layout,928)
	self.liandui=ccui.Helper:seekWidgetByTag(layout,929)

	--测试代码
	public.buttonEvent(self.progress,function(sender,event)
		if self.problem~=nil then
			popup.msgBox({title="科目："..self.problem.json.course,text="旧题号："..self.problem.json.item_id_num.."\n新题号："..self.problem.item_id})
		end
	end)
	-----------

	public.safeCreateArmature("shuangbei",function(armature)
		self.shuangbeiArmature=armature
		self.shuangbeiArmature:setAnchorPoint(cc.p(0,0))
		ccui.Helper:seekWidgetByTag(layout,922):addChild(self.shuangbeiArmature)
		self.shuangbeiArmature:setVisible(false)
	end)
	
	--充值按钮
	public.buttonEvent(ccui.Helper:seekWidgetByTag(layout,3608),function(sender,event)
		--充银币
		require("qwxt/recharge").yinbi(function(success)
			if success then
				self.yinbi:setString(userInfo.yinbi)
			end
		end)
	end)

	--响应后悔药按钮
	self.houhuiyao=ccui.Helper:seekWidgetByTag(layout,920)
	public.buttonEvent(self.houhuiyao,function(sender,event)
		local function regret()
			protocol.regret(self.problem.item_id,function(success,obj)
				if success then
					if obj.expired then
						--过期了
						popup.msgBox({text="亲爱的同学，你的会员有效期已到，如想使用后悔药，请申请成为会员或输入“趣味学堂”充值卡！",title="温馨提示"},function(ok)
							if ok then
								require("qwxt/recharge").expireTime(function(success)
									if success then
										self.vip:setSelectedState(userInfo.expireDays>0)
										regret()
									end
								end)
							end
						end)
					elseif obj.yinbi then
						userInfo.yinbi=obj.yinbi
						userInfo.subjectData.liandui=obj.liandui
						self:showPersonalInfo()
						--再做一次
						self:resetContentLayout()
						self:resetAnswerField()
						self.answerType:setVisible(false)
						self.nextButton:setVisible(false)
						enableButton(self.houhuiyao,false)
						enableButton(self.xiangjie,false)
						self:showProblem(self.problem)
					else
						popup.msgBox({text="亲爱的，你的银币不足，不能使用后悔药了！不过，你还可以用乐币去兑换银币，加油吧，下次要认真看题哦！",title="温馨提示"},function(ok)
							if ok then
								require("qwxt/recharge").yinbi(function(success)
									if success then
										self.yinbi:setString(userInfo.yinbi)
									end
								end)
							end
						end)
					end
				end
			end,{node=self.contentView:getParent()})
		end
		if regretPrice>0 then
			popup.msgBox({text="吃掉“后悔药”，连对不清零，重做一次！\n\n价格："..regretPrice.."银币",title="我要忏悔一下"},function(ok)
				if ok then regret() end
			end)
		else
			regret()
		end
	end)
	enableButton(self.houhuiyao,false)
	local shuangbeiButton=ccui.Helper:seekWidgetByTag(layout,922)
	self.shuangbei=cc.Label:createWithSystemFont(text,"fonts/Marker Felt.ttf",25)
	self.shuangbei:setAnchorPoint(cc.p(1,0))
	self.shuangbei:setPosition(shuangbeiButton:getContentSize().width,0)
	shuangbeiButton:addChild(self.shuangbei)
	--响应双倍按钮
	public.buttonEvent(shuangbeiButton,function(sender,event)
		local function addShuangbei()
			protocol.newShuangbei(function(success,obj)
				if success and obj then
					if obj.expired then
						--过期了
						popup.msgBox({text="亲爱的同学，你的会员有效期已到，如想获得双倍经验和银币，请申请成为会员或输入“趣味学堂”充值卡！",title="温馨提示"},function(ok)
							if ok then
								require("qwxt/recharge").expireTime(function(success)
									if success then
										self.vip:setSelectedState(userInfo.expireDays>0)
										addShuangbei()
									end
								end)
							end
						end)
					elseif userInfo.shuangbei~=obj.shuangbei and userInfo.yinbi~=obj.yinbi then
						userInfo.shuangbei=obj.shuangbei
						userInfo.yinbi=obj.yinbi
						self.yinbi:setString(userInfo.yinbi)
						self:showShuangbei()
					else
						popup.msgBox({text="亲爱的，开启双倍是需要银币的，你银币不够了呀！不过，可以用乐币兑换银币哦！",title="提示"},function(ok)
							if ok then
								require("qwxt/recharge").yinbi(function(success)
									if success then
										self.yinbi:setString(userInfo.yinbi)
									end
								end)
							end
						end)
					end
				end
			end)
		end
		--提示充值双倍
		popup.msgBox({text="开始双倍后，做题时将得到双倍的经验与银币哦！\n100银币=10题",title="开启双倍"},function(ok)
			if ok then addShuangbei() end
		end)
	end)
	--响应详解按钮
	self.xiangjie=ccui.Helper:seekWidgetByTag(layout,924)
	public.buttonEvent(self.xiangjie,function(sender,event)
		self:showProblemAnswer()
	end)
	enableButton(self.xiangjie,false)

	--响应后退按钮
	public.buttonEvent(ccui.Helper:seekWidgetByTag(layout,890),function(sender,event)
		self:onKeyBack()
	end)

	--响应音乐开关按钮
	local musicButton=ccui.Helper:seekWidgetByTag(layout,22774)
	musicButton:setSelectedState(music.zuotiOn)
	public.selectEvent(musicButton,function(sender,event)
		local musicOn=event==ccui.CheckBoxEventType.selected
		music.turnOn(nil,musicOn)
		music.playZuoti()
	end)

	--做题界面
	self.contentView=ccui.Helper:seekWidgetByTag(layout,9820)
	self.contentSize=self.contentView:getContentSize()
	topics.set_scale(self.contentSize.width/self.contentSize.height)

	--创建一个题面布局层
	self.contentLayout=ccui.Layout:create()
	self.contentLayout:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
	self.contentLayout:setBackGroundColor(cc.c3b(0,0,0))
	self.contentLayout:setBackGroundColorOpacity(0)
	self.contentView:addChild(self.contentLayout)
	self.problemContent=ccui.Layout:create()
	self.problemContent:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
	self.problemContent:setBackGroundColor(cc.c3b(0,0,0))
	self.problemContent:setBackGroundColorOpacity(0)
	self.problemAnswer=ccui.ImageView:create()
	self.problemAnswer:setTouchEnabled(false)
	self.problemAnswer:setScale9Enabled(false)
	self.contentLayout:addChild(self.problemContent)
	self.contentLayout:addChild(self.problemAnswer)

	--答题区
	local answerField=ccui.Helper:seekWidgetByTag(layout,9799)
	self.optionImg={}
	self.answerItems={}
	self.answerField=answerField
	self.answerType=ccui.Helper:seekWidgetByTag(answerField,9801)
	--选择
	self.optionImg[1]=ccui.Helper:seekWidgetByTag(answerField,9806)
	self.optionImg[2]=ccui.Helper:seekWidgetByTag(answerField,9807)
	self.optionImg[3]=ccui.Helper:seekWidgetByTag(answerField,9808)
	self.optionImg[4]=ccui.Helper:seekWidgetByTag(answerField,9809)
	self.optionImg[5]=ccui.Helper:seekWidgetByTag(answerField,9810)
	self.optionImg[6]=ccui.Helper:seekWidgetByTag(answerField,9811)
	--填空
	self.optionEditView=ccui.Helper:seekWidgetByTag(answerField,9815)
	self.optionEdit={}
	local blank=ccui.Helper:seekWidgetByTag(self.optionEditView,9816)
	local textField=ccui.Helper:seekWidgetByTag(blank,9818)

	table.insert(self.optionEdit,blank)
	local x,y=blank:getPosition()
	for i=2,12 do
		local item=blank:clone()
		self.optionEditView:addChild(item)
		x=x+item:getContentSize().width+32
		item:setPosition(cc.p(x,y))
		local num=ccui.Helper:seekWidgetByTag(item,9817)
		if num then
			num:setString(tostring(i))
		end
		local edit=ccui.Helper:seekWidgetByTag(item,9818)
		if edit then
			edit:setPlaceHolder(textField:getPlaceHolder())
		end
		table.insert(self.optionEdit,item)
	end
	--其他题型的提示
	self.optionLink=ccui.Helper:seekWidgetByTag(answerField,9802)
	self.optionDrag=ccui.Helper:seekWidgetByTag(answerField,9803)
	self.optionSort=ccui.Helper:seekWidgetByTag(answerField,9805)
	self.optionPosition=ccui.Helper:seekWidgetByTag(answerField,9804)
	self.optionYes=ccui.Helper:seekWidgetByTag(answerField,9812)
	self.optionNo=ccui.Helper:seekWidgetByTag(answerField,9813)
	self.optionNotSupport=ccui.Helper:seekWidgetByTag(answerField,9814)

	--提交和下一题按钮
	self.nextButton=ccui.Helper:seekWidgetByTag(layout,9797)
	public.buttonEvent(self.nextButton,function(sender,event)
		self:onNext()
	end)
	self.submitButton=ccui.Helper:seekWidgetByTag(layout,9798)
	public.buttonEvent(self.submitButton,function(sender,event)
		self:onSubmit(true)
	end)
	self.nextButton:setVisible(false)
	self.submitButton:setVisible(false)

	--重置做题统计
	problemCount.reset()

	--鼠标滚轮和键盘支持
	public.addMouseScrollAndKeyboard(self.contentView,function(line,page)
		local container=self.contentView:getInnerContainer()
		local containerSize=container:getContentSize()
		local offset=cc.p(container:getPosition())
		local minOffset=cc.p(self.contentView:getContentSize().width-containerSize.width*container:getScaleX(),self.contentView:getContentSize().height-containerSize.height*container:getScaleY())
		local distance=0
		if line then
			distance=line*containerSize.height/100
		elseif page then
			distance=page*self.contentView:getContentSize().height
		end
		local newy=math.max(minOffset.y,math.min(offset.y+distance,0))
		if newy~=offset.y then
			offset.y=newy
			container:setPosition(offset)
		end
	end,function()
		self.contentView:jumpToTop()
	end,function()
		self.contentView:jumpToBottom()
	end)

	--题目内容滚动箭头
	self.upButton=ccui.Helper:seekWidgetByTag(layout,31054)
	self.upButton:setVisible(false);
	self.upButton:addTouchEventListener(function(sender,event)
		if event==ccui.TouchEventType.began then
			cc.Director:getInstance():getEventDispatcher():dispatchEvent(cc.EventKeyboard:new(cc.KeyCode.KEY_UP_ARROW,true))
		elseif event==ccui.TouchEventType.ended or event==ccui.TouchEventType.canceled then
			cc.Director:getInstance():getEventDispatcher():dispatchEvent(cc.EventKeyboard:new(cc.KeyCode.KEY_UP_ARROW,false))
		end
	end)
	self.downButton=ccui.Helper:seekWidgetByTag(layout,30315)
	self.downButton:setVisible(false);
	self.downButton:addTouchEventListener(function(sender,event)
		if event==ccui.TouchEventType.began then
			cc.Director:getInstance():getEventDispatcher():dispatchEvent(cc.EventKeyboard:new(cc.KeyCode.KEY_DOWN_ARROW,true))
		elseif event==ccui.TouchEventType.ended or event==ccui.TouchEventType.canceled then
			cc.Director:getInstance():getEventDispatcher():dispatchEvent(cc.EventKeyboard:new(cc.KeyCode.KEY_DOWN_ARROW,false))
		end
	end)

	--反馈按钮，待修改
	ccui.Helper:seekWidgetByTag(layout,34286):setVisible(false)
	ccui.Helper:seekWidgetByTag(layout,35052):setVisible(false)

	return layout
end

--显示双倍动画
function ZuotiScene:showShuangbei()
	self.shuangbei:setString(userInfo.shuangbei)
	if userInfo.shuangbei and userInfo.shuangbei>0 then
		self.shuangbeiArmature:setVisible(true)
		self.shuangbeiArmature:getAnimation():play("Animation1")
	else
		self.shuangbeiArmature:setVisible(false)
		self.shuangbeiArmature:getAnimation():stop()
	end
end

--显示个人信息
function ZuotiScene:showPersonalInfo()
	self.expBar:setPercent(globalSettings.level.calcPercent(userInfo.level,userInfo.exp))
	self.progress:setString(string.format("%d%%",math.modf(userInfo.classData.progress)))
	self.level:setString(userInfo.level.."级")
	self.yinbi:setString(userInfo.yinbi)
	self.liandui:setString((userInfo.subjectData.liandui~=nil and userInfo.subjectData.liandui) or "0")
	self:showShuangbei()
end

--进入场景
function ZuotiScene:onEnterTransitionFinish()
	music.playZuoti()
	self:showPersonalInfo()
	--直接出题
	self:onNext()
end

--返回键
function ZuotiScene:onKeyBack()
	popup.msgBox({text="你真的要离开了么，我会非常想你的！",title="温馨提示"},function(ok)
		if ok then
			cc.Director:getInstance():replaceScene(public.createScene("zuotijieshu"))
		end
	end)
end

--重置答题区
function ZuotiScene:resetAnswerField()
	for i=1,#self.optionImg do
		self.optionImg[i]:setVisible(false)
	end
	self.optionEditView:setVisible(false)
	self.optionEditView:jumpToLeft()
	for i=1,#self.optionEdit do
		self.optionEdit[i]:setVisible(false)
	end
	self.optionLink:setVisible(false)
	self.optionYes:setVisible(false)
	self.optionNo:setVisible(false)
	self.optionDrag:setVisible(false)
	self.optionSort:setVisible(false)
	self.optionPosition:setVisible(false)
	self.optionNotSupport:setVisible(false)

	self.answerField:setEnabled(false)
end

--显示题目
function ZuotiScene:showProblem(data,retry)
	retry=retry or 3

	--设置答题区
	local t=data.json.item_type
	if topics.types[t] and topics.types[t].img and topics.types[t].init then
		data._isdone_=false
		data.topics_answer_image_name=nil

--			--把多答案转换成单一答案
--			local function toSingleAnswer(answer)
--				--如果答案里没有_直接返回就可以了
--				if not string.find(answer,"_") then return answer end
--				--答案可能是用;分割的
--				local answers={}
--				string.gsub(answer,"[^;]+",function(w)
--					table.insert(answers,w)
--				end)
--				--去掉_以及后面的字符
--				for k=1,#answers do
--					local index=string.find(answers[k],"_")
--					if index then answers[k]=string.sub(answers[k],1,index-1) end
--				end
--				--组成单一答案
--				local result=answers[1]
--				for i=2,#answers do
--					result=result..";"..answers[i]
--				end

--				return result
--			end
--			--填答案
--			data.my_answer={}
--			for i=1,#data.answer do
--				data.my_answer[i]=toSingleAnswer(data.answer[i].value)
--			end

		self.answerType:loadTexture(topics.types[t].img)
		--设置题的提示文字
		if t==4 then
			self.optionLink:setVisible(true)
		elseif t==8 or t==7 then
			self.optionSort:setVisible(true)
		elseif t== 9 or t==10 then
			self.optionPosition:setVisible(true)
		elseif t==11 or t==12 then
			self.optionDrag:setVisible(true)
		end
		--设置答题区控件
		if t==1 then --判断
			data._options={}
			data._options[1]=self.optionYes
			data._options[2]=self.optionNo
		elseif t==2 or t==3 or t==6 then --单选,多选
			data._options={}
			for i=1,#self.optionImg do
				data._options[i]=self.optionImg[i]
			end
		elseif t==5 then --填空
			self.optionEditView:setVisible(true)
			data._options={}
			for i=1,#self.optionEdit do
				data._options[i]=self.optionEdit[i]
			end
		end
		--data.eventAnswer=function(layout,data)
		--end
		data.eventInitComplate=function(layout,data,success)
			if not success then
				self:resetContentLayout()
				if retry>0 then
					--重试获取资源
					self:showProblem(data,retry-1)
				else
					--重试次数到了
					popup.msgBox({title="温馨提示",text="获取题目资源失败\n\n点击确定按钮更换题目，点击取消按钮退出练习。"},function(ok)
						if ok then
							self:onNext()
						else
							cc.Director:getInstance():replaceScene(public.createScene("zuotijieshu"))
						end
					end)
				end
				return
			end

			self.contentLayout:setContentSize(layout:getContentSize())
			self.problemContent:setPosition(cc.p(0,layout:getContentSize().height/2))
			self:showProblemContent()

			--题目显示出来才允许答题
			self.answerType:setVisible(true)
			self.answerField:setEnabled(true)
			self.submitButton:setVisible(true)
		end
		topics.types[t].init(self.problemContent,data)
	else
		--不支持的类型
		if  topics.types[t] and topics.types[t].name then
			kits.log( "Can't support type "..t.."	name : "..topics.types[t].name )
		else
			kits.log( "Can't support type "..t )
		end
		self.optionNotSupport:setVisible(true)
	end
end

--重置内容区
function ZuotiScene:resetContentLayout()
	self.contentView:setInnerContainerSize(self.contentSize)

	self.contentLayout:setScale(1)
	self.contentLayout:setAnchorPoint(0,0.5)
	self.contentLayout:setContentSize(cc.size(self.contentSize.width,0))
	self.contentLayout:setPosition(cc.p(0,self.contentSize.height/2))

	self.problemContent:removeAllChildren()
	self.problemContent:setScale(1)
	self.problemContent:setAnchorPoint(0,0.5)
	self.problemContent:setContentSize(cc.size(self.contentSize.width,0))
	self.problemContent:setPosition(cc.p(0,0))
	self.problemAnswer:setVisible(false)

	self.upButton:setVisible(false)
	self.downButton:setVisible(false)
end

--下一题按钮
function ZuotiScene:onNext()
	--重置内容区
	self:resetContentLayout()
	--重置答题区
	self:resetAnswerField()
	self.answerType:setVisible(false)
	self.nextButton:setVisible(false)
	enableButton(self.houhuiyao,false)
	enableButton(self.xiangjie,false)
	--请求出题
	self:getProblem()
end

--请求出题
function ZuotiScene:getProblem()
	protocol.getProblem(userInfo.subjectData.id,userInfo.classData.id,userInfo.classData.nodeType,function(success,obj)
		if success and obj then
			if obj.expired then
				--过期了
				popup.msgBox({text="亲爱的同学，你的会员有效期已到，如想继续在这个关卡学习，请申请成为会员或输入“趣味学堂”充值卡！",title="温馨提示"},function(ok)
					if ok then
						require("qwxt/recharge").expireTime(function(success)
							if success then
								self.vip:setSelectedState(userInfo.expireDays>0)
								self:getProblem()
							else
								cc.Director:getInstance():popScene()
							end
						end)
					else
						cc.Director:getInstance():popScene()
					end
				end)
			else
				self.problem=nil
				local data={}
				if topics.types[obj.item_type].conv(obj,data) then
					data.json=obj
					self.problem=data
					self:showProblem(self.problem)
				end
			end
		end
	end,{node=self.contentView:getParent(),text="请等待出题......."})
end

--提交按钮
function ZuotiScene:onSubmit(check)
	if check then
		--检查有没有完成答题
		local completed=true
		if self.problem.my_answer==nil or #self.problem.my_answer<=0 or self.problem.state~=topics.STATE_FINISHED then
			completed=false
		else
			for i=1,#self.problem.my_answer do
				if self.problem.my_answer[i]==nil or self.problem.my_answer[i]=="" then
					completed=false
				end
			end
		end
		if not completed then
			popup.msgBox({title="温馨提示",text="你还没有完成答题，就这样提交吗？"},function(ok)
				if ok then self:onSubmit(false) end
			end)
			return 
		end
	end

	--隐藏提交按钮
	self.submitButton:setVisible(false)
	--禁止内容区子控件的操作
	for _,v in pairs(self.problemContent:getChildren()) do
		if v.setEnabled then v:setEnabled(false) end
	end
	--禁止答题区控件操作
	self.answerField:setEnabled(false)

	--提交答案
	local data=nil
	--为了防止json编码时把字符串变成数字，每一个答案项在末尾添加一个识别符
	local myAnswer=nil
	if type(self.problem.my_answer)=="table" then
		myAnswer={}
		for k,v in pairs(self.problem.my_answer) do
			myAnswer[k]=v.."~"
		end
	else
		myAnswer=self.problem.my_answer.."~"
	end
	protocol.submitAnswer(self.problem.item_id,myAnswer,function(success,obj)
		if success and obj then
			data=obj
		end
	end,{node=self.contentView:getParent(),onFinished=function()
		if data~=nil then
			--添加做题统计
			problemCount.addCount(data.yinbi-userInfo.yinbi,data.exp-userInfo.exp,data.right)

			local animationParam=
			{
				result=true,		--播放答题结果动画和音效
				pass=true,			--播放通关动画和音效
				level=true,			--播放升级动画和音效
				baozang=true,		--播放获得宝藏动画
				jiangzhuang=true,	--播放获得奖状动画
				liandui=true,		--播放连对动画
			}
			local passMsg=false
			local function resultProcess(param)
				--顺序播放弹出动画和音效
				if param.result then
					--是否答对
					param.result=false
					if data.right then
						music.playEffect("right")
						popup.showAnimation(self,"success","success",function()
							resultProcess(param)
						end)
					else
						music.playEffect("wrong")
						popup.showAnimation(self,"success","fail",function()
							resultProcess(param)
						end)
					end
					return
				end
				if param.liandui then
					--连对动画
					param.liandui=false
					if userInfo.subjectData.liandui~=data.liandui then
						local list={[10]=true,[20]=true,[30]=true,[50]=true,[100]=true,[200]=true,[300]=true,[400]=true,[500]=true,[600]=true,[700]=true,[800]=true,[900]=true,[1000]=true}
						if list[data.liandui] then
							music.playEffect("liandui")
							popup.showAnimation(self,"liandui",tostring(data.liandui),function()
								resultProcess(param)
							end)
							return
						end
					end
				end
				if param.pass then
					--是否通关
					param.pass=false
					if data.progress and data.progress==100 and data.right then
						if userInfo.classData.progress<100 then
							--显示通关动画
							music.playEffect("pass")
							popup.showAnimation(self,"tanchu","dyguoguan",function()
								passMsg=true
								resultProcess(param)
							end)
							return
						elseif tip100>0 then
							--不能获得经验和银币，提示一下
							popup.tip("完成度已达到100%，无法再获得银币和经验！")
							tip100=tip100-1
						end
					end
				end
				if param.level then
					--是否升级
					param.level=false
					if data.level and data.level>userInfo.level then
						music.playEffect("levelup")
						popup.showAnimation(self,"tanchu","shengji",function()
							resultProcess(param)
						end)
						return
					end
				end

				--创建一个动画，从0.1倍放大到1.5倍，然后曲线移动到头像处，移动过程中同时旋转并缩小到0.1倍。动画结束后删除精灵并执行回调函数
				local function spriteAnimation(sp,callback)
					local sx,sy=sp:getPosition()
					local ex=self.pt.x+50
					local ey=self.pt.y+150
					local bezier=
					{
						cc.p(sx,sy),
						cc.p(sx+(ex-sx)*0.5,sy+(ey-sy)*0.5+100),
						self.pt,
					}
					sp:setScale(0.1)
					local action=cc.Sequence:create(cc.ScaleTo:create(0.5,1.2),cc.DelayTime:create(1),cc.Spawn:create(cc.ScaleTo:create(1.5,0.1),cc.RotateTo:create(1.5,1080),cc.BezierTo:create(1.5,bezier)))
					sp:runAction(cc.Sequence:create(action,cc.CallFunc:create(function()
						sp:removeFromParent()
						if callback then callback() end
					end)))
				end
				if param.baozang then
					--是否获得宝藏
					param.baozang=false
					if data.newBaozang and data.newBaozang>0 then
						public.safeCreateArmature("baozang",function(armature)
							music.playEffect("pass")
							popup.tip("获得宝藏："..globalSettings.baozangList["s"..data.newBaozang].name)
							armature:getAnimation():play("s"..data.newBaozang)
							armature:setAnchorPoint(cc.p(0.5,0.5))
							armature:setPosition(self:getContentSize().width/2,self:getContentSize().height/2)
							self:addChild(armature)
							spriteAnimation(armature,function()
								resultProcess(param)
							end)
						end)
						return
					end
				end
				if param.jiangzhuang then
					--是否获得奖状
					if data.newJiangzhuang and #data.newJiangzhuang>0 then
						local img=ccui.ImageView:create(globalSettings.jiangzhuangList[data.newJiangzhuang[1]].image)
						if img then
							music.playEffect("levelup")
							popup.tip("获得奖状："..globalSettings.jiangzhuangList[data.newJiangzhuang[1]].name)
							img:setAnchorPoint(cc.p(0.5,0.5))
							img:setPosition(self:getContentSize().width/2,self:getContentSize().height/2)
							self:addChild(img)
							spriteAnimation(img,function()
								table.remove(data.newJiangzhuang,1)
								resultProcess(param)
							end)
							return
						else
							table.remove(data.newJiangzhuang,1)
							resultProcess(param)
						end
					else
						param.jiangzhuang=false
					end
				end

				--弹出动画播放完毕，处理其他事情
				--答错了后悔药允许使用
				if not data.right then
					enableButton(self.houhuiyao,true)
					regretPrice=data.regrePrice or regretPrice
				end
				--答完题可以查看详解
				enableButton(self.xiangjie,true)
				--用户数据更新
				userInfo.exp=data.exp
				userInfo.level=data.level
				userInfo.yinbi=data.yinbi
				userInfo.expireDays=data.expireDays
				self.vip:setSelectedState(userInfo.expireDays>0)
				userInfo.shuangbei=data.shuangbei
				userInfo.subjectData.liandui=data.liandui
				userInfo.classData.progress=data.progress
				userInfo.classData.totalCount=data.totalCount
				userInfo.classData.rightCount=data.rightCount
				userInfo.unitData.progress=data.unitProgress
				userInfo.unitData.totalCount=data.unitTotalCount
				userInfo.unitData.rightCount=data.unitRightCount
				if data.openTest then
					if userInfo.classData.nodeType==3 then
						--秘境探险打开
						table.insert(userInfo.unitData.classes,
						{
							id=userInfo.unitData.id,
							name="秘境探险",
							progress=0,
							totalCount=0,
							rightCount=0,
							nodeType=2
						})
					elseif userInfo.classData.nodeType==2 then
						--神秘宝屋打开
						table.insert(userInfo.bookData.units,
						{
							id=userInfo.bookData.id,
							name="神秘宝屋",
							progress=0,
							totalCount=0,
							rightCount=0,
							nodeType=1
						})
					end
				end
				self:showPersonalInfo()
				--下一题按钮显示
				self.nextButton:setVisible(true)
				if passMsg then
					--通关提示
					popup.msgBox({title="通关提示",text="完成度已达到100%，继续答题将无法再获得银币和经验\n\n选择另外的关卡吗？"},function(ok)
						if ok then cc.Director:getInstance():popScene() end
					end)
				end
			end
			--处理结果
			resultProcess(animationParam)
		else
			--通讯失败可以再次提交
			self.submitButton:setVisible(true)
			for _,v in pairs(self.problemContent:getChildren()) do
				if v.setEnabled then v:setEnabled(true) end
			end
			self.answerField:setEnabled(true)
		end
	end})
end

function ZuotiScene:showProblemContent(noScroll)
	local layoutSize=self.contentLayout:getContentSize()
	if layoutSize.height<=self.contentSize.height then
		self.contentView:setInnerContainerSize(self.contentSize)
		self.contentLayout:setPosition(cc.p(0,self.contentSize.height/2))
	else
		local maxDelta=self.contentSize.height*2/3
		if noScroll then
			maxDelta=self.contentSize.height*4/3
		end
		if layoutSize.height-self.contentSize.height>maxDelta then
			layoutSize.height=layoutSize.height+2*self.upButton:getContentSize().height
			self.contentView:setInnerContainerSize(layoutSize)
			self.contentLayout:setPosition(cc.p(0,layoutSize.height/2))
			if noScroll==nil then
				self.contentView:jumpToTop()
			else
				self.contentView:jumpToBottom()
			end
			self.upButton:setVisible(true)
			self.downButton:setVisible(true)
		else
			--超的不是太多，稍微缩一下，尽量一屏显示
			local scale=(self.contentSize.height-16)/layoutSize.height
			self.contentLayout:setScale(scale)
			self.contentLayout:setAnchorPoint(0.5,0.5)
			self.contentView:setInnerContainerSize(self.contentSize)
			self.contentLayout:setPosition(cc.p(self.contentSize.width/2,self.contentSize.height/2))
		end
	end
end

function ZuotiScene:showProblemAnswer()
	local url="http://imagecdn.lejiaolexue.com/item_preview/"..self.problem.item_id.."_1.jpg"
	local waiting=true
	cache.request_nc(url,function(success)
		if success then
			self.problemAnswer:loadTexture(cache.get_name(url))
			local scale=topics.get_scale()
			if self.problemAnswer:getContentSize().width*scale>self.contentLayout:getContentSize().width then
				scale=self.contentLayout:getContentSize().width/self.problemAnswer:getContentSize().width
			end
			self.problemAnswer:setScaleX(scale)
			self.problemAnswer:setScaleY(scale)

			local size=self.problemContent:getContentSize()
			local h=self.contentLayout:getBoundingBox().height
			size.height=size.height+self.problemAnswer:getBoundingBox().height+2
			self.contentLayout:setContentSize(size)

			self.problemContent:setAnchorPoint(cc.p(0,0))
			self.problemContent:setPosition(cc.p(0,self.problemAnswer:getBoundingBox().height+1))
			self.problemAnswer:setAnchorPoint(cc.p(0,0))
			self.problemAnswer:setPosition(cc.p(0,0))
			self.problemAnswer:setVisible(true)

			self.contentLayout:setScale(1)
			self.contentLayout:setAnchorPoint(0,0.5)
			self:showProblemContent(h<=self.contentSize.height)
		
			enableButton(self.xiangjie,false)
		end
		waiting=false
	end,fileName)
	public.showWaiting(self.contentView:getParent(),function()
		while waiting do
			coroutine.yield()
		end
	end)
end

return ZuotiScene