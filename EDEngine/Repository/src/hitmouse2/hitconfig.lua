local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local uikits = require "uikits"
local ljshell = require "ljshell"
local md5 =  require 'md5'


local function put_lading_circle( parent )
	local size
	if not parent then return end
	
	if parent.getContentSize then
		size = parent:getContentSize()
	else
		size = uikits.getDR()
	end
	--旋转体
	ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo('hitmouse2/loadingSC/loadingSC.ExportJson')
	ccs.ArmatureDataManager:getInstance():addArmatureFileInfo('hitmouse2/loadingSC/loadingSC.ExportJson')	
	local circle = ccs.Armature:create('loadingSC')

	if circle then
		circle:getAnimation():playWithIndex(0)
		circle:setAnchorPoint(cc.p(0.5,0.5))
		circle:setPosition( cc.p(size.width/2,size.height/2) )
		parent:addChild( circle,9999 )
		return circle
	end
end

local function put_circle( parent )
	local size
	if not parent then return end
	
	if parent.getContentSize then
		size = parent:getContentSize()
	else
		size = uikits.getDR()
	end
	--旋转体
	ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo('hitmouse2/loadingSCS/loadingSC.ExportJson')
	ccs.ArmatureDataManager:getInstance():addArmatureFileInfo('hitmouse2/loadingSCS/loadingSC.ExportJson')	
	local circle = ccs.Armature:create('loadingSC')

	if circle then
		circle:getAnimation():playWithIndex(0)
		circle:setAnchorPoint(cc.p(0.5,0.5))
		circle:setPosition( cc.p(size.width/2,size.height/2) )
		parent:addChild( circle,9999 )
		return circle
	end
end

local download_log_url = 'http://'..kits.getImageDownloadServer()..'/userlogo/'
local function load_logo_pic(handle,uid)

	local function showLogoPic(logo_handle,logo_pic_path)
		if cc_type(logo_handle) == 'ccui.Button' then
			logo_handle:loadTextures(logo_pic_path,'')
		elseif cc_type(logo_handle) == 'ccui.ImageView' then
			logo_handle:loadTexture(logo_pic_path)
		end
	end
	
	local local_dir = ljshell.getDirectory(ljshell.AppDir)
	local file_path = local_dir.."cache/"..uid..'.jpg'
	print("file_path:"..file_path)
	if kits.exist_file(file_path) then
		print("exist_file")
		showLogoPic(handle,file_path)
		--handle:loadTexture(file_path)
	else
		local loadbox = put_circle(handle)
		local send_url = download_log_url..uid..'/99'
		print("send_url:"..tostring(send_url))
		cache.request_nc(send_url,
		function(b,t)
				if b then
					showLogoPic(handle,file_path)
					--handle:loadTexture(file_path)
				else
					kits.log("ERROR :  download_pic_url failed")
				end
				loadbox:removeFromParent()
			end,uid..'.jpg')			
	end
end

local function load_image(handle,url)
	local function showLogoPic(logo_handle,logo_pic_path)
		if logo_handle and cc_isobj(logo_handle) then
			logo_handle:setVisible(true)
			if cc_type(logo_handle) == 'ccui.Button' then
				logo_handle:loadTextures(logo_pic_path,'')
			elseif cc_type(logo_handle) == 'ccui.ImageView' then
				logo_handle:loadTexture(logo_pic_path)
			end
		end
	end
	handle:setVisible(false)
	if kits.exist_cache(cache.get_name(url)) then
		showLogoPic(handle,kits.get_cache_path()..cache.get_name(url))
	else
		local loadbox = put_circle(handle)
		cache.request(url,function(b,data)
			if b then
				showLogoPic(handle,kits.get_cache_path()..cache.get_name(url))
			end
			if loadbox and cc_isobj(loadbox) then
				loadbox:removeFromParent()
			end
		end,'CN')
	end
end

local ui = {
	MSGBOX = 'hitmouse2/tankuang.json',
	TITLE = 'tu/bt',
	CONTENT = 'tu/leir',
	CONFIRM = 'tu/quer',
	GIVEUP = 'tu/fangq',
	KNOW = 'tu/zdl',
	OK = 'tu/hao',
	RETRY = 'tu/chongs',
	GOOD = 'tu/tbl',
	CANCEL = 'tu/qux',
}

local RETRY = 1
local OK = 2
local FAIL = 3
local CANCEL = 4

