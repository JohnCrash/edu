local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"
local http = require "hitmouse2/hitconfig"

local local_dir = kits.get_local_directory()..'res/'

local ui = {
	FILE = 'hitmouse2/chongzhi.json',
	FILE_3_4 = 'hitmouse2/chongzhi43.json',
	CANCEL = "tu/guan",
	BUY_PLANE = "tu",
	LIST = "tu/gun",
	ITEM = "cz1",
	ITEM_SLIVER_COST = "w1",
	ITEM_SLIVER_GIFT = "w2",
	ITEM_LEBI_COST = "qian/w1",
	ITEM_BUY_BUT = "qian",
	WAIT_DIALOG = "guoc",
}
local _spvalue = 0
local _spup = 0
local _spv = 0
local _spst = 0

local function set_sp(sp,up,v)
	_spvalue = sp
	_spup = up
	_spv = 1/v
	_spst = cc_clock()
end

local function get_sp()
	local sp = _spvalue+_spv*(cc_clock()-_spst)
	if sp > _spup then
		return math.floor(_spup),math.floor(_spup),_spv
	else
		return math.floor(sp),math.floor(_spup),_spv
	end
end

local _sliver = 0
local function set_sliver(s)
	_sliver = s
end

local function get_sliver()
	return math.floor(_sliver)
end

local _add_sliver = 0
local function get_add_sliver()
	local s = _add_sliver
	_add_sliver = 0
	return s
end

local _news = {}
local function get_news()
	return _news
end

local function set_news(v1,v2,v3,v4)
	_news.hasMission = v1
	_news.hasMatch = v2
	_news.hasWorldMatch = v3
	_news.hasAchievement = v4
end

local function set_hasmsg(b)
	_news.hasMsg = b
end

local function request_buy_sp(parent,uiid,func)
	uikits.event(uikits.child(parent,uiid),function(sender)
		if get_sp() == _spup then
			http.messagebox(parent,http.OK_MSG,function(s)
			end,"体力值已经是满的了，不需要购买体力值。")
			return
		end
		http.messagebox(parent,http.BUY_SP,function(s)
			if s==http.OK then
				local send_data = {}
				kits.log("do main:buy_sp...")
				http.post_data(parent,'buy_sp',send_data,function(t,v)
					if t and t==200 and v then
						http.logTable(v,1)
						if v.v1 and v.v1==1 then
							if v.v2 and v.v3 and v.v4 and v.v5 then
								set_sliver(v.v2)
								set_sp(v.v3,v.v4,v.v5)
								func(v)
							else
								kits.log("ERROR buy_sp return invalid value!")
							end
						elseif v.v1 and v.v1==0 then
							http.messagebox(parent,http.NO_SILVER,function(s)
							end)
						end
					else
						kits.log("ERROR buy_sp failed!")
					end
				end,true)				
			end
		end)	
	end)
end

local function show_sale_item(parent,func)
	local ssi = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
	ssi:setAnchorPoint{x=0.5,y=0.5}
	local size
	if parent.getContentSize then
		size = parent:getContentSize()
	else
		size = uikits.getDR()
	end
	ssi:setPosition{x=size.width/2,y=size.height/2}	
	parent:addChild(ssi,10000)
	local cancel = uikits.child(ssi,ui.CANCEL)
	if cancel then
		uikits.event(cancel,function(sender)
			uikits.delay_call(parent,function(dt)
				ssi:removeFromParent()
			end)
		end)
	end
	local buy_plane = uikits.child(ssi,ui.BUY_PLANE)
	local wait_dialog = uikits.child(ssi,ui.WAIT_DIALOG)
	wait_dialog:setVisible(false)
	buy_plane:setVisible(true)
	local function cb(parent,n)
		if ssi and cc_isobj(ssi) then
			if n==0 then
				wait_dialog:setVisible(true)
				buy_plane:setVisible(false)			
			else
				uikits.delay_call(parent,function(dt)
					if ssi and cc_isobj(ssi) then
						ssi:removeFromParent()
						ssi = nil
					end
				end)				
			end
		end
	end
	--初始化列表
	local list = uikits.scrollex(ssi,ui.LIST,{ui.ITEM})
	local function init_list(t)
		http.logTable(t,1)
		for i,v in pairs(t) do
			local item = list:additem(1)
			uikits.child(item,ui.ITEM_SLIVER_COST):setString((v.silvers or "-").."银币")
			uikits.child(item,ui.ITEM_SLIVER_GIFT):setString((v.silver_gift or "-").."银币")
			uikits.child(item,ui.ITEM_LEBI_COST):setString((v.cost or "-").."乐币")
			uikits.event(item,
				function(sender)
					cb(parent,0)
					func(v.item_id,cb)
				end)
		end
		list:relayout_horz()
	end
	
	local function init_data()
		local http = require "hitmouse2/hitconfig"
		local send_data = {}
		kits.log("do show_sale_item buy_silver_list")
		http.post_data(parent,"buy_silver_list",send_data,function(t,v)
			http.logTable(v,1)
			if t and t==200 and v then
				if v.v1 and type(v.v1)=='table' then
					init_list(v.v1)
				else
					kits.log("buy_silver_list = nil")
				end
			else
				http.messagebox(parent,http.DIY_MSG,function(e)
					if e == http.RETRY then
						init_data()
					else
						uikits.delay_call(parent,function(dt)
							ssi:removeFromParent()
						end)
					end
				end,v)		
			end
		end)
	end
	init_data()
