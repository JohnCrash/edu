local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local uikits = require "uikits"

local g_person_info = {
id = 149091,
name = 'liyihang',
lvl = 5,
}
local g_person_exp = {
lvl = 5,
cur_exp = 10,
max_exp = 100,
} -- lvl,cur_exp,max_exp

local g_person_silver = 100
local g_person_le_coin = 10

local g_person_bag = {
cards_table = {{id='caoz',lvl=5,cur_exp=10,max_exp=100},{id='caoa',lvl=10,cur_exp=20,max_exp=100},{id='caob',lvl=20,cur_exp=30,max_exp=100},{id='caoc',lvl=30,cur_exp=40,max_exp=100},},
equipment_table = {},
skill_table = {},
} -- 

local g_person_battle_cards = {'caoz','caoc'}
local g_person_section_info = {{id='fengyang',name='凤阳城',star_has=18,star_all=30,is_admit=1,},{id='fengyanga',name='凤阳城A',star_has=19,star_all=30,is_admit=1,},{id='fengyangb',name='凤阳城B',star_has=5,star_all=30,is_admit=1,},{id='fengyangc',name='凤阳城C',star_has=0,star_all=30,is_admit=0,},}
local g_person_boss_info = {
fengyang = {
{id='caoz',name='曹植铜',lvl=20,tili=12,pinzhi=1,shenli=1,hp=150,hp_ex=10,mp=100,mp_ex=10,ap=100,ap_ex=10,star1='1111',star2='1111',star3='1111',star_has=3,is_admit=1,content={{id=149091,data='aaaaa'},{id=0,data='bbbbb'},{id=149091,data='ccccc'},{id=0,data='ddddd'},},},
{id='caoa',name='曹植银',lvl=30,tili=12,pinzhi=2,shenli=1,hp=250,hp_ex=20,mp=200,mp_ex=0,ap=200,ap_ex=10,star1='2222',star2='2222',star3='2222',star_has=2,is_admit=1,content={{id=149091,data='aaaaa'},{id=0,data='bbbbb'},{id=149091,data='ccccc'},{id=0,data='ddddd'},},},
{id='caob',name='曹植金',lvl=40,tili=12,pinzhi=3,shenli=1,hp=350,hp_ex=30,mp=300,mp_ex=0,ap=300,ap_ex=0,star1='3333',star2='3333',star3='3333',star_has=0,is_admit=1,content={{id=149091,data='aaaaa'},{id=0,data='bbbbb'},{id=149091,data='ccccc'},{id=0,data='ddddd'},},},
{id='caoc',name='曹植金',lvl=50,tili=12,pinzhi=3,shenli=2,hp=450,hp_ex=40,mp=400,mp_ex=0,ap=400,ap_ex=0,star1='4444',star2='4444',star3='4444',star_has=0,is_admit=0,content={{id=149091,data='aaaaa'},{id=0,data='bbbbb'},{id=149091,data='ccccc'},{id=0,data='ddddd'},},},
},
fengyanga = {
{id='caoz',name='曹植铜',lvl=20,tili=12,pinzhi=1,shenli=1,hp=150,hp_ex=10,mp=100,mp_ex=10,ap=100,ap_ex=10,star1='1111',star2='1111',star3='1111',star_has=3,is_admit=1,content={{id=149091,data='aaaaa'},{id=0,data='bbbbb'},{id=149091,data='ccccc'},{id=0,data='ddddd'},},},
{id='caoa',name='曹植银',lvl=30,tili=12,pinzhi=2,shenli=1,hp=250,hp_ex=20,mp=200,mp_ex=0,ap=200,ap_ex=10,star1='2222',star2='2222',star3='2222',star_has=2,is_admit=1,content={{id=149091,data='aaaaa'},{id=0,data='bbbbb'},{id=149091,data='ccccc'},{id=0,data='ddddd'},},},
{id='caob',name='曹植金',lvl=40,tili=12,pinzhi=3,shenli=1,hp=350,hp_ex=30,mp=300,mp_ex=0,ap=300,ap_ex=0,star1='3333',star2='3333',star3='3333',star_has=0,is_admit=1,content={{id=149091,data='aaaaa'},{id=0,data='bbbbb'},{id=149091,data='ccccc'},{id=0,data='ddddd'},},},
{id='caoc',name='曹植金',lvl=50,tili=12,pinzhi=3,shenli=2,hp=450,hp_ex=40,mp=400,mp_ex=0,ap=400,ap_ex=0,star1='4444',star2='4444',star3='4444',star_has=0,is_admit=0,content={{id=149091,data='aaaaa'},{id=0,data='bbbbb'},{id=149091,data='ccccc'},{id=0,data='ddddd'},},},
},
fengyangb = {
{id='caoz',name='曹植铜',lvl=20,tili=12,pinzhi=1,shenli=1,hp=150,hp_ex=10,mp=100,mp_ex=10,ap=100,ap_ex=10,star1='1111',star2='1111',star3='1111',star_has=3,is_admit=1,content={{id=149091,data='aaaaa'},{id=0,data='bbbbb'},{id=149091,data='ccccc'},{id=0,data='ddddd'},},},
{id='caoa',name='曹植银',lvl=30,tili=12,pinzhi=2,shenli=1,hp=250,hp_ex=20,mp=200,mp_ex=0,ap=200,ap_ex=10,star1='2222',star2='2222',star3='2222',star_has=2,is_admit=1,content={{id=149091,data='aaaaa'},{id=0,data='bbbbb'},{id=149091,data='ccccc'},{id=0,data='ddddd'},},},
{id='caob',name='曹植金',lvl=40,tili=12,pinzhi=3,shenli=1,hp=350,hp_ex=30,mp=300,mp_ex=0,ap=300,ap_ex=0,star1='3333',star2='3333',star3='3333',star_has=0,is_admit=1,content={{id=149091,data='aaaaa'},{id=0,data='bbbbb'},{id=149091,data='ccccc'},{id=0,data='ddddd'},},},
{id='caoc',name='曹植金',lvl=50,tili=12,pinzhi=3,shenli=2,hp=450,hp_ex=40,mp=400,mp_ex=0,ap=400,ap_ex=0,star1='4444',star2='4444',star3='4444',star_has=0,is_admit=0,content={{id=149091,data='aaaaa'},{id=0,data='bbbbb'},{id=149091,data='ccccc'},{id=0,data='ddddd'},},},
},
fengyangc = {
{id='caoz',name='曹植铜',lvl=20,tili=12,pinzhi=1,shenli=1,hp=150,hp_ex=10,mp=100,mp_ex=10,ap=100,ap_ex=10,star1='1111',star2='1111',star3='1111',star_has=3,is_admit=1,content={{id=149091,data='aaaaa'},{id=0,data='bbbbb'},{id=149091,data='ccccc'},{id=0,data='ddddd'},},},
{id='caoa',name='曹植银',lvl=30,tili=12,pinzhi=2,shenli=1,hp=250,hp_ex=20,mp=200,mp_ex=0,ap=200,ap_ex=10,star1='2222',star2='2222',star3='2222',star_has=2,is_admit=1,content={{id=149091,data='aaaaa'},{id=0,data='bbbbb'},{id=149091,data='ccccc'},{id=0,data='ddddd'},},},
{id='caob',name='曹植金',lvl=40,tili=12,pinzhi=3,shenli=1,hp=350,hp_ex=30,mp=300,mp_ex=0,ap=300,ap_ex=0,star1='3333',star2='3333',star3='3333',star_has=0,is_admit=1,content={{id=149091,data='aaaaa'},{id=0,data='bbbbb'},{id=149091,data='ccccc'},{id=0,data='ddddd'},},},
{id='caoc',name='曹植金',lvl=50,tili=12,pinzhi=3,shenli=2,hp=450,hp_ex=40,mp=400,mp_ex=0,ap=400,ap_ex=0,star1='4444',star2='4444',star3='4444',star_has=0,is_admit=0,content={{id=149091,data='aaaaa'},{id=0,data='bbbbb'},{id=149091,data='ccccc'},{id=0,data='ddddd'},},},
},
}
local function get_user_info()
	local uname = {}
	if g_person_info then
		uname = g_person_info
	end
	return uname
