require "Cocos2d"
require "Cocos2dConstants"

local mt=require("mt")
local json=require("json-c")

local function get(url,callback)
	local ret,msg=mt.new("GET",url,nil,
		function(obj)
			if obj.state=="OK" or obj.state=="CANCEL" or obj.state=="FAILED"  then
				if obj.state=="OK" and obj.data then
					callback(true,json.decode(obj.data))
				else
					callback(false,obj.errmsg)
				end
			end
		end,form)
	if not ret then
		callback(false,msg)
	end
end

--从快递100查数据
--参数：
--		name：快递公司编号
--		order：运单号
--		callback(success,obj,ischeck)：回调函数，成功时obj是个数组，失败时obj是提示信息
local function queryKuaidi100Data(name,order,callback)
	local url="http://www.kuaidi100.com/query?type="..name.."&postid="..order
	get(url,function(success,obj)
		if success then
			if type(obj)~="table" then
				callback(false,obj)
			else
				if obj.status=="200" then
					--data是个数组，ischeck表示是否签收
					callback(true,obj.data,obj.ischeck~="0")
				else
					callback(false,obj.message)
				end
			end
		else
			callback(false,obj)
		end
	end)
end

local function showWuliuScene(layoutName,expressName,itemName,itemImage,order,data,message)
	local scene=cc.Scene:create()
	local layout=ccs.GUIReader:getInstance():widgetFromJsonFile(layoutName)
	scene:addChild(layout)

	--物品图片
	ccui.Helper:seekWidgetByTag(layout,35896):loadTexture(itemImage)
	--物品名称
	ccui.Helper:seekWidgetByTag(layout,35897):setString(itemName)
	--快递公司名称
	ccui.Helper:seekWidgetByTag(layout,35901):setString(expressName)
	--快递单号
	ccui.Helper:seekWidgetByTag(layout,35905):setString(order)

	--返回按扭
	ccui.Helper:seekWidgetByTag(layout,35890):addTouchEventListener(function(sender,event)
		if event~=ccui.TouchEventType.ended then return end
		cc.Director:getInstance():popScene()
	end)

	local contentView=ccui.Helper:seekWidgetByTag(layout,35908)
	local item=ccui.Helper:seekWidgetByTag(contentView,35909)
	item:retain()
	contentView:removeAllChildren()

	if message then
		--只是提示错误
		contentView:setVisible(false)
		ccui.Helper:seekWidgetByTag(layout,35907):setString(message)
		ccui.Helper:seekWidgetByTag(layout,35907):setVisible(true)
		ccui.Helper:seekWidgetByTag(layout,35906):setVisible(true)
	else
		--数据
		for k,v in ipairs(data) do
			local newItem=item:clone()
			contentView:pushBackCustomItem(newItem)
			ccui.Helper:seekWidgetByTag(newItem,35911):setString(v.context)
			ccui.Helper:seekWidgetByTag(newItem,35913):setString(v.time)
			ccui.Helper:seekWidgetByTag(newItem,35975):setTouchEnabled(false)
			if k==1 then
				ccui.Helper:seekWidgetByTag(newItem,35975):setSelectedState(true)
			end
		end
	end

	item:release()
	cc.Director:getInstance():pushScene(scene)
end

--显示物流信息，带界面
--参数：
--		showType：显示方式，1--横屏16:9；2--横屏4:3；3--竖屏16:9；4--竖屏4:3
--		expressName：快递公司名称，界面显示用
--		itemName：物品名称，界面显示用
--		itemImage：物品图片，界面显示用
--		name：快递公司编码
--		order：运单号
--		callback()：回调函数，界面显示出来后调用，可不传，主要让外部控制等待界面
local function showItemExpress(showType,expressName,itemName,itemImage,name,order,callback)
	local layoutNames=
	{
		"wuliu/wuliu.json",
		"wuliu/wuliu43.json",
		"wuliu/wuliu169.json",
		"wuliu/wuliu143.json",
	}
	local layoutName=layoutNames[showType]
	if layoutName==nil then return end

	queryKuaidi100Data(name,order,function(success,data,ischeck)
		if callback then callback() end
		performWithDelay(cc.Director:getInstance():getRunningScene(),function()
			if success then
				showWuliuScene(layoutName,expressName,itemName,itemImage,order,data)
			else
				showWuliuScene(layoutName,expressName,itemName,itemImage,order,nil,data)
			end
		end,0)
	end)
end

return
{
	queryKuaidi100Data=queryKuaidi100Data,
	showItemExpress=showItemExpress,
}