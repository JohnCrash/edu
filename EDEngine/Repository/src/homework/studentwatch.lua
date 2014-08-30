local uikits = require "uikits"
local cache = require "cache"
local kits = require "kits"
local topics = require "homework/topics"
local loadingbox = require "homework/loadingbox"
local json = require "json-c"

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
		uikits.set(self._root,{
			[ui.CAPTION] = self._args.caption or "",
			[ui.OBJECTIVE_RATE] = self._args.cnt_item_finish.."/"..self._args.cnt_item,
			[ui.OBJECTIVE_TIME] = kits.time_to_string(self._args.total_time),
			[ui.OBJECTIVE_FEN] = (self._args.real_score or "0").."分",
		})
		
		self:init_paper_list_by_table(self._args._exam_table)
	else
		kits.log('ERROR StudentWatch:init_data invalid arguments')
	end
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
				
				local loadbox = loadingbox.circle(child)
				cache.request_json(url,function(t)
					loadbox:removeFromParent()
					if t then
						local data = {}
						if t.buffer and t.buffer.difficulty_name then
							uikits.set(item,
							{
								[ui.ITEM_DIFFICULTY] = t.buffer.difficulty_name,
								[ui.ITEM_WRONG_RATE] = "0%"
							})
						end
						if t.detail and t.detail.isright then
							if  t.detail.isright ~= 0 then
								uikits.child(item,ui.ITEM_WRONG):setVisible(false)
								uikits.child(item,ui.ITEM_RIGHT):setVisible(true)
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
								self:paper_relayout()
							end
							child:setEnabled(false) --禁止修改
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
									print("ANSWER:"..data.my_answer[1] )
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
				title:setPosition(cc.p(ox,oy+size.height+6))
				item:setContentSize(cc.size(item_size.width,
					size.height+tsize.height+6))
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
						local scene = persubject:create(self._args.course_name,"",self._args.course_id,1)
						if scene then
							uikits.pushScene( scene )
						end
					end
				end
			--uikits.pushScace()
			end)		
		--列表视图
		self._papers = uikits.scroll(self._root,ui.LIST,ui.ITEM)
	end
	self:init_data()
end

function StudentWatch:release()
	
end

return StudentWatch