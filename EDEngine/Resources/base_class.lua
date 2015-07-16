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
		getClassid = function(self)
			return self._cls.classid
		end,
		read = function(self,res)
			if cc_isdebug() then
				local file = cc.FileUtils:getInstance():getWritablePath()..self:getR(res)
				return kits.read_file(file)
			else
				return kits.read_local_file(self:getR(res))
			end
		end,
		readJson = function(self,res)
			local s = self:read(res)
			if s then
				local result = json.decode(s)
				if result then
					return result
				else
					kits.log("ERROR Root readJson decode failed")
					kits.log("	type:"..tostring(self._cls.classid))
					kits.log("	file:"..tostring(res))
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
					if self._scheduler_ids then
						for i,v in pairs(self._scheduler_ids) do
							self._scheduler:unscheduleScriptEntry(v)
						end
						self._scheduler_ids = nil
						self._scheduler = nil
					end
				end
			end
			self._ccnode:registerScriptHandler(onNodeEvent)
		end,
		scheduler=function(self,func,d)
			self._scheduler = self._scheduler or self._ccnode:getScheduler()
			local schedulerID
			local function delay_call_func(dt)
				local err,ret = pcall(func,dt)
				if not err or not ret then
					self:removeScheduler(schedulerID)
					if not err then
						kits.log( "ERROR : "..tostring(ret))
					end
				end
			end			
			schedulerID = self._scheduler:scheduleScriptFunc(delay_call_func,d or 0.01,false)
			self._scheduler_ids = self._scheduler_ids or {}
			table.insert(self._scheduler_ids,schedulerID)
			return schedulerID
		end,
		removeScheduler=function(self,id)
			for i,v in pairs(self._scheduler_ids) do
				if v==id then
					self._scheduler:unscheduleScriptEntry(id)
					table.remove(self._scheduler_ids,i)
					return
				end
			end
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
			if child._ccnode and self._child_nodes[child] then
				child._parent_node = nil
				self._child_nodes[child] = nil
			else
				kits.log("WARNING : Node.removeChild failed")
			end
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
		setPosition = function(self,p,anchor)
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
		setScale=function(self,scale)
			self._ccnode:setScaleX(scale)
			self._ccnode:setScaleY(scale)
		end,
		setVisible=function(self,b)
			self._ccnode:setVisible(b)
		end,
		runAction=function(self,action)
			self._ccnode:runAction(action)
		end,
		testScene = function(self)
			local factory = require "factory"
			return factory.create(base.Scene)		
		end,
		test = function(self)
			local factory = require "factory"
			local scene = self:testScene()
			uikits.muteSound(false)
			uikits.muteClickSound(true)
			scene:initDesignView(1024,576)
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
		getSize=function(self)
			return uikits.getDR()
		end,
		initDesignView = function(self,w,h,s)
			uikits.initDR{width=w,height=h,mode=s}
		end,
		attach=function(self,scene)
			self._scene = scene
		end,
		ccCreate=function(self)
			self:attach(cc.Scene:create())
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
			self:addChild(but,99)
		end,
		test = function(self)
			self:addCloseButton()
			
			self:push()		
		end,
	}
}

