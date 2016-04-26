local kits = require "kits"
local uikits = require "uikits"
local state = require "hitmouse2/state"
local http = require "hitmouse2/hitconfig"
local md5 = require "md5"

local local_dir = kits.get_local_directory()..'res/'

local ui = {
	FILE = 'hitmouse2/jiaLAO.json',
	FILE_3_4 = 'hitmouse2/jiaLAO43.json',
	designWidth = 1920,
	designHeight = 1080,	
	BACK = 'ding/fan',
	WATCH_INFO_BUT = 'ding/shuom',
	STEP_1 = 'guoc/tu/g1',
	STEP_2 = 'guoc/tu/g2',
	STEP_3 = 'guoc/tu/g3',
	STEP_4 = 'guoc/tu/g4',
	PLANE_1 = 'bu1',
	PLANE_2 = 'bu2',
	PLANE_3 = 'bu3',
	PLANE_4 = 'bu4',
	
	NEXT_BUT = 'xiayi',
	PREV_BUT = 'fanhui',
	PUBLIC_BUT = 'xiayi',
	
	INPUT_NUM = 'gairen',
	INPUT_CAPTION = 'saim',
	INPUT_PROMOTION_NUM = 'jinjiren',
	WATCH_INFO = 'shuom',
	CLOSE_BUT = 'guan',
	INPUT_IMAGE = 'paizhao',
	
	INPUT_CAPTION_TEXT = 'bai/mingz',
	INPUT_CAPTION_OK = 'quer',
	INPUT_CAPTION_CANCEL = 'qux',
	
	PLANE_1_CAPTION_BUT = 'saim',
	PLANE_1_CAPTION  = 'saim/wenz',
	PLANE_1_LIST = 'gund',
	PLANE_1_ITEM = 'xuan1',
	
	STAGE_1 = 'x1',
	STAGE_2 = 'x2',
	STAGE_3 = 'x3',
	STAGE_4 = 'x4',
	
	STAGE_LEVEL = 'xian/s',
	
	STAGE_CURRENT = 's',
	STAGE_PLAY_COUNT = 'guiz/tu/ren',
	STAGE_COUNT_BUT = 'guiz/gai',
	STAGE_DIFENT = 'nandu/n',
	STAGE_DATE_LABEL = 'shijian/tu/w1',
	STAGE_DATE_BUT = 'shijian/tu',
	STAGE_MATCH_DAY = 'shijian/sj2/riqi',
	STAGE_MATCH_BUT = 'shijian/sj2',
	STAGE_VOTE_DAY = 'shijian/sj3/riqi',
	STAGE_VOTE_BUT = 'shijian/sj3',
	
	STAGE_REP_1 = 'jih/c',
	STAGE_REP_SILVER = 'w2',
	
	DAY_PLANE = 'gait',
	DAY_BUT = 't',
	DAY_OK = 'quer',
	PLAY_COUNT_PLANE = 'jinjiren',
	NUM_BUT = 's',
	NUMBER_PLANE = 'gairen',
	NUM_LABEL = 'bai/bai2/su',
	NUM_BACKSPACE = 'tui',
	NUM_DELTE = 'shanc',
	PLAY_COUNT_CANCEL = 'qux',
	PLAY_COUNT_OK = 'quer',
	
	PLAY_COUNT_STAGE = 'xian/s',
	
	PLANE4_ITEM = 'jiang',
	PLANE4_ITEM_BUT = 'xiu',
	PLANE4_ITEM_IMG = 'shiw',
	PLANE4_ITEM_IMGBUT = 'shiw/jia',
	PLANE4_ITEM_INPUT = 'shiw/wen',
	PLANE4_ITEM_NUM = 'suliang',
	
	PLANE_SELECT_IMAGE = 'paizhao',
	SELECT_CAM = 'hei/pai',
	SELECT_IMG = 'hei/tuk',
	SELECT_CLOSE = 'hei/guan',
}

local worldmatch_pub = uikits.SceneClass("worldmatch_pub",ui)

