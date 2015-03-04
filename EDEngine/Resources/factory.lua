local md5 = require "md5"
local json = require "json-c"
local ljshell = require "ljshell"
local kits = require "kits"
local update = require "update_factory"
local uikits = require "uikits"
local base = require "base"

local s_gidcount = os.time()
--从classId到类表的映射表
local _classes = {}

local local_dir = ljshell.getDirectory(ljshell.AppDir)

base.addBaseClass( _classes )

--产生一个唯一的ID字符串
local function generateId()
	local t = tostring(os.time())..tostring(s_gidcount)
	s_gidcount = s_gidcount + 1
	return md5.sumhexa(t)
end

local function loadClassDescription( classId )
	return update.loadClassJson( classId,'desc.json' )
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
	kits.log("ERROR read only")
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
	
	update.UpdateClass( classId,loadClass )
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
local function isKindOf( B,A )
	if B and A and _classes[B] then
		local bcls = _classes[B]
		if bcls.classid == A or bcls.superid = A then
			return true
		end
		local pedigree = bcls.pedigree
		if pedigree then
			for k,v in pairs(pedigree) do
				if v == A then
					return true
				end
			end
		end
	end
end

--判断obj是否继承自A
local function isInstanceOf(obj,A)
	if obj and A and obj._cls then --obj必须是一个具体的对象
		local BaseID
		if A._cls then --A也是一个对象
			BaseID = A._cls.classid
		else
			BaseID = A
		end
		return isKindOf(obj._cls.classid,BaseID)
	end
end

--启动一个classId,分成两个步骤
--1.splash阶段，没有进度条仅仅有一个spalsh。完成检测和下载进度条类的功能。
--2.progress阶段，进一步检测depends.json中的类并跟新。
local function launch(classId)
	local splashid = base.splash_scene
	if hasLocalClass( classId ) then
		local cls = loadClassDescription(classId)
		--如果已经存在本地版本，检查是否存在一个splash
		if cls.splashid and hasLocalClass(cls.splashid) then
			splashid = cls.splashid
		end
	end
	--开启默认启动屏
	local splash
	local function progressStep( progressObject )
		if progressObject and isKindOf(progressObject,base.loading_scene) then
			if splash then
				uikits.popScene()
			end
			splash = 1 --标记已经不需要splash了
			launchProgress(classId)
			uikits.pushScene( progressObject.scene() )
			local deps = update.loadClassJson(classId,'depends.json~')
			local function updateResult( b )
				if b then
				else
					--跟新失败，并且没有本地版本
				end
			end
			local function updateProgress( d )
				progressObject.setProgressValue(d)
			end
			if deps then
				update.UpdateClassByTable(deps,updateResult,updateProgress)
			else
				updateResult(true)
			end
		else
			--无论如何也应该有一个进度条场景，这里显然是一个错误。
			kits.log("ERROR factory.launch failed.have not progress object")
		end
	end
	local function openSplash()
		create(splashid,function(obj)
				if not splash then
					splash = obj
					uikits.pushScene( splash:createScene() )
				end
			end)
	end	
	local function nextStep()
		local cls = update.loadClassJson(classId,'desc.json~')
		if cls and cls.progressid then
			create( cls.progressid,progressStep )
		elseif cls then
			--使用默认的进度条
			create( base.loading_scene,progressStep )
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
			update.UpdateClassFiles( classId,downloadDepends,{"depends.json~","desc.json~"})
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
	isInstanceOf = isInstanceOf,
	create = create,
	launch = launch,
	updateClass = updateClass,
}