local kits = require "kits"
local uikits = require "uikits"

local ui = {
	SPLASH_FILE = "res/splash/splash_1.json",
	LOADING_FILE = "res/splash/laoding_1.json",
	SPLASH_IMAGE = "Image_5",
	SPLASH_TEXT = "Label_4",
	LOADING_PROGRESSBAR = "ProgressBar_1",
	LOADING_TEXT = "Label_2",
}

--基类的名称映射表
local base = {
	root = "",
	splash_scene = "",
	loading_scene = "",
	message_box = "",
}

local root = {
	classid = base.root,
	name = "Root",
	icon = "",
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
		end
	}
}

local splashScene = {
	classid = base.splash_scene,
	superid = base.root,
	name = "SplashScene",
	icon = "",
	comment = "创建一个等待屏直到任务结束",
	version = 1,
	class = {
		createScene = function(self)
			self._scene = cc.Scene:create()
			self._splash = uikits.fromJson{file=self:getR(ui.SPLASH_FILE)}
			self._scene:addChild(self._splash)
			self._text = uikits.child(self._splash,ui.SPLASH_TEXT)
			self._spin = uikits.child(self._splash,ui.SPLASH_IMAGE)
			return self._scene
		end,
		setText = function(self,txt)
			self._text:setString(txt)
		end,
		setBackground = function(self,res)
		end,
	}
}
local loadingScene = {
	classid = base.loading_scene,
	superid = base.root,
	name = "LoadingScene",
	icon = "",
	comment = "创建一个具有进度条的加载屏",
	version = 1,
	class = {
		createScene = function(self)
		end,
		setProgress = function( self,d )
		end,
		setText = function( self,txt )
		end,
	}
}
local messageBox = {
	classid = base.message_box,
	superid = base.root,
	name = "MessageBox",
	icon = "",
	comment = "创建一个等待屏直到任务结束",
	version = 1,
	class = {
		open = function(self)
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