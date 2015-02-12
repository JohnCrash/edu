local uikits = require "uikits"
local cache = require "cache"
local login = require 'login'
local kits = require "kits"
local json = require "json-c"
local loadingbox = require "loadingbox"
local topics = require "homework/topics"

local ui = {
	FILE = 'homework/laoshizuoye/xueshengkeguanti.json',
	FILE_3_4 = 'homework/laoshizuoye/xueshengkeguanti43.json',
	BACK = 'ding/back',
	LIST = 'newview',
	ITEM = 'newview/subject1',
	TITLE = 'ding/mz',
	PAPER_LIST = 'fan',
	PAPER_ITEM = 'shiti',	
	TOPICS_TYPE = 'yanse/tixing',
	TOPICS_DIFF = 'yanse/nandu',
	TOPICS_AVG = 'yanse/pingcuolv',
	TOPICS_RATE = 'yanse/benban',
	TOPICS_ITEM = 'ti',
	TOPICS_TITLE = 'yanse',	
	TOPICS_ANSWER_SELECT = 'xuanz',
	TOPICS_ANSWER_SELECT_A = 'xuanxiang',
	TOPICS_ANSWER_EDIT = 'tiankong',
	TOPICS_ANSWER_EDIT_ITEM1 = 'tk1',
	TOPICS_ANSWER_EDIT_ITEM2 = 'tk2',
	TOPICS_ANSWER_EDIT_ITEM3 = 'tk3',
	TOPICS_ANSWER_JUDGE = 'panduan',	
	TOPICS_ANSWER_RIGHT = 'yanse/dui',
	TOPICS_ANSWER_WRONG = 'yanse/cuo',
}

local TeacherWorkView = class("TeacherWorkView")
TeacherWorkView.__index = TeacherWorkView

function TeacherWorkView.create(t)
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),TeacherWorkView)
	
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

function TeacherWorkView:add_paper_item( topicType,topicID )
	if topics.types[topicType] then
		self._papers:additem{
			[ui.TOPICS_TYPE] = topics.types[topicType].name,
			[ui.TOPICS_DIFF] = '', --难度
			[ui.TOPICS_AVG] = '', --平均错误率
			[ui.TOPICS_RATE] = function(child,item)
					local u = 'http://new.www.lejiaolexue.com/exam/handler/examstatistic.ashx?q=stu_correct&t_id='
					..self._args.teacher_id..'&exam_id='..self._args.exam_id..'&c_id='..self._args.class_id..'&item_id='..topicID
					cache.request_json(u,function(t)
						if t and type(t)=='number' and cc_isobj(child) then
							uikits.set_item(child,tostring(math.floor(100-t))..'%')
						else
							kits.log('WARNING : wrong rate = '..tostring(t))
						end
					end,"CN")
				end, --班错误率
			[ui.TOPICS_ITEM] = function(child,item)
				--topics.types[topicType].canv(s,e)
				--topics.types[topicType].init(child,e)
				local size = child:getContentSize()
				size.height = size.height/2
				child:setContentSize(size)
				
				local url = "http://new.www.lejiaolexue.com/exam/handler/ExamStructure.ashx?q=item&exam_id="..
				self._args.exam_id.."&item_id="..
				topicID
				local loadbox = loadingbox.circle(child)
				cache.request_json(url,function(t)
					--t是题面
					local answer_url = "http://new.www.lejiaolexue.com/exam/handler/ClassGroup.ashx?q=s&exam_id="..
					self._args.exam_id.."&item_id="..
					topicID.."&c_id="..
					self._args.class_id.."&s_id="..
					self._args.uid.."&t_id="..
					self._args.teacher_id
					cache.request_json(answer_url,function(a)
						--a学生答案
						if loadbox and cc_isobj(loadbox) then
							loadbox:removeFromParent()
						else
							return
						end
						if t then
							local data = {}
							if t.difficulty_name then
								uikits.set(item,
								{
									[ui.TOPICS_DIFF] = t.difficulty_name
								})
							end
							if topics.types[topicType].conv(t,data) then
								--标示对错
								local right = uikits.child(item,ui.TOPICS_ANSWER_RIGHT)
								local wrong = uikits.child(item,ui.TOPICS_ANSWER_WRONG)
								if a.isright ~= 0 then
									right:setVisible(true)
									wrong:setVisible(false)
								else
									right:setVisible(false)
									wrong:setVisible(true)								
								end
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
								--放入正确答案
								if a.answer and type(a.answer)=='string' then
									local asw = json.decode(a.answer)
									if asw and asw.answers and type(asw.answers)=='table'  then
										data.my_answer = {}
										for i,v in pairs(asw.answers) do
											data.my_answer[i] = v.value
										end
									end
								end
								topics.types[topicType].init(child,data)
							else
								kits.log('')
							end
						end
					end) --cache_json
				end,"CN") --cache_json
			end
		}
	end
end

function TeacherWorkView:paper_relayout()
	if self._papers and self._papers._list then
		self._paper_item_space = 0
		self._paper_item_space2 = 0
		for k,item in pairs(self._papers._list) do
			local layout = uikits.child(item,ui.TOPICS_ITEM)
			local title = uikits.child(item,ui.TOPICS_TITLE)
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

function TeacherWorkView:load_topics()
	local paper_table = self._args.exam
	self._papers:clear()
	uikits.scrollview_step_add( self._papers,paper_table,5,function(v)
		if v then
			if v.item_type and v.item_id then
				self:add_paper_item( v.item_type,v.item_id )
			end
		else
			self:paper_relayout()
		end
	end)
	self:paper_relayout()	
end

function TeacherWorkView:init()
	if not self._root then
		self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
		self:addChild(self._root)
		local back = uikits.child(self._root,ui.BACK)
		uikits.event(back,function(sender)
			uikits.popScene()
		end)
		local title = uikits.child(self._root,ui.TITLE)
		title:setString(self._args.name)
		
		self._papers = uikits.scroll(self._root,ui.PAPER_LIST,ui.PAPER_ITEM)
		self._papers:refresh(function(state)
			self:load_topics()
		end)		
		self:load_topics()
	end
end

function TeacherWorkView:release()
	
end

return TeacherWorkView