end

local function set_user_info(uinfo)
	if uinfo then
		g_person_info = uinfo
		return true
	else
		return false
	end
end

local function get_user_lvl_info()
	local ulvl_info = {}
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

local function set_all_card_to_bag(cards_table)
	if cards_table and type(cards_table) == 'table' then
		g_person_bag.cards_table = cards_table
		return true
	else
		return false
	end
end

local function get_all_card_in_bag()
	local cards_table = {}
	if g_person_bag.cards_table then
		cards_table = g_person_bag.cards_table
	end
	return cards_table
end

local function get_card_in_bag_by_index(index)
	local card_info = {}
	if index then
		if g_person_bag.cards_table and g_person_bag.cards_table[index] then
			card_info = g_person_bag.cards_table[index]
			return card_info
		end
	end
	return nil
end

local function get_card_in_bag_by_id(id)
	local card_info = {}
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
	local card_info = {}
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

local function get_all_card_in_battle()
	local all_cards_table = {}
	for i,v in ipairs(g_person_bag.cards_table) do	
		for j=1,#g_person_battle_cards do
			if v.id == g_person_battle_cards[j] then
				local card_info = {}
				card_info = g_person_bag.cards_table[j]
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
			if filename1 then
				file_down_path = card_root_path..filename1
			else
				file_down_path = file_path
			end
			if filename2 then
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
			if filename1 then
				file_down_path = section_root_path..filename1
			else
				file_down_path = file_path
			end
			if filename2 then
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
			if filename1 then
				file_down_path = skill_root_path..filename1
			else
				file_down_path = file_path
			end
			if filename2 then
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

