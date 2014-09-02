local uikits = require "uikits"
local socket = require "socket"
local loadingbox = require "src/errortitile/loadingbox"
local cache = require "cache"
local topics = require "src/errortitile/topics"
local resultview = require "src/errortitile/resultview"
local login = require "login"
local kits = require "kits"
--local answer = curweek or require "src/errortitile/answer"
local dopractice = class("dopractice")
dopractice.__index = dopractice
local ui = {
	TITLEVIEW = '2192',
	last_num = '2192/2199',
	right_num = '2192/2193',
	goback_but = '2192/2194',
	questionview = '2242',
	
	answerview = '2202',
	submit_but = '2202/2240',
	next_but = '2202/2241',
	tuofang_txt = '2202/2245',
	lianxian_txt = '2202/2247',
	paixu_txt = '2202/2249',
	weizhi_txt = '2202/2251',
	xuanze_view = '2202/2206',
	xuanze_a_but = '2202/2206/2207',
	xuanze_b_but = '2202/2206/2208',
	xuanze_c_but = '2202/2206/2209',
	xuanze_d_but = '2202/2206/2210',
	xuanze_e_but = '2202/2206/2211',
	xuanze_f_but = '2202/2206/2212',					
	panduan_view = '2202/2215',
	panduan_yes_but = '2202/2215/2216',
	panduan_no_but = '2202/2215/2217',
	tiankong_view = '2202/2218',
	tiankong_input_1 = '2202/2218/2219',
	tiankong_input_2 = '2202/2218/2225',
	tiankong_input_3 = '2202/2218/2237',
	
	question_type_lianxian = '2202/2203/2204',
	question_type_xuanze = '2202/2203/2904',
	question_type_tuofang = '2202/2203/2906',
	question_type_duoxuan = '2202/2203/2908',
	question_type_weizhi = '2202/2203/2910',
	question_type_danxuan = '2202/2203/2912',
	question_type_paixu = '2202/2203/2914',
	question_type_panduan = '2202/2203/2916',
	question_type_tiankong = '2202/2203/2918',
}
local tb_question_type = {
{1,"判断",ui.question_type_panduan,},
{2,"单选",ui.question_type_danxuan},
{3,"多选",ui.question_type_duoxuan},
{4,"连线",ui.question_type_lianxian},
{5,"填空",ui.question_type_tiankong},
{6,"选择",ui.question_type_xuanze},
{7,"横排序",ui.question_type_paixu},
{8,"竖排序",ui.question_type_paixu},
{9,"点图单选",ui.question_type_danxuan},
{10,"点图多选",ui.question_type_duoxuan},
{11,"单拖放",ui.question_type_tuofang},
{12,"多拖放",ui.question_type_tuofang},
{13,"完形",""},
{14,"复合",""},
{15,"主观有答案",""},
{16,"主观无答案",""}
}
--local item_index
local function loadArmature( name )
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(name)
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(name)	
end

function create(tb_item_id)
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),dopractice)		
	cur_layer.tb_item_id = tb_item_id	
	cur_layer.right_itemcount = 0
	cur_layer.item_index = 1
	scene:addChild(cur_layer)
	
	local function onNodeEvent(event)
		if "enter" == event then
			cur_layer:init()
		elseif "exit" == event then			
			cur_layer:release()
		end
	end	
	cur_layer:registerScriptHandler(onNodeEvent)
	return scene	
end

function dopractice:getdatabyurl(index)
	local send_data
	local json_data = {}
	local tab_json = {}
	tab_json[1] = self.tb_item_id[index]
	json_data.item_id = tab_json
	send_data = json.encode(json_data)
	print(self.tb_item_id[index])
	print(send_data)
	result = kits.http_post(t_nextview[10].url,send_data,login.cookie(),1)
	print(result)
	local tb_result = json.decode(result)
	if tb_result.result == 0 then
		self.item_data = tb_result.exerbook_user_items[1]
		self:showitemdata(self.item_data)
	end
end

