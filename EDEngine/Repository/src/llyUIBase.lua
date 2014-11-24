---
--llyUIBase.lua
--lua中UI相关的函数
--卢乐颜
--2014.11.18

local llyUI = {}

--快速生成widget
--名称可以为文字名称，数字tag，或者一个table
--根据不同的类型，可以回调普通点击和复选框点击两种方法
function llyUI.setWidget(father, Name, func)
	local widget = nil

	if type(Name) == "string" then
		widget = father:getChildByName(name)

	else if type(Name) == "number" then
		widget = father:getChildByTag(name)

	else if type(Name) == "table" then
		local _father = father
		for i,v in ipairs(Name) do
			widget = _father:getChildByName(v)
			if widget == nil then break end
			_father = widget
		end
	end

	if widget == nil then error("wrong widget", 2)

	if tolua.type(widget) == "ccui.CheckBox" then
		widget:addEventListener(func)
	else
		widget:addTouchEventListener(func)
	end

	return widget
end

return llyUI