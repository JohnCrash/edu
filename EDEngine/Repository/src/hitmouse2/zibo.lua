require "AudioEngine" 
local kits = require "kits"
local music = require "hitmouse2/music"
local uikits = require "uikits"
local state = require "hitmouse2/state"
local http = require "hitmouse2/hitconfig"
local global = require "hitmouse2/global"
local level = require "hitmouse2/game"

local ui = {
	FILE = 'hitmouse2/zibo.json',
	FILE_3_4 = 'hitmouse2/zibo43.json',
	BACK = 'ding/fan',
	TAN_UI = 'tan',
	LEVEL_1 = 't1',
	LEVEL_2 = 't2',
	LEVEL_3 = 't3',
	LEVEL_4 = 't4',
	LEVEL_5 = 't5',
	SCORE_1 = 't1/fen',
	SCORE_2 = 't2/fen',
	SCORE_3 = 't3/fen',
	SCORE_4 = 't4/fen',
	SCORE_5 = 't5/fen',	
	ZIBOTOP = 'paih',
}

local zibo = uikits.SceneClass("zibo")
local _cy --成语列表
local _gr --迷惑项
local _characters --[{character,idiom:[]},]
local _sources --[{source,idiom:[]},]

function zibo:start(n)
	local t = {}
	t.threshold = 0
	t.condition = 60
	t.type = 9
	t.level = n
	t.time_limit = 180

	t.road_radom = os.time()
	t.answers = {}
	local rangs = {}
	local b,e,c
	c = math.floor(#_cy/5)
	b = (n-1)*c + 1
	e = b+c
	for i = b,e do
		table.insert(rangs,_cy[i])
	end
	math.randomseed(os.time())
	level.random_rang(rangs)
	repeat
		local tp = math.random(1,7)
		local tt = level.get_topics(rangs,tp,1)
		if #tt == 1 then
			local s = tt[1]
			--print( "remove idx = "..s.inx.." name = "..s.name)
			--print( "1rangs count = "..#rangs)
			table.remove(rangs,s.inx)
			--print( "2rangs count = "..#rangs)
			table.insert(t.answers,s)
		end
		level.random_rang(rangs)
	until #t.answers >= 20 or #rangs <= 2
	local battle = require "hitmouse2/battle"
	uikits.pushScene(battle.create(t))	
end

function zibo:init_word()
	if _cy and _cy then return end
	local filename = "res/hitmouse2/data/cy1.json"
	local s = kits.read_local_file(filename)
	if s then
		local errmsg
		_cy,errmsg = json.decode(s)
		if not _cy then
			kits.log("ERROR decode failed "..filename)
			kits.log("	"..tostring(errmsg))
		else
			kits.log("初始化淄博成语库成功，数据量:"..#_cy)
		end
	else
		kits.log("ERROR can't read file "..filename)
	end
	filename = "res/hitmouse2/data/gr1.json"
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

function zibo:updateScroe()
	local function setstring()
	uikits.child(self._root,ui.SCORE_1):setString(self._s1 or '')
	uikits.child(self._root,ui.SCORE_2):setString(self._s2 or '')
	uikits.child(self._root,ui.SCORE_3):setString(self._s3 or '')
	uikits.child(self._root,ui.SCORE_4):setString(self._s4 or '')
	uikits.child(self._root,ui.SCORE_5):setString(self._s5 or '')
	end
	setstring()
	local send_data = {}
	http.post_data(self._root,'get_score_zibo',send_data,function(t,v)
			if t and t==200 and v then
				self._s1 = v.v1
				self._s2 = v.v2
				self._s3 = v.v3
				self._s4 = v.v4
				self._s5 = v.v5
				setstring()
			 end
		end)	
end

function zibo:init(b)
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		self._ss = cc.size(1920,1080)
	else
		self._ss = cc.size(1440,1080)
	end
	uikits.initDR{width=self._ss.width,height=self._ss.height}
	if not self._root then
		self:init_word()
		self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
		self:addChild(self._root)	
		uikits.child(self._root,ui.TAN_UI):setVisible(false)
		uikits.event(uikits.child(self._root,ui.BACK),function(sender)
			uikits.popScene()
		end)		
		uikits.event(uikits.child(self._root,ui.LEVEL_1),function(sender)
			self:start(1)
		end)
		uikits.event(uikits.child(self._root,ui.LEVEL_2),function(sender)
			self:start(2)
		end)
		uikits.event(uikits.child(self._root,ui.LEVEL_3),function(sender)
			self:start(3)
		end)
		uikits.event(uikits.child(self._root,ui.LEVEL_4),function(sender)
			self:start(4)
		end)
		uikits.event(uikits.child(self._root,ui.LEVEL_5),function(sender)
			self:start(5)
		end)
		uikits.event(uikits.child(self._root,ui.ZIBOTOP),function(sender)
			uikits.pushScene(require "hitmouse2/zibotop".create())
		end)
	end
	self:updateScroe()
end

function zibo:release()
	uikits.popKeyboardListener()
end

return zibo