end

local function notify_paypay(parent,ispay,order,item_id,notify,cb)
	local send_data = {v1=item_id,v2=order,v3=ispay}
	kits.log("do notify_paypay...")
	http.post_data(parent,'notify_buy_result',send_data,function(t,v)
		http.logTable(v,1)
		if cb then
			cb(parent,1)
		end
		if t and t==200 and v then
			if not v.v1 then
				kits.log("ERROR notify_buy_result return invalid result")
			end
			if v.v1 and v.v2 and v.v2>0 then
				_add_sliver = v.v2
				http.messagebox(parent,http.OK_MSG,function(e)
						notify(true)
							end,tostring("支付成功"))
			end
		else
			http.messagebox(self._root,http.DIY_MSG,function(e)
			   if e==http.RETRY then
					notify_paypay(parent,ispay,order,item_id,notify,cb)
				else
					uikits.popScene()
				end
			end,v)		
		end		
	end,true)
end

local function paypay2(parent,order,payurl,item_id,notify,cb)
	local pay = require "pay"
	kits.log("do paypay2...")
	if payurl then
		kits.log("paypay2 url "..tostring(payurl))
		local s,msg = pay.byurl(
			payurl,
			function(b,msg)
				kits.log("paypay b = "..tostring(b).." msg="..tostring(msg))
				notify_paypay(parent,b,order,item_id,notify,cb)
				--提示用户支付失败
				if not b then
					local errormsg
					if msg and type(msg)=='string' and string.len(msg)>0 then
						errormsg = msg
					elseif not b then
						errormsg = "因为网络原因导致支付失败."
					else
						errormsg = msg
					end
					if cb then
						cb(parent,1)
					end					
					http.messagebox(parent,http.OK_MSG,function(e)
						end,tostring(errormsg))
				end
			end
		)
		if not s then
			notify_paypay(false,order,item_id,notify,cb)
			http.messagebox(self._root,http.OK_MSG,function(e)
					end,tostring(msg))
		end
	end
end

local function pay2(parent,item_id,notify,cb)
	local send_data = {v1=item_id,v2="",v3="",v4=1}
	kits.log("do pay2...")
	http.post_data(parent,'buy_item',send_data,function(t,v)
		if cb then
			cb(parent,1)
		end		
		if t and t==200 and v then
			http.logTable(v,1)
			if v.v1 then
				--paypay2(parent,v.v3,v.v4,v.v5,notify,cb)
				--废弃以前的购买接口，这里已经成功付款
				--v2(string): 失败的原因描述
				--v3(int):如果是兑换操作返回要增加的银币数量		
				if v.v3 and v.v3 >= 0 then
					_add_sliver = v.v3
					http.messagebox(parent,http.OK_MSG,function(e)
							notify(true)
								end,tostring("支付成功"))
				else
					http.messagebox(parent,http.OK_MSG,function(e)
					end,"购买接口没有返回预期结果!")
				end
			else
				local buys = {
					[-6] = 2000,
					[-5] = 1000,
					[-4] = 500,
					[-3] = 200,
					[-2] = 100,
				}
				local c = buys[item_id]
				
				http.messagebox(parent,http.BUY_LB,function(e)
					if e == http.BUY_LB then
						cc_buy("count="..tostring(c or 2000),function(t,result,res)
							if t == 100 then
								kits.log('type ='..tostring(t)..' result='..tostring(result)..' res='..tostring(res))
								if result ~= 0 then
									--成功充值
								end
							end
						end)
					end
				end,tostring(v.v2 or 'buy_item return v.v2 = nil'))		
				
			end
		else
			http.messagebox(parent,http.DIY_MSG,function(e)
			   if e==http.RETRY then
					pay2(parent,item_id,notify,cb)
				else
					uikits.popScene()
				end
			end,v)		
		end
	end,true)	
end

local function request_buy_silver(parent,uiid,func)
	local but = uikits.child(parent,uiid)
	if but then
		but:setVisible(true)
		uikits.event(but,function(sender)
			show_sale_item(parent,function(item_id,cb)
				pay2(parent,item_id,func,cb)
			end)
		end)
	end
end

