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
	BUTTON_CANCEL = "Button_6",
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
		createScene = function(self)
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
			return self._scene
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
		createScene = function(self)
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
			return self._scene
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
			self._scene = cc.Scene:create()
			self._box = uikits.fromJson{file=self:getR(ui.MESSAGEBOX_FILE)}
			self._scene:addChild(self._box)
			self._text = uikits.child(self._box,ui.MESSAGE_TEXT)
			self._caption = uikits.child(self._box,ui.CAPTION_TEXT)
			self._ok = uikits.child(self._box,ui.BUTTON_OK)
			self._cancel = uikits.child(self._box,ui.BUTTON_CANCEL)
			
			self._caption:setString( tostring(t.caption) )
			self._text:setString( tostring(t.text) )
			if t.okText then
				self._ok:setTitleText( tostring(t.okText) )
			end
			if t.cancelText then
				self._cancel:setTitleText( tostring(t.cancelText) )
			end
			uikits.event(self._ok,function(sender)
				if t.onClick then
					t.onClick( 'OK' )
				end
			end)
			uikits.event(self._cancel,function(sender)
				if t.onClick then
					t.onClick( 'CANCEL' )
				end			
			end)
			return self._scene			
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