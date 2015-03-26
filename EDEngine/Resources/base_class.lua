local kits = require "kits"
local uikits = require "uikits"
local json = require "json-c"
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

local Root = {
	classid = base.Root,
	name = "Root",
	icon = "res/splash/root_icon.png",
	comment = "所有对象都是它的子类",
	version = 1,
	class = {
		getR = function(self,res)
			local function resFile( classid )
				if classid then
					local resfile = "class/"..classid.."/"..res
					if cc_isdebug() then
						local f = cc.FileUtils:getInstance():getWritablePath()..resfile
						if kits.exist_file(f) then
							return resfile
						end
					else
						if kits.local_exists(resfile) then
							return resfile
						end
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

local Node = {
	classid = base.Node,
	superid = base.Root,
	name = "Node",
	icon = "res/splash/node_icon.png",
	comment = "所有可以放入到屏幕中的对象都是Node的子类",
	version = 1,
	class = {
		__init__ = function(self)
			self._child_nodes = {}
			self:ccCreate()
			local function onNodeEvent(event,v)
				if "enter" == event then
					self:init()
				elseif "exit" == event then
					self:release()
				end
			end
			self._ccnode:registerScriptHandler(onNodeEvent)
		end,
		addChild = function(self,child,z)
			if child._ccnode then
				child._parent_node = self
				self._child_nodes[child] = child
				if z then
					self._ccnode:addChild(child._ccnode,z)
				else
					self._ccnode:addChild(child._ccnode)
				end
			elseif cc_isobj(child) then
				if z then
					self._ccnode:addChild(child,z)
				else
					self._ccnode:addChild(child)
				end
			else
				kits.log("ERROR Node addChild unknow type child")
			end
		end,
		attach = function(self,ccnode)
			self._ccnode = ccnode
		end,
		ccNode = function(self)
			return self._ccnode
		end,
		init = function(self)
		end,
		release = function(self)
		end,
		ccCreate = function(self)
			self:attach( cc.Node:create() )
		end,
		getParent = function(self)
			return self._parent_node
		end,
		getScene = function(self)
			if self._parent_scene then
				return self._parent_scene
			end
			if self._parent_node then
				return self._parent_node:getScene()
			end
		end,
		childs = function(self)
			local child = {}
			for i,v in pairs(self._child_nodes) do
				table.insert(child,v)
			end
			return child
		end,
		removeChild = function(self,child)
			self._child_nodes[child] = nil
		end,
		removeFromParent = function(self,isdelay)
			if self._parent_node then
				self._parent_node:removeChild(self)
			end
			if self._parent_scene then
				self._parent_scene:removeChild(self)
			end
			if self._ccnode then
				if isdelay then
					uikits.delay_call(nil,function()self._ccnode:removeFromParent()end)
				else
					self._ccnode:removeFromParent()
				end
			end
		end,
		setPosition = function(self,p)
			self._ccnode:setPosition(p)
		end,
		getPosition = function(self)
			local x,y = self._ccnode:getPosition()
			return cc.p(x,y)
		end,
		setAnchor = function(self,p)
			self._ccnode:setAnchorPoint(p)
		end,
		getAnchor = function(self)
			local x,y = self._ccnode:getAnchorPoint()
			return cc.p(x,y)
		end,
		setSize = function(self,s)
			self._ccnode:setContentSize(s)
		end,
		getSize = function(self)
			return self._ccnode:getContentSize()
		end,	
		test = function(self)
			local factory = require "factory"
			local scene = factory.create(base.Scene)
			scene:initDesignView(1024*2,576*2)
			scene:addCloseButton()
			scene:addChild(self)
			scene:push()
		end,
	}
}

local Scene = {
	classid = base.Scene,
	superid = base.Root,
	name = "Scene",
	icon = "res/splash/scene_icon.png",
	comment = "场景",
	version = 1,
	class = {
		__init__=function(self)
			self._child_nodes = {}
			self._scene = cc.Scene:create()
			self:ccCreate()
			local function onNodeEvent(event,v)
				if "enter" == event then
					self:init()
				elseif "exit" == event then
					self:release()
				end
			end
			self._scene:registerScriptHandler(onNodeEvent)
		end,
		init=function(self)
		end,
		release=function(self)
		end,
		initDesignView = function(self,w,h,s)
			uikits.initDR{width=w,height=h,mode=s}
		end,
		ccCreate=function(self)
		end,
		ccScene=function(self)
			return self._scene
		end,
		addChild=function(self,child,z)
			if child._ccnode then
				child._parent_scene = self
				self._child_nodes[child] = child
				if z then
					self._scene:addChild(child._ccnode,z)
				else
					self._scene:addChild(child._ccnode)
				end
			elseif cc_isobj(child) then
				if z then
					self._scene:addChild(child,z)
				else
					self._scene:addChild(child)
				end
			else
				kits.log("ERROR Scene addChild unknow type child")
			end
		end,
		removeChild = function(self,child)
			self._child_nodes[child] = nil
		end,		
		childs=function(self)
			local child = {}
			for i,v in pairs(self._child_nodes) do
				table.insert(child,v)
			end
			return child
		end,
		push = function(self)
			uikits.pushScene(self._scene)
		end,
		pop = function(self)
			uikits.popScene()
		end,		
		replace = function(self)
			uikits.replaceScene(self._scene)
		end,
		addCloseButton=function(self)
			local but = uikits.button{width=96,height=96}
			local ss = uikits.getDR()
			but:loadTextures("res/hd/Images/close.png","res/hd/Images/close.png")
			but:setPosition(cc.p(ss.width-100,ss.height-100))
			uikits.event(but,function(sender)
				self:pop()
			end)
			self:addChild(but)
		end,
		test = function(self)
			self:addCloseButton()
			self:push()		
		end,
	}
}

local Layer = {
	classid = base.Layer,
	superid = base.Node,
	name = "Layer",
	icon = "res/splash/layer_icon.png",
	comment = "一个场景可以有多个层",
	version = 1,
	pedigree = {
		base.Root
	},
	class = {
		ccCreate = function(self)
			self:attach(cc.Layer:create())
		end,
		test=function(self)
			local factory = require "factory"
			local scene = factory.create(base.Scene)
			scene:addChild(self)
			scene:addCloseButton()
			scene:push()
		end,
	}
}

local splashScene = {
	classid = base.SplashScene,
	superid = base.Scene,
	pedigree={
		base.Root
	},
	name = "SplashScene",
	icon = "res/splash/splash_icon.png",
	comment = "创建一个等待屏直到任务结束",
	version = 1,
	class = {
		ccCreate = function(self)
			self._splash = uikits.fromJson{file=self:getR(ui.SPLASH_FILE)}
			self:addChild(self._splash)
			self._text = uikits.child(self._splash,ui.SPLASH_TEXT)
			self._text_shadow = uikits.child(self._splash,ui.SPLASH_TEXT_SHADOW)
			self._spin = uikits.child(self._splash,ui.SPLASH_IMAGE)		
			self._scheduler = self:ccScene():getScheduler()		
			self:setText("")			
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
		base.Root
	},
	name = "LoadingScene",
	icon = "res/splash/loadingscene_icon.png",
	comment = "创建一个具有进度条的加载屏",
	version = 1,
	class = {
		ccCreate = function(self)
			self._loading = uikits.fromJson{file=self:getR(ui.LOADING_FILE)}
			self:addChild(self._loading)
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
			self._scheduler = self:ccScene():getScheduler()				
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
	superid = base.Root,
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
		modal = function(self,box,cancel)
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
			if cancel and self._root then
				uikits.event(self._root,function(sender)
					uikits.delay_call(nil,function()
						self:close()
					end)
				end,"click")
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
		base.Root
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
		base.Root
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
			super.close(self)
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
		base.Root
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
			super.close(self)
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
		base.Root
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

local Layout={
	classid = base.Layout,
	superid = base.Node,
	pedigree = {
		base.Root
	},
	name = "Layout",
	icon = "res/splash/layout_icon.png",
	comment = "界面元件容器",
	version = 1,
	class={
	}
}

local Button={
	classid = base.Button,
	superid = base.Node,
	pedigree = {
		base.Root
	},
	name = "Button",
	icon = "res/splash/button_icon.png",
	comment = "界面元件按钮",
	version = 1,
	class={
	}
}

local ScrollView={
	classid = base.ScrollView,
	superid = base.Node,
	pedigree = {
		base.Root
	},
	name = "ScrollView",
	icon = "res/splash/widget_icon.png",
	comment = "界面元件滚动区",
	version = 1,
	class={
	}
}

local Text={
	classid = base.Text,
	superid = base.Node,
	pedigree = {
		base.Root
	},
	name = "Text",
	icon = "res/splash/text_icon.png",
	comment = "界面元件文字",
	version = 1,
	class={
	}
}

local ProgressBar={
	classid = base.ProgressBar,
	superid = base.Node,
	pedigree = {
		base.Root
	},
	name = "ProgressBar",
	icon = "res/splash/widget_icon.png",
	comment = "界面元件进度条",
	version = 1,
	class={
	}
}

local ScrollBar={
	classid = base.ScrollBar,
	superid = base.Node,
	pedigree = {
		base.Root
	},
	name = "ScrollBar",
	icon = "res/splash/widget_icon.png",
	comment = "界面元件滚动条",
	version = 1,
	class={
		ccCreate=function(self)
			self:attach(uikits.layout{bgcolor=cc.c3b(128,128,128),
				anchorX=0,anchorY=0})
			self._slider = uikits.layout{bgcolor=cc.c3b(0,0,0)}
			self:addChild(self._slider)
			self._width = 16
			self._rang = 1
			self._slider:setAnchorPoint(cc.p(0,0))
			self:setScrollRang(1)
			self:setScrollPos(0)
		end,
		getWidth = function(self)
			return self._width
		end,
		setSize = function(self,s)
			s.width = 16
			super.setSize(self,s)
		end,
		trackScrollView = function(self,scrollview)
			local sv = scrollview._widget or scrollview
			local function scrollEvent(sender,state)
				if state == ccui.ScrollviewEventType.scrolling then
					local size = sv:getContentSize()
					local isize = sv:getInnerContainerSize()
					local inner = sv:getInnerContainer()
					local x,y = inner:getPosition()
					self:setScrollRang(size.height/isize.height)
					self:setScrollPos(-y/isize.height)
				end
			end
			uikits.event(sv,scrollEvent)
			scrollEvent(sv,ccui.ScrollviewEventType.scrolling)
		end,
		setScrollRang = function(self,rang)
			local size = self:getSize()
			self._rang = rang or self._rang
			self._block = size.height*self._rang
			self._slider:setContentSize(cc.size(self._width,self._block))
		end,
		setScrollPos = function(self,p)
			if p<0 then p = 0 end
			if p>1 then p = 1 end
			local s = self:getSize()
			self._slider:setPosition(cc.p(0,p*(s.height)))
		end,
	}
}

local PopupMenu={
	classid = base.PopupMenu,
	superid = base.Dialog,
	pedigree = {
		base.Root
	},
	name = "PopupMenu",
	icon = "res/splash/widget_icon.png",
	comment = "界面元件菜单",
	version = 1,
	class={
		__init__=function(self)
			self._menu = uikits.layout{}
			self._items = {}
			self._texts = {}
			self._maxsize = {width=0,height=0}
		end,
		addItem = function(self,text,onclick)
			local bg = uikits.layout{anchorX=0,anchorY=0,bgcolor=cc.c3b(255,66,0)}
			local text = uikits.text{caption=text,anchorX=0.5,anchorY=0.5}
			bg:addChild(text)
			self._menu:addChild(bg)
			table.insert(self._items,bg)
			table.insert(self._texts,text)
			local size = text:getContentSize()
			self._maxsize.width = math.max(self._maxsize.width,size.width)
			self._maxsize.height = math.max(self._maxsize.height,size.height)
			uikits.event(bg,function(sender)
				uikits.delay_call(nil,function()self:close()end)
				if onclick then
					onclick()
				end
			end
			,"click")
		end,
		open = function(self,p)
			self:relayout()
			self:modal(self._menu,true)
			if p and p.x and p.y then
				self._menu:setAnchorPoint(cc.p(0,1))
				self._menu:setPosition(p)
			end
		end,
		relayout = function(self)
			for i,v in pairs(self._items) do
				v:setContentSize(self._maxsize)
				v:setPosition(cc.p(0,(i-1)*self._maxsize.height))
			end
			for i,v in pairs(self._texts) do
				v:setPosition(cc.p(self._maxsize.width/2,self._maxsize.height/2))
			end
			self._menu:setContentSize(cc.size(self._maxsize.width,self._maxsize.height*#self._items))
		end,
	}
}

local Game={
	classid = base.Game,
	superid = base.Root,
	name = "Game",
	icon = "res/splash/game_icon.png",
	comment = "游戏基类",
	version = 1,
	class={
	}
}

local Sprite={
	classid = base.Sprite,
	superid = base.Node,
	name = "Sprite",
	icon = "res/splash/sprite_icon.png",
	comment = "场景中的角色",
	version = 1,
	pedigree={
		base.Root
	},
	class={
	}
}

local Item={
	classid = base.Item,
	superid = base.Node,
	name = "Item",
	icon = "res/splash/item_icon.png",
	comment = "场景中的道具，物品，角色",
	version = 1,
	pedigree={
		base.Root
	},
	class={
		ccCreate=function(self)
			self._actions = {}
			self._default = ""
			self._current = ""
			local root = cc.Node:create()
			self:attach(root)
			self._animation = ccs.Armature:create()
			self._sprite = cc.Sprite:create()
			root:addChild(self._animation)
			root:addChild(self._sprite)
			self:loadFromJson(self:getR("actions.json"))
			self:reset()
		end,
		loadFromJson=function(self,file)
			local s = kits.read_file(file)
			if s then
				local a = json.decode(s)
				if a then
					self._default = a.default or ""
					if a.animations then
						for i,v in pairs(a.animations) do
							self:addAnimationFile(v)
						end
					end
					if a.actions then
						for i,v in pairs(a.actions) do
							self:addAction(v)
						end
					end
				else
					kits.log("ERROR Item loadFromJson decode failed")	
					kits.log("	"..tostring(file))	
				end
			end
		end,
		init=function(self)
		end,
		release=function(self)
		end,
		addAnimationFile=function(self,file)
			local arm = ccs.ArmatureDataManager:getInstance()
			local localres = self:getR(file)
			arm:removeArmatureFileInfo(localres)
			arm:addArmatureFileInfo(localres)
		end,
		addAction=function(self,action)
			if action and action.name and (action.animation or action.image) then
				action.offset = action.offset or cc.p(0,0)
				action.scale = action.scale or 1
				action.angle = action.angle or 0
				self._actions[action.name]=action
			end
		end,
		reset=function(self)
			self:doAction(self._default)
		end,
		actions=function(self)
			return self._actions
		end,
		currentAction=function(self)
			return self._current
		end,
		doAction=function(self,name)
			if self._actions[name] then
				local action = self._actions[name]
				if action.animation then
					if not self._animation:init(action.animation) then
						self._animation:setPosition(action.offset)
						self._animation:setScaleX(action.scale)
						self._animation:setScaleY(action.scale)
						self._animation:setRotation(action.angle)
						if action.animationName then
							self._animation:play(action.animationName)
						elseif action.animationIndex then
							self._animation:playWithIndex(action.animationIndex)
						else
							kits.log("WARNING item.doAction animationName or animationIndex not exst "..tostring(action.animation))
						end
						self._sprite:setVisible(false)
						self._animation:setVisible(true)
					else
						kits.log("WARNING item.doAction unknow animation "..tostring(action.animation))
					end
				elseif action.image then
					self._sprite:setTexture(self:getR(action.image))
					self._sprite:setPosition(action.offset)
					self._sprite:setScaleX(action.scale)
					self._sprite:setScaleY(action.scale)
					self._sprite:setRotation(action.angle)					
					self._sprite:setVisible(true)
					self._animation:setVisible(false)				
				else
					self._animation:setVisible(false)
					self._sprite:setVisible(false)
				end
				self._current = name
			else
				kits.log("WARNING item.doAction unknow action "..tostring(name))
			end
		end,
		test=function(self)
			super.test(self)
			local scene = self:getScene()
			local function actionButton()
				local action = self:actions()
				local x = 0
				local y = 0
				local space = 4
				for i,v in pairs(action) do
					local but = uikits.button{caption=tostring(i),x=x,y=y}
					y = y + but:getContentSize().height+space
					scene:addChild(but)
				end
			end
			uikits.delay_call(nil,actionButton)
		end,
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

local function setupClassEnv(cls)
	local defaultEnv = _G
	local newenv
	if cls.super then
		newenv = {super=cls.super.class}
	else
		newenv = {}
	end
	setmetatable(newenv,{__index=defaultEnv})
	for i,v in pairs(cls.class) do
		if type(v)=='function' then
			setfenv(v,newenv)
		end
	end
end

local function addBaseClass(_classes)
	local function addClass( cls )
		if cls.superid then
			cls.super = _classes[cls.superid]
			if cls.super then
				setupClassEnv(cls)
				setmetatable(cls.class,{__index=cls.super.class,__newindex=_readonly})
			else
				kits.log("ERROR addBaseClass super class = nil "..tostring(cls.superid))
			end
		else
			setupClassEnv(cls)
			setmetatable(cls.class,{__newindex=_readonly})
		end
		_classes[cls.classid] = readOnly(cls)
	end
	addClass(Root)
	addClass(Node)
	addClass(Scene)
	addClass(Layer)
	addClass(splashScene)
	addClass(loadingScene)
	addClass(Dialog)
	addClass(messageBox)
	addClass(BaiduVoice)
	addClass(Spin)
	addClass(ProgressBox)
	addClass(Layout)
	addClass(Button)
	addClass(ScrollView)
	addClass(Text)
	addClass(PopupMenu)
	addClass(ProgressBar)
	addClass(ScrollBar)
	addClass(Game)
	addClass(Sprite)
	addClass(Item)
end

return {
	addBaseClass = addBaseClass
}