function dopractice:resetview()
	local item_temp
	item_temp = uikits.child(self._widget,ui.submit_but)
	item_temp:setVisible(false)
	item_temp = uikits.child(self._widget,ui.next_but)
	item_temp:setVisible(false)
	item_temp = uikits.child(self._widget,ui.tuofang_txt)
	item_temp:setVisible(false)
	item_temp = uikits.child(self._widget,ui.lianxian_txt)
	item_temp:setVisible(false)	
	item_temp = uikits.child(self._widget,ui.paixu_txt)
	item_temp:setVisible(false)
	item_temp = uikits.child(self._widget,ui.weizhi_txt)
	item_temp:setVisible(false)	
	item_temp = uikits.child(self._widget,ui.xuanze_view)
	item_temp:setVisible(false)	
	item_temp = uikits.child(self._widget,ui.panduan_view)
	item_temp:setVisible(false)	
	item_temp = uikits.child(self._widget,ui.tiankong_view)
	item_temp:setVisible(false)	
	item_temp = uikits.child(self._widget,ui.question_type_lianxian)
	item_temp:setVisible(false)	
	item_temp = uikits.child(self._widget,ui.question_type_xuanze)
	item_temp:setVisible(false)	
	item_temp = uikits.child(self._widget,ui.question_type_tuofang)
	item_temp:setVisible(false)	
	item_temp = uikits.child(self._widget,ui.question_type_duoxuan)
	item_temp:setVisible(false)	
	item_temp = uikits.child(self._widget,ui.question_type_weizhi)
	item_temp:setVisible(false)	
	item_temp = uikits.child(self._widget,ui.question_type_danxuan)
	item_temp:setVisible(false)	
	item_temp = uikits.child(self._widget,ui.question_type_paixu)
	item_temp:setVisible(false)	
	item_temp = uikits.child(self._widget,ui.question_type_panduan)
	item_temp:setVisible(false)	
	item_temp = uikits.child(self._widget,ui.question_type_tiankong)
	item_temp:setVisible(false)	
	local questionview = uikits.child(self._widget,ui.questionview)
	questionview:removeAllChildren()
end

function dopractice:submitanswer(item_id,item_answer,item_type)
	local send_data
	local json_data = {}
	local tab_json = {}
	--tab_json[1] = item_id
--	print(item_type)
	uikits.stopAllSound()
	if item_type > 0 and item_type < 13 then
		tab_json.item_id = item_id
		tab_json.answer = ''
		if item_answer == nil then
			tab_json.answer = ''
		else
			if item_type == 5 then
				for i = 1,#item_answer do 
					tab_json.answer = tab_json.answer .. item_answer[i]
					if i ~= #item_answer then
						tab_json.answer = tab_json.answer .. ','
					end
				end
			else
				tab_json.answer = item_answer[1]
			end
		end
		json_data[1] = tab_json
		send_data = json.encode(json_data)
	--	print("send_data"..send_data)
--		print(t_nextview[11].url)
		result = kits.http_post(t_nextview[11].url,send_data,login.cookie(),1)
	--	print(result)
		local tb_result = json.decode(result)
		if tb_result.result == 0 then
			if tb_result.corr_cnt == 1 then
				self.right_itemcount = self.right_itemcount+1				
			end
		end		
	end

end

function dopractice:showitemdata(item_data)
	local last_num = uikits.child(self._widget,ui.last_num)
	local right_num = uikits.child(self._widget,ui.right_num)
	local questionview = uikits.child(self._widget,ui.questionview)
	self:resetview()
