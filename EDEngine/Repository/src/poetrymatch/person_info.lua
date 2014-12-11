local g_person_name
local g_person_exp = {
lvl = 0,
cur_exp = 0,
max_exp = 0,
} -- lvl,cur_exp,max_exp

local g_person_silver
local g_person_le_coin

local g_person_bag = {
cards_table = {},
equipment_table = {},
skill_table = {},
} -- 

local g_person_battle_cards = {}
local g_person_section_info = {}

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
			if v.id = id then
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
			if v.id = id then
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
			if v.id = id then
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
			if v.id = id then
				card_info = g_person_bag.cards_table[i]
				return card_info
			end
		end
	end
	return nil
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
}
