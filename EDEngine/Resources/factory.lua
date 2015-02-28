local md5 = require "md5"
local json = require "json-c"
local ljshell = require "ljshell"
local kits = require "kits"
local update = require "update_factory"
local uikits = require "uikits"
local types = require "types"

local s_gidcount = os.time()
--从classId到类表的映射表
local _classes = {}
--给定的classId是否已经进行了跟新(本地版本和服务器版本的关系)
local _updates = {}

local local_dir = ljshell.getDirectory(ljshell.AppDir)
local ui = {
	SPLASH_FILE = "res/splash/splash_1.json",
	LOADING_FILE = "res/splash/laoding_1.json",
	SPLASH_IMAGE = "Image_5",
	SPLASH_TEXT = "Label_4",
	LOADING_PROGRESSBAR = "ProgressBar_1",
	LOADING_TEXT = "Label_2",
}

--产生一个唯一的ID字符串
local function generateId()
	local t = tostring(os.time())..tostring(s_gidcount)
	s_gidcount = s_gidcount + 1
	return md5.sumhexa(t)
end

local function loadClassDescription( classId )
	local df = update.getClassRootDirectory()..classId..'/desc.json'
	local file = io.read( df,"rb" )
	if file then
		local all = file:read("*a")
		file:close()
		local destable = json.decode( all )
		return destable
	else
		kits.log("ERROR can not read file "..tostring(df))
	end
end

--检查存在本地类吗
local function hasLocalClass( classId )
	local df = update.getClassRootDirectory()..classId..'/desc.json'
	local file = io.read( df,"rb" )
	if file then
		file:close()
		return true
	end
end

--[[跟新类，成功返回true,失败返回false
	如果跟新完成可以进行加载类调用updateResult(true)
	否则updateResult(false)
--]]
local function UpdateClass( classId,updateResult )
	local function notify( state )
		if state == 1 or state == 2 or state == -2 then
			--需要跟新,-2再次尝试
			local function updateComplete( result )
				if not result then
					if state == 2 then
						--跟新失败，但是有本地版本可以运行给出一个警告
						kits.log("WARNING UpdateClass failed,but local version existed 2."..tostring(classId))
						updateResult(true)
					else
						--跟新失败，同时没有本地版本可以运行
						kits.log("ERROR UpdateClass failed,local version not exist")
						updateResult(false)
					end
				else
					updateResult(true)
				end
			end
			update.UpdateClass( classId,updateComplete )
		elseif state == 0 then
			--不需要跟新
			_updates[classId] = 2
			updateResult(true)
		elseif state == -1 then
			_updates[classId] = 1
			kits.log("WARNING UpdateClass failed,but local version existed -1."..tostring(classId))
			updateResult(true)
		else
			kits.log("ERROR UpdateClass unknow state")
			updateResult(false)
		end
	end
	return update.CheckClassVersion( classId,notify )
end

local function loadClassTable( scriptFile )
	local function protected_func( file )
		local mod = require file
		local obj
		if mod and type( mod ) == 'table' then
			obj = mod
		elseif mod and type( mod ) == 'function' then
			obj = mod()
		end
		return obj
	end
	local b,classTable = pcall( protected_func,scriptFile )
	if b then return classTable end
	kits.log("ERROR loadCalss failed.script file : "..tostring(scriptFile))
	kits.log("	"..tostring(classTable))
end

local function _readonly(t,k,v)
	kits.log("read only")
end

--向类表中加入新的类
local function addClass( classId,addClassResult )
	--在_classes中存在表示已经跟新过
	if _classes[classId] then 
		addClassResult(true)
		return
	end
	
	local function loadClass( b )
		if not b then 
			addClassResult(false)
			return 
		end
		local cls = loadClassDescription( classId )
		if not cls then
			kits.log("ERROR addClass failed,can not load class description file. "..tostring(classId))
			addClassResult(false)
			return
		end
		local function thisClass( b )
			if cls.superid then
				if _classes[cls.superid] and _classes[cls.superid].class then
					cls.super = _classes[cls.superid].class
				else
					--存在父类id却没有加载成功
					kits.log("ERROR addClass class "..tostring(classId).." super class "..tostring(superid).." not exist")
					addClassResult(false)
					return
				end
			end		
			cls.class = loadClassTable(cls.script)
			if cls.class then
				cls.class.this = cls.class
				cls.class.super = cls.super
				setmetatable(cls.class,{__index=cls.super,__newindex=_readonly})
				setmetatable(cls,{__newindex=_readonly})
				_classes[classId] = cls
				addClassResult(true)
			else
				kits.log("ERROR "..tostring(classId).." is not exist.")
				addClassResult(false)
			end
		end		
		if cls.superid then --如果存在父类
			addClass( cls.superid,thisClass )
		else
			thisClass(true)
		end
	end
	
	if not _updates[classId] then
		UpdateClass( classId,loadClass )
	else
		--已经提前跟新好了
		loadClass( true )
	end	
end

--通过classId创建给定对象
local function create(classId,notify)
	local function buildObject( b )
		if b then --在列表中存在classId的类
			local obj = {}
			obj._cls = _classes[classId]
			setmetatable(obj,{__index=obj._cls.class})
			notify(obj)
		else
			kits.log("ERROR factory.create can not create object ."..tostring(classId))
			notify()
		end
	end
	addClass( classId,buildObject )
end

--判断B是否继承自A
local function isKindOf(B,A)
end

--启动一个classId,分成两个步骤
--1.splash阶段，没有进度条仅仅有一个spalsh。完成检测和下载进度条类的功能。
--2.progress阶段，进一步检测depends.json中的类并跟新。
local function launchProgress(classId)
end

local function launch(classId)
	if hasLocalClass( classId ) then
		--如果已经存在本地版本，检查是否存在一个splash
		
	end
	--开启默认启动屏
	local scene
	local splash
	local function progressStep( progressObject )
		if progressObject then
			uikits.popScene()
			launchProgress(classId)
		else
			--无论如何也应该有一个进度条场景，这里显然是一个错误。
			kits.log("ERROR factory.launch failed.have not progress object")
		end
	end
	local function openSplash()
		scene = cc.Scene:create()
		splash = uikits.fromJson{file=ui.SPLASH_FILE}
		scene:addChild(splash)
		uikits.pushScene(scene)
	end	
	local function nextStep()
		local cls = loadClassDescription(classId)
		if cls and cls.progressid then
			create( cls.progressid,progressStep )
		elseif cls then
			--使用默认的进度条
			create( types.loading_scene,progressStep )
		else
			kits.log("ERROR factory.launch failed.can not load class description file."..tostring(classId))
		end
	end
	local function checkResult( state )
		if state ~= 0 then
			local function downloadDepends( result )
				if result then
					nextStep()
				elseif state == -1 or state == 2 then
					--失败了但是有本地版本，也进入下一个阶段
					nextStep()
				else
					--既不能跟新，也不没有本地版本
					kits.log("ERROR factory.launch failed.")
				end
			end
			update.UpdateClassFiles( classId,downloadDepends,{"depends.json","desc.json"})
		else
			--不需要跟新,进入下一个步骤
			nextStep()
		end
	end
	
	openSplash()
	update.CheckClassVersion( classId,checkResult )
end

return {
	generateId = generateId,
	getClassDescription = getClassDescription,
	isKindOf = isKindOf,
	create = create,
	launch = launch,
	updateClass = updateClass,
}