local NETWORK_ERROR = 1
local DOWNLOAD_ERROR = 2
local SER_ERROR = 3
local BATTLE_SEARCH_ERROR = 4
local NO_SILVER = 5
local NO_LE = 6
local NO_TILI = 7
local HAS_TILI = 8
local DEL_CARD = 9
local LEARN_SKILL = 10
local RESET_SKILL = 11
local BATTLE_GIVEUP = 12
local BUY_SILVER = 13
local DEF_MSG = 14
local OK_MSG = 15
local BUY_SP = 16
local DIY_MSG = 200

local flag_dictionary = {
{title = '啊！上不了网了',content='少侠，你的网络突然中断了，请检查一下网络，然后重试一下！',button_type = 3,}, --网络中断
{title = '出错啦',content='少侠，网络不给力，加载出错了，请重试一下！',button_type = 1,}, 						 --加载出错
{title = '圣上有旨',content='少侠，今天外面阳光灿烂，出去晒晒太阳吧，让服务器休息一下！',button_type = 2,},	 --服务器维护
{title = '你是高手',content='少侠，你的对战排名实在是太高，整个天朝都选不出人来和你对战了！请稍后再来试试吧！',button_type = 3,},	 --对战选不出人
{title = '没有银币了',content='少侠，行走江湖，怎么能没有银币呢？快去多赚一点银币吧！',button_type = 3,},	 --没银币了
{title = '没有乐币了',content='少侠，你没有乐币了，我实在无能为力！',button_type = 2,},	 				 --没乐币了
{title = '没有体力了',content='少侠，你体力不够了，多休息一下，体力每5分钟增加1点。',button_type = 2,},	 --没体力了
{title = '还有体力哦',content='少侠，你的体力还没有用完，你确定要购买吗？100体力 需要 花费500银币',button_type = 4,},	 --购买体力，体力有剩余
{title = '天啊',content='你真的要丢掉这张卡牌吗？丢掉了，就再也找不回来了！',button_type = 4,},	 		--丢弃卡牌
{title = '可以学技能了',content='天啊，你的卡牌可以学习新的技能了，快去“背包”看看吧！',button_type = 5,},	 		--卡牌升到10/40/80级
{title = '我的天啊',content='你真的确定要把卡牌已经学到的技能洗掉，重新学习新的技能吗？花费10000银币',button_type = 4,},	 		--洗掉卡牌技能
{title = '甘拜下风',content='你真的要甘拜下风，然后认输吗？',button_type = 4,},	 		--战斗中，退出
{title = '长安钱庄',content='少侠，你太明智了，我们可是这里最大的钱庄了。你确定要用10乐币兑换1000银币吗？',button_type = 4,},	 		--乐币兑换银币
{title = '错误',content='未知错误',button_type = 1,},	 		--自定义弹出框
{title = '错误',content='未知错误',button_type = 2,},	 		--自定义弹出框
{title = '购买体力',content='亲爱的，补满体力需要消费200银币，真的需要点击确认！',button_type = 4,},	 		--自定义弹出框
}

