local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local ljshell = require "ljshell"
local md5 = require "md5"


local function put_lading_circle( parent )
	local size
	if not parent then return end
	
	if parent.getContentSize then
		size = parent:getContentSize()
	else
		size = uikits.getDR()
	end
	--旋转体
	ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo('lemall/loadingSC/loadingSC.ExportJson')
	ccs.ArmatureDataManager:getInstance():addArmatureFileInfo('lemall/loadingSC/loadingSC.ExportJson')	
	local circle = ccs.Armature:create('loadingSC')

	if circle then
		circle:getAnimation():playWithIndex(0)
		circle:setAnchorPoint(cc.p(0.5,0.5))
		circle:setPosition( cc.p(size.width/2,size.height/2) )
		parent:addChild( circle,9999 )
		return circle
	end
end

local ui = {
	MSGBOX = 'lemall/tankuang.json',
	MSGBOX_3_4 = 'lemall/tankuang43.json',
	TITLE = 'ti/wen',
	CONTENT = 'ti/wen2',
	OK = 'ti/qr',
	CANCEL = 'ti/qx',
}

local g_gold_num = 0
local g_phone_num = ''
local g_user_name = ''

local function get_gold_num()
	local cur_gold_num = g_gold_num
	return cur_gold_num
end

local function set_gold_num(cur_gold_num)
	if cur_gold_num then
		g_gold_num = tonumber(cur_gold_num)
	end
end

local function add_gold_num(modify_num)
	if modify_num then
		g_gold_num = g_gold_num + tonumber(modify_num)
	end
end

local function remove_gold_num(modify_num)
	if modify_num and tonumber(modify_num) <= g_gold_num then
		g_gold_num = g_gold_num - tonumber(modify_num)
	end
end

local function get_phone_num()
	local cur_phone_num = g_phone_num
	return cur_phone_num
end

local function set_phone_num(cur_phone_num)
	if cur_phone_num then
		g_phone_num = tostring(cur_phone_num)
	end
end

local function get_name()
	local cur_user_name = g_user_name
	return cur_user_name
end

local function set_name(cur_user_name)
	if cur_user_name then
		g_user_name = tostring(cur_user_name)
	end
end

local FACTOR_3_4 = 1
local FACTOR_9_16 = 2

local function get_factor()
	local sizeWin=cc.Director:getInstance():getOpenGLView():getFrameSize()
	local factor = sizeWin.height/sizeWin.width
	kits.log('factor:::::'..factor)
	kits.log('(4/3+16/9)/2:::::'..(4/3+16/9)/2)
	if factor < (4/3+16/9)/2 then --更接近3/4
		return FACTOR_3_4,factor
	else --更接近9/16
		return FACTOR_9_16,factor
	end	
end
local function initDR(t)
	local glview = cc.Director:getInstance():getOpenGLView()
	local ss = glview:getFrameSize()

	if t and type(t)=='table' then
		cc.Director:getInstance():setContentScaleFactor( t.scale or 1 )
		--[[
				cc.ResolutionPolicy = 
				{
					EXACT_FIT = 0,
					NO_BORDER = 1,
					SHOW_ALL  = 2,
					FIXED_HEIGHT  = 3,
					FIXED_WIDTH  = 4,
					UNKNOWN  = 5,
				}		
		--]]

		glview:setDesignResolutionSize(t.width or ss.width,t.height or ss.height,t.mode or cc.ResolutionPolicy.EXACT_FIT)
		scale = t.width/ss.width
		return scale
	end
	return 1	
end

local function fromJson( t )
	local s
	if t and type(t)=='table' then
		if t.file_9_16 and t.file_3_4 then
			--根据不同的分辨率加载文件
			if get_factor() == FACTOR_3_4 then
				s = ccs.GUIReader:getInstance():widgetFromJsonFile(t.file_9_16)
			else
				s = ccs.GUIReader:getInstance():widgetFromJsonFile(t.file_3_4)
			end
		end
	end
	if not s then
		kits.log('uikits.fromJson return nil')
	end
	return s
end

local DIY_MSG = 0
local PW_SET_OK = 1
local PW_MODIFY_OK = 2
local ERR_NETWORK = 3
local ERR_PRO_PAY = 4
local ERR_PRO_NIL = 5

local flag_dictionary = {
{title = '',content='太棒了，支付密码设置成功！'}, 
{title = '',content='恭喜，您的支付密码已经修改成功！'}, 
{title = '',content='天啊！网络中断了，无法上网！'}, 
{title = '',content='天啊！购买商品出错了，请稍后重新再试一下！'}, 
{title = '',content='对不起，此商品已经下架或已售完，无法购买！'}, 

}

local function show_messagebox(parent,flag,func,txt_title,txt_content)
	local s
	if cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_WINDOWS then
		s = uikits.fromJson{file=ui.MSGBOX_3_4}
	else
		s = fromJson{file_9_16=ui.MSGBOX_3_4,file_3_4=ui.MSGBOX}
	end
