local kits = require "kits"
local uikits = require "uikits"
local base = require "base"

local ui = {
	SPLASH_FILE = "res/splash/splash_1.json",
	LOADING_FILE = "res/splash/laoding_1.json",
	SPLASH_IMAGE = "Image_5",
	SPLASH_TEXT = "Label_4",
	SPLASH_TEXT_SHADOW="Label_4_0",
	LOADING_PROGRESSBAR = "Panel_12",
	LOADING_PROGRESSBAR_BG = "Image_8",
	LOADING_PROGRESSBAR_SP = "Image_13",
	LOADING_TEXT = "Label_2",
	LOADING_TEXT_SHADOW="Label_2_0",
	MESSAGEBOX_FILE = "res/splash/messagebox.json",
	BUTTON_OK = "Button_5",
	CAPTION_TEXT = "Label_8",
	MESSAGE_TEXT = "Label_7",
	SPIN_IMAGE = "res/splash/009.png",
	PROGRESS_BOX = "res/splash/progressbox.json",
	PROGRESS_TEXT = "Label_9",
}

local root = {
	classid = base.root,
	name = "Root",
	icon = "res/splash/root_icon.png",
	comment = "所有对象都是它的子类",
	version = 1,
	class = {
		getR = function(self,res)
			local function resFile( classid )
				if classid then
					local resfile = "class/"..classid.."/"..res
					if kits.local_exists(resfile) then
						return resfile
					end
				end				
			end
			
			if self._cls then
				local cr = resFile( self._cls.classid )
				if cr then
					return cr
				end
				cr = resFile( self._cls.superid )
				if cr then
					return cr
				end
				if self._cls.pedigree then
					for k,v in pairs(self._cls.pedigree) do
						cr = resFile( v )
						if cr then
							return cr
						end
					end
				end
			end
			return res
		end,
		isInstanceOf = function(self,A)
			local cls = self._cls
			if cls then
				if cls.classid == A or cls.superid == A then
					return true
				end
				if cls.pedigree then
					for k,v in pairs(cls.pedigree) do
						if v == A then return true end
					end
				end
			end
		end,
		test = function(self)
			kits.log("root test function")
		end,		
	},
}

local Scene = {
	classid = base.Scene,
	superid = base.root,
	name = "Scene",
	icon = "res/splash/scene_icon.png",
	comment = "场景",
	version = 1,
	class = {
		__init__ = function(self)
				self._scene = cc.Scene:create()
				local function onNodeEvent(event,v)
					if "enter" == event then
						self:init()
					elseif "exit" == event then
						self:release()
					end
				end	
				self._scene:registerScriptHandler(onNodeEvent)			
			end,
		addChild = function(self,child)
			if child._layer then
				self._scene:addChild(child._layer)
			elseif child._widget then
				self._scene:addChild(child._widget)
			else
				self._scene:addChild(child)
			end
		end,
		ccScene = function(self)
			return self._scene
		end,
		push = function(self)
			uikits.pushScene(self._scene)
		end,
		pop = function(self)
			if self._scene then	
				uikits.popScene()
			end
		end,		
		replace = function(self)
				uikits.replaceScene(self._scene)
		end,
		init = function(self)
		end,
		release = function(self)
		end,
		test = function(self)
			self:push()		
		end,
	}
}

local Layer = {
	classid = base.Layer,
	superid = base.root,
	name = "Layer",
	icon = "res/splash/layer_icon.png",
	comment = "一个场景可以有多个层",
	version = 1,
	class = {
		__init__ = function(self)
				self._layer = cc.Layer:create()
				local function onNodeEvent(event,v)		
					if "enter" == event then
						self:init()
					elseif "exit" == event then
						self:release()
					end
				end	
				self._layer:registerScriptHandler(onNodeEvent)			
			end,
		addChild = function(self,child)
			if child._widget then
				self._layer:addChild(child._widget)
			else
				self._layer:addChild(child)
			end
		end,	
		ccLayer = function(self)
			return self._layer
		end,
		init = function(self)
		end,
		release = function(self)
		end,
		test=function(self)
			local factory = require "factory"
			local scene = factory.create(base.Scene)
			scene:addChild(self)
			scene:push()
		end,
	}
}