local function set_all_section_info(all_section_info)
	if all_section_info and type(all_section_info) == 'table' then
		g_person_section_info = all_section_info
	end
end

local function get_all_section_info()
	local all_section_info = {}
	all_section_info = g_person_section_info
	return all_section_info
end

local function get_boss_info_by_id(id)
	local boss_info = {}
	if g_person_boss_info[id] then
		boss_info = g_person_boss_info[id]
	end 
	return boss_info
end

local base_url = 'http://schooladmin.lejiaolexue.com/client.ashx'

local function post_data_by_new_form(module_id,post_data,func)
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
	print('str_send_data::'..str_send_data)
	cache.post(base_url,str_send_data,function(t,d)
		print('d::'..d)
		local tb_result = json.decode(d)
		if t == true then
			func(t,tb_result.v)
		else
			func(t,tb_result.msg)
		end
	end)		
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
{title = '啊！上不了网了',content='少侠，你的网络突然中断了，请检查一下网络，然后重试一下！',button_type = 1,}, --网络中断
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
					s:removeFromParent()
				end,0)
				func(OK)
			end,'click')	
	uikits.event( but_giveup,function(sender)
				uikits.delay_call(parent,function()
					s:removeFromParent()
				end,0)
				func(FAIL)
			end,'click')	
	uikits.event( but_know,function(sender)
				uikits.delay_call(parent,function()
					s:removeFromParent()
				end,0)
				func(OK)
			end,'click')	
			
	uikits.event( but_ok,function(sender)
				uikits.delay_call(parent,function()
					s:removeFromParent()
				end,0)
				func(OK)
			end,'click')	
			
	uikits.event( but_retry,function(sender)
				uikits.delay_call(parent,function()
					s:removeFromParent()
				end,0)
				func(RETRY)
			end,'click')	
	uikits.event( but_good,function(sender)
				uikits.delay_call(parent,function()
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
	parent:addChild( s,9999 )
end

return {
	get_user_info = get_user_info,
	set_user_info = set_user_info,
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
	add_card_to_bag = add_card_to_bag,	
	set_all_card_to_bag = set_all_card_to_bag,
	get_all_card_in_bag = get_all_card_in_bag,	
	get_card_in_bag_by_index = get_card_in_bag_by_index,	
	add_card_to_battle_by_index = add_card_to_battle_by_index,
	get_card_in_battle_by_index = get_card_in_battle_by_index,
	get_card_in_bag_by_id = get_card_in_bag_by_id,
	get_all_card_in_battle = get_all_card_in_battle,
	load_section_pic = load_section_pic,
	load_skill_pic = load_skill_pic,
	load_card_pic = load_card_pic,
	set_all_section_info = set_all_section_info,
	get_all_section_info = get_all_section_info,
	get_boss_info_by_id = get_boss_info_by_id,
	post_data_by_new_form = post_data_by_new_form,
	messagebox = messagebox,
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
	HAS_TILI = NO_TILI,
	DEL_CARD = DEL_CARD,
	LEARN_SKILL = LEARN_SKILL,
	RESET_SKILL = RESET_SKILL,
	BATTLE_GIVEUP = BATTLE_GIVEUP,
	BUY_SILVER = BUY_SILVER,
	DIY_MSG = DIY_MSG,
}