--	print("item_index::"..self.item_index)
	last_num:setString(#self.tb_item_id-self.item_index)
	right_num:setString(self.right_itemcount)
	
	local question_type_view = uikits.child(self._widget,tb_question_type[item_data.item_type][3])
	question_type_view:setVisible(true)
	local submit_but = uikits.child(self._widget,ui.submit_but)
	local next_but = uikits.child(self._widget,ui.next_but)

	local data = {}
	print(item_data.item_type)
	topics.setEditChildTag("daan")
	if item_data.item_type > 0 and item_data.item_type < 13 then
--		print(topics.types[item_data.item_type])
		if topics.types[item_data.item_type].conv(item_data,data) then
			data.eventInitComplate = function(layout,data)

			end
			data._options = {}
			local item_temp
			if item_data.item_type == 5 then											--填空
				item_temp = uikits.child(self._widget,ui.tiankong_view)
				item_temp:setVisible(true)	
				item_temp = uikits.child(self._widget,ui.tiankong_input_1)
				data._options[1] = item_temp
				item_temp:setVisible(false)
				item_temp = uikits.child(self._widget,ui.tiankong_input_2)
				data._options[2] = item_temp
				item_temp:setVisible(false)					
				item_temp = uikits.child(self._widget,ui.tiankong_input_3)
				data._options[3] = item_temp
				item_temp:setVisible(false)					
			elseif item_data.item_type == 1 then											--判断
				item_temp = uikits.child(self._widget,ui.panduan_view)
				item_temp:setVisible(true)	
				item_temp = uikits.child(self._widget,ui.panduan_yes_but)
				data._options[1] = item_temp
				item_temp:setVisible(false)	
				item_temp = uikits.child(self._widget,ui.panduan_no_but)
				data._options[2] = item_temp
				item_temp:setVisible(false)	
			elseif item_data.item_type == 2 or item_data.item_type == 3 or item_data.item_type == 6 then --选择
				item_temp = uikits.child(self._widget,ui.xuanze_view)
				item_temp:setVisible(true)					
				item_temp = uikits.child(self._widget,ui.xuanze_a_but)
				data._options[1] = item_temp
				item_temp:setVisible(false)	
				item_temp = uikits.child(self._widget,ui.xuanze_b_but)
				data._options[2] = item_temp
				item_temp:setVisible(false)		
				item_temp = uikits.child(self._widget,ui.xuanze_c_but)
				data._options[3] = item_temp
				item_temp:setVisible(false)	
				item_temp = uikits.child(self._widget,ui.xuanze_d_but)
				data._options[4] = item_temp
				item_temp:setVisible(false)		
				item_temp = uikits.child(self._widget,ui.xuanze_e_but)
				data._options[5] = item_temp
				item_temp:setVisible(false)	
				item_temp = uikits.child(self._widget,ui.xuanze_f_but)
				data._options[6] = item_temp
				item_temp:setVisible(false)		
			elseif item_data.item_type == 11 or item_data.item_type == 12 then 						--拖放
					item_temp = uikits.child(self._widget,ui.tuofang_txt)
					item_temp:setVisible(true)
			elseif item_data.item_type == 9 or item_data.item_type == 10 then 						--点图选择
					item_temp = uikits.child(self._widget,ui.weizhi_txt)
					item_temp:setVisible(true)
			elseif item_data.item_type == 4 then 														--连线
					item_temp = uikits.child(self._widget,ui.lianxian_txt)
					item_temp:setVisible(true)	
			elseif item_data.item_type == 7 or item_data.item_type == 8 then 							--排序		
					item_temp = uikits.child(self._widget,ui.paixu_txt)
					item_temp:setVisible(true)
			else
			
			end
			topics.types[item_data.item_type].init(questionview,data)
		end		
	end

	
	uikits.event(submit_but,	
		function(sender,eventType)
		
		local loadbox = loadingbox.open(self)
		self:submitanswer(item_data.item_id,data.my_answer,item_data.item_type)
		loadbox:removeFromParent()
		self.dt = os.time()-self.dt
		local scene_next = resultview.create(self.dt,self.right_itemcount,self.item_index)								
		cc.Director:getInstance():replaceScene(scene_next)			
	end,"click")
	
	uikits.event(next_but,
		function(sender,eventType)
		
		local loadbox = loadingbox.open(self)
		self:submitanswer(item_data.item_id,data.my_answer,item_data.item_type)
		loadbox:removeFromParent()
		
		self.item_index = self.item_index+1
		self:getdatabyurl(self.item_index)
	end,"click")
		
	if self.item_index == #self.tb_item_id then		
		submit_but:setVisible(true)
	else
		next_but:setVisible(true)	
	end
	
	local goback_but = uikits.child(self._widget,ui.goback_but)
	uikits.event(goback_but,
		function(sender,eventType)
		local loadbox = loadingbox.open(self)
		self:submitanswer(item_data.item_id,data.my_answer,item_data.item_type)
		loadbox:removeFromParent()
		self.dt = os.time()-self.dt
		local scene_next = resultview.create(self.dt,self.right_itemcount,self.item_index)								
		cc.Director:getInstance():replaceScene(scene_next)	
	end,"click")
end

function dopractice:init()	
	if _G.screen_type == 1 then
		self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/zuoti.json")			
	else
		self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/zuoti43.json")		
	end
	self:addChild(self._widget)
	self.dt = os.time()	
	local last_num = uikits.child(self._widget,ui.last_num)
	local right_num = uikits.child(self._widget,ui.right_num)

	last_num:setString(#self.tb_item_id-self.item_index)
	right_num:setString(self.right_itemcount)

	
	self:getdatabyurl(self.item_index)
	--self:showitemdata(self.item_data)
end

function dopractice:release()

end
return {
create = create,
}