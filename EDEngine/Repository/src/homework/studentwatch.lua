local uikits = require "uikits"
local cache = require "cache"
local kits = require "kits"
local topics = require "homework/topics"
local loadingbox = require "loadingbox"
local json = require "json-c"
local login = require "login"

local ui = {
	FILE = 'homework/yijiaokeguan.json',
	FILE_3_4 = 'homework/yijiaokeguan43.json',
	BACK = 'white/back',
	
	WRONG_BUTTON = 'white/wrong',
	CAPTION = 'white/lesson_name',
	OBJECTIVE_RATE = 'xinxi/objective_no',
	OBJECTIVE_TIME = 'xinxi/time',
	OBJECTIVE_FEN = 'xinxi/fenshu',
	LIST = 'tixinxi',
	ITEM = 'ti1',
	ITEM_TITLE = 'hui',
	ITEM_NAME = 'hui/tixing',
	ITEM_DIFFICULTY = 'hui/nandu',
	ITEM_WRONG_RATE = 'hui/cuotilv',
	ITEM_RIGHT = 'hui/dui',
	ITEM_WRONG = 'hui/cuo',
	ITEM_ANSWER = 'hui/answer',
	ITEM_LAYOUT = 'Panel_25',
	TOPICS_ANSWER_SELECT = 'xuanz',
	TOPICS_ANSWER_SELECT_A = 'xuanxiang',
	TOPICS_ANSWER_EDIT = 'tiankong',
	TOPICS_ANSWER_EDIT_ITEM1 = 'tk1',
	TOPICS_ANSWER_EDIT_ITEM2 = 'tk2',
	TOPICS_ANSWER_EDIT_ITEM3 = 'tk3',
	TOPICS_ANSWER_JUDGE = 'panduan',	
}

local StudentWatch = class("StudentWatch")
StudentWatch.__index = StudentWatch

function StudentWatch.create(t)
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),StudentWatch)
	
	scene:addChild(layer)
	
	local function onNodeEvent(event)
		if "enter" == event then
			layer._args = t
			layer:init()
		elseif "exit" == event then
			layer:release()
		end
	end	
	layer:registerScriptHandler(onNodeEvent)
	return scene
end

function StudentWatch:init_data()
	if self._args and self._args._exam_table then
		if not self._first then
			self._first = true
			uikits.set(self._root,{
				[ui.CAPTION] = self._args.caption or "",
				[ui.OBJECTIVE_RATE] = "0/"..self._args.cnt_item,
				[ui.OBJECTIVE_TIME] = kits.time_to_string_simple(self._args.total_time),
				[ui.OBJECTIVE_FEN] = (self._args.real_score or "0").."分",
			})
			if self._args and type(self._args)=='table' then
				self._args.right_num = 0
			end
			self:init_paper_list_by_table(self._args._exam_table)
		end
	else
		kits.log('ERROR StudentWatch:init_data invalid arguments')
	end
end

local HasAnswerPlane={
	[1] = 1,
	[2] = 2,
	[3] = 3,
	[5] = 5,
	[6] = 6,
}

