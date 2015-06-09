local kits = require "kits"
local json = require "json-c"

local _cy
local _gr
local function init_level()
	if _cy and _cy then return end
	local filename = "res/hitmouse/data/cy.json"
	local s = kits.read_local_file(filename)
	if s then
		_cy = json.decode(s)
		if not _cy then
			kits.log("ERROR decode failed "..filename)
		else
			kits.log("初始化成语库成功，数据量:"..#_cy)
		end
	else
		kits.log("ERROR can't read file "..filename)
	end
	filename = "res/hitmouse/data/gr.json"
	s = kits.read_local_file(filename)
	if s then
		_gr = json.decode(s)
		if not _gr then
			kits.log("ERROR decode failed "..filename)
		end		
	else
		kits.log("ERROR can't read file "..filename)
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
		local i = math.random(1,4)
		local i2 = diffRandom(i)
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

local function getLevel(t)
	local result = {}
	if t and t.diff1 and t.diff2 and t.rand and t.signle and t.dual then
		t.diff1 = math.min(t.diff1,#_cy)
		t.diff2 = math.min(t.diff2,#_cy)
		math.randomseed(t.rand)
		t.count = t.signle + t.dual
		if t.diff2 - t.diff1 < t.count then
			if t.diff1 + t.count <= #_cy then
				t.diff2 = t.diff1 + t.count
			else
				t.diff1 = t.diff2 - t.count
				if t.diff1 < 0 then
					t.diff1 = 0 --all
					t.diff2 = #_cy
				end
			end
		end
		local temp = {}
		for i = t.diff1,t.diff2 do
			table.insert(temp,_cy[i])
		end
		local count = #temp
		for i = 1,t.count do
			local s = temp[i]
			local idx = math.random(1,count)
			temp[i] = temp[idx]
			temp[idx] = s
		end
		for i = 1,t.signle do
			local s = utf8_string_to_table(temp[i])
			if s and #s >= 4 then
				table.insert(result,makeWord(s,1))
			else
				kits.log("ERROR getLevel cy.json invaild "..tostring(temp[i]))
			end
		end
		for i = t.signle+1,t.count do
			local s = utf8_string_to_table(temp[i])
			if s and #s >= 4 then
				table.insert(result,makeWord(s,2))
			else
				kits.log("ERROR getLevel cy.json invaild "..tostring(temp[i]))
			end
		end
	else
		kits.log("ERROR getLevel invaild argument")
	end
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
	init = init_level,
	get = getLevel,
	setLevelCount = setLevelCount,
	getLevelCount = getLevelCount,
	setCurrent = setCurrent,
	getCurrent = getCurrent
}