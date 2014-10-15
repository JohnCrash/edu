local uikits = require "uikits"
local cache = require "cache"
local login = require 'login'
local kits = require "kits"
local json = require "json-c"
local loadingbox = require "loadingbox"
local topics = require "homework/topics"
local TeacherSubjective = require "homework/teachersubjective"

local ui = {
	FILE = 'homework/laoshizuoye/jinruzuoye.json',
	FILE_3_4 = 'homework/laoshizuoye/jinruzuoye43.json',
	FILE_TOPICS_LIST = 'homework/laoshizuoye/keguanti.json',
	FILE_TOPICS_LIST_3_4 = 'homework/laoshizuoye/keguanti43.json',
	FILE_SUBJECTIVE_LIST = 'homework/laoshizuoye/zhuguanti.json',
	FILE_SUBJECTIVE_LIST_3_4 = 'homework/laoshizuoye/zhuguanti43.json',
	FILE_STUDENT_LIST = 'homework/laoshizuoye/xuesheng.json',
	FILE_STUDENT_LIST_3_4 = 'homework/laoshizuoye/xuesheng43.json',	
	BACK = 'ding/back',
	CLASS_NAME = 'ding/banji',
	TOPICS_NAME = 'ding/kewen',
	PAPER_LIST = 'keguan',
	PAPER_ITEM = 'shiti',
	LIST = 'newview',
	ITEM = 'newview/subject1',
	RED_LINE = 'heitiao/redline',
	TAB_BUTTON_1 = 'heitiao/keguan',
	TAB_BUTTON_2 = 'heitiao/zhuguan',
	TAB_BUTTON_3 = 'heitiao/xuesheng',
	TOPICS_VIEW = 'keguan',
	SUBJECTIVE_VIEW = 'zuguan',
	SUBJECTIVE_ITEM = 'zhuguan1',
	SUBJECTIVE_TITLE = 'yaoqiu',
	SUBJECTIVE_COMMITNUM = 'yiti/tijiaoren',
	SUBJECTIVE_AUDIO = 'audio',
	SUBJECTIVE_AUDIO_BUTTON = 'yuyin',
	SUBJECTIVE_AUDIO_TIME = 'shijian',
	SUBJECTIVE_IMAGE = 'zhaopian',
	SUBJECTIVE_BUTTON = 'jinru',
	STUDENT_LIST = 'xuesheng',
	STUDENT_ITEM_TITLE = 'ztxx',
	STUDENT_ITEM = 'xs1',
	HIGH_SCORE = 'keguan/tongji/defen/gaofen',
	LOW_SCORE = 'keguan/tongji/defen/difen',
	AVG_SCORE =  'keguan/tongji/defen/pingfen',
	HIGH_TIME = 'keguan/tongji/yongshi/pingfen',
	LOW_TIME = 'keguan/tongji/yongshi/gaofen',
	AVG_TIME = 'keguan/tongji/yongshi/pingjun',
	COMMIT_LIST = 'keguan/tongji/manfen',
	COMMIT_ITEM = 'xuesheng1',
	COMMIT_NAME = 'mingzhi',
	COMMIT_ICON = 'touxiang',
	STUDENT_NUM = 'renshu',
	STUDENT_APPR = 'zhuangtai',
	STUDENT_NAME = 'mingzhi',
	STUDENT_COMMIT_TIME = 'shijian',
	STUDENT_TOPICS_NUM = 'keguan',
	STUDENT_SUBJECTIVE_NUM = 'zhuguan',
	STUDENT_SCORE = 'defen',
	STUDENT_ICON = 'touxiang',
	TOPICS_TYPE = 'yanse/tixing',
	TOPICS_DIFF = 'yanse/nandu',
	TOPICS_AVG = 'yanse/pingcuolv',
	TOPICS_RATE = 'yanse/benban',
	TOPICS_ITEM = 'ti',
	TOPICS_TITLE = 'yanse',
}

local Batch = class("Batch")
Batch.__index = Batch

function Batch.create(t,c)
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),Batch)
	
	scene:addChild(layer)
	
	local function onNodeEvent(event)
		if "enter" == event then
			layer._args = t --考试参数
			layer._args_class = c --班级参数
			layer:init()
		elseif "exit" == event then
			layer:release()
		end
	end	
	layer:registerScriptHandler(onNodeEvent)
	return scene
end