local function setAnswerPlane( plane,e,typ )
	if not plane or not e then return end
	if typ == 1 then --判断
		if e.my_answer and type(e.my_answer)=='table' then
			if e.my_answer[1] == 'A' then
			elseif e.my_answer[1] == 'B' then
				local item = uikits.child(plane,'xuanxiang')
				item:loadTexture('homework/option_wrong.png')
			end
		end
	elseif typ == 2 or typ == 3 or typ == 6 then
		local item = uikits.child(plane,'xuanxiang')
		for i,v in pairs(e.my_answer) do
			local op
			if i == 1 then
				op = item
			else
				op = item:clone()
				plane:addChild(op)
				local size = item:getContentSize()
				local x,y = item:getPosition()
				op:setPosition( x+(i-1)*size.width*3/2,y)
			end
			if string.len(v)==1 then
				op:loadTexture('homework/option_'..string.lower(tostring(v))..'x.png')
			else
				op:setVisible(false)
			end
		end
	elseif typ == 5 then
		if e.answer and type(e.answer)=='table' then
			local item = uikits.child(plane,'tk1')
			local item2 = uikits.child(plane,'tk2')
			local item3 = uikits.child(plane,'tk3')
			if e.isFraction then--分数
				item:setVisible(false)
				item2:setVisible(false)
				item3:setVisible(false)
				local ox,oy
				local size
				local op
				for i,v in pairs(e.isFraction) do
					if v == 1 then
						op = item:clone()
						uikits.child(op,'Label_79'):setString(tostring(e.my_answer[i]))
					elseif v == 2 then
						op = item2:clone()
						local str = tostring(e.my_answer[i])
						num1,num2 = string.match( str,'%s*(%-*%+*%d*$*)%s*~%s*(%-*%+*%d*$*)%s*')
						if num1 and num2 then
							uikits.child(op,'Label_78'):setString(tostring(num1))
							uikits.child(op,'Label_79'):setString(tostring(num2))
						else
							kits.log("ERROR Fraction invalid my_answer :"..tostring(str))
						end
					elseif v == 3 then
						op = item3:clone()
						local str = tostring(e.my_answer[i])
						local num1,num2,num3 = string.match( str,'%s*(%-*%+*%d*$*)%s*~%s*(%-*%+*%d*$*)%s*~(%-*%+*%d*$*)%s*')
						if num1 and num2 and num3 then
							uikits.child(op,'Label_78_0'):setString(tostring(num1))	
							uikits.child(op,'Label_78'):setString(tostring(num2))
							uikits.child(op,'Label_79'):setString(tostring(num3))						
						else
							kits.log("ERROR Fraction invalid my_answer :"..tostring(str))
						end
					else
						kits.log("ERROR isFraction invild value")
						return
					end
					plane:addChild(op)
					op:setVisible(true)
					if i == 1 then
						ox,oy = op:getPosition()
						size = op:getContentSize()
					else
						local nsize = op:getContentSize()
						op:setPosition(ox+nsize.width*(1/2+1/4)+size.width*(1/2+1/4),oy)
						ox,oy = op:getPosition()
						size = nsize
					end
				end
			else --正常填空
				item:setVisible(true);
				item2:setVisible(false);
				item3:setVisible(false);
				for i,v in pairs(e.my_answer) do
					local op
					if i == 1 then
						op = item
					else
						op = item:clone()
						plane:addChild(op)
						local size = item:getContentSize()
						local x,y = item:getPosition()
						op:setPosition( x+size.width*4/3,y)					
						uikits.child(op,'Label_78'):setString(tostring(i))
					end
					uikits.child(op,'Label_79'):setString(tostring(v))
				end
			end
		end	
	end
	--[[
	local function print_table(s,t)
		print('TABLE '..s)
		for i,v in pairs(t) do
			if type(v)=='table' then
				print_table( tostring(i),v )
			else
				print(tostring(i)..":"..tostring(v))
			end
		end
	end	
	print("type:"..tostring(typ))
	print("================")
	if type(e.answer)=='table' then
		
		print_table('answer',e.answer)
	else
		print('answer:'..tostring(e.answer))
	end
	if type(e.my_answer)=='table' then
		print_table('my_answer',e.my_answer)
	else
		print('my_answer:'..tostring(e.my_answer))
	end	
	print("================")
	--]]
end

--和teacherbatch.lua add_paper_item类似
function StudentWatch:add_paper_item( topicType,topicID )
	if topics.types[topicType] then
		self._papers:additem{
			[ui.ITEM_NAME] = topics.types[topicType].name,
			[ui.ITEM_DIFFICULTY] = '', --难度
			[ui.ITEM_LAYOUT] = function(child,item)
				local size = child:getContentSize()
				size.height = size.height/2
				child:setContentSize(size)
				
				local url = "http://new.www.lejiaolexue.com/student/handler/WorkItem.ashx?examId="..
				self._args.exam_id.."&itemId="..
				topicID.."&teacherId="..
				self._args.tid
				
				if login.get_uid_type() == login.PARENT then
					url = url..'&uid='..login.get_subuid()
				end
				
				local circle = loadingbox.circle(child)
				cache.request_json(url,function(t)
					if circle and cc_isobj(circle) then
						circle:removeFromParent()
					else
						kits.log('WARNING : StudentWatch:add_paper_item already remove')
						return
					end
					if t then
						local data = {}
						if t.buffer and t.buffer.difficulty_name then
							uikits.set(item,
							{
								[ui.ITEM_DIFFICULTY] = t.buffer.difficulty_name,
								[ui.ITEM_WRONG_RATE] = "0%"
							})
							local it = uikits.child(item,ui.ITEM_WRONG_RATE)
							if it and t.detail and t.detail.class_id then
								local u = 'http://new.www.lejiaolexue.com/exam/handler/examstatistic.ashx?q=stu_correct&t_id='
								..self._args.tid..'&exam_id='..self._args.exam_id..'&c_id='..t.detail.class_id..'&item_id='..topicID
								if login.get_uid_type() == login.PARENT then
									u = u..'&uid='..login.get_subuid()
								end
								cache.request_json(u,function(t)
									if t and type(t)=='number' and cc_isobj(it) then
										uikits.set_item(it,tostring(100-t)..'%')
									else
										kits.log('WARNING : wrong rate = '..tostring(t))
									end
								end)
							end
						end
						if t.detail and t.detail.isright then
							if  t.detail.isright ~= 0 then
								uikits.child(item,ui.ITEM_WRONG):setVisible(false)
								uikits.child(item,ui.ITEM_RIGHT):setVisible(true)
								self._args.right_num = self._args.right_num or 0
								self._args.right_num = self._args.right_num + 1
								uikits.set(self._root,{
									[ui.OBJECTIVE_RATE] = tostring(self._args.right_num).."/"..self._args.cnt_item,
								})								
							else
								uikits.child(item,ui.ITEM_WRONG):setVisible(true)
								uikits.child(item,ui.ITEM_RIGHT):setVisible(false)
							end
						else
							uikits.child(item,ui.ITEM_WRONG):setVisible(false)
							uikits.child(item,ui.ITEM_RIGHT):setVisible(false)						
							kits.log('ERROR request data not detail feild')
						end
						if topics.types[topicType].conv(t.buffer,data) then
							data.eventInitComplate = function(layout,data)
								if HasAnswerPlane[topicType] then
									local x,y = layout:getPosition()						
									local parent = child:getParent()
									--将答案置于面板中
									if topicType==1 then
										local plane = uikits.child(parent,ui.TOPICS_ANSWER_JUDGE)
										plane:setVisible(true)
										parent._answerPlane = plane
									elseif topicType==2 or topicType==3 or topicType==6 then
										local plane = uikits.child(parent,ui.TOPICS_ANSWER_SELECT)
										plane:setVisible(true)
										parent._answerPlane = plane
									elseif topicType==5 then
										local plane = uikits.child(parent,ui.TOPICS_ANSWER_EDIT)
										plane:setVisible(true)
										parent._answerPlane = plane
									end
									setAnswerPlane(parent._answerPlane,data,topicType)
								end							
								self:paper_relayout()
							end
							child:setEnabled(false) --禁止修改
							--[[ BUG? 服务器传送给我一个重复的多选题答案，例如C,C
							--]]
							if t.detail.answer and t.detail.answer and type(t.detail.answer)=='string' then --用户作答
								local asw = json.decode(t.detail.answer)
								if asw and asw.answers  and type(asw.answers)=='table' then
									data.my_answer = {}
									for i,v in pairs(asw.answers) do
										data.my_answer[i] = v.value
									end
								end
							end
							--设置答案
							local aw = uikits.child(item,ui.ITEM_ANSWER)
							if aw and data.my_answer[1] then
								if topicType==1 or topicType==2 or topicType==3 or topicType==6 then
									aw:setText( data.my_answer[1] )
								elseif topicType==5 then --填空
									local txt = ''
									for i,v in pairs(data.my_answer) do
										if v then
											if i == 1 then
												txt = v
											else
												txt = txt..','..v
											end
										end
									end
									aw:setText( txt )
								end
							end
							topics.types[topicType].init(child,data)
						else
							kits.log('')
						end
					end
				end)
			end
		}
	end