local splashScene = {
	classid = base.SplashScene,
	superid = base.Scene,
	pedigree={
		base.root
	},
	name = "SplashScene",
	icon = "res/splash/splash_icon.png",
	comment = "创建一个等待屏直到任务结束",
	version = 1,
	class = {
		__init__ = function(self)
			self.super.__init__(self)
			self._splash = uikits.fromJson{file=self:getR(ui.SPLASH_FILE)}
			self._scene:addChild(self._splash)
			self._text = uikits.child(self._splash,ui.SPLASH_TEXT)
			self._text_shadow = uikits.child(self._splash,ui.SPLASH_TEXT_SHADOW)
			self._spin = uikits.child(self._splash,ui.SPLASH_IMAGE)		
			self._scheduler = self._scene:getScheduler()		
			self:setText("")			
		end,
		push = function(self)
			self._oldDR=uikits.getDR()
			self.super.push(self)
		end,
		init = function(self)
			uikits.initDR{width=960,height=540,mode=cc.ResolutionPolicy.SHOW_ALL}
			local angle = 0
			local N = 12
			local function spin()
				self._spin:setRotation( angle )
				angle = angle + 360/N
			end
			self._schedulerId = self._scheduler:scheduleScriptFunc(spin,0.8/N,false)	
		end,
		release = function(self)
			if self._schedulerId then
				uikits.initDR(self._oldDR)
				self._scheduler:unscheduleScriptEntry(self._schedulerId)
				self._schedulerId = nil
			end
		end,
		setText = function(self,txt)
			self._text:setString(txt)
			self._text_shadow:setString(txt)
		end,
		test = function(self)
			self:push()
			self:setText("测试")
			for i=1,10 do
				uikits.delay_call(nil,function()
					self:setText("进度:"..tostring(i*10).."%")
					end,3*i/10)
			end					
			uikits.delay_call(nil,function()self:pop()end,3.5)			
		end,
	}
}

local loadingScene = {
	classid = base.LoadingScene,
	superid = base.Scene,
	pedigree={
		base.root
	},
	name = "LoadingScene",
	icon = "res/splash/loadingscene_icon.png",
	comment = "创建一个具有进度条的加载屏",
	version = 1,
	class = {
		__init__ = function(self)
			self.super.__init__(self)
			self._loading = uikits.fromJson{file=self:getR(ui.LOADING_FILE)}
			self._scene:addChild(self._loading)
			self._text = uikits.child(self._loading,ui.LOADING_TEXT)
			self._text_shadow = uikits.child(self._loading,ui.LOADING_TEXT_SHADOW)
			self._progress = uikits.child(self._loading,ui.LOADING_PROGRESSBAR)
			self._progress_bg = uikits.child(self._loading,ui.LOADING_PROGRESSBAR_BG)
			self._size = self._progress_bg:getContentSize()
			self._size.width = self._size.width -5
			self._size.height = self._size.height -6	
			self._sp = uikits.child(self._progress,ui.LOADING_PROGRESSBAR_SP)
			self._sps = {}		
			table.insert(self._sps,self._sp)
			local ox,oy = self._sp:getPosition()
			for i=1,14 do
				local s = self._sp:clone()
				s:setPosition(cc.p(ox+i*28,oy))
				self._progress:addChild( s )
				table.insert(self._sps,s)
			end
			self:setProgress(0)		
			self:setText("")
			self._scheduler = self._scene:getScheduler()				
		end,
		push = function(self)
			self._oldDR = uikits.getDR()
			self.super.push(self)
		end,
		init = function(self)
			uikits.initDR{width=960,height=540,mode=cc.ResolutionPolicy.SHOW_ALL}
			local dx = 0
			local d = 2	
			local function spin()
				uikits.move(self._sps,-3,0)
				dx = dx + 3
				if dx >= 30 then
					dx = 0
					uikits.move(self._sps,30,0)
				end
			end				
			self._schedulerId = self._scheduler:scheduleScriptFunc(spin,0.02,false)	
		end,
		release = function(self)
			if self._schedulerId then
				uikits.initDR(self._oldDR)
				self._scheduler:unscheduleScriptEntry(self._schedulerId)
				self._schedulerId = nil
				self._text = nil
				self._progress = nil
			end		
		end,
		setProgress = function( self,d )
			if self._progress then
				self._progress:setContentSize(cc.size(self._size.width*d,self._size.height))
			end
		end,
		setText = function( self,txt )
			if self._text then
				self._text:setString(txt)
				self._text_shadow:setString(txt)
			end
		end,
		test = function(self)
			self:push()
			local count = 4*20
			local i = 0
			local function progress()
				i=i+1
				self:setProgress(i/count)
				self:setText("进度:"..tostring(math.floor(i/count*100)).."%")
				if i > count then
					self._scheduler:unscheduleScriptEntry(self._testId)
					self:pop()
				end
			end
			self._testId = self._scheduler:scheduleScriptFunc(progress,1/20,false)
		end,
	}
}