--和StudentWatch.lua add_paper_item相同
function Batch:add_paper_item( topicType,topicID )
	if topics.types[topicType] then
		self._papers:additem{
			[ui.TOPICS_TYPE] = topics.types[topicType].name,
			[ui.TOPICS_DIFF] = '', --难度
			[ui.TOPICS_AVG] = '', --平均错误率
			[ui.TOPICS_RATE] = function(child,item)
					local u = 'http://new.www.lejiaolexue.com/exam/handler/examstatistic.ashx?q=stu_correct&t_id='
					..self._args.teacher_id..'&exam_id='..self._args.exam_id..'&c_id='..self._args_class.class_id..'&item_id='..topicID
					cache.request_json(u,function(t)
						if t and type(t)=='number' and cc_isobj(child) then
							uikits.set_item(child,tostring(math.floor(100-t))..'%')
						else
							kits.log('WARNING : wrong rate = '..tostring(t))
						end
					end)
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
							data.eventInitComplate = function(layout,data)
								self:paper_relayout()
							end
							child:setEnabled(false) --禁止修改
							--放入正确答案
							if t.correct_answer and type(t.correct_answer)=='string' then
								local asw = json.decode(t.correct_answer)
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
				end)
			end
		}
	end
end

function Batch:init_paper_list_by_table( p )
	local paper_table = {}
	for k,v in pairs(p.part) do
		for i,t in pairs(p.detail) do
			if t.part_id == v.part_id then --属于这部分的
				--self:add_paper_item( t.item_type,t.item_id )
				local item = { item_type = t.item_type,item_id = t.item_id }
				table.insert(paper_table,item)
			end
		end
	end
	uikits.scrollview_step_add( self._papers._scrollview,paper_table,5,function(v)
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

function Batch:init_paper_item_space( item )
	local layout = uikits.child(item,ui.TOPICS_ITEM)
	local title = uikits.child(item,ui.TOPICS_TITLE)
	if layout and title then
		local item_size = item:getContentSize()
		local size = layout:getContentSize()
		local tx,ty = title:getPosition()
		local tsize = title:getContentSize()
		local ox,oy = layout:getPosition()
		self._paper_item_space = item_size.height-ty-tsize.height
		self._paper_item_space2 = ty-oy-size.height
	end
end

function Batch:paper_relayout()
	if self._papers and self._papers._list then
		for k,item in pairs(self._papers._list) do
			local layout = uikits.child(item,ui.TOPICS_ITEM)
			local title = uikits.child(item,ui.TOPICS_TITLE)
			if layout and title then
				local item_size = item:getContentSize()
				local size = layout:getContentSize()
				local tsize = title:getContentSize()
				local ox,oy = layout:getPosition()
				title:setPosition(cc.p(ox,oy+size.height+self._paper_item_space2))
				item:setContentSize(cc.size(item_size.width,
					size.height+tsize.height+self._paper_item_space+self._paper_item_space2))
			end
		end
		self._papers:relayout()
	end
end

function Batch:init_topics_paper_list()
	if self._papers then
		self._papers:clear()
		local url = "http://new.www.lejiaolexue.com/paper/handler/LoadPaperItem.ashx?pid="..
			self._args.paper_id..'&uid='..
			self._args.teacher_id
		local loadbox = loadingbox.open(self)
		cache.request_json( url,function(t)
			if t and type(t)=='table' then
				if kits.check(t,"detail","part" ) then
					self:init_paper_list_by_table( t )
				end
			end
			loadbox:removeFromParent()
		end)
	end
end

function Batch:init_topics_statics(t)
	if self and t then
		uikits.set(self._topics_root,
			{
				[ui.HIGH_SCORE] = math.floor(t.high),
				[ui.LOW_SCORE] = math.floor(t.low),
				[ui.AVG_SCORE] = math.floor(t.avg),
				[ui.HIGH_TIME] = kits.time_to_string_simple(t.high_time,true),
				[ui.LOW_TIME] = kits.time_to_string_simple(t.low_time,true),
				[ui.AVG_TIME] = kits.time_to_string_simple(t.avg_time,true),
			}
		)
	end
end

function Batch:init_commits_list( t )
	local count = 1
	self._commits:clear()
	for k,v in pairs(t) do
		if v.status==10 or v.status==11 then
			self._commits:additem{
				[ui.COMMIT_NAME] =v.student_name,
				[ui.COMMIT_ICON] = function(child,item)
						local url = login.get_logo(v.student_id,3)
						cache.request(url,function(b)
							if b and child then
								child:loadTexture( cache.get_name(url) )
								--uikits.fitsize( child,250,250 )
							end
						end )
					end				
			}
			if count >= 5 then
				break
			end
			count = count + 1
		end
	end
	self._commits:relayout()
end

function Batch:init_topics()
	cache.request_cancel()
	self._topicsview:setVisible(true)
	self._subjectiveview:setVisible(false)
	self._studentview:setVisible(false)
	--请求班级统计成绩
	if not kits.check(self._args_class,'exam_id','class_id','class_name') then
		self._topicsview:setVisible(false)
		kits.log('ERROR Batch:init_topics invalid parameter')
		return
	end
	uikits.set(
		self._root,
		{
			[ui.CLASS_NAME] = self._args_class.class_name,
			[ui.TOPICS_NAME] = self._args.exam_name,
		}
	)
	local loadbox = loadingbox.open(self)
	self._busy = true
	local url = "http://new.www.lejiaolexue.com/exam/handler/ExamStatistic.ashx?q=rank&exam_id="..
	self._args_class.exam_id.."&c_id="..
	self._args_class.class_id.."&has_score=1"
	cache.request_json(url,function(t)
			if not loadbox:removeFromParent() then
				return
			end
			if t and type(t)=='table' then
				table.sort(t,function(a,b)
						return a.real_score < b.real_score
					end)
				self._student_list_table = t
				local high,low,avg = 0,math.huge,0
				local count = 0
				local high_time,low_time,avg_time = 0,math.huge,0
				for k,v in pairs(t) do
					if v.status and (v.status==10 or v.status==11) then
						high = math.max(high,v.real_score)
						low = math.min(low,v.real_score)
						high_time = math.max(high_time,v.time)
						low_time = math.min(low_time,v.time)
						avg_time = avg_time + v.time
						avg = avg + v.real_score
						count = count + 1
					end
				end
				if count > 0 then
					avg = avg/count
					avg_time = avg_time/count
				end
				if low==math.huge then low = 0 end
				if low_time==math.huge then low_time = 0 end
				--开始设置统计
				self:init_topics_statics{
					high = high,low = low,avg=avg,high_time=high_time,low_time=low_time,avg_time=avg_time
				}
				self:init_commits_list( t )
				self:init_topics_paper_list()
			else
				self._topicsview:setVisible(false)
			end
			self._busy =false
		end)
	return true
end

--主观题
function Batch:init_subjective()
	cache.request_cancel()
	self._topicsview:setVisible(false)
	self._subjectiveview:setVisible(true)
	self._studentview:setVisible(false)
	
	self._subjectives:clear()
	local result = kits.read_cache("backup-2/sujective_list.json")
	if result then
		local t = json.decode(result)
		if t then
			local size = nil
			for k,v in pairs(t) do
				local item = self._subjectives:additem{
					[ui.SUBJECTIVE_TITLE] = v.title or '',
					[ui.SUBJECTIVE_COMMITNUM] = tostring(v.commits or 0)..'人',
					[ui.SUBJECTIVE_AUDIO] = function(child,item)
						size = size or child:getContentSize()
						if v.audio and type(v.audio)=='string' and string.len(v.audio) > 0 then
							local play_but = uikits.child(child,ui.SUBJECTIVE_AUDIO_BUTTON)
							local time_txt =  uikits.child(child,ui.SUBJECTIVE_AUDIO_TIME)
							if play_but and time_txt then
								uikits.event(play_but,function(sender)
										uikits.playSound(v.audio)
								end)
							end
						else
							child:setVisible(false)
							--将image向上移动
							local img = uikits.child(item,ui.SUBJECTIVE_IMAGE)
							if img then
								local size = child:getContentSize()
								local x,y = img:getPosition()
								img:setPosition( cc.p(x,y+size.height))
							end
						end
					end,
					[ui.SUBJECTIVE_BUTTON] = function(child,item)
						uikits.event(child,function(sender)
							uikits.pushScene(TeacherSubjective.create())
						end)
					end
				}
				local layout = uikits.scroll(item,nil,ui.SUBJECTIVE_IMAGE,true,16)
				layout:clear()
				if v.image and type(v.image) == 'table' then
					for i,p in pairs(v.image) do
						if p and type(p)=='string' and string.len(p)>0 then
							local it = layout:additem()
							if it then
								it:loadTexture(p)
							end
						end
					end
				end
				layout:relayout()
			end
			self._subjectives:relayout()
		end
	end
	return true
end

local appraise = {
	[1] = {low=90,up=100,title = '优秀'},
	[2] = {low=80,up=90,title = '优'},
	[3] = {low=70,up=80,title = '良'},
	[4] = {low=60,up=70,title = '中'},
	[5] = {low=0,up=60,title = '待提高'},
}
local loadbox_student_list
function Batch:init_student_list_func()
	if self._student_list_table then
		local total_score = self._args.real_score or 100
		if total_score<= 0 then total_score = 1 end
		--没有实现分布加载
		for i,appr in pairs(appraise) do
			local st = {}
			for k,v in pairs(self._student_list_table) do
				local score = v.real_score/total_score
				if score >= appr.low and score < appr.up 
				 and (v.status==10 or v.status==11) then --FIXME:暂时将未提交的加入进去
					table.insert(st,1,v)
				end
			end
			if #st > 0 then
				self._students:additem({
					[ui.STUDENT_NUM] = tostring(#st)..'人',
					[ui.STUDENT_APPR] = appr.title,
				},2)
				for k,v in pairs(st) do
					self._students:additem{
						[ui.STUDENT_NAME] = v.student_name,
						[ui.STUDENT_COMMIT_TIME] = '',
						[ui.STUDENT_TOPICS_NUM] = '',
						[ui.STUDENT_SUBJECTIVE_NUM] = '',
						[ui.STUDENT_SCORE] = tostring(math.floor(v.real_score/total_score))..'分',
						[ui.STUDENT_ICON] = function(child,item)
							local url = login.get_logo(v.student_id,3)
							cache.request(url,function(b)
									if b and child then
										child:loadTexture( cache.get_name(url) )
										--uikits.fitsize( child,300,300 )
									end
								end)
						end
					}
				end
			end --for
		end
		self._students:relayout()
		if loadbox_student_list then
			loadbox_student_list:removeFromParent()
			loadbox_student_list = nil
		end
	end
end

function Batch:init_student_list()
	cache.request_cancel()
	self._topicsview:setVisible(false)
	self._subjectiveview:setVisible(false)
	self._studentview:setVisible(true)
	
	self._students:clear()
	loadbox_student_list = loadingbox.open(self)
	uikits.delay_call(self._studentview,self.init_student_list_func,0,self)
	return true
end

function Batch:init_gui()
	self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
	self:addChild(self._root)
	local back = uikits.child(self._root,ui.BACK)
	uikits.event(back,function(sender)
		cache.request_cancel()
		uikits.popScene()
	end)
	--初始化标签
	self._tab = uikits.tab(self._root,ui.RED_LINE,{
		[ui.TAB_BUTTON_1] = function(sender) return self:init_topics() end,
		[ui.TAB_BUTTON_2] = function(sender) return self:init_subjective() end,
		[ui.TAB_BUTTON_3] = function(sender) return self:init_student_list() end,
	})
	--初始化可观题列表
	self._topics_root = uikits.fromJson{file_9_16=ui.FILE_TOPICS_LIST,file_3_4=ui.FILE_TOPICS_LIST_3_4}
	self._topicsview = uikits.child(self._topics_root,ui.TOPICS_VIEW)
	self._commits = uikits.scroll(self._topics_root,ui.COMMIT_LIST,ui.COMMIT_ITEM,true)
	self._papers = uikits.scroll(self._topics_root,ui.PAPER_LIST,ui.PAPER_ITEM)
	self:init_paper_item_space( uikits.child(self._topicsview,ui.PAPER_ITEM))
	self:addChild(self._topics_root)
	--初始化主观题列表
	self._subjective_root = uikits.fromJson{file_9_16=ui.FILE_SUBJECTIVE_LIST,file_3_4=ui.FILE_SUBJECTIVE_LIST_3_4}
	self._subjectiveview = uikits.child(self._subjective_root,ui.SUBJECTIVE_VIEW)
	self._subjectives = uikits.scroll(self._subjective_root,ui.SUBJECTIVE_VIEW,ui.SUBJECTIVE_ITEM)
	
	self:addChild(self._subjective_root)	
	self._subjectiveview:setVisible(false)
	--学生列表
	self._student_root = uikits.fromJson{file_9_16=ui.FILE_STUDENT_LIST,file_3_4=ui.FILE_STUDENT_LIST_3_4}
	self._studentview = uikits.child(self._student_root,ui.STUDENT_LIST)
	self._students = uikits.scroll(self._student_root,ui.STUDENT_LIST,ui.STUDENT_ITEM,false,0,ui.STUDENT_ITEM_TITLE)
	self:addChild(self._student_root)	
	self._studentview:setVisible(false)
	
	self:init_topics()
end

function Batch:init()
	if not self._root then
		self:init_gui()
	end
end

function Batch:release()
	
end

return Batch