end
--和teacherbatch.lua paper_relayout类似
function StudentWatch:paper_relayout()
	if self._papers and self._papers._list then
		for k,item in pairs(self._papers._list) do
			local layout = uikits.child(item,ui.ITEM_LAYOUT)
			local title = uikits.child(item,ui.ITEM_TITLE)
			if layout and title then
				local item_size = item:getContentSize()
				local size = layout:getContentSize()
				local tsize = title:getContentSize()
				local ox,oy = layout:getPosition()
				local dh = 0
				if item._answerPlane then
					local x,y = item._answerPlane:getPosition()
					oy = y+item._answerPlane:getContentSize().height+self._paper_item_space
					dh = item._answerPlane:getContentSize().height+self._paper_item_space
				else
					oy = 0
				end
				layout:setPosition(ox,oy)
				title:setPosition(cc.p(ox,oy+size.height+self._paper_item_space2))
				item:setContentSize(cc.size(item_size.width,size.height+tsize.height+self._paper_item_space+self._paper_item_space2+dh))
			end
		end
		self._papers:relayout()
	end
end

function StudentWatch:init_paper_list_by_table( p )
	if p and type(p)=='table' then
		uikits.scrollview_step_add(self._papers._scrollview,p,5,function(v)
			if v then
				if v and v.item_type and v.item_id then
					self:add_paper_item( v.item_type,v.item_id )
				end			
			else
				self:paper_relayout()
			end
		end)
	else
		kits.log('ERROR  StudentWatch:init_paper_list_by_table p=nil')
	end
	self:paper_relayout()
end

function StudentWatch:init()
	if not self._root then
		self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
		self:addChild(self._root)
		--返回按钮
		local back = uikits.child(self._root,ui.BACK)
		uikits.event(back,function(sender)
				cache.request_cancel()
				uikits.popScene()
			end)
		--初始化错题本按钮
		local wrong = uikits.child(self._root,ui.WRONG_BUTTON)
		uikits.event(wrong,function(sender)
			cache.request_cancel()
				if self._args then
					local persubject = require "errortitile/persubject"
					if persubject then
						local scene = persubject.create(self._args.course_name,"",self._args.course_id,1)
						if scene then
							uikits.pushScene( scene )
						end
					end
				end
			--uikits.pushScace()
			end)		
			if login.get_uid_type() == login.PARENT then
				wrong:setVisible(false)	
			end
		--列表视图
		self._papers = uikits.scroll(self._root,ui.LIST,ui.ITEM)
		self._paper_item_space2 = 0;
		self._paper_item_space = 0;
		uikits.enableMouseWheelIFWindows(self._papers)
	end
	self:init_data()
end

function StudentWatch:release()
	uikits.enableMouseWheelIFWindows()
end

return StudentWatch