local function messagebox(parent,flag,func,txt_content,but1_text,but2_text)
	local s = uikits.fromJson{file=ui.MSGBOX}
	local content = uikits.child(s,ui.CONTENT)
	local title = uikits.child(s,ui.TITLE)
	local but_confirm = uikits.child(s,ui.CONFIRM)
	local but_giveup = uikits.child(s,ui.GIVEUP)
	local but_know = uikits.child(s,ui.KNOW)
	local but_ok = uikits.child(s,ui.OK)
	local but_retry = uikits.child(s,ui.RETRY)
	local but_good = uikits.child(s,ui.GOOD)
	local but_cancel = uikits.child(s,ui.CANCEL)
	

	uikits.event( but_confirm,function(sender)
				uikits.delay_call(parent,function()
					if sender.parent then
						if sender.parent.setEnabled then
							sender.parent:setEnabled(true)
						end
						if sender.parent.setTouchEnabled then
							sender.parent:setTouchEnabled(true)	
						end				
					end
					s:removeFromParent()
				end,0)
				func(OK)
			end,'click')	
	uikits.event( but_giveup,function(sender)
				uikits.delay_call(parent,function()
					if sender.parent then
						if sender.parent.setEnabled then
							sender.parent:setEnabled(true)
						end
						if sender.parent.setTouchEnabled then
							sender.parent:setTouchEnabled(true)	
						end			
					end
					if s and cc_isobj(s) then
						s:removeFromParent()
					end
				end,0)
				func(FAIL)
			end,'click')	
	uikits.event( but_know,function(sender)
				uikits.delay_call(parent,function()
					if sender.parent then
						if sender.parent.setEnabled then
							sender.parent:setEnabled(true)
						end
						if sender.parent.setTouchEnabled then
							sender.parent:setTouchEnabled(true)	
						end						
					end
					if s and cc_isobj(s) then
						s:removeFromParent()
					end
				end,0)
				func(OK)
			end,'click')	
			
	uikits.event( but_ok,function(sender)
				uikits.delay_call(parent,function()
					if sender.parent then
						if sender.parent.setEnabled then
							sender.parent:setEnabled(true)
						end
						if sender.parent.setTouchEnabled then
							sender.parent:setTouchEnabled(true)	
						end			
					end
					if s and cc_isobj(s) then
						s:removeFromParent()
					end
				end,0)
				func(OK)
			end,'click')	
			
	uikits.event( but_retry,function(sender)
				uikits.delay_call(parent,function()
					if sender.parent then
						if sender.parent.setEnabled then
							sender.parent:setEnabled(true)
						end
						if sender.parent.setTouchEnabled then
							sender.parent:setTouchEnabled(true)	
						end
					end
					if s and cc_isobj(s) then
						s:removeFromParent()
					end
				end,0)
				func(RETRY)
			end,'click')	
	uikits.event( but_good,function(sender)
				uikits.delay_call(parent,function()
					if sender.parent then
						if sender.parent.setEnabled then
							sender.parent:setEnabled(true)
						end
						if sender.parent.setTouchEnabled then
							sender.parent:setTouchEnabled(true)	
						end			
					end
					if s and cc_isobj(s) then
						s:removeFromParent()
					end
				end,0)
				func(OK)
			end,'click')	
	uikits.event( but_cancel,function(sender)
				uikits.delay_call(parent,function()
				--[[
					if sender.parent then
						if sender.parent.setEnabled then
							sender.parent:setEnabled(true)
						end
						if sender.parent.setTouchEnabled then
							sender.parent:setTouchEnabled(true)	
						end				
					end
					--]]
					if s and cc_isobj(s) then
						s:removeFromParent()
					end
				end,0)
				func(CANCEL)
			end,'click')	

	but_confirm:setVisible(false)
	but_giveup:setVisible(false)
	but_know:setVisible(false)
	but_ok:setVisible(false)
	but_retry:setVisible(false)
	but_good:setVisible(false)
	but_cancel:setVisible(false)

	if flag > #flag_dictionary then