local Dialog = {
	classid = base.Dialog,
	superid = base.root,
	name = "Dialog",
	icon = "res/splash/dialog_icon.png",
	comment = "对话栏基类",
	version = 1,
	class = {
		open = function(self,t)
		end,
		close = function(self)
			if self._root then
				self._root:removeFromParent()	
				self._root = nil
				if self._needpop	then
					uikits.popScene()
				end
			end
		end,
		modal = function(self,box)
			local director = cc.Director:getInstance()
			local scene = director:getRunningScene()
			local size = uikits.getDR()
			box:setPosition(cc.p(size.width/2,size.height/2))
			box:setAnchorPoint(cc.p(0.5,0.5))			
			if scene then
				self._scene = scene
				self._root = ccui.Layout:create()
				self._root:addChild(box)
				scene:addChild(self._root)
				self._root:setTouchEnabled(true)
				self._root:setContentSize(uikits.getDR())
			else
				self._scene = cc.Scene:create()
				self._scene:addChild(box)
				self._root = box
				self._needpop = true
				uikits.pushScene(self._scene)
			end		
		end,
		test = function(self)
			self:open()
		end,
	}
}

local messageBox = {
	classid = base.MessageBox,
	superid = base.Dialog,
	pedigree = {
		base.root
	},
	name = "MessageBox",
	icon = "res/splash/messagebox_icon.png",
	comment = "创建一个等待屏直到任务结束",
	version = 1,
	class = {
		open = function(self,t)
			if not t then return end
			self._box = uikits.fromJson{file=self:getR(ui.MESSAGEBOX_FILE)}
			self._text = uikits.child(self._box,ui.MESSAGE_TEXT)
			self._caption = uikits.child(self._box,ui.CAPTION_TEXT)
			self._ok = uikits.child(self._box,ui.BUTTON_OK)
			self._caption:setString( t.caption or "" )
			self._texts = {}
			self._buttons = {}
			if t.text and type(t.text)=='string' then
				local txt = self._text:clone()
				txt:setString( t.text )
				self._box:addChild(txt)
				table.insert(self._texts,txt)
			elseif t.text and type(t.text)=='table' then
				for k=#t.text,1,-1 do
					local v = t.text[k]
					local txt = self._text:clone()
					txt:setString(v)
					self._box:addChild(txt)
					table.insert(self._texts,txt)
				end
			end
			self._text:setVisible(false)
			local function click(i,v)
				if self._root then
					uikits.delay_call(parent,function()	
												self:close()
												if t.onClick then
													t.onClick(i,v)
												end													
											end,0)	
				end
			end
			if t.button and type(t.button)=='number' then
				local bt={"确定","取消","重试"}
				for i = 1,t.button do
					local but
					if i==1 then
						but = self._ok
					else
						but = self._ok:clone()
						self._box:addChild(but)
					end
					but:setTitleText(tostring(bt[i]))
					uikits.event(but,function()
						click(i,bt[i])
					end)
					table.insert(self._buttons,but)					
				end
			elseif t.button and type(t.button)=='table' then
				for i,v in pairs(t.button) do
					local but
					if i==1 then
						but = self._ok
					else
						but = self._ok:clone()
						self._box:addChild(but)
					end
					but:setTitleText(tostring(v))
					uikits.event(but,function()
						click(i,tostring(v))
					end)					
					table.insert(self._buttons,but)					
				end
			end
			self:relayout()
			self:modal(self._box)
		end,
		relayout=function(self)
			local bhspace = 20 --按钮中的文字和边框两侧的间隔
			local bvspace = 16 --上下的间隔
			local space = 16
			local title_height = 56
			local H,W = space,space
			local BW,BH = 0,0
			--计算需要的空间
			for i,v in pairs(self._buttons) do
				local txt = v:getTitleText()
				self._text:setString(txt)
				local size = self._text:getContentSize()
				size.width = size.width+bhspace*2
				size.height = size.height+bvspace*2
				v:setContentSize(size)
				W = W+size.width+space
				if i==1 then
					H = H+size.height+space
				end
			end
			BW = W-2*space
			BH = H
			for i,v in pairs(self._texts) do
				local size = v:getContentSize()
				W = math.max(W,size.width+2*space)
				H = H+size.height+space
			end
			local box_size = cc.size(W,H+title_height)
			self._box:setContentSize(box_size)
			--开始布局按钮
			local ox = (W-BW)/2
			for i,v in pairs(self._buttons) do
				local x,y = v:getPosition()
				local size = v:getContentSize()
				v:setPosition(cc.p(ox,y))
				ox = ox+size.width+space
			end
			--布局文本
			local oy = BH
			for i,v in pairs(self._texts) do
				local x,y = v:getPosition()
				local size = v:getContentSize()
				v:setPosition(cc.p(x,oy))
				oy = oy+size.height+space
			end
			--放置标题
			self._caption:setPosition(cc.p(W/2,H+title_height/2))
			self._caption:setFontName("simhei")
			--居中放置消息栏
			local s = uikits.getDR()
			self._box:setPosition((s.width-box_size.width)/2,(s.height-box_size.height)/2)
		end,
		test = function(self)
			self:open{caption="提示",text={"1.第一行提示","2.第二行提示...","3.随着云时代的到来，大数据也吸引了越来越多多关注。"},
					button={"选择1","选择2","选择3","选择4"},onClick=function(i,txt)
					print(tostring(i)..":"..txt)
			end}
		end,
	}
}

