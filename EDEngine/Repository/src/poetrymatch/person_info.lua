local g_person_name
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
local g_person_section_info = {{id='fengyang',star_has=18,star_all=30,is_admit=1,},{id='fengyanga',star_has=19,star_all=30,is_admit=1,},{id='fengyangb',star_has=5,star_all=30,is_admit=0,},}

local function get_user_name()
	local uname = ''
	if g_person_name then
		uname = g_person_name
	end
	return uname
end

local function set_user_name(uname)
	if uname then
		g_person_name = uname
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

local function load_card_pic(handle,filename,filename1)
	if handle and filename then
		local file_path = card_root_path..filename
		local file_down_path
		if cc_type(handle) == 'ccui.Button' then
			if filename1 then
				file_down_path = card_root_path..filename1
			else
				file_down_path = file_path
			end
			handle:loadTextures(file_path, file_down_path, "")
		elseif cc_type(handle) == 'ccui.ImageView' then
			handle:loadTexture(file_path)
		end
		return true
	else
		return false
	end
end

local function load_section_pic(handle,filename,filename1)
	if handle and filename then
		local file_path = section_root_path..filename
		local file_down_path
		if cc_type(handle) == 'ccui.Button' then
			if filename1 then
				file_down_path = section_root_path..filename1
			else
				file_down_path = file_path
			end
			handle:loadTextures(file_path, file_down_path, "")
		elseif cc_type(handle) == 'ccui.ImageView' then
			handle:loadTexture(file_path)
		end
		return true
	else
		return false
	end
end

local function load_skill_pic(handle,filename,filename1)
	if handle and filename then
		local file_path = skill_root_path..filename
		local file_down_path
		if cc_type(handle) == 'ccui.Button' then
			if filename1 then
				file_down_path = skill_root_path..filename1
			else
				file_down_path = file_path
			end
			handle:loadTextures(file_path, file_down_path, "")
		elseif cc_type(handle) == 'ccui.ImageView' then
			handle:loadTexture(file_path)
		end
		return true
	else
		return false
	end
end

return {
	get_user_name = get_user_name,
	set_user_name = set_user_name,
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
}
