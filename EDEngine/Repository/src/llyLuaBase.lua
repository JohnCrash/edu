---
--llyLuaBase.lua
--lua基础函数，系统所用
--某些函数可在release时注销其内容
--卢乐颜
--2014.11.2

local lly = {}

--用于main函数，进行错误输出，用法如下
--local status, msg = xpcall(main, lly.traceback)
--if not status then error(msg) end
--最终release时，可把此函数内容注释掉
function lly.traceback(msg)
	---[====[
	lly.log("----------------------------------------")
	lly.log("LUA ERROR: " .. tostring(msg) .. "\n")
	lly.log(debug.traceback())
	lly.log("----------------------------------------")
	--]====]
	return msg
end



---
--自定义的log类，便于修改和调试

-- cclog
--最终release时，可把此函数内容注释掉
function lly.log(...)
	---[====[
	print(string.format(...))
	--]====]
end

--自定义的log输出，调试时，输出时同时打印位置，所在函数名，以及所在文件名
--最终release时，可把此函数内容注释掉
function lly.logCurLocAnd(...)
	---[====[
	local info = debug.getinfo(2,"Sln")
	local strInfo = "(^_^)/: " .. string.format(...) .. " @ LINE " .. info.currentline .. " IN " .. 
		(info.name and ("FUCN: " .. info.name .. " << ") or "FUCN: unnamed << ") .. info.short_src

	lly.log(strInfo)
	--]====]
end

--打印当前位置函数的调用追溯
function lly.logTraceback()
	---[====[
	lly.log("(O_O)/ this func is called from :")
	for nLevel = 3, math.huge do
		local info = debug.getinfo(nLevel,"Sln")
		if not info then break end
		local strInfo = " " .. info.short_src .. ">> LINE: " .. info.currentline ..
			(info.name and (" FUCN: " .. info.name .. " ") or " FUCN: unnamed ")
		lly.log(strInfo)
	end
	--]====]
end

--打印table中所有内容
function lly.logTable(t, index)
	---[====[
	if index == nil then
		print("TABLE:")
	end

	local space = "    "
	local _space = ""
	if index ~= nil then
		for i = 1, index do
			_space = _space .. space
		end
		index = index + 1
	else
		index = 1
	end

	for k,v in pairs(t) do
		if type(v) ~= "table" then
			print(_space .. string.format(k) .. "  " .. v)
		else
			print(_space .. "T[".. string.format(k) .. "]------------------")
			lly.logTable(v, index)
		end
	end

	--]====]
end

---
--禁止产生全局变量的函数，定义在主函数中，此后将不可新建全局变量，避免因写错名称但无法检测而造成的麻烦

--禁止所有的全局变量
function lly.finalizeGlobalEnvironment()
	---[====[
	local mt = {}	
	
	mt.__index = function (t, k)
		error("(>_<)/undeclared global var : " .. k, 2)
	end

	mt.__newindex = function (t, k, v)
		error("(>_<)/undeclared global var : " .. k, 2)
	end

	setmetatable(_G, mt)
	--]====]
end

--只禁止当前文件的全局变量，会改变当前文件的环境
function lly.finalizeCurrentEnvironment()
	---[====[
	local mt = {}
	
	mt.__index = function (t, k)
		local globalValue = _G[k]
		
		if globalValue == nil then
			error("(>_<)/undeclared global var : " .. k, 2)
		else
			return globalValue
		end
	end

	mt.__newindex = function (t, k, v)
		error("(>_<)/undeclared global var : " .. k, 2)
	end
	
	local newgt = {}
	setmetatable(newgt,mt)
	
	setfenv(2, newgt)
	--]====]
end




--【私有函数】给每个结构体提供唯一标识，为每个对象提供唯一标示
local structID = 0 
local function getUniqueStructID()
	structID = structID + 1
	return structID
end

---
--使类的实例最终化，也就是这之后不能再添加新的属性，避免因写错名称但无法检测而造成的麻烦
--适用于
--	自定义的c class、
--	自定义的lua class
--	自定义的结构
--	自定义的有限项目数组
--最终release时，可把此函数内容注释掉