local Spin ={
	classid = base.Spin,
	superid = base.Dialog,
	pedigree={
		base.root
	},
	name = "Spin",
	icon = "res/splash/splash_icon.png",
	comment = "在屏幕中间加入一个旋转圈用来等待一个任务",
	version = 1,
	class = {
		open=function(self)
			self._image = uikits.image{image=ui.SPIN_IMAGE}
			self:modal(self._image)
			local angle = 0
			local N = 12
			local function spin()
				self._image:setRotation( angle )
				angle = angle + 360/N
			end
			self._scheduler = self._root:getScheduler()			
			self._schedulerId = self._scheduler:scheduleScriptFunc(spin,0.8/N,false)	
		end,
		close=function(self)
			self.super.close(self)
			if self._schedulerId then
				self._scheduler:unscheduleScriptEntry(self._schedulerId)
			end
		end,
		test=function(self)
			self:open()
			uikits.delay_call(nil,function()self:close()end,3.5)
		end,
	}
}

local ProgressBox={
	classid = base.ProgressBox,
	superid = base.Dialog,
	pedigree = {
		base.root
	},	
	name = "ProgressBox",
	icon = "res/splash/progressbox_icon.jpg",
	comment = "一个有进度条的对话栏",
	version = 1,
	class = {
		open=function(self,t)
			self._box = uikits.fromJson{file=self:getR(ui.PROGRESS_BOX)}
			self._text = uikits.child(self._box,ui.PROGRESS_TEXT)
			self._progress = uikits.child(self._box,ui.LOADING_PROGRESSBAR)
			self._progress_bg = uikits.child(self._box,ui.LOADING_PROGRESSBAR_BG)
			self._size = self._progress_bg:getContentSize()
			self._size.width = self._size.width -6
			self._size.height = self._size.height -7	
			self._sp = uikits.child(self._progress,ui.LOADING_PROGRESSBAR_SP)
			self._box:setScaleX(2)
			self._box:setScaleY(2)
			self:modal(self._box)
			self._sps = {}
			table.insert(self._sps,self._sp)
			local ox,oy = self._sp:getPosition()
			for i=1,14 do
				local s = self._sp:clone()
				s:setPosition(cc.p(ox+i*28,oy))
				self._progress:addChild( s )
				table.insert(self._sps,s)
			end
			self:setProgress(0)
			self._scheduler = self._root:getScheduler()
			local dx = 0
			local d = 2
			local function spin()
				uikits.move(self._sps,-3,0)
				dx = dx + 3
				if dx >= 30 then
					dx = 0
					uikits.move(self._sps,30,0)
				end
			end
			self._schedulerId = self._scheduler:scheduleScriptFunc(spin,0.02,false)				
		end,
		close=function(self)
			self.super.close(self)
			if self._schedulerId then
				self._scheduler:unscheduleScriptEntry(self._schedulerId)
				self._schedulerId = nil
				self._progress = nil
				self._text = nil
			end		
		end,	
		setProgress=function(self,d)
			if self._progress then
				self._progress:setContentSize(cc.size(self._size.width*d,self._size.height))
			end
		end,
		setText = function( self,txt )
			if self._text then
				self._text:setString(txt)
			end
		end,		
		test = function(self)
			self:open()
			local count = 4*20
			local i = 0
			local function progress()
				i=i+1
				self:setProgress(i/count)
				self:setText("进度:"..tostring(math.floor(i/count*100)).."%")
				if i > count then
					self._scheduler:unscheduleScriptEntry(self._testId)
					self:close()
				end
			end
			self._testId = self._scheduler:scheduleScriptFunc(progress,1/20,false)
		end,
	}
}

