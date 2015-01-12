local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local uikits = require "uikits"
local ljshell = require "ljshell"

local g_person_info = {
id = 149091,
name = 'liyihang',
lvl = 5,
sex = 1, --2为女 ，1为男
}
local g_person_exp = {
lvl = 5,
cur_exp = 10,
max_exp = 100,
} -- lvl,cur_exp,max_exp

local g_person_silver = 100
local g_person_le_coin = 10
local g_person_tili = 0


local g_person_bag = {
cards_table = {},
max_store_num = 5,
equipment_table = {},
skill_table = {},
} -- 
local g_person_skill_list = {
	
}
local g_person_battle_cards = {}
local g_person_section_info = {}
local g_person_boss_info = {}


local function put_lading_circle( parent )
	local size
	if not parent then return end
	
	if parent.getContentSize then
		size = parent:getContentSize()
	else
		size = uikits.getDR()
	end
	--旋转体
	ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo('poetrymatch/loading/loading.ExportJson')
	ccs.ArmatureDataManager:getInstance():addArmatureFileInfo('poetrymatch/loading/loading.ExportJson')	
	local circle = ccs.Armature:create('loading')

	if circle then
		circle:getAnimation():playWithIndex(0)
		circle:setAnchorPoint(cc.p(0.5,0.5))
		circle:setPosition( cc.p(size.width/2,size.height/2) )
		parent:addChild( circle,9999 )
		return circle
	end
end

local function get_user_info()
	local uname
	if g_person_info then
		uname = g_person_info
	end
	return uname
end

local function update_user_info_by_tag(tag,content)
	if g_person_info[tag] and content then
		g_person_info[tag] = content
	end
end

local function set_user_info(uinfo)
	if uinfo then
		g_person_info = uinfo
		return true
	else
		return false
	end
end

local function set_user_tili(tili_num)
	if tili_num then
		g_person_tili = tili_num
		return true
	else
		return false
	end
end

local function get_user_tili()
	local tili_num
	if g_person_tili then
		tili_num = g_person_tili
	end
	return tili_num
end

local function get_user_lvl_info()
	local ulvl_info
	if g_person_exp then
		ulvl_info = g_person_exp
	end
	return ulvl_info
end

local function set_user_lvl_info(uexp_table)
	if uexp_table then
		if uexp_table.lvl then
			g_person_exp.lvl = uexp_table.lvl
		end
		if uexp_table.cur_exp then
			g_person_exp.cur_exp = uexp_table.cur_exp
		end
		if uexp_table.max_exp then
			g_person_exp.max_exp = uexp_table.max_exp
		end		
		return true
	else
		return false
	end
end

local function get_user_silver()
	local silver_num = 0
	if g_person_silver then
		silver_num = g_person_silver
	end
	return silver_num
end

local function set_user_silver(silver_num)
	if silver_num then
		g_person_silver = silver_num
		return get_user_silver()
	else
		return nil
	end
end

local function add_user_silver(silver_num)
	if silver_num then
		g_person_silver = g_person_silver + silver_num
		return get_user_silver()
	else
		return nil
	end
end

local function remove_user_silver(silver_num)
	if silver_num then
		if silver_num > g_person_silver then
			return nil
		end
		g_person_silver = g_person_silver - silver_num
		return get_user_silver()
	else
		return nil
	end
end

local function get_user_le_coin()
	local coin_num = 0
	if g_person_le_coin then
		coin_num = g_person_le_coin
	end
	return coin_num
end

local function set_user_le_coin(coin_num)
	if coin_num then
		g_person_le_coin = coin_num
		return get_user_le_coin()
	else
		return nil
	end
end

local function add_user_le_coin(coin_num)
	if coin_num then
		g_person_le_coin = g_person_le_coin + coin_num
		return get_user_le_coin()
	else
		return nil
	end
end