--	local s = uikits.fromJson{file=ui.MSGBOX}
	
	local viewParent=parent:getParent()
	viewParent:addChild( s,9999 )	
	local title = uikits.child(s,ui.TITLE)
	local content = uikits.child(s,ui.CONTENT)		
	
	if flag ==  DIY_MSG then
		if txt_title then
			title:setString(txt_title)
		end
		content:setString(txt_content)	
	else
	print('flag:::'..flag)
	--	title:setString(flag_dictionary[flag].title)
		content:setString(flag_dictionary[flag].content)	
	end

	local but_ok = uikits.child(s,ui.OK)
	local but_cancel = uikits.child(s,ui.CANCEL)

	
	uikits.event( but_ok,function(sender)
				uikits.delay_call(parent,function()
					if sender.parent then
						sender.parent:setEnabled(true)
						sender.parent:setTouchEnabled(true)					
					end
					if s then
						s:removeFromParent()
					end
					func(true)
				end,0)
			end,'click')	
	uikits.event( but_cancel,function(sender)
				uikits.delay_call(parent,function()
					if sender.parent then
						sender.parent:setEnabled(true)
						sender.parent:setTouchEnabled(true)					
					end
					if s then
						s:removeFromParent()
					end
					func(false)
				end,0)
			end,'click')		
	
end

local str_platform = ''
if cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_WINDOWS then
	str_platform = 'WINDOWS'
elseif cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_MAC then
	str_platform = 'MAC'
elseif cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_IPHONE then
	str_platform = 'IPHONE'
elseif cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_IPAD then
	str_platform = 'IPAD'
elseif cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_ANDROID then
	str_platform = 'ANDROID'
end

local base_url = 'http://app.lejiaolexue.com/shop/shop.ashx'
--local base_url = 'http://shoping.lejiaolexue.com/shop.ashx'

local base_rid = ''

local function set_base_rid()
	base_rid = kits.config("base_rid",'get')
	if not base_rid then
		base_rid = tostring(cc_clock())
		base_rid = md5.sumhexa(base_rid)
		kits.config("base_rid",base_rid)
	end
	math.randomseed(os.time())
end

local function post_data_by_new_form(parent,module_id,post_data,func,is_not_loading)
	
	local temp
--[[	local wildcard = 'lejiaolexuezhangyu'
	if module_id == 'PayOrder' then
		temp = post_data.order_no
		post_data.order_no = wildcard
	end--]]
	local send_data = {}
	send_data.v = {}
	if post_data then
		send_data.v = post_data
	end
	
	if module_id then
		send_data.m = module_id
	else
		func(false,'module_id is nil')
		return
	end
    local rand_num = math.random()
	send_data.rid = base_rid..'_'..os.time()..rand_num
	send_data.icp = false
	send_data.ct = str_platform
	local str_send_data = json.encode(send_data)
--[[	if module_id == 'PayOrder' then
		str_send_data = string.gsub(str_send_data,wildcard,temp)
	end--]]
	local loadbox
	if not is_not_loading then
		loadbox = put_lading_circle(parent)
	end
	parent:setEnabled(false)
	parent:setTouchEnabled(false)
	kits.log('str_send_data::'..str_send_data)
	cache.post(base_url,str_send_data,function(t,d)
		kits.log('d::'..d)
		local tb_result = json.decode(d)
		if t == true then
			if tb_result.c == 200 then
				func(tb_result.c,tb_result.v)
			elseif 	tb_result.c < 600 and tb_result.c > 200 then
				if tb_result.c == 505 then
					--messagebox(parent,DIY_MSG,function(e)
					--	if e == OK then
							post_data_by_new_form(parent,'login','',function(t,v)
									if t and t == 200 then
--[[										uikits.stopAllSound()
										local random_src = os.time()
										local bg_music_index = random_src%3+1
										uikits.setDefaultClickSound(1,'poetrymatch/audio/other/button.mp3')	
										uikits.playSound('poetrymatch/audio/music/bj'..bg_music_index..'.mp3',true)									
										cc.Director:getInstance():popToRootScene()--]]
										if not is_not_loading then
											post_data_by_new_form(parent,module_id,post_data,func)
										else
											func(tb_result.c,tb_result.msg)
										end
									else
										show_messagebox(parent,DIY_MSG,function(e)
--[[											if e == OK then
											
											end--]]
										end,'提示',tb_result.c..' : '..tb_result.msg)	
									end
									end)
					--	end
					--end,'提升',tb_result.c..' : '..tb_result.msg)	
				elseif tb_result.c == 506 then
					show_messagebox(parent,DIY_MSG,function(e)
--[[						if e == RETRY then
							post_data_by_new_form(parent,module_id,post_data,func)
						else
							cc.Director:getInstance():endToLua()
						end--]]
					end,'提示','您的账号正在其它设备登录')	
				else
					show_messagebox(parent,DIY_MSG,function(e)
--[[						if e == RETRY then
							post_data_by_new_form(parent,module_id,post_data,func)
						else
							cc.Director:getInstance():endToLua()
						end--]]
					end,tb_result.c..' : '..tb_result.msg)		
				end
			elseif  tb_result.c > 599 then
				func(tb_result.c,tb_result.msg)
			end
		else
			--func(tb_result.c,tb_result.msg)
			show_messagebox(parent,ERR_NETWORK,function(e)
--[[				if e == RETRY then
					post_data_by_new_form(parent,module_id,post_data,func)
				end--]]
			end)
		end
		parent:setEnabled(true)
		parent:setTouchEnabled(true)
		if loadbox then
			loadbox:removeFromParent()
		end
	end)		