local function tab(parent,uitabs,func)
	local t = {}
	
	local function switchTab(i)
		if t[i] then
			for k,v in pairs(t) do
				v:setSelectedState(false)
			end
			if func then
				func(i)
			end
			t[i]:setSelectedState(true)
		end
	end
	
	for i,v in pairs(uitabs) do
		local item = uikits.child(parent,v)
		t[i] = item
		uikits.event(item,function()
			switchTab(i)
		end)
	end
	switchTab(1)
	
	return {_tabs = t,switch=switchTab}
end

local function progress(parent,uitabs,func,b)
	local t = {}
	
	local function switchTab(i)
		for k,v in pairs(t) do
			if k <= i then
				v:setSelectedState(true)
			else
				v:setSelectedState(false)
			end
		end
		if func then
			func(i)
		end
	end
	
	for i,v in pairs(uitabs) do
		local item = uikits.child(parent,v)
		if not b then
			item:setTouchEnabled(false)
		else
			uikits.event(item,function()
				switchTab(i)
			end)		
		end
		t[i] = item
	end
	switchTab(1)
	
	return {_tabs = t,progress=switchTab}
end

local _times_local = {}
local function timer(time_label,time_total)
	local total = time_total or 0
	local t0 = os.time()
	_times_local[time_label] = time_total
	if time_label and cc_isobj(time_label) then
		time_label:setString(kits.time_to_string(time_total))
	end
	uikits.delay_call(nil,function(dt)
		local dt = os.time()-t0
		local t = total-dt
		if _times_local[time_label] == time_total then
			if t < 0 then t = 0 end
			if cc_isobj(time_label) then
				time_label:setString(kits.time_to_string(t))
				return true
			end
		end
	end,1)
end

local _star={}
local function set_level_star(t)
	_star = t
end
local function get_level_star()
	return _star
end

local function messagebox(caption,text,button,func)
	local factory = require "factory"
	local base = require "base"
	local messageBox = factory.create(base.MessageBox)
	messageBox:open{caption=caption,text=text,onClick=func,button=button or 1}
end

local function progressbar(caption)
	local factory = require "factory"
	local base = require "base"
	local progressbox = factory.create(base.ProgressBox)
	progressbox:open()
	progressbox:setProgress(0)	
	return progressbox
end

local _isregion
local _region_name
local _region_id
local _region_v
local function set_region(b,n,i,v)
	_isregion = b
	_region_name = n
	_region_id = i
	_region_v = v
	--将直接的单位加入到第一个
	if _region_v and _region_id and _region_name and type(_region_v)=='table' then
		table.insert(_region_v,1,{region_id=_region_id,name=_region_name})
	end
end

local function get_region()
	return _isregion,_region_name,_region_id,_region_v
end

local function playSound( name )
	local file = 'hitmouse2/snd/'..name
	kits.log( "Play sound: "..file )
	uikits.playSound(local_dir..file)
end

local function uploads( files,func )
	local url = 'http://file-stu.lejiaolexue.com/rest/user/upload/hw'
	local count = #files
	local c = 0
	local dones = {}
	local failes = {}
	for i,v in pairs(files) do
		local data = kits.read_cache(v)
		if data then
			kits.log("upload file : "..tostring(v))
			cache.upload( url,v,data,
				function(b,t)
					c = c + 1	
					if b and t and t.md5 then
						dones[v] = "http://file-stu.lejiaolexue.com/rest/dl/"..tostring(t.md5)
						kits.log("upload success : "..dones[v] )
					else
						kits.log("upload failed : "..dones[v] )
						table.insert(failes,v)
					end
					if c==count then
						func( #failes==0,dones,failes )
					end
				end,
				function(p)
				end)
		else
			kits.log("ERROR state.uploads can not read "..tostring(v))
		end
	end
end

local function next_stage(parent,id,func)
	local send_data = {v1=id}
	kits.log("do main:promotion...")
	http.post_data(parent,'promotion',send_data,function(t,v)
		if t and t==200 then
			http.logTable(v,1)
			func(true)
			kits.log("promotion done.")
		else
			func(false)
			kits.log("ERROR promotion failed!")
		end
	end,true)		
end

local g_name
local function set_name(n)
	g_name = n
end

local function get_name()
	return g_name
end

local _zone

local function set_zone(z)
	_zone = z
end

local function get_zone()
	return _zone
end

return {
	set_sp = set_sp,
	get_sp = get_sp,
	set_sliver = set_sliver,
	get_sliver = get_sliver,
	get_add_sliver = get_add_sliver,
	get_news = get_news,
	set_hasmsg = set_hasmsg,
	set_news = set_news,
	request_buy_sp = request_buy_sp,
	request_buy_silver = request_buy_silver,
	tab = tab,
	timer = timer,
	messagebox = messagebox,
	progressbar = progressbar,
	progress = progress,
	set_region = set_region,
	get_region = get_region,
	get_level_star = get_level_star,
	set_level_star = set_level_star,
	playSound = playSound,
	uploads = uploads,
	next_stage = next_stage,
	set_name = set_name,
	get_name = get_name,
	set_zone = set_zone,
	get_zone = get_zone,
}