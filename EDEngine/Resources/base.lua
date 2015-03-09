local kits = require "kits"
local uikits = require "uikits"

local ui = {
	SPLASH_FILE = "res/splash/splash_1.json",
	LOADING_FILE = "res/splash/laoding_1.json",
	SPLASH_IMAGE = "Image_5",
	SPLASH_TEXT = "Label_4",
	LOADING_PROGRESSBAR = "ProgressBar_1",
	LOADING_TEXT = "Label_2",
	MESSAGEBOX_FILE = "res/splash/messagebox",
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
	classid = base.splash_scene,
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
			self._spin = uikits.child(self._splash,ui.SPLASH_IMAGE)
			local function onNodeEvent(event)
				local angle = 0
				local N = 12
				local function spin()
					self._spin:setRotation( angle )
					angle = angle + 360/N
				end
				local scheduler = obj:getScheduler()
				local schedulerId
				if event == 'enter' then
					uikits.initDR{width=960,height=640}
					schedulerId = scheduler:scheduleScriptFunc(spin,0.8/N,false)	
				elseif event == 'exit' then
					scheduler:unscheduleScriptEntry(schedulerId)
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
		end,
	}
}
local loadingScene = {
	classid = base.loading_scene,
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
			self._progress = uikits.child(self._loading,ui.LOADING_PROGRESSBAR)
			local function onNodeEvent(event)
				if event == 'enter' then
					uikits.initDR{width=960,height=640}
				elseif event == 'exit' then
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
			self._progress:setPercent( d )
		end,
		setText = function( self,txt )
			self._text:setString(txt)
		end,
	}
}
local messageBox = {
	classid = base.message_box,
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
				self._text:setString( t.text )
				table.insert(self._texts,self._text)
			elseif t.text and type(t.text)=='table' then
				for k,v in pairs(t.text) do
					local txt = self._text:clone()
					txt:setString(v)
					table.insert(self._texts,txt)
				end
			end
			self._text:setVisible(false)
			if t.button and type(t.button)=='number' then
				local bt={"确定","取消","重试"}
				for i = 1,t.button do
					local but
					if i==1 then
						but = self._ok
					else
						but = self._ok:clone()
					end
					but:setTitleText(bt[i])
					table.insert(self._buttons,but)					
				end
			elseif t.button and type(t.button)=='table' then
				for i,v pairs(t.button) do
					local but
					if i==1 then
						but = self._ok
					else
						but = self._ok:clone()
					end
					but:setTitleText(tostring(v))
					table.insert(self._buttons,but)					
				end
			end
			self:relayout()
			local director = cc.Director:getInstance()
			local scene = director:getRunningScene()
			if scene then
				self._scene = scene
				scene:addChild(self._box)
			else
				self._scene = cc.Scene:create()
				self._scene:addChild(self._box)
				uikits.pushScene(self._scene)
			end
		end,
		relayout=function(self)
			local bhspace = 12 --按钮中的文字和边框两侧的间隔
			local bvspace = 8 --上下的间隔
			local space = 8
			local title_height = 42
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
			self._box:setContentSize(cc.Size(W,H+title_height))
			--开始布局按钮
			local ox = (W-BW)/2*space
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
		end
	}
}

local function _readonly(t,k,v)
	kits.log("ERROR read only")
end

local function addBaseClass(_classes)
	local function addClass( classid,cls )
		if cls.superid then
			setmetatable(cls.class,{__index=root.class,__newindex=_readonly})
		else
			setmetatable(cls.class,{__newindex=_readonly})
		end
		setmetatable(cls,{__newindex=_readonly})
		_classes[classid] = cls
	end
	addClass(base.splash_scene,splashScene)
	addClass(base.loading_scene,loadingScene)
	addClass(base.message_box,messageBox)
end

base.addBaseClass = addBaseClass

return base