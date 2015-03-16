local md5 = require "md5"
local json = require "json-c"
local kits = require "kits"
local update = require "update_factory"
local uikits = require "uikits"
local base = require "base"

local s_gidcount = os.time()
--从classId到类表的映射表
local _classes = {}

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
		local mod = require(file)
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
local function readOnly(t)
	local proxy = {}
	local mt={
		__index=t,
		__newindex=_readonly,
	}
	setmetatable(proxy,mt)
	return proxy
end

--向类表中加入新的类
local function addClass( classId,addClassResult,progress )
	--在_classes中存在表示已经跟新过
	if _classes[classId] then 
		addClassResult(true)
		return
	end
	local step = 0
	local function progressFunc( d,txt )
		if progress then
			progress( step/2+d/2,txt or '' )
		end
	end
	local function loadClass( b )
		if not b then 
			addClassResult(false)
			return
		end
		local cls = loadClassDescription( classId )
		if not cls then
			local errmsg = "addClass failed,can not load class description file. "..tostring(classId)
			kits.log("ERROR "..errmsg )
			addClassResult(false,errmsg)
			return
		end
		local function thisClass( b )
			if cls.superid then
				if _classes[cls.superid] and _classes[cls.superid].class then
					cls.super = _classes[cls.superid].class
				else
					--存在父类id却没有加载成功
					local errmsg = "addClass class "..tostring(classId).." super class "..tostring(superid).." not exist"
					kits.log("ERROR "..errmsg)
					addClassResult(false,errmsg)
					return
				end
			end
			if cls.script then
				local script = 'class/'..tostring(classId)..'/'..tostring(cls.script)
				cls.class = loadClassTable(script)
			end
			cls.class = cls.class or {}
			if cls.class then
				cls.class.this = cls.class
				cls.class.super = cls.super
				setmetatable(cls.class,{__index=cls.super,__newindex=_readonly})
				_classes[classId] = readOnly(cls)
				addClassResult(true)
			end
		end		
		--收集父类和依赖
		step = 1
		progressFunc(0)
		local depends = {}
		if cls.superid then
			table.insert(depends,cls.superid)
		end
		if cls.depends then
			for k,v in pairs(cls.depends) do
				table.insert(depends,v)
			end
		end
		local count = #depends
		if count>0 then
			local idx = 0
			local function stepByStep( b )
				if b then
					if idx==count then
						thisClass(true)
						return
					end
					idx=idx+1
					progressFunc(idx/count)					
					addClass( depends[idx],stepByStep )
				else
					local errmsg = "factory.addClass "..tostring(depends[idx]).." failed"
					kits.log("ERROR "..errmsg )
					thisClass(false,errmsg)
				end
			end
			stepByStep(true)
		else
			thisClass(true)
		end
	end
	
	update.UpdateClass( classId,loadClass,progressFunc )
end

local function instance( cls )
	local obj = {}
	obj._cls = cls
	setmetatable(obj,{__index=obj._cls.class})
	if obj.__init__ then
		obj:__init__()
	end
	return obj
end

--通过classId创建给定对象
local function createAsyn(classId,notify,progress)
	local function buildObject( b,errormsg )
		if b then --在列表中存在classId的类
			notify(instance(_classes[classId]))
		else
			local msg = "factory.create can not create object ."..tostring(classId)..
								"\n\t"..tostring(errormsg)
			kits.log("ERROR "..msg)
			notify(nil,msg)
		end
	end
	addClass( classId,buildObject,progress )
end

--本地是不是存在
local function isExist( classId )
	if _classes[classId] then
		return true
	else
		return hasLocalClass( classId )
	end
end

local function import( classIds,notify,progress )
	if classIds and type(classIds)=='table' then
		local idx = 0
		local count = #classIds
		
		if count == 0 then
			notify( true )
			return true
		end
		local function progressFunc( d,text )
			if progress then
				progress( (idx-1)/count+d/count,text )
			end
		end
		local function nextClass( b,errormsg )
			if b then
				if idx == count then
					notify(true)
					return
				end
				idx = idx + 1
				progressFunc(0,'')
				addClass( classIds[idx],nextClass,progressFunc )
			else
				local msg = "factory.import addClass "..tostring(classIds[idx])..
									" failed\n\t"..tostring(errormsg)
				kits.log("ERROR "..msg)
				notify(false,msg)
			end
		end
		nextClass( true )
		return true
	else
		kits.log("ERROR factory.import invalid argument #1")
	end
end

local function create(classId)
	local cls = _classes[classId]
	if not cls then return end
	return instance(cls)
end

--判断B是否继承自A
local function isKindOf( B,A )
	if B and A and _classes[B] then
		local bcls = _classes[B]
		if bcls.classid == A or bcls.superid == A then
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
	local splashid = base.SplashScene
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
		if progressObject and isKindOf(progressObject,base.LoadingScene) then
			if splash then
				splash:close()
			end
			splash = 1 --标记已经不需要splash了
			launchProgress(classId)
			progressObject:open()
			local deps = update.loadClassJson(classId,'depends.json~')
			local function updateResult( b )
				if b then
				else
					--跟新失败，并且没有本地版本
				end
			end
			local function updateProgress( d )
				progressObject.setProgress(d)
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
					splash:open()
				end
			end)
	end	
	local function nextStep()
		local cls = update.loadClassJson(classId,'desc.json~')
		if cls and cls.progressid then
			create( cls.progressid,progressStep )
		elseif cls then
			--使用默认的进度条
			create( base.LoadingScene,progressStep )
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
	createAsyn = createAsyn,
	create = create,
	import = import,
	isExist = isExist,
	launch = launch,
	updateClass = updateClass,
}