local BaiduVoice={
	classid = base.BaiduVoice,
	superid = base.Dialog,
	pedigree = {
		base.root
	},	
	name = "BaiduVoice",
	icon = "res/splash/baidu_icon.png",
	comment = "百度语音识别",
	version = 1,
	class={
		open=function(self,t)
			local platform = CCApplication:getInstance():getTargetPlatform()
			if platform == kTargetWindows then
				local factory = require "factory"
				local msgbox = factory.create(base.MessageBox)
				if msgbox then
					msgbox:open{caption="错误",text="百度语音不支持windows平台",button=1}
				end
			else
				cc_showBaiduVoice( function(text)
					if t and type(t)=='function' then
						t(text)
					end
				end)
			end
		end,
		close=function(self)
			local platform = CCApplication:getInstance():getTargetPlatform()
			if platform == kTargetWindows then		
				kits.log("BaiduVoice not support windows platform")
			else
				cc_closeBaiduVoice()
			end
		end,
	}
}

local Widget={
	classid = base.Widget,
	superid = base.root,
	name = "Widget",
	icon = "res/splash/widget_icon.png",
	comment = "界面的基本元件的基类",
	version = 1,
	class={
	}
}

local Layout={
	classid = base.Layout,
	superid = base.Widget,
	pedigree = {
		base.root
	},
	name = "Layout",
	icon = "res/splash/layout_icon.png",
	comment = "界面的基本元件的基类",
	version = 1,
	class={
	}
}

local Button={
	classid = base.Button,
	superid = base.Widget,
	pedigree = {
		base.root
	},
	name = "Button",
	icon = "res/splash/button_icon.png",
	comment = "界面的基本元件的基类",
	version = 1,
	class={
	}
}

local ScrollView={
	classid = base.ScrollView,
	superid = base.Widget,
	pedigree = {
		base.root
	},
	name = "ScrollView",
	icon = "res/splash/widget_icon.png",
	comment = "界面的基本元件的基类",
	version = 1,
	class={
	}
}

local Text={
	classid = base.Text,
	superid = base.Widget,
	pedigree = {
		base.root
	},
	name = "Text",
	icon = "res/splash/text_icon.png",
	comment = "界面的基本元件的基类",
	version = 1,
	class={
	}
}

local ProgressBar={
	classid = base.ProgressBar,
	superid = base.Widget,
	pedigree = {
		base.root
	},
	name = "ProgressBar",
	icon = "res/splash/widget_icon.png",
	comment = "界面的基本元件的基类",
	version = 1,
	class={
	}
}

local function _readonly(t,k,v)
	kits.log("ERROR read only")
end

local function readOnly(t)
	local proxy = {}
	local mt={
		__index=t,
		__newindex=_readonly,
	}
	setmetatable(proxy,mt)
	return proxy
end

local function addBaseClass(_classes)
	local function addClass( classid,cls )
		if cls.superid then
			local supercls = _classes[cls.superid]
			if supercls then
				cls.class.super = supercls.class
				setmetatable(cls.class,{__index=supercls.class,__newindex=_readonly})
			else
				kits.log("ERROR addBaseClass super class = nil "..tostring(cls.superid))
			end
		else
			setmetatable(cls.class,{__newindex=_readonly})
		end
		_classes[classid] = readOnly(cls)
	end
	addClass(base.root,root)
	addClass(base.Scene,Scene)
	addClass(base.Layer,Layer)	
	addClass(base.SplashScene,splashScene)
	addClass(base.LoadingScene,loadingScene)
	addClass(base.Dialog,Dialog)
	addClass(base.MessageBox,messageBox)
	addClass(base.BaiduVoice,BaiduVoice)
	addClass(base.Spin,Spin)
	addClass(base.ProgressBox,ProgressBox)
	addClass(base.Widget,Widget)
	addClass(base.Layout,Layout)
	addClass(base.Button,Button)
	addClass(base.ScrollView,ScrollView)
	addClass(base.Text,Text)
	addClass(base.ProgressBar,ProgressBar)
end

return {
	addBaseClass = addBaseClass
}