end



local function createRankView(parent,viewPosition,viewSize,cellItem,setItem,reflash)
	local tableView=cc.TableView:create(viewSize)
	tableView:setTouchEnabled(true)
	tableView:setDelegate()
	tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
	tableView:setBounceable(true)
	tableView.item=cellItem:clone()
	local function disableTouch(node)
		node:setTouchEnabled(false)
		local children=node:getChildren()
		if children then
			for _,v in pairs(children) do
				disableTouch(v)
			end
		end
	end
	disableTouch(tableView.item)
	tableView.item:retain()

	local cellSize=cellItem:getContentSize()
	local bounceHeight=cellSize.height
	local top=0
	local bottom=0

	cc.Node.registerScriptHandler(tableView,function(event)
		if event=="cleanup" then
			--释放内存
			tableView.item:release()
		elseif event=="exit" and tableView.stopKeySchedule then
			--终止连续按键
			tableView.stopKeySchedule()
		end
	end)

	tableView:registerScriptHandler(function(table)
		if tableView.data then
			return #tableView.data
		end
		return 0
	end,cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
	tableView:registerScriptHandler(function(table,index)
		return cellSize.height,cellSize.width
	end,cc.TABLECELL_SIZE_FOR_INDEX)
	tableView:registerScriptHandler(function(table,index)
		local cell=tableView:dequeueCell()
		local item=nil
		if cell then
			item=cell:getChildByTag(1)
		else
			cell=cc.TableViewCell:create()
			item=tableView.item:clone()
			item:setAnchorPoint(cc.p(0,0))
			item:setPosition(0,0)
			item:setTag(1)
			cell:addChild(item)
		end
		setItem(item,tableView.data[index+1])
		return cell
	end,cc.TABLECELL_SIZE_AT_INDEX)
	local check=false
	local pos_save
	tableView:registerScriptHandler(function(table)
		local offset=tableView:getContentOffset()
		print('offset.y:::::::'..offset.y)
		if offset.y>top and tableView:isDragging() then
			if check == false then
				check = true
				reflash(tableView:getParent(),tableView.setData)	
			end
			return
		end
	end,cc.SCROLLVIEW_SCRIPT_SCROLL)

	function tableView.setData(data)
		local offset_pos = 0
		if check == true then
			offset_pos = viewSize.height-tableView:getContentSize().height
			print('offset_pos1111111::::::::'..offset_pos)
		end
		tableView.data=nil
		tableView.data=data
		tableView:reloadData()

		top=math.max(viewSize.height-tableView:getContentSize().height,0)
		bottom=math.min(viewSize.height-tableView:getContentSize().height,viewSize.height)
		tableView:setBounceable(true)
		if offset_pos ~= 0 then
			offset_pos = viewSize.height-tableView:getContentSize().height - offset_pos
			print('offset_pos22222222::::::::'..offset_pos)
			tableView:setContentOffset(cc.p(0,offset_pos))			
		end
		check = false
	end

	--初始化数据
	tableView:setPosition(viewPosition)
	parent:addChild(tableView)
	if reflash then
		reflash(tableView:getParent(),tableView.setData)
	end

	return tableView
end


return {
circle = put_lading_circle,
messagebox = show_messagebox,
DIY_MSG = DIY_MSG,
PW_SET_OK = PW_SET_OK,
PW_MODIFY_OK = PW_MODIFY_OK,
ERR_NETWORK = ERR_NETWORK,
ERR_PRO_PAY = ERR_PRO_PAY,
ERR_PRO_NIL = ERR_PRO_NIL,
get_gold_num = get_gold_num,
set_gold_num = set_gold_num,
add_gold_num = add_gold_num,
remove_gold_num = remove_gold_num,
get_phone_num = get_phone_num,
set_phone_num = set_phone_num,
get_factor = get_factor,
FACTOR_3_4 = FACTOR_3_4,
FACTOR_9_16 = FACTOR_9_16,
fromJson = fromJson,
initDR = initDR,
createRankView = createRankView,
post_data = post_data_by_new_form,
set_base_rid = set_base_rid,
set_name = set_name,
get_name = get_name,
}