local function remove_user_le_coin(coin_num)
	if coin_num then
		if coin_num > g_person_le_coin then
			return nil
		end
		g_person_le_coin = g_person_le_coin - coin_num
		return get_user_le_coin()
	else
		return nil
	end
end

local function add_card_to_bag(card_info)
	if card_info then
		g_person_bag.cards_table[#g_person_bag.cards_table+1] = card_info
		return true
	else
		return false
	end
end

local function set_max_store_num(store_num)
	if store_num then
		g_person_bag.max_store_num = store_num
	end
end

local function get_max_store_num()
	local store_num
	if g_person_bag.max_store_num then
		store_num = g_person_bag.max_store_num
	end
	return store_num
end

local function set_all_card_to_bag(cards_table)
	if cards_table and type(cards_table) == 'table' then
		g_person_bag.cards_table = cards_table
		return true
	else
		return false
	end
end

local function get_all_card_in_bag()
	local cards_table
	if g_person_bag.cards_table then
		cards_table = g_person_bag.cards_table
	end
	return cards_table,g_person_bag.max_store_num
end

local function get_card_in_bag_by_index(index)
	local card_info
	if index then
		if g_person_bag.cards_table and g_person_bag.cards_table[index] then
			card_info = g_person_bag.cards_table[index]
			return card_info
		end
	end
	return nil
end

local function update_card_in_bag_by_id(id,tag,content)
	if id then
		for i,v in ipairs(g_person_bag.cards_table) do
			if v.id == id then
				if tag then
					if tag == 0 then
						v = content
					else
						if v[tag] then
							v[tag] = content
						end
					end
				end
			end
		end		
		--g_person_bag.cards_table = card_info
	end
end

local function del_card_in_bag_by_id(id)
	local card_info
	if id then
		for i,v in ipairs(g_person_bag.cards_table) do
			if v.id ~= id then
				card_info[#card_info+1] = v
			end
		end		
		g_person_bag.cards_table = card_info
	end
end

local function get_card_in_bag_by_id(id)
	local card_info
	if id then
		for i,v in ipairs(g_person_bag.cards_table) do
			if v.id == id then
				card_info = v
				return card_info
			end
		end
	end
	return nil
end

local function update_card_info_by_id(id,card_info)
	if id then
		for i,v in ipairs(g_person_bag.cards_table) do
			if v.id == id then
				if card_info and type(card_info) == 'table' then
					for j=1,#card_info do
						g_person_bag.cards_table[i][card_info[j].name] = card_info[j].value
					end
				end
			end
		end		
	end
	return nil
end

local function get_battle_list()
	local battle_list
	if g_person_battle_cards then
		battle_list = g_person_battle_cards
	end
	return battle_list
end

local function add_card_to_battle_by_index(id,index)
	if id then
		for i,v in ipairs(g_person_bag.cards_table) do
			if v.id == id then
				g_person_battle_cards[index] = id
				return true
			end
		end
	end
	return false
end

local function get_card_in_battle_by_index(index)
	local card_info
	if g_person_battle_cards and g_person_battle_cards[index] then
		local id = g_person_battle_cards[index]
		for i,v in ipairs(g_person_bag.cards_table) do
			if v.id == id then
				card_info = g_person_bag.cards_table[i]
				return card_info
			end
		end
	end
	return nil
end

local function exchange_card_in_battle_by_id(in_id,out_id)
	for i,v in ipairs(g_person_bag.cards_table) do
		if in_id ~= 0 and v.id == in_id then
			v.in_battle_list = 1
		end
		if out_id ~= 0 and v.id == out_id then
			v.in_battle_list = 0
		end
	end
	if out_id ~= 0 then
		for i=1,#g_person_battle_cards do
			if g_person_battle_cards[i] == out_id then
				if in_id then
					g_person_battle_cards[i] = in_id
				else
					g_person_battle_cards[i] = nil
				end
				break
			end
		end
	else
		if #g_person_battle_cards < 3 and in_id ~= 0 then
			g_person_battle_cards[#g_person_battle_cards+1] = in_id
		end
	end
end

local function get_all_card_in_battle()
	local all_cards_table = {}
	for i,v in ipairs(g_person_bag.cards_table) do	
		for j=1,#g_person_battle_cards do
			if v.id == g_person_battle_cards[j] then
				local card_info
				card_info = v
				all_cards_table[#all_cards_table+1] = card_info
				break
			end
		end
	end
	return all_cards_table
end

local card_root_path = 'poetrymatch/kapai/'
local section_root_path = 'poetrymatch/guanka/'
local skill_root_path = 'poetrymatch/jineng/'

local function load_card_pic(handle,filename,filename1,filename2)
	if handle and filename then
		local file_path = card_root_path..filename
		local file_path_dis
		local file_path_down
		if cc_type(handle) == 'ccui.Button' then
			if filename1 and string.len(filename1)>0 then
				file_down_path = card_root_path..filename1
			else
				file_down_path = ''
			end
			if filename2 and string.len(filename2)>0 then
				file_path_dis = card_root_path..filename2
			else
				file_path_dis = ''
			end
			handle:loadTextures(file_path, file_down_path, file_path_dis)
		elseif cc_type(handle) == 'ccui.ImageView' then
			handle:loadTexture(file_path)
		end
		return true
	else
		return false
	end
end

local function load_section_pic(handle,filename,filename1,filename2)
	if handle and filename then
		local file_path = section_root_path..filename
		local file_path_dis
		local file_down_path
		if cc_type(handle) == 'ccui.Button' then
			if filename1 and string.len(filename1)>0 then
				file_down_path = section_root_path..filename1
			else
				file_down_path = ''
			end
			if filename2 and string.len(filename2)>0 then
				file_path_dis = section_root_path..filename2
			else
				file_path_dis = ''
			end
			handle:loadTextures(file_path, file_down_path, file_path_dis)
		elseif cc_type(handle) == 'ccui.ImageView' then
			handle:loadTexture(file_path)
		end
		return true
	else
		return false
	end
end

local function load_skill_pic(handle,filename,filename1,filename2)
	if handle and filename then
		local file_path = skill_root_path..filename
		local file_path_dis
		local file_down_path
		if cc_type(handle) == 'ccui.Button' then
			if filename1 and string.len(filename1)>0 then
				file_down_path = skill_root_path..filename1
			else
				file_down_path = ''
			end
			if filename2 and string.len(filename2)>0 then
				file_path_dis = skill_root_path..filename2
			else
				file_path_dis = ''
			end
			handle:loadTextures(file_path, file_down_path, file_path_dis)
		elseif cc_type(handle) == 'ccui.ImageView' then
			handle:loadTexture(file_path)
		end
		return true
	else
		return false
	end
end
local download_log_url = 'http://image.lejiaolexue.com/userlogo/'
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
	if kits.exist_file(file_path) then
		showLogoPic(handle,file_path)
		--handle:loadTexture(file_path)
	else
		local loadbox = put_lading_circle(handle)
		local send_url = download_log_url..uid..'/99'
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


local function set_all_section_info(all_section_info)
	if all_section_info and type(all_section_info) == 'table' then
		g_person_section_info = all_section_info
	end
end

local function get_all_section_info()
	local all_section_info
	all_section_info = g_person_section_info
	return all_section_info
end

local function get_boss_info_by_id(id)
	local boss_info
	if g_person_boss_info[id] then
		boss_info = g_person_boss_info[id]
	end 
	return boss_info
end

local function set_boss_info_by_id(id,boss_info) 
	if boss_info and  type(boss_info) == 'table' then
		g_person_boss_info[id] = boss_info
	end
end

local function set_skill_list(skill_list)
	if skill_list and type(skill_list) == 'table' then
		g_person_skill_list = skill_list
	end
end

local function get_skill_list()
	local skill_list
	if g_person_skill_list then
		skill_list = g_person_skill_list
	end
	return skill_list
end

local function get_skill_info_by_id(id)
	local skill_info
	if g_person_skill_list then
		for i=1,#g_person_skill_list do	
			if g_person_skill_list[i].sub_id == id then
				--print(g_person_skill_list[i].skill_name)
				skill_info = g_person_skill_list[i]
			end
		end	
	end
	return skill_info
end

local ui = {
	MSGBOX = 'poetrymatch/tanchu.json',
	TITLE = 'tu/bt',
	CONTENT = 'tu/leir',
	CONFIRM = 'tu/quer',
	GIVEUP = 'tu/fangq',
	KNOW = 'tu/zdl',
	OK = 'tu/hao',
	RETRY = 'tu/chongs',
	GOOD = 'tu/tbl',
}

local RETRY = 1
local OK = 2
local FAIL = 3

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
local DIY_MSG = 14

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
{title = '错误',content='未知错误',button_type = 3,},	 		--自定义弹出框
}

local function messagebox(parent,flag,func,txt_title,txt_content)
	local s = uikits.fromJson{file=ui.MSGBOX}
	local content = uikits.child(s,ui.CONTENT)
	local title = uikits.child(s,ui.TITLE)
	local but_confirm = uikits.child(s,ui.CONFIRM)
	local but_giveup = uikits.child(s,ui.GIVEUP)
	local but_know = uikits.child(s,ui.KNOW)
	local but_ok = uikits.child(s,ui.OK)
	local but_retry = uikits.child(s,ui.RETRY)
	local but_good = uikits.child(s,ui.GOOD)

	uikits.event( but_confirm,function(sender)
				uikits.delay_call(parent,function()
					if sender.parent then
						sender.parent:setEnabled(true)
						sender.parent:setTouchEnabled(true)					
					end
					s:removeFromParent()
				end,0)
				func(OK)
			end,'click')	
	uikits.event( but_giveup,function(sender)
				uikits.delay_call(parent,function()
					if sender.parent then
						sender.parent:setEnabled(true)
						sender.parent:setTouchEnabled(true)					
					end
					s:removeFromParent()
				end,0)
				func(FAIL)
			end,'click')	
	uikits.event( but_know,function(sender)
				uikits.delay_call(parent,function()
					if sender.parent then
						sender.parent:setEnabled(true)
						sender.parent:setTouchEnabled(true)					
					end
					s:removeFromParent()
				end,0)
				func(OK)
			end,'click')	
			
	uikits.event( but_ok,function(sender)
				uikits.delay_call(parent,function()
					if sender.parent then
						sender.parent:setEnabled(true)
						sender.parent:setTouchEnabled(true)					
					end
					s:removeFromParent()
				end,0)
				func(OK)
			end,'click')	
			
	uikits.event( but_retry,function(sender)
				uikits.delay_call(parent,function()
					if sender.parent then
						sender.parent:setEnabled(true)
						sender.parent:setTouchEnabled(true)					
					end
					s:removeFromParent()
				end,0)
				func(RETRY)
			end,'click')	
	uikits.event( but_good,function(sender)
				uikits.delay_call(parent,function()
					if sender.parent then
						sender.parent:setEnabled(true)
						sender.parent:setTouchEnabled(true)					
					end
					s:removeFromParent()
				end,0)
				func(OK)
			end,'click')	

	but_confirm:setVisible(false)
	but_giveup:setVisible(false)
	but_know:setVisible(false)
	but_ok:setVisible(false)
	but_retry:setVisible(false)
	but_good:setVisible(false)

	if flag > #flag_dictionary then
		if txt_title and type(txt_title) == 'string' then
			title:setString(txt_title)
		else
			title:setString(flag_dictionary[#flag_dictionary].title)
		end
		
		if txt_content and type(txt_content) == 'string' then
			content:setString(txt_content)
		else
			content:setString(flag_dictionary[#flag_dictionary].content)
		end
		but_confirm:setVisible(true)
		but_giveup:setVisible(true)
		return
	else
		content:setString(flag_dictionary[flag].content)
		title:setString(flag_dictionary[flag].title)
	end
	
	if flag_dictionary[flag].button_type == 1 then
		but_retry:setVisible(true)
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
	parent:setEnabled(false)
	parent:setTouchEnabled(false)
	but_confirm.parent = parent
	but_giveup.parent = parent
	but_know.parent = parent
	but_ok.parent = parent
	but_retry.parent = parent
	but_good.parent = parent
	s:setEnabled(true)
	s:setTouchEnabled(true)
end


local base_url = 'http://app.lejiaolexue.com/poems/client.ashx'
--local base_url = 'http://schooladmin.lejiaolexue.com/client.ashx'

local function post_data_by_new_form(parent,module_id,post_data,func)
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
	send_data.rid = os.time()
	send_data.icp = false
	local str_send_data = json.encode(send_data)
	local loadbox = put_lading_circle(parent)
	print('str_send_data::'..str_send_data)
	cache.post(base_url,str_send_data,function(t,d)
		--print('d::'..d)
		local tb_result = json.decode(d)
		if t == true then
			if tb_result.c == 200 then
				func(tb_result.c,tb_result.v)
			elseif 	tb_result.c < 600 and tb_result.c > 200 then
				if tb_result.c == 505 then
					local send_data
					post_data_by_new_form(parent,'login',send_data,function(t,v)
						if t and t == 200 then
							post_data_by_new_form(parent,module_id,post_data,func)
						else
							messagebox(parent,NETWORK_ERROR,function(e)
								if e == OK then
									
								end
							end)
						end
					end)
				else
					messagebox(parent,SER_ERROR,function(e)
						if e == OK then
							
						end
					end)				
				end
			elseif  tb_result.c > 599 then
				func(tb_result.c,tb_result.msg)
			end
		else
			--func(tb_result.c,tb_result.msg)
			messagebox(parent,NETWORK_ERROR,function(e)
				if e == RETRY then
					post_data_by_new_form(parent,module_id,post_data,func)
				end
			end)
		end
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
--[[	local text=cc.Label:createWithSystemFont("继续往下拖动将更新排行榜","System",30)
	text:setVisible(false)
	text:setColor(cc.c3b(255,255,255))
	text:setAnchorPoint(cc.p(0.5,1))
	text:setPosition(viewPosition.x+viewSize.width/2,viewPosition.y+viewSize.height)
	if parent.setLayoutType then
		parent:setLayoutType(ccui.LayoutType.ABSOLUTE)
	end
	parent:addChild(text)
--]]
	local cellSize=cellItem:getContentSize()
	local bounceHeight=cellSize.height
	local top=0
	local bottom=0

--[[	--键盘和鼠标滚轮支持
	local targetPlatform=cc.Application:getInstance():getTargetPlatform()
	if targetPlatform==cc.PLATFORM_OS_WINDOWS or targetPlatform==cc.PLATFORM_OS_MAC then
		local function moveContainer(line,page)
			if tableView:isVisible() then
				local offset=tableView:getContentOffset()
				local distance=0
				if line then
					distance=line*cellSize.height
				elseif page then
					distance=page*viewSize.height
				end
				local newy=math.max(tableView:minContainerOffset().y,math.min(offset.y+distance,0))
				if newy~=offset.y then
					offset.y=newy
					tableView:setContentOffset(offset)
				end
			end
		end

		--鼠标滚轮
		local function onMouseScroll(event)
			if tableView:isVisible() then
				moveContainer(event:getScrollY())
				event:stopPropagation()
			end
		end
		local listener=cc.EventListenerMouse:create(nil)
		listener:registerScriptHandler(onMouseScroll,cc.Handler.EVENT_MOUSE_SCROLL)
		local eventDispatcher=parent:getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener,parent)

		--键盘
		local line=nil
		local page=nil
		local function processKey()
			moveContainer(line,page)
		end
		local sid=nil
		function tableView.stopKeySchedule()
			if sid then
				tableView:getScheduler():unscheduleScriptEntry(sid)
				sid=nil
			end
		end
		local function onKeyPressed(key,event)
			if tableView:isVisible() then
				tableView.stopKeySchedule()
				if key==cc.KeyCode.KEY_PG_UP or key==cc.KeyCode.KEY_KP_PG_UP then
					--上翻页
					line,page=nil,-1
					moveContainer(line,page)
					--连续按键支持
					sid=tableView:getScheduler():scheduleScriptFunc(processKey,0.1,false)
					event:stopPropagation()
				elseif key==cc.KeyCode.KEY_PG_DOWN or key==cc.KeyCode.KEY_KP_PG_DOWN then
					--下翻页
					line,page=nil,1
					moveContainer(line,page)
					--连续按键支持
					sid=tableView:getScheduler():scheduleScriptFunc(processKey,0.1,false)
					event:stopPropagation()
				elseif key==cc.KeyCode.KEY_UP_ARROW or key==cc.KeyCode.KEY_KP_UP then
					--上箭头
					line,page=-1,nil
					moveContainer(line,page)
					sid=tableView:getScheduler():scheduleScriptFunc(processKey,0.1,false)
					event:stopPropagation()
				elseif key==cc.KeyCode.KEY_DOWN_ARROW or key==cc.KeyCode.KEY_KP_DOWN then
					--下箭头
					line,page=1,nil
					moveContainer(line,page)
					sid=tableView:getScheduler():scheduleScriptFunc(processKey,0.1,false)
					event:stopPropagation()
				elseif key==cc.KeyCode.KEY_HOME or key==cc.KeyCode.KEY_KP_HOME then
					local offset=tableView:getContentOffset()
					if offset.y>bottom then
						offset.y=bottom
						tableView:setContentOffset(offset)
					end
					event:stopPropagation()
				elseif key==cc.KeyCode.KEY_END or key==cc.KeyCode.KEY_KP_END then
					local offset=tableView:getContentOffset()
					if offset.y<top then
						offset.y=top
						tableView:setContentOffset(offset)
					end
					event:stopPropagation()
				end
			end
		end
		
		local function onKeyReleased(key,event)
			if tableView:isVisible() then
				tableView.stopKeySchedule()
			end
		end
		local listener=cc.EventListenerKeyboard:create()
		listener:registerScriptHandler(onKeyPressed,cc.Handler.EVENT_KEYBOARD_PRESSED)
		listener:registerScriptHandler(onKeyReleased,cc.Handler.EVENT_KEYBOARD_RELEASED)
		local eventDispatcher=tableView:getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener,tableView)
	end
--]]
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
--[[	tableView:registerScriptHandler(function(table)
	--	text:setString("继续往下拖动将更新排行榜")
	--	text:setVisible(false)
		--限制拖动范围
		local offset=tableView:getContentOffset()
		if offset.y<bottom then
			if tableView:isDragging() then
				if bottom-offset.y>bounceHeight then
					--触底准备触发刷新
					offset.y=bottom-bounceHeight
					tableView:setContentOffset(offset)
					check=true
				--	text:setString("释放拖动将更新排行榜")
				else
					--尚未触底或者取消触发刷新
					if check and bottom-offset.y<bounceHeight*2/3 then
						check=false
					end
					if check then
					--	text:setString("释放拖动将更新排行榜")
					end
				--	text:setVisible(true)
				end
			elseif check and reflash then
				--释放拖动并触发刷新
				offset.y=bottom
				tableView:setBounceable(false)			--暂停回弹，免得画面乱跑
				tableView:setContentOffset(offset)
				reflash(tableView:getParent(),tableView.setData)
				check=false
			end
			return
		elseif offset.y>top then
			if tableView:isDragging() and offset.y-top>bounceHeight then
				offset.y=top+bounceHeight
				tableView:setContentOffset(offset)
			end
			return
		end
	end,cc.SCROLLVIEW_SCRIPT_SCROLL)--]]

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

	print(string.format(...))

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

--粒子效果
local PARTICLE_WIND = "poetrymatch/Particles/hua.plist"
local PARTICLE_SNOW = "poetrymatch/Particles/xue.plist"

local randomForParticle = 0
local function getParticleEffect()

	if randomForParticle == 0 then
		math.randomseed(os.time())
		randomForParticle = math.random(2)
	end
	
	local _particle
	if randomForParticle == 1 then
		_particle = cc.ParticleSystemQuad:create(PARTICLE_WIND)
		_particle:setPosition(
			cc.Director:getInstance():getVisibleSize().width, 
			cc.Director:getInstance():getVisibleSize().height / 2)
		_particle:setScale(3.0)
	else
		_particle = cc.ParticleSystemQuad:create(PARTICLE_SNOW)
		_particle:setPosition(
			cc.Director:getInstance():getVisibleSize().width / 2, 
			cc.Director:getInstance():getVisibleSize().height)
		_particle:setScale(3.0)
	end

	return _particle
end

return {
	get_user_info = get_user_info,
	set_user_info = set_user_info,
	update_user_info_by_tag = update_user_info_by_tag,
	set_user_tili = set_user_tili,
	get_user_tili = get_user_tili,
	get_user_lvl_info = get_user_lvl_info,
	set_user_lvl_info = set_user_lvl_info,	
	get_user_silver = get_user_silver,
	set_user_silver = set_user_silver,	
	add_user_silver = add_user_silver,
	remove_user_silver = remove_user_silver,
	get_user_le_coin = get_user_le_coin,
	set_user_le_coin = set_user_le_coin,
	add_user_le_coin = add_user_le_coin,
	remove_user_le_coin = remove_user_le_coin,
	set_max_store_num = set_max_store_num,
	get_max_store_num = get_max_store_num,
	add_card_to_bag = add_card_to_bag,	
	set_all_card_to_bag = set_all_card_to_bag,
	get_all_card_in_bag = get_all_card_in_bag,	
	update_card_in_bag_by_id = update_card_in_bag_by_id,
	del_card_in_bag_by_id = del_card_in_bag_by_id,
	get_card_in_bag_by_index = get_card_in_bag_by_index,	
	add_card_to_battle_by_index = add_card_to_battle_by_index,
	get_battle_list = get_battle_list,
	get_card_in_bag_by_id = get_card_in_bag_by_id,
	exchange_card_in_battle_by_id = exchange_card_in_battle_by_id,
	get_all_card_in_battle = get_all_card_in_battle,
	get_all_card_in_battle = get_all_card_in_battle,
	load_section_pic = load_section_pic,
	load_skill_pic = load_skill_pic,
	load_card_pic = load_card_pic,
	load_logo_pic = load_logo_pic,
	set_all_section_info = set_all_section_info,
	get_all_section_info = get_all_section_info,
	get_boss_info_by_id = get_boss_info_by_id,
	set_boss_info_by_id = set_boss_info_by_id,
	set_skill_list = set_skill_list,
	get_skill_list = get_skill_list,
	get_skill_info_by_id = get_skill_info_by_id,
	post_data_by_new_form = post_data_by_new_form,
	messagebox = messagebox,
	createRankView = createRankView,
	logTable = logTable,
	getParticleEffect = getParticleEffect,
	log = log,
	RETRY = RETRY,
	OK = OK,
	FAIL = FAIL,
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
}
