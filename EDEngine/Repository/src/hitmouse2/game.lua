--[[
[
	{
		idiom:"疲于奔命",
		pingyin:"pí yú bēn mìng",
		explanation:"原指因奉命奔走而精疲力尽。后也指事情繁多，忙不过来。",
		source:"《三国志·魏书·袁绍传》",
		memo:"晋·陈寿《三国志·魏书·袁绍传》：“乘虚迭出，以扰河南，救右则击其左，救左则击其右，使敌疲于奔命。”",
		story:"春秋时期，楚国战胜宋国，大将子重居功要求楚王把北部两处地方封赏给自己，大臣申公巫臣极力反对，楚王没有答应子重的要求。另一个大臣子反想娶美丽的夏姬，巫臣却说夏姬命相不好，不能娶",
		character:[
			"申公巫",
			"夏姬",
			"子重",
			"子反",
			"楚王",
		]
	},
]
--]]
local kits = require "kits"
local json = require "json-c"

local _cy --成语列表
local _gr --迷惑项
local _characters --[{character,idiom:[]},]
local _sources --[{source,idiom:[]},]

local function init_data( o )
	if _cy and _cy then return end
	local filename = "res/hitmouse2/data/cy.json"
	local s = kits.read_local_file(filename)
	if s then
		local errmsg
		_cy,errmsg = json.decode(s)
		if not _cy then
			kits.log("ERROR decode failed "..filename)
			kits.log("	"..tostring(errmsg))
		else
			kits.log("初始化成语库成功，数据量:"..#_cy)
		end
	else
		kits.log("ERROR can't read file "..filename)
	end
	filename = "res/hitmouse2/data/gr.json"
	s = kits.read_local_file(filename)
	if s then
		local errmsg
		_gr = json.decode(s)
		if not _gr then
			kits.log("ERROR decode failed "..filename)
			kits.log("	"..tostring(errmsg))
		end		
	else
		kits.log("ERROR can't read file "..filename)
	end	
	filename = "res/hitmouse2/data/gr1.json"
	s = kits.read_local_file(filename)
	if s then
		local errmsg
		local gr = json.decode(s)
		if not gr then
			kits.log("ERROR decode failed "..filename)
			kits.log("	"..tostring(errmsg))
		end		
		for i,v in pairs(gr) do
			if i and v then
				_gr[i] = v
			end
		end
	else
		kits.log("ERROR can't read file "..filename)
	end	
	
	if not _cy then
		kits.log("ERROR hitmouse2 initialization game data failed!")
		return
	end
	--init _characters
	local ct = {}
	for i,v in pairs(_cy) do
		if v and v.character then
			for k,s in pairs(v.character) do
				if not ct[s] then
					ct[s] = {character=s,idiom={}}
				end
				ct[s].idiom[v.idiom] = v.idiom
			end
		end
	end
	_characters = {}
	for i,v in pairs(ct) do
		local idiom = {}
		for k,s in pairs(v.idiom) do
			table.insert(idiom,s)
		end
		table.insert(_characters,{character=v.character,idiom=idiom})
	end
	--init _sources
	ct = {}
	for i,v in pairs(_cy) do
		if v and v.source then
			if not ct[v.source] then
				ct[v.source] = {source=v.source,idiom={}}
			end
			ct[v.source].idiom[v.idiom] = v.idiom
		end	
	end
	_sources = {}
	for i,v in pairs(ct) do
		local idiom = {}
		for k,s in pairs(v.idiom) do
			table.insert(idiom,s)
		end
		table.insert(_sources,{source=v.source,idiom=idiom})
	end
end

local function utf8_string_to_table( w )
	local length = cc.utf8.length(w)
	local t = {}
	if length and length > 1 then
		local idx = 0
		repeat
			local idx2 = cc.utf8.next(w,idx)
			if idx2 then
				table.insert(t,string.sub(w,idx+1,idx+idx2))
				idx = idx2 + idx
			end
		until #t >= length
	end
	return t
end

local function diffRandom(i)
	while true do
		local v = math.random(1,4)
		if v ~= i then
			return v
		end
	end
end

local function makeWord(s,n)
	if n==1 then
		local i = math.random(1,4)
		local d = s[i]
		local text = ""
		local answer = d..","
		local gr = _gr[d]
		if gr then
			local grt = utf8_string_to_table( gr )
			for k=1,3 do
				answer=answer..tostring(grt[k])
			end
		else
			kits.log("ERROR makeWord can't found "..tostring(d))
		end
		for j=1,4 do
			if j ~= i then
				text=text..s[j]
			else
				text=text.."(　)"
			end
		end
		return {name=text,answer=answer}
	elseif n==2 then
		local _1 = math.random(1,4)
		local _2 = diffRandom(i)
		local i = math.min(_1,_2)
		local i2 = math.max(_1,_2)
		local d = s[i]
		local d2 = s[i2]
		local text = ""
		local answer = d..d2..","
		local gr = _gr[d]		
		local gr2 = _gr[d2]	
		if gr and gr2 then
			if d ~= d2 then
				local grt = utf8_string_to_table( gr )
				local grt2 = utf8_string_to_table( gr2 )
				answer=answer..grt[1]..grt2[1]
			else
				answer = d..","
				local grt = utf8_string_to_table( gr )
				for k=1,3 do
					answer=answer..tostring(grt[k])
				end				
			end
		else
			kits.log("ERROR makeWord can't found "..tostring(d)..","..tostring(d2))
		end
		for j=1,4 do
			if j ~= i and j ~= i2 then
				text=text..s[j]
			else
				text=text.."(　)"
			end
		end
		return {name=text,answer=answer}
	end
end

local function random_rang(rangs)
	local count = #rangs
	for i = 1,count do
		local s = rangs[i]
		local idx = math.random(1,count)
		rangs[i] = rangs[idx]
		rangs[idx] = s
	end	
end

local function in_table(item,t)
	if t then
		for i,v in pairs(t) do
			if item == v then
				return true
			end
		end
	end
	return false
end

local function make_answer_by_character(rangs,correct_pos)
	local ct = rangs[correct_pos].character
	local correct = ct[math.random(1,#ct)]
	local answer = {}
	local idiom = rangs[correct_pos].idiom
	table.insert(answer,correct)
	for i=1,3 do
		local c
		repeat
			local cmi = _characters[math.random(1,#_characters)]
			c = cmi.character
		until not in_table(c,answer) and not in_table(idiom,cmi.idiom)
		table.insert(answer,c)
	end
	random_rang(answer)
	return answer,correct
end

local function make_answer_by_idiom(rangs,correct_pos)
	local correct = rangs[correct_pos].idiom
	local answer = {}
	table.insert(answer,correct)
	for i=1,3 do
		local idiom
		repeat
			idiom = _cy[math.random(1,#_cy)].idiom
		until idiom ~= correct
		table.insert(answer,idiom)
	end
	random_rang(answer)
	return answer,correct	
end

local function make_answer_by_idiom_exclude_character(rangs,correct_pos)
	local rt = rangs[correct_pos]
	local correct = rt.idiom
	local character = rt.character[math.random(1,#rt.character)]
	local answer = {}
	table.insert(answer,correct)
	for i=1,3 do
		local idiom
		repeat
			local cyt = _cy[math.random(1,#_cy)]
			idiom = cyt.idiom
		until idiom ~= correct and not in_table(character,cyt.character)
		table.insert(answer,idiom)	
	end
	random_rang(answer)
	return answer,correct,character
end

local function make_answer_by_idiom_exclude_source(rangs,correct_pos)
	local rt = rangs[correct_pos]
	local correct = rt.idiom
	local source = rt.source
	local answer = {}
	table.insert(answer,correct)
	for i=1,3 do
		local idiom
		repeat
			local cyt = _cy[math.random(1,#_cy)]
			idiom = cyt.idiom
		until idiom ~= correct and source ~= cyt.source
		table.insert(answer,idiom)	
	end
	random_rang(answer)
	return answer,correct,source
end

local function make_answer_by_source(rangs,correct_pos)
	local rt = rangs[correct_pos]
	local correct = rt.source
	local idiom = rt.idiom
	local answer = {}
	table.insert(answer,correct)
	for i=1,3 do
		local source
		repeat
			local st = _sources[math.random(1,#_sources)]
			source = st.source 
		until source ~= correct and not in_table(correct,st.idiom)
		table.insert(answer,source)	
	end
	random_rang(answer)
	return answer,correct
end
--[[
	t的含义
	{
		question_amount, 总数
		time_limit,时间限定(秒)
		road_radom,随机数
		diffcult(int)难度(1-9)
		answers:[
			{
				type(int):题目的类型(1-7)	
					1.成语补全,缺字选择补全
					2.成语选典故人物
					3.典故选成语
					4.出处选成语
					5.成语选出处
					6.释义选成语
					7.释义填空成语
				count(int): 该题型的数量
				cy_id(string): 正常给我一个空的字符串
				（当错题任务时，可以指定count=1,cy_id=错题id）
			},
		]
	}
	cy_id(string) :是一个编码过得json
	{
		type(int): 题型
		name(string): 题面
			1.成语补全
				name:"犹豫(　)决"
				answer:"不,步,布,补"
			2.成语选典故人物
				name:"变化无方"
				answer:
				[
					"曹操",
					"长安君",
					"赵威后",
					"触詟"
				]
			3.典故人物选成语
			4.出处选成语
			5.成语选出处
			6.释义选成语
			7.释义填成语
		answer(string): 答案
			选项用","分割
		correct : 正确答案
		entry : 引用的成语条目
	}
--]]
local function get_topics(rangs,type,count)
	local result = {}
	if type==1 then
		for i=1,count do
			if rangs[i] then
				local s = utf8_string_to_table(rangs[i].idiom)
				if s and #s >= 4 then
					local qs = makeWord(s,1)
					table.insert(result,{type=type,count=1,name=qs.name,answer=qs.answer,correct=cor,entry=rangs[i],inx=i})
				else
					kits.log("ERROR get_topics cy.json invaild "..tostring(s))
				end
			end
		end
	elseif type==2 then
		local c = 0
		for i=1,#rangs do
			if rangs[i] then
				if rangs[i].character and #rangs[i].character > 0 then
					local qa,cor = make_answer_by_character(rangs,i)
					table.insert(result,{type=type,count=1,name=rangs[i].idiom,answer=qa,correct=cor,entry=rangs[i],inx=i})
					c = c+1
					if c >= count then
						break
					end
				end
			else
				kits.log("ERROR get_topics rangs["..tostring(i).."]=nil")
			end
		end
	elseif type==3 then
		local c = 0
		for i=1,#rangs do
			if rangs[i] then
				if rangs[i].character and #rangs[i].character > 0 then
					local qa,cor,chara = make_answer_by_idiom_exclude_character(rangs,i)
					table.insert(result,{type=type,count=1,name=chara,answer=qa,correct=cor,entry=rangs[i],inx=i})
					c = c+1
					if c >= count then
						break
					end
				end
			else
				kits.log("ERROR get_topics rangs["..tostring(i).."]=nil")
			end
		end	
	elseif type==4 then
		local c = 0
		for i=1,#rangs do
			if rangs[i] then
				if rangs[i].source and string.len(rangs[i].source) > 0 then
					local qa,cor = make_answer_by_idiom_exclude_source(rangs,i)
					table.insert(result,{type=type,count=1,name=rangs[i].source,answer=qa,correct=cor,entry=rangs[i],inx=i})
					c = c+1
					if c >= count then
						break
					end
				end
			else
				kits.log("ERROR get_topics rangs["..tostring(i).."]=nil")
			end
		end		
	elseif type==5 then
		local c = 0
		for i=1,#rangs do
			if rangs[i] then
				if rangs[i].idiom and string.len(rangs[i].idiom) > 0 then
					local qa,cor = make_answer_by_source(rangs,i)
					table.insert(result,{type=type,count=1,name=rangs[i].idiom,answer=qa,correct=cor,entry=rangs[i],inx=i})
					c = c+1
					if c >= count then
						break
					end
				end
			else
				kits.log("ERROR get_topics rangs["..tostring(i).."]=nil")
			end
		end		
	elseif type==6 then
		local c = 0
		for i=1,#rangs do
			if rangs[i] and rangs[i].explanation then
				local ss = utf8_string_to_table(rangs[i].explanation)
				local length = #ss
				if  length > 4 and length < 25 then
					local qa,cor = make_answer_by_idiom(rangs,i)
					table.insert(result,{type=type,count=1,name=rangs[i].explanation,answer=qa,correct=cor,entry=rangs[i],inx=i})
					c = c+1
					if c >= count then
						break
					end
				end
			else
				kits.log("ERROR get_topics rangs["..tostring(i).."]=nil")
			end
		end		
	elseif type==7 then
		local c = 0
		for i=1,#rangs do
			if rangs[i] and rangs[i].explanation then
				local ss = utf8_string_to_table(rangs[i].explanation)
				local length = #ss			
				if length > 4 and length < 25 then
					table.insert(result,{type=type,count=1,name=rangs[i].explanation,answer={},correct=rangs[i].idiom,entry=rangs[i],inx=i})
					c = c+1
					if c >= count then
						break
					end
				end
			else
				kits.log("ERROR get_topics rangs["..tostring(i).."]=nil")
			end
		end	
	else
		kits.log("ERROR can not support type of question")
	end
	return result
end

local diffcult_table={
	[1] = {
		1,149
	},
	[2] = {
		150,317
	},
	[3] = {
		318,501
	},
	[4] = {
		502,704
	},
	[5] = {
		705,949
	},
	[6] = {
		950,1244
	},
	[7] = {
		1245,1567
	},
	[8] = {
		1568,2004
	},
	[9] = {
		2005,2566
	},	
}
local function init_game(t)
	if not _cy then
		kits.log("ERROR can not initialization game,_cy = nil")
		return
	end
	local diffcult = t.diffcult or 1
	diffcult = math.min(diffcult,9)
	diffcult = math.max(diffcult,1)
	local rangs = {}
	local count = #_cy
	for i=diffcult_table[diffcult][1],diffcult_table[diffcult][2] do
		if _cy[i] then
			table.insert(rangs,_cy[i])
		else
			kits.log("Warning : diffcult out of rang : "..tostring(i))
		end
	end
	--linear
	-- for i=math.floor((diffcult-1)*count/9),math.floor(diffcult*count/9) do
		-- if _cy[i] then
			-- table.insert(rangs,_cy[i])
		-- end
	-- end
	math.randomseed(t.road_radom or 0)
	local result = {}
	result.question_amount = t.question_amount
	result.time_limit = t.time_limit
	result.road_radom = t.road_radom or 0
	result.diffcult =  diffcult
	if t.answers and type(t.answers)=='table' then
		result.answers = {}
		local begin = 1
		for i,v in pairs(t.answers) do
			random_rang(rangs) 
			if v.count and v.count > 0 then
				local tt = get_topics(rangs,v.type,v.count)
				for k,s in pairs(tt) do
					table.insert(result.answers,s)
				end
			end
		end
	else
		kits.log("ERROR init_game t.answers = nil or is not table")
		result.answers = {}
	end
	random_rang(result.answers)
	return result
end

local _count = 60
local _current = 1

local function setLevelCount(c)
	_count = c
end

local function getLevelCount()
	return _count
end

local function setCurrent(c)
	_current = c
end

local function getCurrent()
	return _current
end

return {
	init = init_data,
	get = init_game,
	setLevelCount = setLevelCount,
	getLevelCount = getLevelCount,
	setCurrent = setCurrent,
	getCurrent = getCurrent,
	get_topics = get_topics,
	random_rang = random_rang,
}