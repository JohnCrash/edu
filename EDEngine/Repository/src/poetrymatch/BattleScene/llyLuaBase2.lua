---
--llyLuaBase.lua
--lua基础函数，系统所用
--某些函数可在release时注销其内容
--卢乐颜
--2014.11.2

local lly = {
	traceback = true,
	log = true,
	logCurLocAnd = true,
	logTraceback = true,
	logTable = true,
	error = true,
	finalizeGlobalEnvironment = true,
	finalizeCurrentEnvironment = true,
	finalizeInstance = true,
	class = true,
	struct = true,
	array = true,
	const = true,
	ensure = true,
	assert = true
}

--代表空值，但是不释放对象
Lnull = false

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
	local strInfo = "(^_^)/" .. string.format(...) .. " @" .. info.currentline .. info.short_src

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
		lly.log("TABLE:")
	end

	local space = "   "
	local _space = " "
	if index ~= nil then
		for i = 1, index do
			_space = _space .. space
		end
		index = index + 1
	else
		index = 1
	end

	if t == nil then 
		lly.log(_space .. "table is nil") 
		return
	end

	for k,v in pairs(t) do
		if type(v) ~= "table" then
			lly.log("%s%s[%s]      %s[%s]", 
				_space, tostring(k), type(k), tostring(v), type(v))
		else
			lly.log(_space .. "T[".. tostring(k) .. "]------------------")
			lly.logTable(v, index)
		end
	end

	--]====]
end

--错误
function lly.error(errorStr, n)
	if not n then n = 2 end
	--error("(>_<)/" .. errorStr, n)

	moKits.log("ERROR : " .. errorStr)
end

---
--禁止产生全局变量的函数，定义在主函数中，此后将不可新建全局变量，避免因写错名称但无法检测而造成的麻烦

--禁止所有的全局变量
function lly.finalizeGlobalEnvironment()
	---[====[
	local mt = {}	
	
	mt.__index = function (t, k)
		lly.error("undeclared global var : " .. k, 2)
	end

	mt.__newindex = function (t, k, v)
		lly.error("undeclared global var : " .. k, 2)
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
			lly.error("undeclared global var : " .. k, 2)
		else
			return globalValue
		end
	end

	mt.__newindex = function (t, k, v)
		lly.error("undeclared global var : " .. k, 2)
	end
	
	local newgt = {}
	setmetatable(newgt,mt)
	
	setfenv(2, newgt)
	--]====]
end



---
--使类的实例最终化，也就是这之后不能再添加新的属性，避免因写错名称但无法检测而造成的麻烦
--适用于
--	自定义的c class、
--	自定义的lua class
--	自定义的结构
--	自定义的有限项目数组
--最终release时，可把此函数内容注释掉

--【私有】保存是否已经修改了本类的index 和newindex 修改了则不用再修改，ID防止ins的__ID
---[====[
local isModify_table = {}
local ID_table = {}
--]====]

