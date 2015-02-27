local md5 = require "md5"
local json = require "json-c"
local ljshell = require "ljshell"
local kits = require "kits"
local update = require "update_factory"

local s_gidcount = os.time()
--从classId到类表的映射表
local _classes = {}
--给定的classId是否已经进行了跟新
local _updates = {}
local local_dir = ljshell.getDirectory(ljshell.AppDir)

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

--跟新类，成功返回true,失败返回false
local function UpdateClass( classId )
	if _updates[classId] then return true end --已经跟新
	
	local state = update.CheckClassVersion( classId )
	if state == 1 or state == 2 or state == -2 then
		--需要跟新,-2再次尝试
		local result = update.UpdateClass( classId )
		if not result then
			if state == 2 then
				--跟新失败，但是有本地版本可以运行给出一个警告
				kits.log("WARNING UpdateClass failed,but local version existed 2."..tostring(classId))
			else
				--跟新失败，同时没有本地版本可以运行
				kits.log("ERROR UpdateClass failed,local version not exist")
				return false			
			end
		end
	elseif state == 0 then
		--不需要跟新
		_updates[classId] = 2
	elseif state == -1 then
		_updates[classId] = 1
		kits.log("WARNING UpdateClass failed,but local version existed -1."..tostring(classId))
	else
		kits.log("ERROR UpdateClass unknow state")
		return false
	end
	return true
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
local function addClass( classId )
	--在_classes中存在表示已经跟新过
	if _classes[classId] then return true end
	
	if not _updates[classId] then --已经进行了跟新
		if not UpdateClass( classId )  then
			return false 
		end
	end
	
	local cls = loadClassDescription( classId )
	if not cls then
		kits.log("ERROR addClass failed,can not load class description file. "..tostring(classId))
		return false
	end
	if cls.superid and addClass( cls.superid ) then
		cls.super = _classes[cls.superid].class
	end
	cls.class = loadClassTable(cls.script)
	if cls.class then
		cls.class.this = cls.class
		cls.class.super = cls.super
		setmetatable(cls.class,{__index=cls.super,__newindex=_readonly})
		setmetatable(cls,{__newindex=_readonly})
		_classes[classId] = cls
		return true
	else
		kits.log("ERROR "..tostring(classId).." is not exist.")
	end
	return false
end

--通过classId创建给定对象
local function create(classId)
	if addClass( classId ) then
		local obj = {}
		obj._cls = _classes[classId]
		setmetatable(obj,{__index=obj._cls.class})
		return obj
	end
end

--启动一个classId
local function launch(classId)
	if hasLocalClass( classId ) then
		--如果已经存在本地版本，检查是否存在一个splash
		
	end
	--开启默认启动屏
	local state = update.CheckClassVersion( classId )
	if state ~= 0 then
		if update.UpdateClassFiles( classId,{"depends.json","desc.json"}) then
		elseif state == -2 or state == 1 then
			--跟新失败,又不存在本地版本
			kits.log("ERROR factory.launch failed.")
			return false
		end
	end
end

return {
	generateId = generateId,
	getClassDescription = getClassDescription,
	create = create,
	launch = launch,
	updateClass = updateClass,
}