--[[		if txt_title and type(txt_title) == 'string' then
			title:setString(txt_title)
		else
			title:setString(flag_dictionary[#flag_dictionary].title)
		end--]]
		
		if txt_content and type(txt_content) == 'string' then
			content:setString(txt_content)
		else
			content:setString(flag_dictionary[#flag_dictionary].content)
		end
		if but1_text and type(but1_text) == 'string' then
			but_retry:setTitleText( but1_text )
		end
		if but2_text and type(but2_text) == 'string' then
			but_cancel:setTitleText( but2_text )
		end			
		but_retry:setVisible(true)
		but_cancel:setVisible(true)
		s:setAnchorPoint{x=0.5,y=0.5}
		local size
		if parent.getContentSize then
			size = parent:getContentSize()
		else
			size = uikits.getDR()
		end
		s:setPosition{x=size.width/2,y=size.height/2}
		local viewParent=parent:getParent()
		viewParent:addChild( s,1000 )	
		--[[
		if parent.setEnabled then
			parent:setEnabled(false)
		end
		if parent.setTouchEnabled then
			parent:setTouchEnabled(false)
		end
		--]]
		but_confirm.parent = parent
		but_giveup.parent = parent
		but_know.parent = parent
		but_ok.parent = parent
		but_retry.parent = parent
		but_good.parent = parent
		but_cancel.parent = parent
		s:setEnabled(true)
		s:setTouchEnabled(true)		
		return
	else
		if txt_content and type(txt_content) == 'string' then
			content:setString(txt_content)
		else
			content:setString(flag_dictionary[flag].content)
		end	
		if but1_text and type(but1_text) == 'string' then
			but_retry:setTitleText( but1_text )
		end
		if but2_text and type(but2_text) == 'string' then
			but_cancel:setTitleText( but2_text )
		end		
		--title:setString(flag_dictionary[flag].title)
		if flag_dictionary[flag].button_type == 1 then
			but_retry:setVisible(true)
			but_cancel:setVisible(true)
		elseif flag_dictionary[flag].button_type == 2 then
			but_ok:setVisible(true)
		elseif flag_dictionary[flag].button_type == 3 then
			but_know:setVisible(true)
		elseif flag_dictionary[flag].button_type == 4 then
			but_confirm:setVisible(true)
			but_giveup:setVisible(true)	
		elseif flag_dictionary[flag].button_type == 5 then
			but_good:setVisible(true)
		end
	end
	

	s:setAnchorPoint{x=0.5,y=0.5}
	local size
	if parent.getContentSize then
		size = parent:getContentSize()
	else
		size = uikits.getDR()
	end
	s:setPosition{x=size.width/2,y=size.height/2}
	local viewParent=parent:getParent()
	viewParent:addChild( s,9999 )	
--[[
	if parent.setEnabled then
		parent:setEnabled(false)
	end
	if parent.setTouchEnabled then
		parent:setTouchEnabled(false)
	end
	--]]
	but_confirm.parent = parent
	but_giveup.parent = parent
	but_know.parent = parent
	but_ok.parent = parent
	but_retry.parent = parent
	but_good.parent = parent
	but_cancel.parent = parent
	s:setEnabled(true)
	s:setTouchEnabled(true)
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

local base_url
--debug
if cc_isdebug() then
	--debug
	--base_url = 'http://app.idiom.lejiaolexue.com/idiom/idiomclient.ashx'
	--线上
	--base_url = 'http://app.lejiaolexue.com/newidiom/idiomclient.ashx'
	base_url = 'http://app.lejiaolexue.com/idiom_zibo/idiomclient.ashx'
else
--release
--old local base_url = 'http://'..kits.getAppServer()..'/idiom/idiomclient.ashx'
--test
	base_url = 'http://'..kits.getAppServer()..'/newidiom/idiomclient.ashx'
--
	--base_url = 'http://'..kits.getAppServer()..'/idiom/idiomclient.ashx'
end

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

local function soft_print( s )
	local MAX_LENGTH = 1024
	if string.len(s) > MAX_LENGTH then
		local prev
		repeat
			prev = string.sub(s,1,MAX_LENGTH)
			s = string.sub(s,MAX_LENGTH+1)
			kits.log(prev)
		until not s or string.len(s) < MAX_LENGTH
		if s then
			kits.log( s )
		end
	else
		kits.log( s )
	end
end

local function post_data_by_new_form(parent,module_id,post_data,func,is_not_loading)
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
	local loadbox
	if not is_not_loading then
		loadbox = put_lading_circle(parent)
	end
	parent:setEnabled(false)
	parent:setTouchEnabled(false)
	soft_print('str_send_data::'..str_send_data)
	cache.post(base_url,str_send_data,function(t,d)
		soft_print('d::'..d)
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
										messagebox(parent,DIY_MSG,function(e)
											if e == OK then
											
											end
										end,tb_result.c..' : '..tb_result.msg)	
									end
									end)
					--	end
					--end,'提升',tb_result.c..' : '..tb_result.msg)	
				elseif tb_result.c == 506 then
					messagebox(parent,DIY_MSG,function(e)
						if e == RETRY then
							post_data_by_new_form(parent,module_id,post_data,func)
						else
							cc.Director:getInstance():endToLua()
						end
					end,'您的账号正在其它设备登录')	
				else
					messagebox(parent,DIY_MSG,function(e)
						if e == RETRY then
							post_data_by_new_form(parent,module_id,post_data,func)
						else
							cc.Director:getInstance():endToLua()
						end
					end,tb_result.c..' : '..tb_result.msg)		
				end
			elseif  tb_result.c > 599 then
				func(tb_result.c,tb_result.msg)
			end
		else
			--func(tb_result.c,tb_result.msg)
			messagebox(parent,NETWORK_ERROR,function(e)
				if e == RETRY then
					post_data_by_new_form(parent,module_id,post_data,func)
				else
					uikits.popScene()
				end
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

	function tableView.setData(data)
		tableView.data=nil
		tableView.data=data
		tableView:reloadData()
		top=math.max(viewSize.height-tableView:getContentSize().height,0)
		bottom=math.min(viewSize.height-tableView:getContentSize().height,viewSize.height)
		tableView:setBounceable(true)
	end

	--初始化数据
	tableView:setPosition(viewPosition)
	parent:addChild(tableView)
	if reflash then
		reflash(tableView:getParent(),tableView.setData)
	end

	return tableView
end

local function log(...)

	kits.log('INFO:'..string.format(...))

end
local function logTable(t, index)
	---[====[
	if index == nil then
		log("TABLE:")
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
		log(_space .. "table is nil") 
		return
	end

	if type(t)~='table' then
		log(tostring(t))
		return
	end
	
	for k,v in pairs(t) do
		if type(v) ~= "table" then
			log("%s%s[%s]      %s[%s]", 
				_space, tostring(k), type(k), tostring(v), type(v))
		else
			log(_space .. "T[".. tostring(k) .. "]------------------")
			logTable(v, index)
		end
	end

	--]====]
end


local ID_FLAG_STU = 1
local ID_FLAG_TEA = 2
local ID_FLAG_SCH = 3
local ID_FLAG_PAR = 4

local id_flag

local function set_id_flag(id)
	if id == ID_FLAG_STU or id == ID_FLAG_TEA or id == ID_FLAG_SCH or id == ID_FLAG_PAR then
		id_flag = id
	end
end

local function get_id_flag()
	return id_flag
end

local school_info
local function set_school_info(cur_school)
	school_info = cur_school
end

local function get_school_info()
	local cur_school
	if school_info then
		cur_school = school_info
	end
	return cur_school
end


local get_uesr_info_url = 'http://'..kits.getApiServer()..'/rest/userinfo/simple/current'

local function get_user_id(parent,func)
	kits.log("get_user_id "..tostring(get_uesr_info_url))
	cache.request_json( get_uesr_info_url,function(t)
		if t and type(t)=='table' then
			logTable(t)
			if 	t.result ~= 0 then				
				messagebox(parent,DIY_MSG,function(e)
					func(false,false)
				end,t.result..' : '..t.msg)		
			elseif t.uig and t.uig[1] then
				local user_id
				if t.uig[1].user_role == 1 then	--xuesheng
					user_id = ID_FLAG_STU
				elseif t.uig[1].user_role == 2 then	--parent
					user_id = ID_FLAG_PAR
				elseif t.uig[1].user_role == 3 then	--teacher
					user_id = ID_FLAG_TEA
				elseif t.uig[1].user_role >10 and t.uig[1].user_role <15 then	--manager
					user_id = ID_FLAG_SCH
				else
					user_id = ID_FLAG_TEA
				end
				print('user_id:::::'..user_id)
				set_id_flag(user_id)
				func(true)
			else
				kits.log("ERROR : get_user_id return invalid value")
			end	
		else
			messagebox(parent,NETWORK_ERROR,function(e)
				if e == RETRY then
					get_user_id(parent)
					func(false,true)
				else
					func(false,false)
				end
			end)
		end
	end,'N')	
end

return {
	post_data = post_data_by_new_form,
	messagebox = messagebox,
	createRankView = createRankView,
	logTable = logTable,
	log = log,
	RETRY = RETRY,
	OK = OK,
	FAIL = FAIL,
	CANCEL = CANCEL,
	NETWORK_ERROR = NETWORK_ERROR,
	DOWNLOAD_ERROR = DOWNLOAD_ERROR,
	SER_ERROR = SER_ERROR,
	BATTLE_SEARCH_ERROR = BATTLE_SEARCH_ERROR,
	NO_SILVER = NO_SILVER,
	NO_LE = NO_LE,
	NO_TILI = NO_TILI,
	HAS_TILI = HAS_TILI,
	DEL_CARD = DEL_CARD,
	LEARN_SKILL = LEARN_SKILL,
	RESET_SKILL = RESET_SKILL,
	BATTLE_GIVEUP = BATTLE_GIVEUP,
	BUY_SILVER = BUY_SILVER,
	DIY_MSG = DIY_MSG,
	OK_MSG = OK_MSG,
	BUY_SP = BUY_SP,
	DEF_MSG = DEF_MSG,
	set_id_flag = set_id_flag,
	get_id_flag = get_id_flag,
	ID_FLAG_STU = ID_FLAG_STU,
	ID_FLAG_TEA = ID_FLAG_TEA,
	ID_FLAG_SCH = ID_FLAG_SCH,
	ID_FLAG_PAR = ID_FLAG_PAR,
	circle = put_lading_circle,
	set_base_rid = set_base_rid,
	get_user_id = get_user_id,
	load_logo_pic = load_logo_pic,
	load_image = load_image,
	set_school_info = set_school_info,
	get_school_info = get_school_info,
}