--最终化
--注意：如果userdata的tolua.type一致，则会使用同一个元表，
--      这意味着自己继承一个类，比如layer，所有layer的元表会改变
--     	因此，在isModify_table中，我使用tolua.type(ins)获得同类的元表并记录，在index中检测是否是同种元表
--		另外利用__ID获得当前对象的唯一值，以防止对象之间相互影响
function lly.finalizeInstance(ins)
	---[====[
	local mt = getmetatable(ins)

	if mt ~= nil and type(ins) == "userdata" then --有元表

		if type(ins.__ID) ~= "number" then lly.error("no __ID") end --么有ID就不是自定义的类，不能final

		ID_table[ins.__ID] = true --保存ID

		local strClassName = tolua.type(ins) --对象的类名
		if isModify_table[strClassName] == true then return end --如果有说明已经修改

		isModify_table[strClassName] = true

		local mtindex = mt.__index
		local mtnewindex = mt.__newindex

		mt.__index = function (t, k)
			local result = nil
			local id = nil
			if type(mtindex) == "function" then
				result = mtindex(t, k)
				id = mtindex(t, "__ID")
			else
				result = mtindex[k]
				id = mtindex["__ID"]
			end

			local b = ID_table[id]

			if result == nil and b == true then
				lly.error("no attribute [" .. k .. "] in " .. 
					mtindex(t, "__cname") .. "[" .. tolua.type(t) .. "]", 2)
			end

			return result
		end

		mt.__newindex = function (t, k, v)
			if t[k] ~= nil then --检测是否存在，不存在就会新建
				--lly.log("new attribute " .. k) 
			end 

			if type(mtnewindex) == "function" then
				mtnewindex(t, k, v)
			else
				mtnewindex[k] = v
			end

		end	

	elseif mt == nil then
		mt = {}	
		
		mt.__index = function (t, k)
			lly.error("no this attribute " .. k, 2)
		end

		mt.__newindex = function (t, k, v)
			lly.error("no this attribute " .. k, 2)
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

--【私有函数】给每个结构体提供唯一标识，为每个对象提供唯一标示
---[====[
local IDIndex = 0 
local function getUniqueID()
	IDIndex = IDIndex + 1
	return IDIndex
end
--]====]

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
		--生成一个表，直接分配避免多次rehash
		cls = {
			__create = true,
			super = true,
			ctor = true,
			__cname = true,
			__ctype = true,
			new = true,
			init = true,
			create = true
		}

		if superType == "table" then
			cls.__create = super.__create
			cls.super = super

			--将父类作为本类的元表，因为父类的__index也为本身，所以当本类没有时，也会从父类找
			setmetatable(cls, super)
		else
			cls.__create = super
			cls.super = false --没有父类，不用nil是因为finalize中所有nil的属性不能通过
		end

		cls.ctor = function() lly.error("need implement", 2) end--必须重载，返回一个表格里面放置类的变量
		cls.__cname = classname
		cls.__ctype = 1
		cls.__index = cls --可让类作为元表

		function cls.new()
			local instance = cls.__create()
			local insTable = cls:ctor()
			if type(insTable) ~= "table" then lly.error("ctor must return table", 2) end

			local superTable
			local super = cls.super
			if super then
				superTable = super.ctor(cls)
				if type(superTable) ~= "table" then lly.error("ctor must return table", 2) end
				for k, v in pairs(insTable) do
					superTable[k] = v
				end
				insTable = superTable
				super = super.super
			end

			---[====[
			insTable.__ID = getUniqueID()
			--]====]

			insTable.__class = cls

			--让类作为实例的元表，就可以使用类中保留的方法
			setmetatable(insTable, cls) 

			--把产生的userdata实例的同位表设置成ctor产生的表，可用里面所有属性
			tolua.setpeer(instance, insTable)

			return instance
		end

	else
		-- inherited from Lua Object
		if super then
			cls = clone(super)
			cls.super = super
		else
			cls = {ctor = function() lly.error("need ctor", 2) end}--必须重载
			cls.super = false
		end

		cls.__cname = classname
		cls.__ctype = 2 -- lua
		cls.__index = cls

		function cls.new()
			local instance = setmetatable(cls:ctor(), cls)
			instance.__class = cls

			return instance
		end
	end
	
	--自添加
	--初始化 --返回是否初始化成功
	function cls:init(t) lly.error("need init", 2) end

	--工厂函数，创建对象，可以放入一个table进入init
	function cls:create(t)--返回class的对象
		local pRet = self.new()

		--检查是否有没有实现的纯虚函数
		--遍历纯虚函数列表里面的文本，查看有无同样文本的函数在对象里
		---[====[
		if pRet.__pure_virtual_func_tab ~= nil then
			for i, v in ipairs(pRet.__pure_virtual_func_tab) do
				if type(pRet[v]) ~= "function" then
					lly.error(v .. " is pure virtual func, must implement")
				end
			end
		end
		--]====]

		---[====[
		lly.finalizeInstance(pRet)--最终化对象
		--]====]

		local b = pRet:init(t)  
		if not b then
			lly.log("(O_O)/%s fail", pRet.__class.__cname)
			pRet = nil
			return nil
		end

		lly.log("(^_^)/%s init", pRet.__class.__cname)
		return pRet
	end

	return cls
end



--创建一个结构体，基本为 一个简化的创建类的方法
--在函数的ctor方法要返回 一个结构体
--创建好以后，用create生成的对象，不能再往里面添加内容
function lly.struct(create_table_func)
	---[====[
	if type(create_table_func) ~= "function" then 
		lly.error("create struct need a func param", 2)
	end
	--]====]

	local stru = {}
	stru.table_ctor = create_table_func

	---[====[
	stru.__ID = getUniqueID()
	--]====]

	--工厂函数，创建对象，t为构造函数的给定值
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
function lly.array(number, default)
	---[====[
	if type(number) ~= "number" then 
		lly.error("create array need a number param", 2)
	end
	--]====]

	local ar = {}
	
	if default then
		if type(default) == "function" then
			for i = 1, number do
				ar[i] = default()
			end
		elseif type(default) == "table" then
			for i = 1, number do
				ar[i] = clone(default)
			end
		else
			for i = 1, number do
				ar[i] = default
			end
		end
	else
		---[====[
		for i = 1, number do
			ar[i] = false
		end
		--]====]
	end

	---[====[
	lly.finalizeInstance(ar)
	--]====]

	return ar
end

--枚举
function lly.enum(tab)
	---[====[
	if type(tab) ~= "table" then 
		lly.error("create enum need a table param", 2)
	end
	--]====]

	local e = {}

	for i, v in ipairs(tab) do
		e[v] = i
	end
	
	---[====[
	e.__ctype = 4
	--]====]

	---[====[
	lly.finalizeInstance(e)
	--]====]

	return e
end

--只读的table
function lly.const(table)
	---[====[
	if type(table) ~= "table" then 
		lly.error("create const need a table param", 2)
	end
	local oldtable = table --交换是为了能在注释以外直接返回table
	table = {}
	local mt = {
		__index = oldtable,
		__newindex = function (t, k, v)
			lly.error("it is a const table")
		end
	}
	setmetatable(table, mt)
	--]====]
	return table
end


--设置纯虚函数
--输入一个类和其函数的文本名，将这个函数称为此类的纯虚函数
--纯虚函数必须实现，否则报错
function lly.set_pure_virtual_function(class, strFunc)
	---[====[
	if type(class) ~= "table" or class.__cname == nil then 
		lly.error("wrong class")
	end

	if type(strFunc) ~= "string" then 
		lly.error("wrong strFunc")
	end

	--生成纯虚函数表
	if class.__pure_virtual_func_tab == nil then
		class.__pure_virtual_func_tab = {}
	end

	local nIndex = #class.__pure_virtual_func_tab + 1
	class.__pure_virtual_func_tab[nIndex] = strFunc

	--]====]
end



--确保对象属于某个类型，不属于则报错
--基础类型和原始c类型的typename为文字
--自定义类型和自定义结构体的typename为table
function lly.ensure(value, typename)
	---[====[
	if value == nil or value == Lnull then return end --值为空则不进行检查

	if type(typename) == "string" then 
		if type(value) ~= typename and tolua.type(value) ~= typename then
			lly.error("value is a " .. type(value) .. ", but it must be a " .. typename, 2)
		end

	elseif type(typename) == "table" then
		if value.__ctype == 1 or value.__ctype == 2 then --ctype == 1 or 2则为class，3是struct
			if value.class == nil then --instance是对象
				lly.error("value must be a instance", 2)
			end

			if typename.__ctype == nil or typename.class ~= nil then --class是类
				lly.error("typename must be a class", 2)
			end

			if value.__ctype ~= typename.__ctype then
				lly.error("value must belong to this class", 2)
			end

			local cname = value.__cname
			while true do --看是否自己是或者父类是
				if cname ~= typename.__cname then
					if value.super ~= false then --检测是否还有父类
						cname = value.super.__cname
					else
						lly.error("value must belong to this class", 2)						
					end
				else break end
			end

		elseif value.__ctype == 3 then
			if value.__structID ~= typename.__ID then
				lly.error("ensure wrong: value must belong to this struct", 2)
			end
		else
			lly.error("ensure wrong: value is illegal", 2)
		end
	else
		lly.error("ensure wrong: typename must be a string/table", 2)
	end
	--]====]
end

function lly.assert(func)
	---[====[
	if not func or not func() then
		lly.error("assert wrong", 2)
	end
	--]====]
end

function lly.startupKeyboardForTest(node, key, func)
	---[====[
	local function onKeyReleased(keyCode, event)
		if keyCode == key then
			func()
		end
	end

    local listener = cc.EventListenerKeyboard:create()
    listener:registerScriptHandler(onKeyReleased, cc.Handler.EVENT_KEYBOARD_RELEASED )

    local eventDispatcher = node:getEventDispatcher()
    eventDispatcher:addEventListenerWithFixedPriority(listener, 1)
	--]====]
end

return lly

