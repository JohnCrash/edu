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
    {
        "idiom": "啊",
        "pinyin": "ā",
        "explanation": "叹词，表示赞叹或惊异",
        "story": "",
        "character": []
    },
    {
        "idiom": "阿",
        "pinyin": "ā",
        "explanation": "加在称呼上的词头",
        "story": "",
        "character": []
    },	
]
--]]
local kits = require "kits"
local json = require "json-c"

--[[
 āáǎà
 ēéěè
 ūúǔù
 ōóǒò
 īíǐì
 ǖǘǚǜ
 êńňü
 --]]
local _yuan = {
	['a'] = {'ā','á','ǎ','à'},
	['e'] = {'ē','é','ě','è'},
	['u'] = {'ū','ú','ǔ','ù'},
	['o'] = {'ō','ó','ǒ','ò'},
	['i'] = {'ī','í','ǐ','ì'},
	['ü'] = {'ǖ','ǘ','ǚ','ǜ'},
}

local _yuan2 = {
	['ā'] = 'a',
	['á'] = 'a',
	['ǎ'] = 'a',
	['à'] = 'a',
	['ē'] = 'e',
	['é'] = 'e',
	['ě'] = 'e',
	['è'] = 'e',
	['ū'] = 'u',
	['ú'] = 'u',
	['ǔ'] = 'u',
	['ù'] = 'u',
	['ō'] = 'o',
	['ó'] = 'o',
	['ǒ'] = 'o',
	['ò'] = 'o',
	['ī'] = 'i',
	['í'] = 'i',
	['ǐ'] = 'i',
	['ì'] = 'i',
	['ǖ'] = 'u',
	['ǘ'] = 'u',
	['ǚ'] = 'u',
	['ǜ'] = 'u',
}

local _jing = {
	{'c','ch'},
	{'s','sh'},
	{'l','n'},
	{'f','h'},
	{'uan','uang'},
	{'an','ang'},
	{'in','ing'},
	{'en','eng'},
}

local function utf8_string_to_table( w )
	local length = cc.utf8.length(w)
	local len = string.len(w)
	local t = {}
	if length and length >= 1 then
		local idx = 0
		repeat
			local idx2 = cc.utf8.next(w,idx)
			if idx2 and idx+idx2 <= len then
				table.insert(t,string.sub(w,idx+1,idx+idx2))
				idx = idx2 + idx
			else
				break
			end
		until #t >= length
	end
	return t
end

--取得去掉音调的字符串
local function getpy(w)
	local t = utf8_string_to_table(w)
	local result = {}
	for i,v in ipairs(t) do
		local c = _yuan2[v]
		if c then
			table.insert(result,c)
		else
			table.insert(result,v)
		end
	end
	return table.concat(result)
end

local _han = {}

local _dy --多音字
local _cy
local _cyy ----成语列表
local _gr --迷惑项,同音字表
local _tongyin --自建同音字表
local _allrangs --如果只指定范围没找到足够的就扩大到全部,但是需要打乱
local _characters --[{character,idiom:[]},]
local _sources --[{source,idiom:[]},]

local _count1 = 60
local _count2 = 60
local _count3 = 60
local _current1 = 1
local _current2 = 1
local _current3 = 1
local function setLevelCount(c1,c2,c3)
	_count1 = c1
	_count2 = c2
	_count3 = c3
end

local function getLevelCount(d)
	if d== 1 then
		return _count1
	elseif d==2 then
		return _count2
	elseif d==3 then
		return _count3
	end
	return _count1
end

local function setCurrent(c1,c2,c3)
	_current1 = c1
	_current2 = c2
	_current3 = c3
end
local function setCurrent2(c,d)
	if d==1 then
		_current1 = c
	elseif d==2 then
		_current2 = c
	elseif d==3 then
		_current3 = c
	else
		_current1 = c
	end
end
local function getCurrent(d)
	if d== 1 then
		return _current1
	elseif d==2 then
		return _current2
	elseif d==3 then
		return _current3
	end
	return _current1
end

local _dfficulty = 1
local function setDifficulty(d)
	_dfficulty = d
end
local function getDifficulty()
	return _dfficulty