function worldmatch_pub:init(b)
	if b then
		uikits.event(uikits.child(self._root,ui.BACK),function(sender)
			uikits.popScene()
		end)
		self._watch_info = uikits.child(self._root,ui.WATCH_INFO)
		self._input_image = uikits.child(self._root,ui.INPUT_IMAGE)
		self._input_promotion_num = uikits.child(self._root,ui.INPUT_PROMOTION_NUM)
		self._input_caption = uikits.child(self._root,ui.INPUT_CAPTION)
		self._input_num = uikits.child(self._root,ui.INPUT_NUM)
		self._watch_info:setVisible(false)
		self._input_image:setVisible(false)
		self._input_promotion_num:setVisible(false)
		self._input_caption:setVisible(false)
		self._input_num:setVisible(false)
		uikits.event(uikits.child(self._watch_info,ui.CLOSE_BUT),function(sender)
			self._watch_info:setVisible(false)
		end)
		uikits.event(uikits.child(self._root,ui.WATCH_INFO_BUT),function(sender)
			self._watch_info:setVisible(true)
		end)
		self._planes={}
		table.insert(self._planes,uikits.child(self._root,ui.PLANE_1))
		table.insert(self._planes,uikits.child(self._root,ui.PLANE_2))
		table.insert(self._planes,uikits.child(self._root,ui.PLANE_3))
		table.insert(self._planes,uikits.child(self._root,ui.PLANE_4))
		self._data = {}
		self._data.current_stage = 1
		self._data.match_level_count = 5
		local function next_prev_event(plane,i)
			local but = uikits.child(plane,ui.PREV_BUT)
			if but then
				uikits.event(but,function(sender)
					if i==3 then
						if self._data.current_stage>1 then
							self._data.current_stage = self._data.current_stage - 1
							self:initStagePlane(self._planes[3],self._data.current_stage)						
							return
						end
					end
					self._tabs.progress(i-1)
				end)
			end
			but = uikits.child(plane,ui.NEXT_BUT)
			if but then
				uikits.event(but,function(sender)
					if i==3 then
						if self._data.current_stage<self._data.match_level_count then
							self._data.current_stage = self._data.current_stage + 1
							self:initStagePlane(self._planes[3],self._data.current_stage)
							return
						end
					end
					self._tabs.progress(i+1)
				end)			
			end
		end
		for i=1,#self._planes do
			next_prev_event(self._planes[i],i)
		end
		uikits.event(uikits.child(self._planes[4],ui.PUBLIC_BUT),function(sender)
			self:do_upload()
		end)

		self._tabs = state.progress(self._root,{ui.STEP_1,ui.STEP_2,ui.STEP_3,ui.STEP_4},function(i)
			for k=1,4 do
				self._planes[k]:setVisible(false)
			end
			self._planes[i]:setVisible(true)
		end)
		
		self:initData()
		uikits.child(self._root,ui.DAY_PLANE):setVisible(false)
	end
end