local PhysicsScene = {
	classid = base.PhysicsScene,
	superid = base.Scene,
	name = "PhysicsScene",
	icon = "res/splash/scene_icon.png",
	comment = "物理场景场景",
	version = 1,
	pedigree={
		base.Root
	},
	class = {
		ccCreate=function(self)
			attach(cc.Scene:createWithPhysics())
			self._physics = self._scene:getPhysicsWorld()
		end,
		setGravity=function(self,x,y)
			self._physics:setGravity(cc.p(x, y));
		end,
		setUpdateRate=function(self,f)
			self._physics:setUpdateRate(f);
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

local ParallaxLayer = {
	classid = base.ParallaxLayer,
	superid = base.Node,
	name = "ParallaxLayer",
	icon = "res/splash/layer_icon.png",
	comment = "视差层，由无限循环的图组成的背景",
	version = 1,
	pedigree = {
		base.Root
	},
	class={
		ccCreate=function(self)
			self:attach(gl.glNodeCreate())
			local function visit()
				if not self._patterns  then
					return
				end
				local ss = self._ss
				local pt = self:ccNode():convertToNodeSpace(cc.p(0,0))				
				--ss = ss or self:getScene():getSize() --简单优化
				for i,v in pairs(self._patterns) do
					local x = pt.x - math.fmod(pt.x-v.offset.x,v.strip)
					local y = v.offset.y
					if not v.obj then
						v.obj = {}
						for k=1,math.floor(ss.width/v.strip) + 2 do
							local obj = cc.Sprite:create()
							obj:setTexture(self:getR(v.image))
							self:addChild(obj)
							obj:setAnchorPoint(v.anchor)
							obj:setScaleX(v.scale.x)
							obj:setScaleY(v.scale.y)
							obj:setRotation(v.angle)
							table.insert(v.obj,obj)
						end
					end
					for k,o in pairs(v.obj) do
						o:setPosition(cc.p(x,y))
						if pt.x > 0 then
							x = x + v.strip
						else
							x = x - v.strip
						end
					end
				end
			end
			self:ccNode():registerScriptDrawHandler(visit)
			self:loadFromJson("pattern.json")
		end,
		init=function(self)
			self._ss = self:getScene():getSize()
			if self._tdata.width then
				local scale = self._ss.width/self._tdata.width
				self._ss.width = self._tdata.width
				self:setScale(scale)
			end
		end,
		loadFromJson=function(self,file)
			local t = self:readJson(file)
			if t and t.patterns then
				self._tdata = t
				self._patterns = t.patterns
				for i,v in pairs(self._patterns) do
					v.scale = v.scale or cc.p(1,1)
					v.angle = v.angle or 0
					v.anchor = v.anchor or cc.p(0,0)
					v.offset = v.offset or cc.p(0,0)
				end
			end
		end,	
		test=function(self)
			super.test(self)
			local move = cc.MoveTo:create(1000,cc.p(-1024*400,0))
			self:ccNode():runAction(move)
		end,		
	}
}

local Parallax = {
	classid = base.Parallax,
	superid = base.Node,
	name = "Parallax",
	icon = "res/splash/layer_icon.png",
	comment = "由多个视差层组成一个有层次的视差背景",
	version = 1,
	pedigree = {
		base.Root
	},
	class={
		ccCreate=function(self)
			self:attach(cc.ParallaxNode:create())
			self:loadFromJson("parallax.json")
		end,
		addChild=function(self,child,z,ratio,offset)
			if child._ccnode then
				child._parent_node = self
				self._child_nodes[child] = child
				self._ccnode:addChild(child:ccNode(),z or -1,ratio or cc.p(1,1),offset or cc.p(0,0))
			elseif cc_isobj(child) then
				self._ccnode:addChild(child,z or -1,ratio or cc.p(1,1),offset or cc.p(0,0))
			else
				kits.log("ERROR Node addChild unknow type child")
			end
		end,
		init=function(self)
			local factory = require "factory"
			local t = self._parallax
			local scene = self:getScene()
			local ss
			if not t then
				return
			end
			if scene then
				ss = scene:getSize()
			else
				kits.log("WARNING Parallax.init scene = nil")
				return
			end
			for i,v in pairs(t.parallax) do
				local scale = v.scale or cc.p(1,1)
				local obj
				if v.objectid then
					obj = factory.create(v.objectid) 
					obj:ccNode():setScaleX(scale.x)
					obj:ccNode():setScaleY(scale.y)		
					if t.height and v.offset and v.offset.y then
						v.offset.y = ss.height*v.offset.y/t.height
					end
				elseif v.background then
					obj = cc.Sprite:create()
					obj:setTexture(self:getR(v.background))
					obj:setAnchorPoint(cc.p(0,0))
					local s = obj:getContentSize()
					obj:setPosition(cc.p(0,0))
					obj:setScaleX(ss.width/s.width)
					obj:setScaleY(ss.height/s.height)					
				end
				if obj then
					self:addChild(obj,1,v.ratio or cc.p(1,1),v.offset or cc.p(0,0))
					if v.speed then
						local t = 24*3600
						obj:runAction(cc.MoveTo:create(t,cc.p(v.speed.x*t,v.speed.y*t)))
					end
				else
					kits.log("ERROR Parallax.loadFromJson parallax object is nil")
					kits.log("	"..tostring(v.objectid))
				end					
			end		
		end,
		loadFromJson=function(self,res)
			local t = self:readJson(res)
			if t and t.parallax then
				self._parallax = t
			end
		end,
		test=function(self)
			super.test(self)
			local move = cc.MoveTo:create(1000,cc.p(-1024*400,0))
			self:ccNode():runAction(move)
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
			super.ccCreate(self)
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
			super.ccCreate(self)
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
			self:setText("")
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
			self:loadFromJson("actions.json")
		end,
		loadFromJson=function(self,file)
			local s = self:read(file)
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
			if action and action.name and (action.animation or action.image or action.script) then
				action.offset = action.offset or cc.p(0,0)
				action.scale = action.scale or 1
				action.angle = action.angle or 0
				self._actions[action.name]=action
			end
		end,
		reset=function(self)
			if self._actions[self._default] then
				self:doAction(self._default)
			end
		end,
		setDefaultAction=function(self,name)
			self._default = name
		end,
		actions=function(self)
			return self._actions
		end,
		currentAction=function(self)
			return self._current
		end,
		doAction=function(self,name,...)
			if not name then return end
			local result
			local function actionimp(...)
				if self._actions[name] then
					local action = self._actions[name]
					if action.audio then
						self:scheduler(function()
							uikits.playSound(self:getR(action.audio))
						end,action.audioDelay)
					end
					if action.script then
						if type(action.script)=='function' then
							result = action.script(...)
						end
					end
					if action.animation then
						if self._animation:init(action.animation) then
							self._animation:setPosition(action.offset)
							self._animation:setScaleX(action.scale)
							self._animation:setScaleY(action.scale)
							self._animation:setRotation(action.angle)
							if self._ItemSize then
								self._animation:setContentSize(self._ItemSize)
							end
							if self._ItemAnchorPt then
								self._animation:setAnchorPoint(self._ItemAnchorPt)
							end
						
							if action.animationName then
								self._animation:play(action.animationName)
							elseif action.animationIndex then
								local anim = self._animation:getAnimation()
								if(action.animationIndex < anim:getMovementCount()) and action.animationIndex>=0 then
									anim:playWithIndex(action.animationIndex)
								else
									kits.log("WARNING item.doAction animation index overflow :"..tostring(action.animation))
								end
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
						if self._ItemSize then
							self._sprite:setContentSize(self._ItemSize)
						end
						if self._ItemAnchorPt then
							self._sprite:setAnchorPoint(self._ItemAnchorPt)
						end
						self._sprite:setVisible(true)
						self._animation:setVisible(false)				
					else
						self._animation:setVisible(false)
						self._sprite:setVisible(false)
					end
				else
					kits.log("WARNING item.doAction unknow action ["..tostring(name).."]")
				end
			end
			if self._current_loop_id then
				self:removeScheduler(self._current_loop_id)
				self._current_loop_id = nil
			end
			if self._actions[name] and self._actions[name].loop then
				local a,b,c,d = ...
				actionimp(...)
				self._current_loop_id = self:scheduler(function()
					actionimp(a,b,c,d)
					return true
				end,self._actions[name].loop)
			else
				actionimp(...)
			end
			self._current = name
			return result
		end,
		getSize=function(self)
			if self._animation:isVisible() then
				return self._animation:getContentSize()
			else
				return self._sprite:getContentSize()
			end
		end,
		setSize=function(self,s)
			self._ItemSize = s
			if self._animation:isVisible() then
				self._animation:setContentSize(s)
			else
				local ss = self._sprite:getContentSize()
				self._sprite:setScaleX(s.width/ss.width)
				self._sprite:setScaleY(s.height/ss.height)
			end		
		end,
		setAnchor=function(self,p)
			self._ItemAnchorPt = p
			if self._animation:isVisible() then
				self._animation:setAnchorPoint(p)
			else
				self._sprite:setAnchorPoint(p)
			end
		end,
		getAnchor=function(self,p)
			if self._animation:isVisible() then
				local x,y = self._animation:getAnchorPoint()
				return cc.p(x,y)
			else
				local x,y = self._sprite:getAnchorPoint()
				return cc.p(x,y)			
			end		
		end,
		test=function(self)
			super.test(self)
			local scene = self:getScene()
			local ss = uikits.getDR()
			self:setPosition(cc.p(ss.width/2,ss.height/2))
			local function actionButton()
				local action = self:actions()
				local x = ss.width-256
				local y = 10
				local space = 4
				for i,v in pairs(action) do
					local but = uikits.button{caption=tostring(i),x=x,y=y,width=250,height=40}
					y = y + but:getContentSize().height+space
					scene:addChild(but)
					uikits.event(but,function(sender)
						self:doAction(tostring(i))
					end)
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
	addClass(PhysicsScene)
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
	addClass(ParallaxLayer)
	addClass(Parallax)
end

return {
	addBaseClass = addBaseClass
}