--【私有】保存原有的mt的index函数
local mt_table = {}

--最终化
--注意：如果userdata的tolua.type一致，则会使用同一个元表，这意味着自己继承一个类，比如layer，所有layer的元表会改变
--     	因此，在mt_table中，我使用tolua.type(ins)获得同类的元表并记录，在index中检测是否是同种元表
--		另外利用__ID获得当前对象的唯一值，以防止对象之间相互影响
function lly.finalizeInstance(ins)
	---[====[
	local mt = getmetatable(ins)

	if mt ~= nil and type(ins) == "userdata" then --有元表

		local strClassName = tolua.type(ins) --对象的类名

		if mt_table[strClassName] == nil then
			mt_table[strClassName] = {}
			mt_table[strClassName].__index = mt.__index
			mt_table[strClassName].__newindex = mt.__newindex
			mt_table[strClassName].ID = {}
		end

		mt_table[strClassName].ID[#mt_table[strClassName].ID + 1] = ins.__ID

		mt.__index = function (t, k)
			local mt = mt_table[tolua.type(t)]
			local __idxTmp = mt.__index

			if __idxTmp == nil then error("wrong __index " .. tolua.type(t)) end

			local result = nil
			local id = nil --cname用于区分是否是自定义的类
			if type(__idxTmp) == "function" then
				result = __idxTmp(t, k)
				id = __idxTmp(t, "__ID")
			else
				result = __idxTmp[k]
				id = __idxTmp["__ID"]
			end

			local b = false
			for i, v in ipairs(mt.ID) do
				if id == v then
					b = true
					break
				end
			end

			if result == nil and b then
				error("(>_<)/no attribute [" .. k .. "] in " .. tolua.type(t) .. "[" .. cname .. "]", 2)
			end

			return result
		end

		mt.__newindex = function (t, k, v)
			if t[k] ~= nil then --检测是否存在，不存在就会新建
				--lly.log("new attribute " .. k) 
			end 

			local __nwidxTmp = mt_table[tolua.type(t)].__newindex

			if type(__nwidxTmp) == "function" then
				__nwidxTmp(t, k, v)
			else
				__nwidxTmp[k] = v
			end

		end	

	elseif mt == nil then
		mt = {}	
		
		mt.__index = function (t, k)
			error("(>_<)/no this attribute " .. k, 2)
		end

		mt.__newindex = function (t, k, v)
			error("(>_<)/no this attribute " .. k, 2)
		end

		setmetatable(ins, mt)			
	end
	--]====]
end



---
--创建类的函数，基本等于cocos3.2的extern。lua中的class函数，
--但里面为所创建的类增加了必须实现的函数，包括：
--	ctor 用于声明所有的常量，属性，以及函数（函数声明为function () end）
--	implementFunction 用于实现在ctor中声明的函数
--						因为在ctor之后会用finalizeInstance使得类不
--						可再增加新的属性，所以在此实现是比较不易出错的
--	init 用于初始化，调用create时调用
--还有一个create作为模板，生成对象用，create可以自行修改或者禁用

--【私有函数】克隆，完全复制于extern
local function clone(object)
	local lookup_table = {}
	local function _copy(object)
		if type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
		local new_table = {}
		lookup_table[object] = new_table
		for key, value in pairs(object) do
			new_table[_copy(key)] = _copy(value)
		end
		return setmetatable(new_table, getmetatable(object))
	end
	return _copy(object)
end

--Create an class. super可以是一个function或者一个自定义的class
function lly.class(classname, super)
	local superType = type(super)
	local cls

	if superType ~= "function" and superType ~= "table" then
		superType = nil
		super = nil
	end
	
	--如果从userdata，或继承于userdata的table中继承c的类
	if superType == "function" or (super and super.__ctype == 1) then
		-- inherited from native C++ Object
		cls = {}

		if superType == "table" then
			-- copy fields from super
			--for k,v in pairs(super) do cls[k] = v end
			cls.__create = super.__create
			cls.super = super
		else
			cls.__create = super
		end

		cls.ctor = function() error("need implement", 2) end--必须重载
		cls.__cname = classname
		cls.__ctype = 1

		function cls.new()
			local instance = cls.__create()
			-- copy fields from class to native object
			for k,v in pairs(cls) do instance[k] = v end
			instance.class = cls
			---[====[
			instance.__ID = getUniqueStructID()
			--]====]
			instance:ctor()
			return instance
		end

	else
		-- inherited from Lua Object
		if super then
			cls = clone(super)
			cls.super = super
		else
			cls = {ctor = function() error("need ctor", 2) end}--必须重载
		end

		cls.__cname = classname
		cls.__ctype = 2 -- lua
		cls.__index = cls

		function cls.new()
			local instance = setmetatable({}, cls)
			instance.class = cls
			instance:ctor()
			return instance
		end
	end
	
	--自添加
	--实现ctor中的函数
	function cls:implementFunction() error("need implement func", 2) end

	--初始化 --返回是否初始化成功
	function cls:init(t) error("need init", 2) end

	--工厂函数，创建对象，可以放入一个table进入init
	function cls:create(t)--返回class的对象
		local pRet = self.new()
		lly.finalizeInstance(pRet)--最终化对象
		pRet:implementFunction()
		b = pRet:init(t)  
		if b then
			return pRet
		else
			lly.log("(O_O)/init false")
			pRet = nil
			return nil
		end
	end

	return cls
end

--创建一个结构体，基本为 一个简化的创建类的方法
--在函数的ctor方法要返回 一个结构体
--创建好以后，用create生成的对象，不能再往里面添加内容
function lly.struct(create_table_func)
	if type(create_table_func) ~= "function" then 
		error("create struct need a func param", 2)
	end

	local stru = {}
	stru.table_ctor = create_table_func
	stru.__ID = getUniqueStructID()

	--工厂函数，创建对象
	function stru:create()--返回struct的对象
		local pRet = self.table_ctor()
		if type(pRet) == "table" then

			---[====[
			pRet.__ctype = 3 --区别于class
			pRet.__structID = self.__ID
			lly.finalizeInstance(pRet)--最终化对象
			--]====]

			return pRet
		end
	end

	return stru
end

--创建一个确定项目的数组，参数为取得数组的指针和数组的项目数
function lly.array(number)
	local ar = {}

	---[====[
	for i = 1, number do
		ar[i] = 0
	end

	lly.finalizeInstance(ar)
	--]====]

	return ar
end

--只读的table
function lly.const(table)
	---[====[
	local oldtable = table --交换是为了能在注释以外直接返回table
	table = {}
	local mt = {
		__index = oldtable,
		__newindex = function (t, k, v)
			error("it is a const table")
		end
	}
	setmetatable(table, mt)
	--]====]
	return table
end


--确保对象属于某个类型，不属于则报错
--基础类型和原始c类型的typename为文字
--自定义类型和自定义结构体的typename为table
function lly.ensure(value, typename)
	---[====[
	if type(value) == nil then return end --值为空则不进行检查

	if type(typename) == "string" then 
		if type(value) ~= typename and tolua.type(value) ~= typename then
			error("(>_<)/ensure wrong: value is a " .. type(value) .. 
				", but it must be a " .. typename, 2)
		end

	elseif type(typename) == "table" then
		if value.__ctype == 1 or value.__ctype == 2 then --ctype == 1 or 2则为class，3是struct
			if value.class == nil then --instance是对象
				error("(>_<)/ensure wrong: value must be a instance", 2)
			end

			if typename.__ctype == nil or typename.class ~= nil then --class是类
				error("(>_<)/ensure wrong: value must be a class", 2)
			end
			
			if value.__cname ~= typename.__cname or
				value.__ctype ~= typename.__ctype then
				error("(>_<)/ensure wrong: value must belong to this class", 2)
			end

		elseif value.__ctype == 3 then
			if value.__structID ~= typename.__ID then
				error("(>_<)/ensure wrong: value must belong to this struct", 2)
			end
		else
			error("(>_<)/ensure wrong: value is illegal", 2)
		end
	else
		error("(>_<)/ensure wrong: typename must be a string/table", 2)
	end
	--]====]
end



return lly