function worldmatch_pub:do_upload()
	local files = {}
	if not self._upload_circle then
		self._upload_circle = http.circle( self._root )
	end
	local function close_circle()
		if self._upload_circle then
			if cc_isobj(self._upload_circle) then
				self._upload_circle:removeFromParent()
			end
			self._upload_circle = nil
		end	
	end
	self._do_upload = self._do_upload or 0
	self._do_upload = self._do_upload + 1
	local plane = self._planes[4]
	for i=1,4 do
		if self._data.award[i].award_file then
			table.insert(files,self._data.award[i].award_file)
		end
		local input = uikits.child(plane,ui.PLANE4_ITEM_INPUT)
		self._data.award[i].awarddesc = ''
		if input then
			self._data.award[i].awarddesc = input:getStringValue()
		end
	end
	kits.log("INFO do_upload #"..#files)
	if #files > 0 then
		state.uploads( files,function(b,ups,failes)
			for i=1,4 do
				if self._data.award[i].award_file and ups[self._data.award[i].award_file] then
					self._data.award[i].awardimg = ups[self._data.award[i].award_file]
					self._data.award[i].award_file = nil
				end
			end
			if b then
				close_circle()
				kits.log("INFO do_public")
				self:do_public()
			else
				if self._do_upload <= 3 then
					self.do_upload()
				else
					self._do_upload = 0
					http.messagebox(self._root,http.DIY_MSG,function(e)
						if e == http.RETRY then
							self.do_upload()
						else
							close_circle()
						end
					end,"奖品照片上传失败")						
				end
			end
		end)
	else
		self:do_public()
	end
end

function worldmatch_pub:do_public()
	local send_data = {
		v1 = "@"..tostring(self._data.match_name),
		v2 = self._data.match_level_count,
		v3 = self._data.regions,
		v4 = self._data.stages,
		v5 = self._data.award,
	}
	send_data.v3 = {}
	for i,v in pairs(self._data.regions) do
		table.insert(send_data.v3,{region_id=v})
	end
	local ti=0
	http.logTable(self._data.stages,1)
	for i=1, #self._data.stages do
		local v = self._data.stages[i]
		if i==1 then
			ti = os.time()
			local da = os.date("*t",ti)
			v.begin = da.year..'/'..da.month..'/'..da.day
			ti = ti+(v.voteday+v.matchday)*24*3600
		else
			local da = os.date("*t",ti)
			v.begin = da.year..'/'..da.month..'/'..da.day
			ti = ti+(v.voteday+v.matchday)*24*3600
		end
		v.money = self._slivers[v.rep] or 0
	end

	kits.log("do worldmatch_pub:do_public...")
	http.post_data(self._root,'pub_wordmatch',send_data,function(t,v)
		if t and t==200 and v then	
			if v.v1 then
				uikits.popScene()
				kits.log("public success")
			else
				kits.log("public failed")
			end
		else
			http.messagebox(self._root,http.DIY_MSG,function(e)
				if e == http.RETRY then
					self:do_public()
				else
					uikits.popScene()
				end
			end,v)			
		end
	end)
end

function worldmatch_pub:initData()
	self._planes[1]:setVisible(false)
	local send_data = {}
	kits.log("do worldmatch_pub:initData...")
	http.post_data(self._root,'get_rep_money',send_data,function(t,v)
		if t and t==200 and v then
			kits.log("loading worldmatch_pub:initData success!")
			http.logTable(v,1)
			if v and type(v)=='table' and v.v1 and v.v2 then
				self._planes[1]:setVisible(true)
				self._slivers = v.v2
				self:initPlane1()
				self:initPlane2()
				self:initPlane3()
				self:initPlane4()							
			else
				kits.log("ERROR worldmatch_pub return invalid value")
			end
		else
			http.messagebox(self._root,http.DIY_MSG,function(e)
				if e == http.RETRY then
					self:initData()
				else
					uikits.popScene()
				end
			end,v)			
		end
	end)		
end

local function closeIMEKeyboard()
	local Director = cc.Director:getInstance()
	local glview = Director:getOpenGLView()
	glview:setIMEKeyboardState(false)
end

function worldmatch_pub:show_input_caption(func)
	self._input_caption:setVisible(true)
	local edit = uikits.child(self._input_caption,ui.INPUT_CAPTION_TEXT)
	edit:attachWithIME()
	uikits.event(uikits.child(self._input_caption,ui.INPUT_CAPTION_CANCEL),
	function(sender)
		self._input_caption:setVisible(false)
		func(false)
		closeIMEKeyboard()
	end)
	uikits.event(uikits.child(self._input_caption,ui.INPUT_CAPTION_OK),
	function(sender)
		self._input_caption:setVisible(false)
		func(true,edit:getStringValue())
		closeIMEKeyboard()
	end)	
end

function worldmatch_pub:initPlane1()
	local plane = self._planes[1]
	local next_but = uikits.child(plane,ui.NEXT_BUT)
	next_but:setBright (false)
	next_but:setEnabled(false)
	local function updateButton()
		if self._data.match_name and string.len(self._data.match_name) 
			and self._data.regions and #self._data.regions > 0 then
			next_but:setBright (true)
			next_but:setEnabled(true)
		else
			next_but:setBright (false)
			next_but:setEnabled(false)
		end
	end
	local function clear_region(rid)
		if self._data.regions then
			for i,v in pairs(self._data.regions) do
				if v == rid then
					table.remove(self._data.regions,i)
					break
				end
			end
		end
	end
	local caption = uikits.child(plane,ui.PLANE_1_CAPTION)
	local sc = uikits.scrollex(plane,ui.PLANE_1_LIST,{ui.PLANE_1_ITEM})
	local b,n,rid,v = state.get_region()
	self._data.regions = {}
	if b and n and v then
		for i,s in pairs(v) do
			item = sc:additem(1)
			uikits.child(item,'an/wen'):setString(s.name)
			uikits.event(uikits.child(item,'an'),function(sender,b)
				clear_region(s.region_id)
				if b then
					table.insert(self._data.regions,s.region_id)
				end
				updateButton()
			end)
		end
	end
	sc:relayout_horz()
	uikits.event(uikits.child(plane,ui.PLANE_1_CAPTION_BUT),function(sender)
		self:show_input_caption(function(b,str)
			if b then
				self._data.match_name = str
				caption:setString(str)
			end
			updateButton()
		end)
	end)
end

function worldmatch_pub:initPlane2()
	local plane = self._planes[2]
	
	local next_but = uikits.child(plane,ui.NEXT_BUT)
	next_but:setBright (false)
	next_but:setEnabled(false)
	local function updateButton()
		if self._data.match_level_count then
			next_but:setBright (true)
			next_but:setEnabled(true)
		else
			next_but:setBright (false)
			next_but:setEnabled(false)
		end
	end
	local stl = {}
	for i=1,5 do
		local item = uikits.child(plane,ui.STAGE_LEVEL..i)
		item:setSelectedState(true)
		table.insert(stl,item)
	end
	local function hide()
		for i=1,5 do
			stl[i]:setVisible(false)
		end
	end
	local stages = state.tab(plane,{ui.STAGE_1,ui.STAGE_2,ui.STAGE_3,ui.STAGE_4},function(i)
		self._data.match_level_count = i+1
		updateButton()
		hide()
		if i==1 then
			stl[1]:setVisible(true)
			stl[5]:setVisible(true)
		elseif i==2 then
			stl[1]:setVisible(true)
			stl[2]:setVisible(true)
			stl[5]:setVisible(true)
		elseif i==3 then
			stl[1]:setVisible(true)
			stl[2]:setVisible(true)
			stl[3]:setVisible(true)
			stl[5]:setVisible(true)
		else
			stl[1]:setVisible(true)
			stl[2]:setVisible(true)
			stl[3]:setVisible(true)
			stl[4]:setVisible(true)
			stl[5]:setVisible(true)		
		end
	end)
end

function worldmatch_pub:initStagePlane(plane,i)
	local sc = {}
	for k=1,5 do
		table.insert(sc,uikits.child(plane,ui.STAGE_CURRENT..k))
	end
	local function hide()
		for k=1,5 do
			sc[k]:setVisible(false)
		end
	end
	hide()
	local show = {}
	if self._data.match_level_count==2 then
		table.insert(show,1)
		table.insert(show,5)
	elseif self._data.match_level_count==3 then
		table.insert(show,1)
		table.insert(show,2)
		table.insert(show,5)
	elseif self._data.match_level_count==4 then
		table.insert(show,1)
		table.insert(show,2)
		table.insert(show,3)
		table.insert(show,5)
	elseif self._data.match_level_count==5 then
		table.insert(show,1)
		table.insert(show,2)
		table.insert(show,3)
		table.insert(show,4)
		table.insert(show,5)
	end
	sc[show[i]]:setVisible(true)
	self._data.stages = self._data.stages or {}
	self._data.stages[i] = self._data.stages[i] or {}
	self._data.stages[i].rules = self._data.stages[i].rules or 10
	self._data.stages[i].diff = self._data.stages[i].diff or 1
	self._data.stages[i].rep = self._data.stages[i].rep or 0
	self._data.stages[i].matchday = self._data.stages[i].matchday or 2
	self._data.stages[i].voteday = self._data.stages[i].voteday or 2
	self._data.stages[i].money = self._data.stages[i].money or 1
	uikits.event(uikits.child(plane,ui.STAGE_COUNT_BUT),
		function(sender)
			self:showPlayerCountDialog(self._data.stages[i].rules,
			self._data.current_stage,
			self._data.match_level_count,
			function(n)
				self._data.stages[i].rules = n
				uikits.child(plane,ui.STAGE_PLAY_COUNT):setString(n)
			end)
		end)
	uikits.child(plane,ui.STAGE_PLAY_COUNT):setString(self._data.stages[i].rules)	
	local diff_t = {}
	for i=1,9 do
		table.insert(diff_t,ui.STAGE_DIFENT..i)
	end
	local bd = self._data.stages[i].diff
	local diff_tabs = state.tab(plane,diff_t,function(k)
		self._data.stages[i].diff = k
	end)
	diff_tabs.switch(bd)
	
	local match_day = uikits.child(plane,ui.STAGE_MATCH_DAY)
	match_day:setString(self._data.stages[i].matchday)
	uikits.event(uikits.child(plane,ui.STAGE_MATCH_BUT),
	function(sender)
		self:showDayDialog(self._data.stages[i].matchday,function(n)
			self._data.stages[i].matchday = n
			match_day:setString(self._data.stages[i].matchday)
		end)
	end)
	local vote_day = uikits.child(plane,ui.STAGE_VOTE_DAY)
	vote_day:setString(self._data.stages[i].voteday)
	uikits.event(uikits.child(plane,ui.STAGE_VOTE_BUT),
	function(sender)
		self:showDayDialog(self._data.stages[i].voteday,function(n)
			self._data.stages[i].voteday = n
			vote_day:setString(self._data.stages[i].voteday)		
		end)
	end)	
	
	local reps = {}
	for i=1,4 do
		table.insert(reps,ui.STAGE_REP_1..(i-1))
		if self._slivers then
			uikits.child(plane,ui.STAGE_REP_1..(i-1)..'/w2'):setString("消费银币"..(self._slivers[i] or '-'))
		else
			uikits.child(plane,ui.STAGE_REP_1..(i-1)..'/w2'):setString("消费银币-")
		end
	end
	local m = self._data.stages[i].money
	local progs = state.progress(plane,reps,function(k)
		self._data.stages[i].money = k
		self._data.stages[i].rep = k
	end,true)
	progs.progress(m)
	
	if i==1 then
		local da = os.date("*t")
		uikits.child(plane,ui.STAGE_DATE_LABEL):setString(da.year..'/'..da.month..'/'..da.day)
	else
		local ti = os.time()
		for k=1,i-1 do
			ti = ti + (self._data.stages[k].voteday+self._data.stages[k].matchday)*24*3600
		end
		local da = os.date("*t",ti)
		uikits.child(plane,ui.STAGE_DATE_LABEL):setString(da.year..'/'..da.month..'/'..da.day)		
	end
end

function worldmatch_pub:initPlane3()
	local plane = self._planes[3]
	self._data.current_stage = self._data.current_stage or 1
	self:initStagePlane(plane,self._data.current_stage)
end

function worldmatch_pub:initPlane4()
	local plane = self._planes[4]
	local defn = {1,2,3,10}
	self._data.award = {}
	local function init_plane_item( i,item )
		local but = uikits.child(item,ui.PLANE4_ITEM_BUT)
		local img = uikits.child(item,ui.PLANE4_ITEM_IMG)
		local img_but = uikits.child(item,ui.PLANE4_ITEM_IMGBUT)
		uikits.event(but,function(sender)
			self:showNumberDialog(self._data.award[i].itemnum,function(n)
				self._data.award[i].itemnum = n
				uikits.child(item,ui.PLANE4_ITEM_NUM):setString( n or '-' )
			end)
		end)
		uikits.event(img_but,function(sender)
			self:showSelectImage(function(img_file)
				local file = kits.get_cache_path()..img_file
				self._data.award[i].award_file = img_file
				img:loadTexture(file)
			end)
		end)
	end
	for i=1,4 do
		table.insert(self._data.award,{itemnum=defn[i],awardimg=""})
		init_plane_item( i,uikits.child(plane,ui.PLANE4_ITEM..i) )
	end
end

function worldmatch_pub:showDayDialog(num,func)
	local days = {1,2,3,4,5,7,10,15,30,60}
	local plane = uikits.child(self._root,ui.DAY_PLANE)
	plane:setVisible(true)
	local t = {}
	for i=1,10 do
		table.insert(t,ui.DAY_BUT..days[i])
	end
	local function ge_day_num( s )
		for i,v in pairs(days) do
			if v == s then
				return i
			end
		end
		return 1
	end
	local _num = 1
	local tabs = state.tab(plane,t,function(i)
		_num = i
	end)
	tabs.switch(ge_day_num( num or 1 ) or 1)
	uikits.event(uikits.child(plane,ui.DAY_OK),function(sender)
		plane:setVisible(false)
		if func then
			func(days[_num])
		end
	end)
end

function worldmatch_pub:showNumberDialog(defn,func)
	local plane = uikits.child(self._root,ui.NUMBER_PLANE)
	plane:setVisible(true)
	local number = uikits.child(plane,ui.NUM_LABEL)
	local num = defn
	number:setString(num)
	for i = 0,9 do
		uikits.event( uikits.child(plane,ui.NUM_BUT..i),function(sender)
			num = num*10+i
			number:setString(num)
		end)
	end
	uikits.event(uikits.child(plane,ui.NUM_BACKSPACE),function(sender)
		num = math.floor(num/10)
		number:setString(num)
	end)
	uikits.event(uikits.child(plane,ui.NUM_DELTE),function(sender)
		num = 0
		number:setString(num)
	end)	
	uikits.event(uikits.child(plane,ui.PLAY_COUNT_CANCEL),function(sender)
		plane:setVisible(false)
	end)		
	uikits.event(uikits.child(plane,ui.PLAY_COUNT_OK),function(sender)
		plane:setVisible(false)
		if func then
			func( num )
		end
	end)	
end

function worldmatch_pub:showPlayerCountDialog(defn,c,t,func)
	local plane = uikits.child(self._root,ui.PLAY_COUNT_PLANE)
	plane:setVisible(true)
	local number = uikits.child(plane,ui.NUM_LABEL)
	local num = defn
	number:setString(num)
	for i = 0,9 do
		uikits.event( uikits.child(plane,ui.NUM_BUT..i),function(sender)
			num = num*10+i
			number:setString(num)
		end)
	end
	uikits.event(uikits.child(plane,ui.NUM_BACKSPACE),function(sender)
		num = math.floor(num/10)
		number:setString(num)
	end)
	uikits.event(uikits.child(plane,ui.NUM_DELTE),function(sender)
		num = 0
		number:setString(num)
	end)	
	uikits.event(uikits.child(plane,ui.PLAY_COUNT_CANCEL),function(sender)
		plane:setVisible(false)
	end)		
	uikits.event(uikits.child(plane,ui.PLAY_COUNT_OK),function(sender)
		plane:setVisible(false)
		if func then
			func( num )
		end
	end)	
	local stage = {}
	for i=1,4 do
		local item = uikits.child(plane,ui.PLAY_COUNT_STAGE..i)
		item:setVisible(false)
		table.insert(stage,item)
	end
	local show = {}
	if t==2 then
		table.insert(show,1)
		table.insert(show,5)
	elseif t==3 then
		table.insert(show,1)
		table.insert(show,2)
		table.insert(show,5)
	elseif t==4 then
		table.insert(show,1)
		table.insert(show,2)
		table.insert(show,3)
		table.insert(show,5)
	elseif t==5 then
		table.insert(show,1)
		table.insert(show,2)
		table.insert(show,3)
		table.insert(show,4)
		table.insert(show,5)
	end
	if show[c] < 5 and show[c] > 0 then
		stage[show[c]]:setVisible(true)
	end
end

function worldmatch_pub:cacheRes( res )
	local cacheFile
	
	if string.sub(res,-4,-4)=='.' then
		cacheFile = md5.sumhexa(res)..string.sub(res,-4)
	else
		cacheFile = md5.sumhexa(res)
	end
	local cpFile = kits.get_cache_path()..cacheFile
	if kits.exist_file(cpFile) then
		return cacheFile
	else
		kits.copy_file(res,cpFile)
		return cacheFile
	end
end

function worldmatch_pub:showSelectImage(func)
	local sp = uikits.child(self._root,ui.PLANE_SELECT_IMAGE)
	sp:setVisible(true)
	uikits.event( uikits.child(sp,ui.SELECT_CAM),function(sender)
		cc_takeResource(TAKE_PICTURE,function(t,result,res)
			kits.log('type ='..tostring(t)..' result='..tostring(result)..' res='..tostring(res))
			if result == RESULT_OK then
				local b,res = cc_adjustPhoto(res,1280)
				if b and kits.exist_file(res) then
					res = self:cacheRes(res)
					func(res)
					sp:setVisible(false)
				else
					state.messagebox("错误","图像调整失败\n"..tostring(res))
					sp:setVisible(false)
				end
			else
				state.messagebox("提示","没有发现摄像头.")				
			end
		end)	
	end)
	uikits.event( uikits.child(sp,ui.SELECT_IMG),function(sender)
			cc_takeResource(PICK_PICTURE,function(t,result,res)
			kits.log('type ='..tostring(t)..' result='..tostring(result)..' res='..tostring(res))
			if result == RESULT_OK then
				local b,res = cc_adjustPhoto(res,1280)
				if b and kits.exist_file(res) then
					res = self:cacheRes(res)
					func(res)
					sp:setVisible(false)
				else
					state.messagebox("错误","图像调整失败\n"..tostring(res))
					sp:setVisible(false)
				end
			end
		end)	
	end)
	uikits.event( uikits.child(sp,ui.SELECT_CLOSE),function(sender)
		sp:setVisible(false)
	end)
end

function worldmatch_pub:release()
end

return worldmatch_pub