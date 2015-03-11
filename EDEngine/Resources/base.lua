local kits = require "kits"
local uikits = require "uikits"

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
}

--基类的名称映射表
local base = {
	root = "7c3064bb858e619b9f02fef85432f162",
	SplashScene = "b50a67aa2ed2183bee9b804ce7dbdefd",
	LoadingScene = "8bb51443e440190b892996b8c2864672",
	MessageBox = "8736daf38faaa28693f922843cc0c5aa",
}

local root = {
	classid = base.root,
	name = "Root",
	icon = "res/icon/root.png",
	comment = "所有对象都是它的子类",
	version = 1,
	class = {
		getR = function(self,res)
			local function resFile( classid )
				if classid then
					local resfile = "classes/"..classid.."/"..res
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
		end
	}
}

local splashScene = {
	classid = base.SplashScene,
	superid = base.root,
	name = "SplashScene",
	icon = "res/icon/splash_scene.png",
	comment = "创建一个等待屏直到任务结束",
	version = 1,
	class = {
		open = function(self)
			self._scene = cc.Scene:create()
			self._splash = uikits.fromJson{file=self:getR(ui.SPLASH_FILE)}
			self._scene:addChild(self._splash)
			self._text = uikits.child(self._splash,ui.SPLASH_TEXT)
			self._text_shadow = uikits.child(self._splash,ui.SPLASH_TEXT_SHADOW)
			self._spin = uikits.child(self._splash,ui.SPLASH_IMAGE)
			local scheduler = self._scene:getScheduler()
			local schedulerId		
			local oldDR
			local function onNodeEvent(event)
				local angle = 0
				local N = 12
				local function spin()
					self._spin:setRotation( angle )
					angle = angle + 360/N
				end
				if event == 'enter' then
					oldDR=uikits.getDR()
					uikits.initDR{width=960,height=540,mode=cc.ResolutionPolicy.SHOW_ALL}
					schedulerId = scheduler:scheduleScriptFunc(spin,0.8/N,false)	
				elseif event == 'exit' then
					if schedulerId then
						uikits.initDR(oldDR)
						scheduler:unscheduleScriptEntry(schedulerId)
						schedulerId = nil
					end
				end
			end
			self._scene:registerScriptHandler(onNodeEvent)
			uikits.pushScene(self._scene)
		end,
		close = function(self)
			if self._scene then	
				uikits.popScene()
			end
		end,
		setText = function(self,txt)
			self._text:setString(txt)
			self._text_shadow:setString(txt)
		end,
	}
}
local loadingScene = {
	classid = base.LoadingScene,
	superid = base.root,
	name = "LoadingScene",
	icon = "res/icon/loading_scene.png",
	comment = "创建一个具有进度条的加载屏",
	version = 1,
	class = {
		open = function(self)
			self._scene = cc.Scene:create()
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
			local scheduler = self._scene:getScheduler()
			local schedulerId				
			local oldDR
			local dx = 0
			local d = 2
			local function onNodeEvent(event)
				local function spin()
					uikits.move(self._sps,-3,0)
					dx = dx + 3
					if dx >= 30 then
						dx = 0
						uikits.move(self._sps,30,0)
					end
				end			
				if event == 'enter' then
					oldDR=uikits.getDR()
					uikits.initDR{width=960,height=540,mode=cc.ResolutionPolicy.SHOW_ALL}
					schedulerId = scheduler:scheduleScriptFunc(spin,0.02,false)	
				elseif event == 'exit' then
					if schedulerId then
						uikits.initDR(oldDR)
						scheduler:unscheduleScriptEntry(schedulerId)
						schedulerId = nil
					end
				end			
			end
			self._scene:registerScriptHandler(onNodeEvent)
			uikits.pushScene(self._scene)
		end,
		close = function(self)
			if self._scene then
				uikits.popScene(self._scene)
			end
		end,
		setProgress = function( self,d )
			--self._progress:setPercent( d*100 )
			self._progress:setContentSize(cc.size(self._size.width*d,self._size.height))
		end,
		setText = function( self,txt )
			self._text:setString(txt)
			self._text_shadow:setString(txt)
		end,
	}
}
local messageBox = {
	classid = base.MessageBox,
	superid = base.root,
	name = "MessageBox",
	icon = "res/icon/message_box.png",
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
												if self._root then
													self._root:removeFromParent()	
													self._root = nil
													if self._needpop	then
														uikits.popScene()
													end
												end
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
			local director = cc.Director:getInstance()
			local scene = director:getRunningScene()
			if scene then
				self._scene = scene
				self._root = ccui.Layout:create()
				self._root:addChild(self._box)
				scene:addChild(self._root)
				self._root:setTouchEnabled(true)
				self._root:setContentSize(uikits.getDR())
			else
				self._scene = cc.Scene:create()
				self._scene:addChild(self._box)
				self._root = self._box
				self._needpop = true
				uikits.pushScene(self._scene)
			end
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
		end
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
			setmetatable(cls.class,{__index=root.class,__newindex=_readonly})
		else
			setmetatable(cls.class,{__newindex=_readonly})
		end
		_classes[classid] = readOnly(cls)
	end
	addClass(base.SplashScene,splashScene)
	addClass(base.LoadingScene,loadingScene)
	addClass(base.MessageBox,messageBox)
end

base.addBaseClass = addBaseClass

return base