end
local _star1={}
local _star2={}
local _star3={}
local function set_level_star(t1,t2,t3)
	_star1 = t1
	_star2 = t2
	_star3 = t3
end
local function set_level_star2(t,d)
	if d==1 then
		_star1 = t
	elseif d==2 then
		_star2 = t
	elseif d==3 then
		_star3 = t
	else
		_star1 = t
	end
end
local function get_level_star(d)
	if d==1 then
		return _star1
	elseif d==2 then
		return _star2
	elseif d==3 then
		return _star3
	end
	return _star1
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

local function init_data()
	if _cy and _cy then return end
		--随机打乱
	math.randomseed(os.time())
	local filename = "res/han/data/han"
	_cy = {} --全部打乱
	_tongyin = {} --全部顺序
	for i=1,3 do
		local s = kits.read_local_file(filename..i..".json")
		local cy,errmsg
		if s then
			cy,errmsg = json.decode(s)
			_han[i] = cy
			
			--random_rang(cy)
			if not cy then
				kits.log("ERROR decode failed "..filename..i..".json")
				kits.log("	"..tostring(errmsg))
			end
		else
			kits.log("ERROR can't read file "..filename..i..".json")
		end
		_cy[i] = {}
		for j,v in ipairs(cy) do
			v.diff = j
			table.insert(_cy[i],v)
			if v.pinyin then
				local py = getpy(v.pinyin)
				_tongyin[py] = _tongyin[py] or {}
				table.insert(_tongyin[py],v)
			end
			--修复bug
			if string.len(v.idiom)==5 or string.len(v.idiom)==4 then
				if string.len(v.idiom)==4 and string.byte(string.sub(v.idiom,4,4))==32 then
					v.idiom = string.sub(v.idiom,1,3)
				elseif string.len(v.idiom)==5 and string.byte(string.sub(v.idiom,4,4))==194 then
					v.idiom = string.sub(v.idiom,1,3)
				end
			end
		end
	end
	_dy = {}
	filename = "res/han/data/dy.json"
	local s = kits.read_local_file(filename)
	if s then
		local errmsg
		local dy
		dy,errmsg = json.decode(s)
		if not dy then
			kits.log("ERROR decode failed "..filename)
			kits.log("	"..tostring(errmsg))
		else
			kits.log("初始化多音字，数据量:"..#dy)
		end
		for i,v in pairs(dy) do
			_dy[v] = 1
		end
	else
		kits.log("ERROR can't read file "..filename)
	end	
	
	kits.log("初始化成功，数据量:"..#_cy[1].."/"..#_cy[2].."/"..#_cy[3])

	--初始化一个同音字表
	filename = "res/han/data/cy.json"
	local s = kits.read_local_file(filename)
	if s then
		local errmsg
		_cyy,errmsg = json.decode(s)
		if not _cyy then
			kits.log("ERROR decode failed "..filename)
			kits.log("	"..tostring(errmsg))
		else
			kits.log("初始化成语库成功，数据量:"..#_cyy)
		end
	else
		kits.log("ERROR can't read file "..filename)
	end
	random_rang(_cyy)
	_allrangs={}
	for k=1,3 do
		for i,v in pairs(_cy[k]) do
			table.insert(_allrangs,v)
		end
	end

	random_rang(_allrangs)
	
	filename = "res/han/data/gr.json"
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
	if not _cy then
		kits.log("ERROR han initialization game data failed!")
		return
	end
	--init _characters
	--[[
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
	--]]
	--init _sources
	--[[
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
	--]]
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

--[[
    {
        "idiom": "啊",
        "pinyin": "ā",
        "explanation": "叹词，表示赞叹或惊异",
        "story": "",
        "character": []
    }
--]]
--返回拼音一组欺骗性质的答案

--找到音标字母的元音
--如w = 'á' ,返回'a',1 
--如w = 'ǐ' ,返回'i',5
local function yuan(w)
	for i,v in pairs(_yuan) do
	--	if i==w then
	--		return v,i
	--	end
		for j,vv in pairs(v) do
			if vv==w then
				return v,i
			end
		end
	end
end
local function yuan2(w)
	for i,v in pairs(_yuan) do
		if i==w then
			return v,i
		end
		for j,vv in pairs(v) do
			if vv==w then
				return v,i
			end
		end
	end
end
--如果表中有元音字母就返回true
local function haveYuan(t)
	for i,v in pairs(t) do
		if _yuan2[v] then
			return true
		end
	end
	return false
end

--如果w是一个元音e,返回true
--w = 'ǐ' e = 'i' 返回true
--w = 'i' e = 'i' 返回true
--其他返回false
local function isyuan(w,e)
	if w==e then return true end
	local s,i = yuan(w)
	if i==e then return true end
	return false
end

--元音声调替换
local function pingyin_approx2(pinyin)
	local result = {}
	local t = utf8_string_to_table(pinyin)
	local function suffix(t,i)
		local suff,pref
		suff = {}
		pref = {}
		for k,v in pairs(t) do
			if k<i then
				table.insert(suff,v)
			elseif k>i then
				table.insert(pref,v)
			end
		end
		return table.concat(suff),table.concat(pref)
	end
	--元音替换
	local yuanyin = haveYuan(t)
	if yuanyin then
		for i,v in pairs(t) do
			local yt,a = yuan(v)
			if yt then
				--前缀，后缀
				local suffix,prefix = suffix(t,i)
				for j,vv in pairs(yt) do
					if v ~= vv then
						table.insert(result,suffix..vv..prefix)
					end
				end
				break
			end
		end
	else
		for i,v in pairs(t) do
			local yt,a = yuan2(v)
			if yt then
				if a==v then
					--例如 'ma' ,这时候迷惑项不能使用平音
					--并且没有其他元音
					local suffix,prefix = suffix(t,i)
					for j = 2,#yt do
						if v ~= yt[j] then
							table.insert(result,suffix..yt[j]..prefix)
						end
					end
					break
				else
					--前缀，后缀
					local suffix,prefix = suffix(t,i)
					for j,vv in pairs(yt) do
						if v ~= vv then
							table.insert(result,suffix..vv..prefix)
						end
					end
					break
				end
			end
		end		
	end
	return result
end

--模糊音替换
local function pingyin_approx(pinyin)	
	local result = {}
	local tt = utf8_string_to_table(pinyin)
	--模糊音替换
	local ss = {}
	local is = false
	local i = 1
	repeat
		if tt[i] == 'c' and tt[i+1] ~= 'h' and (not tt[i-1] or tt[i-1]==' ') then --c->ch
			table.insert(ss,'ch')
			is = true
		elseif tt[i] == 'c' and tt[i+1] == 'h' and (not tt[i-1] or tt[i-1]==' ') then --ch->c
			table.insert(ss,'c')
			is = true
			i=i+1
		else
			table.insert(ss,tt[i])
		end
		i=i+1
	until i > #tt
	
	if is then
		is = false
		table.insert(result,table.concat(ss))
	end
	ss = {}
	local i = 1
	repeat
		if tt[i] == 's' and tt[i+1] ~= 'h' and (not tt[i-1] or tt[i-1]==' ') then --s->sh
			table.insert(ss,'sh')
			is = true
		elseif tt[i] == 's' and tt[i+1] == 'h' and (not tt[i-1] or tt[i-1]==' ') then --sh->s
			table.insert(ss,'s')
			is = true
			i=i+1
		else
			table.insert(ss,tt[i])
		end
		i=i+1
	until i > #tt
	if is then
		is = false
		table.insert(result,table.concat(ss))
	end
	ss = {}
	local i = 1
	repeat
		if tt[i] == 'z' and tt[i+1] ~= 'h' and (not tt[i-1] or tt[i-1]==' ') then --z->zh
			table.insert(ss,'zh')
			is = true
		elseif tt[i] == 'z' and tt[i+1] == 'h' and (not tt[i-1] or tt[i-1]==' ') then --zh->z
			table.insert(ss,'z')
			is = true
			i=i+1
		else
			table.insert(ss,tt[i])
		end
		i=i+1
	until i > #tt
	if is then
		is = false
		table.insert(result,table.concat(ss))
	end	
	ss = {}
	local i = 1
	repeat
		if tt[i] == 'l' and (not tt[i-1] or tt[i-1]==' ') then --l->n
			table.insert(ss,'n')
			is = true
		elseif tt[i] == 'n' and (not tt[i-1] or tt[i-1]==' ') then --n->l
			table.insert(ss,'l')
			is = true
		else
			table.insert(ss,tt[i])
		end
		i=i+1
	until i > #tt
	if is then
		is = false
		table.insert(result,table.concat(ss))
	end	
	ss = {}
	local i = 1
	repeat
		if tt[i] == 'f' and (not tt[i-1] or tt[i-1]==' ') then --f->h
			table.insert(ss,'h')
			is = true
		elseif tt[i] == 'h' and (not tt[i-1] or tt[i-1]==' ') then --h->f
			table.insert(ss,'f')
			is = true
		else
			table.insert(ss,tt[i])
		end			
		i=i+1
	until i > #tt
	if is then
		is = false
		table.insert(result,table.concat(ss))
	end	
	ss = {}
	local i = 1
	repeat
		if isyuan(tt[i],'u') and isyuan(tt[i+1],'a') and tt[i+2] == 'n' and tt[i+3] ~= 'g' then --uan -> uang
			table.insert(ss,tt[i])
			table.insert(ss,tt[i+1])
			table.insert(ss,'ng')
			is = true
			i = i+2
		elseif isyuan(tt[i],'u') and isyuan(tt[i+1],'a') and tt[i+2] == 'n' and tt[i+3] == 'g' then --uang -> uan
			table.insert(ss,tt[i])
			table.insert(ss,tt[i+1])
			table.insert(ss,'n')
			is = true
			i = i+3	
		else
			table.insert(ss,tt[i])
		end			
		i=i+1
	until i > #tt
	if is then
		is = false
		table.insert(result,table.concat(ss))
	end	
	ss = {}
	local i = 1
	repeat
		if isyuan(tt[i],'i') and tt[i+1] == 'n' and tt[i+2] ~= 'g' then --in->ing
			table.insert(ss,tt[i])
			table.insert(ss,'ng')
			is = true
			i = i+1
		elseif isyuan(tt[i],'i') and tt[i+1] == 'n' and tt[i+2] == 'g' then --ing->in
			table.insert(ss,tt[i])
			table.insert(ss,'n')
			is = true
			i = i+2	
		else
			table.insert(ss,tt[i])
		end			
		i=i+1
	until i > #tt
	if is then
		is = false
		table.insert(result,table.concat(ss))
	end	
	ss = {}
	local i = 1
	repeat
		if isyuan(tt[i],'a') and tt[i+1] == 'n' and tt[i+2] ~= 'g' then --an -> ang
			table.insert(ss,tt[i])
			table.insert(ss,'ng')
			is = true
			i = i+1
		elseif isyuan(tt[i],'a') and tt[i+1] == 'n' and tt[i+2] == 'g' then --ang -> an
			table.insert(ss,tt[i])
			table.insert(ss,'n')
			is = true
			i = i+2	
		else
			table.insert(ss,tt[i])
		end			
		i=i+1
	until i > #tt
	if is then
		is = false
		table.insert(result,table.concat(ss))
	end	
	ss = {}
	local i = 1
	repeat
		if isyuan(tt[i],'e') and tt[i+1] == 'n' and tt[i+2] ~= 'g' then --en -> eng
			table.insert(ss,tt[i])
			table.insert(ss,'ng')
			is = true
			i = i+1
		elseif isyuan(tt[i],'e') and tt[i+1] == 'n' and tt[i+2] == 'g' then --eng -> en		
			table.insert(ss,tt[i])
			table.insert(ss,'n')
			is = true
			i = i+2
		else
			table.insert(ss,tt[i])
		end
		i=i+1
	until i > #tt
	if is then
		is = false
		table.insert(result,table.concat(ss))
	end
	return result	
end

--[[ 测试近似拼音
local pingyin = {
	"jī",
	"méi",
	"huí",
	"zhàn",
	"shào",
	"píng",
	"pǐn",
	"niǎo",
	"fù",
	"gā",
	"mǎn mù chuāng yí",
}

for i,v in pairs(pingyin) do
	local t = pingyin_approx(v)
	print(v)
	for j,vv in pairs(t) do
		print("\t"..tostring(vv))
	end
end
--]]

local function pingyin_confuse(pingyin,count)
	if not pingyin then return {} end
	--先找模糊
	local t = pingyin_approx(pingyin)
	t = t or {}
	table.insert(t,pingyin)
	local total = {}
	--将模糊音进行元音组合
	for i,v in pairs(t) do
		local tt = pingyin_approx2(v)
		for j,vv in pairs(tt) do
			table.insert(total,vv)
		end
	end
	--打乱
	random_rang(total)
	local result = {}
	--取得count-1个迷惑项
	for i = 1,count do
		if total[i] ~= pingyin then
			table.insert(result,total[i])
		end
	end
	return result
end

--组合1,2,并且返回指定数量的
local function pingyin_approx3(pingyin,count)
	if not pingyin then return {} end
	
	local result = pingyin_confuse(pingyin,count-1)

	--插入正确答案
	table.insert(result,pingyin)
	--打乱
	random_rang(result)
	return result
end

--cur.idiom="会" {"hui","hiu","hou","hui"}
local function pingyin_answer(cur,count)
	return pingyin_approx3(cur.pinyin,count)
end

--已知正确答案返回一个可能错误的拼音，后面返回是否正确,1正确,2错误
--如cur.pinyin="hui" ,返回hiu,2
local function pingyin_answer2(cur)
	--先决定是否正确
	local d = math.random(1,2)
	if d==1 then
		return cur.pinyin,1
	else
		local result = pingyin_confuse(cur.pinyin,1)
		if result and result[1] then
			return result[1],2
		else
			return cur.pinyin,1 --找不到迷惑项就让此题正确
		end
	end
end

--已知一个字返回一组多音字
--cur.idiom = "会"  {"会","回","辉","灰"}
--1.先在_gr中找迷惑项
--2._tongyin 在中定位到当前的字或者词，在前面或者后面取迷惑项
--3.随便找剩余的迷惑项
local function pingyin_answer3(cur,count)
	local result = {}
	local len = cc.utf8.length(cur.idiom)
	--0 同音字查找
	local py = getpy(cur.pinyin)
	if py and _tongyin and _tongyin[py] then
		for i,v in pairs(_tongyin[py]) do
			if v.pinyin ~= cur.pinyin then
				table.insert(result,v.idiom)
			end
		end
	end
	--1
	-- bug : 这导致相同拼音的字
	--[[
	if _gr and _gr[cur.idiom] and len==1 then
		local tt = utf8_string_to_table(_gr[cur.idiom])
		for i,v in pairs(tt) do
			table.insert(result,v)
		end
	end
	--]]
	--2
	--这里要加入排重处理
	local pc = {}
	for i=1,#result do
		pc[result[i]] = 1
	end
	--local cf = #result
	result = {}
	for i,v in pairs(pc) do
		table.insert(result,i)
	end

	if #result < count then
		for i,v in ipairs(_allrangs) do
			if v.idiom==cur.idiom then
				local item
				for j = i,#_allrangs do
					item = _allrangs[j]
					if item and item.idiom and cc.utf8.length(item.idiom)==len and item.pinyin~=cur.pinyin and item.idiom~=cur.idiom then
						table.insert(result,item.idiom)
						if #result > count then
							break
						end
					end
				end
				if #result < count then --向前搜索
					for j = i,1,-1 do
						item = _allrangs[j]
						if item and item.idiom and cc.utf8.length(item.idiom)==len and item.pinyin~=cur.pinyin and item.idiom~=cur.idiom then
							table.insert(result,item.idiom)
							if #result > count then
								break
							end
						end
					end	
				end
				break
			end
		end
	end
	--3
	--print("========="..cf.."/"..#result.."=========")
	--kits.logTable(result)
	--排重完成
	random_rang(result)
	local total = {}
	for i=1,#result do
		if result[i] and cc.utf8.length(result[i])==len and result[i] ~= cur.idiom then
			table.insert(total,result[i])
		end
		if #total >= count-1 then
			break
		end
	end
	--插入正确答案
	if #total < count then
		
	end
	table.insert(total,cur.idiom)
	random_rang(total)	
	return total
end

--已知字返回几个不同的释义进行选择
local function explanation_answer(cur,count)
	local all = #_allrangs
	local result = {}
	local idxs = {}
	c = 0
	repeat
		local idx = math.random(1,all)
		if _allrangs[idx] and _allrangs[idx].explanation and 
			_allrangs[idx].explanation ~= cur.explanation and not idxs[idx] and
			cc.utf8.length(_allrangs[idx].explanation) <= 32 and 
			cc.utf8.length(_allrangs[idx].explanation) > 1 then --迷惑别太长
			table.insert(result,_allrangs[idx].explanation)
			idxs[idx] = 1
			c = c + 1
		end
	until c >= count-1
	table.insert(result,cur.explanation)
	random_rang(result)
	return result
end

local function get_toipics2(type,cur)
	local length = cc.utf8.length(cur.idiom)
	if type==1 then
		--字选择拼音
		if length ~= 1 then return nil end
		if _dy[cur.idiom] then return nil end
		
		local answer = pingyin_answer(cur,4)
		if not answer then return nil end
		return {type=type,count=1,
			name=cur.idiom,
			answer=answer,
			correct=cur.pinyin,
			entry=cur}
	elseif type==2 then
		--字拼音是否正确
		if length ~= 1 then return nil end
		if _dy[cur.idiom] then return nil end
		
		local answer,correct = pingyin_answer2(cur)
		if not answer then return nil end
		return {type=type,count=1,
			name={cur.idiom,answer},
			answer={1,2},
			correct=correct,
			entry=cur}
	elseif type==3 then
		--拼音选择正确的字
		if length ~= 1 then return nil end
		local answer = pingyin_answer3(cur,4)
		if not answer then return nil end
		return {type=type,count=1,
			name=cur.pinyin,
			answer=answer,
			correct=cur.idiom,
			entry=cur}
	elseif type==4 then
		--字选正确的解释
		if length ~= 1 then return nil end
		if not cur.explanation then return nil end
		local length = cc.utf8.length(cur.explanation)
		if length > 32 or length < 2 then return nil end
		
		local answer = explanation_answer(cur,3)
		if not answer then return nil end
		return {type=type,count=1,
			name=cur.idiom,
			answer=answer,
			correct=cur.explanation,
			entry=cur}
	elseif type==5 then
		--字选书体
		local b = (length ~= 1 or cur.check~="1")
		if b then 
			return nil 
		end
		return {type=type,count=1,
			name=cur.idiom,
			answer="",
			correct="",
			entry=cur}
	elseif type==6 then
		--字的字体是否正确
		local b = (length ~= 1 or cur.check~="1")
		if b then 
			return nil 
		end
		return {type=type,count=1,
			name=cur.idiom,
			answer="",
			correct="",
			entry=cur}
	elseif type==7 then
		--词语选择拼音
		if length ~= 2 then return nil end
		local answer = pingyin_answer(cur,3)
		if not answer then return nil end
		return {type=type,count=1,
			name=cur.idiom,
			answer=answer,
			correct=cur.pinyin,
			entry=cur}
	elseif type==8 then
		--词语拼音是否正确
		if length ~= 2 then return nil end
		local answer,correct = pingyin_answer2(cur)
		if not answer then return nil end
		return {type=type,count=1,
			name={cur.idiom,answer},
			answer={1,2},
			correct=correct,
			entry=cur}
	elseif type==9 then
		--拼音选择正确的词语
		if length ~= 2 then return nil end
		local answer = pingyin_answer3(cur,4)
		if not answer then return nil end
		return {type=type,count=1,
			name=cur.pinyin,
			answer=answer,
			correct=cur.idiom,
			entry=cur}
	elseif type==10 then
		--词语选正确的解释
		if length ~= 2 then return nil end
		if not cur.explanation then return nil end
		local length = cc.utf8.length(cur.explanation)
		if length > 32 or length < 2 then return nil end
		
		local answer = explanation_answer(cur,3)
		if not answer then return nil end
		return {type=type,count=1,
			name=cur.idiom,
			answer=answer,
			correct=cur.explanation,
			entry=cur}
	elseif type==11 then
		--成语去掉一个字，选择正确的字 (类似打地鼠)
		local rangs = _cyy
		local i = math.random(1,#rangs)
		local s = utf8_string_to_table(rangs[i].idiom)
		if s and #s >= 4 then
			local qs = makeWord(s,1)
			local words = utf8_string_to_table(qs.name)
			local answers2 = utf8_string_to_table(qs.answer)
			local names = {}
			for i,v in ipairs(words) do
				if v=='(' or v==')' or v=='　' then
					if v=='　' then
						table.insert(names,' ')
					end
				else
					table.insert(names,v)
				end
			end
			local answers = {}
			if answers2[1] and answers2[2]==',' and answers2[3] and answers2[4] and answers2[5] then
				table.insert(answers,answers2[1])
				table.insert(answers,answers2[3])
				table.insert(answers,answers2[4])
				table.insert(answers,answers2[5])
				cor = answers2[1]
				random_rang(answers)
			else
				kits.log("ERROR answers : "..tostring(qs.answer))	
			end
			return {type=type,count=1,name=names,answer=answers,correct=cor,entry=rangs[i]}
		else
			kits.log("ERROR get_topics cy.json invaild "..tostring(s))
		end
	elseif type==12 then
		--成语是否正确
		--成语去掉一个字，选择正确的字 (类似打地鼠)
		local rangs = _cyy
		local i = math.random(1,#rangs)
		local s = utf8_string_to_table(rangs[i].idiom)
		if s and #s >= 4 then
			local qs = makeWord(s,1)
			local words = utf8_string_to_table(qs.name)
			local answers2 = utf8_string_to_table(qs.answer)
			local names = {}
			for i,v in ipairs(words) do
				if v=='(' or v==')' or v=='　' then
					if v=='　' then
						table.insert(names,' ')
					end
				else
					table.insert(names,v)
				end
			end
			local answers = {}
			if answers2[1] and answers2[2]==',' and answers2[3] and answers2[4] and answers2[5] then
				table.insert(answers,answers2[1])
				table.insert(answers,answers2[3])
				table.insert(answers,answers2[4])
				table.insert(answers,answers2[5])
				cor = answers2[1]
			else
				kits.log("ERROR answers : "..tostring(qs.answer))	
			end
			cor = math.random(1,2)
			local name
			if cor == 1 then --正确
				name = rangs[i].idiom
			else
				for i=1,#names do
					if names[i]==' ' then
						names[i] = answers2[math.random(3,5)]
					end
				end
				name = table.concat(names)
			end
			return {type=type,count=1,name=name,answer={1,2},correct=cor,entry=rangs[i]}
		else
			kits.log("ERROR get_topics cy.json invaild "..tostring(s))
		end		
	elseif type==13 then	
		--成语解释是否正确
		--词语选正确的解释
		if length ~= 4 then return nil end
		local answer = explanation_answer(cur,3)
		if not answer then return nil end
		return {type=type,count=1,
			name=cur.idiom,
			answer=answer,
			correct=cur.explanation,
			entry=cur}		
	else
		kits.log("not support type = "..tostring(type))
	end
end

local function get_topics1(rangs,type,idx)
	local current
	repeat
		current = rangs[idx]
		if current and current.idiom then
			local t = get_toipics2(type,current)
			if t then
				return t,idx+1
			end
		end
		idx = idx + 1
	until idx > #rangs
	return nil,idx+1
end

local function get_topics(rangs,type,count)
	local result = {}
	idx = 1
	print("get_topics type = "..tostring(type).." count="..count)
	for i=1,count do
		local t
		t,idx = get_topics1(rangs,type,idx)
		if t then
			--kits.logTable(t)
			table.insert(result,t)
		end
		if idx > #rangs then
			return result
		end
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
	local rang = {} --出题范围
	local diff = t.diff --1,2,3 代表小学,初中,高中
	local level = t.level --关卡
	print("============init_game=============")
	print("diff = "..tostring(diff).." level = "..tostring(level))
	math.randomseed(os.time())
	
	if not _cy[diff] then
		kits.log("ERROR init_game _cy[diff] = "..tostring(_cy[diff]))
		return
	end
--	local count = #_cy[diff]
--	if level*20 > count then
--		kits.log("ERROR init_game level is bigger than _cy"..level)
--		return
--	end
	--每关20道题
	for i=1,20 do
		local j = (level-1)*20+i
		if _cy[diff][j] then
			--kits.logTable(_cy[diff][j])
			table.insert(rang,_cy[diff][j])
		else
			kits.log("ERROR overflow level = "..tostring(level).." diff = "..tostring(diff))
		end
	end
	local ex = {}
	--取得考试用字
	if diff == 1 then
		local count = #_cy[diff]		
		for i=2482,count do
			if _cy[diff][j] then
				table.insert(ex,_cy[diff][j])
			end
		end
	elseif diff == 2 then
		local count = #_cy[diff]
		local ex = {}
		for i=2482,count do
			if _cy[diff][j] then
				table.insert(ex,_cy[diff][j])
			end
		end
	end
	random_rang(ex)
	--插入5个考试用字
	for i=1,5 do
		if ex[i] then
			table.insert(rang,ex[i])
		end
	end	
	--打乱
	random_rang(rang)
	
	local result = {}
	result.question_amount = t.question_amount
	result.time_limit = t.time_limit
	result.road_radom = t.road_radom or 0
	result.diffcult =  diffcult
	result.answers = {}
	
	--测试用
	--[[
	rang[1] = {
	idiom="靡",
	check="0",
	pinyin="mí",
	explanation="浪费，奢侈",
	story=""
	}
	--]]
	--[[
	rang[1] = {
        idiom="泥",
        check="0",
        pinyin="ní",
        explanation="土和水合成的东西。",
        story="",
        character={}
    }
	--]]
	--[[
	rang[1] = {
		idiom="吗",
		check="0",
		pinyin="ma",
		explanation="助词，表疑问，用在一般直陈句尾.",
		story="",
		character={}
	}
[	rang[1] = {
        idiom="左",
		check="0",
        pinyin="zuǒ",
        explanation="面向南时，东的一边，与“右”相对",
        story="",
        character={}
    }
	--]]
	for i=1,20 do
		local v = rang[i]
		if v then
			local t = utf8_string_to_table(v.idiom)
			local length = #t
			local type = 0
			
			--print("============================")
			--kits.logTable(v)
			if length==1 and v.check=="0" then
				type = math.random(1,4)
			elseif length==1 and v.check=="1" then
				type = math.random(1,6)
			elseif length==1 then
				type = math.random(1,4)
			elseif length==2 then
				type = math.random(7,10)
			elseif length==4 then
				type = math.random(11,12)
			else
				kits.log("ERROR can not type match")
				--kits.logTable(v)
			end
			--type = 4
			print("type = "..type)
			local t = get_toipics2(type,v)
			table.insert(result.answers,t)
		end
	end
	return result
end

--根据类型出题
local function init_game2(t)
	if not _cy then
		kits.log("ERROR can not initialization game,_cy = nil")
		return
	end
	_cy = _han[_dfficulty or 1]
	local diffcult = t.diffcult or 1
	diffcult = math.min(diffcult,9)
	diffcult = math.max(diffcult,1)
	local rangs = {}
	local count = #_cy
	--平均难度分布
	for i=1,9 do
		diffcult_table[i][1] = (i-1)*count/10+1
		diffcult_table[i][2] = i*count/10
	end
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
				--测试
				local tt = get_topics(rangs,v.type,v.count)
				if v.count > #tt then
					local ttt = get_topics(_allrangs,v.type,v.count-#tt)
					for k,s in pairs(ttt) do
						table.insert(result.answers,s)
					end
				end
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

return {
	init = init_data,
	get = init_game,
	setLevelCount = setLevelCount,
	getLevelCount = getLevelCount,
	setCurrent = setCurrent,
	setCurrent2= setCurrent2,
	getCurrent = getCurrent,
	setDifficulty = setDifficulty,
	getDifficulty = getDifficulty,
	set_level_star=set_level_star,
	get_level_star=get_level_star,
	set_level_star2 = set_level_star2,
}