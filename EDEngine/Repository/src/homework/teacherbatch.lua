local uikits = require "uikits"
local cache = require "cache"
local login = require 'login'
local kits = require "kits"
local json = require "json-c"
local loadingbox = require "loadingbox"
local topics = require "homework/topics"
local imagepreview = require "homework/imagepreview"
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
	TIPS = "heitiao/tips",
	TIPS_TEXT = "text",
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
	SUBJECTIVE_IMAGE = 'clip',
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
	self._objective_num = 0
	self._subject_num = 0
	for k,v in pairs(p.part) do
		for i,t in pairs(p.detail) do
			if t.part_id == v.part_id then --属于这部分的
				--self:add_paper_item( t.item_type,t.item_id )
				local item = { item_type = t.item_type,item_id = t.item_id }
				table.insert(paper_table,item)
				if t.item_type == 93 then
					self._objective_num = self._objective_num + 1
				elseif topics.types[t.item_type] then
					self._subject_num = self._subject_num + 1
				end
			end
		end
	end
	
	self:tips(1)
	if self._subject_num == 0 then return end
	
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
				self._exam_data = t
				if kits.check(t,"detail","part" ) then
					self:init_paper_list_by_table( t )
				end
			else
				self._exam_data = "error"
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
						login.get_logo(v.student_id,function(filename)
							if filename and child then
								child:loadTexture( filename )
								--uikits.fitsize( child,250,250 )
							end
						end,3 )
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

function Batch:load_topics()
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
end

function Batch:init_topics()
	if self._busy then return end
	
	cache.request_cancel()
	self._topicsview:setVisible(true)
	self._subjectiveview:setVisible(false)
	self._studentview:setVisible(false)
	
	self:tips(1)
	if self._init_topics_done then
	else
		self._init_topics_done = true
		self:load_topics()
	end
	return true
end

function Batch:tips(t)
	if t == 1 then
		if self._subject_num == 0 then
			self._tips:setVisible(true)
			self._tips_text:setString("没有客观题")	
		else
			self._tips:setVisible(false)
		end
	elseif t== 2 then
		if self._objective_num == 0 then
			self._tips:setVisible(true)
			self._tips_text:setString("没有主观题")		
		else
			self._tips:setVisible(false)
		end
	elseif t==3 then
		if self._statuents_num == 0 then
			self._tips:setVisible(true)
			self._tips_text:setString("还没有学生提交")				
		else
			self._tips:setVisible(false)
		end
	end
end

function Batch:load_clip_texture(item,filename)
	if kits.exist_cache(filename) or kits.exist_file(filename) then
		item:loadTexture(filename)
		local size = item:getContentSize()
		local scale
		if size.width > size.height then
			scale = 256/size.height
		else
			scale = 256/size.width
		end
		item:setScaleX(scale)
		item:setScaleY(scale)
		uikits.event( item,function(sender)
			
		end,"click")
	end
end

function Batch:load_subjective()
	self._busy = true
	self._subjectives:clear()
	if self._exam_data == 'error' then 
		kits.log("INFO : exam data download error")
		return 
	end
	local ds
	if self._exam_data.item and type(self._exam_data.item)=='table' then
		ds = self._exam_data.item
	else
		ds = self._exam_data
	end	
	local t = {}
	local rtable = {}
	rtable.urls = {}
	for i,v in ipairs(ds) do
		if v.item_type == 93 then
			local p = {}
			p.title = v.content
			p.commits = self._args.commit_num
			p.itemid = v.item_id
			p.attachs = {}
			if v.attachment then
				local atts = json.decode(v.attachment)
				if atts and atts.attachments then
					for i,v in pairs(atts.attachments) do
						if v.value then
							table.insert(rtable.urls,{url=v.value,filename=v.name})
							table.insert(p.attachs,{url=v.value,filename=v.name})
						end
					end
				end
			end
			table.insert(t,1,p)
		end
	end
	local function init_subjective_by_table( t )
		local size = nil
		for k,v in pairs(t) do
			local item = self._subjectives:additem{
				[ui.SUBJECTIVE_TITLE] = v.title or '',
				[ui.SUBJECTIVE_COMMITNUM] = tostring(v.commits or 0)..'人',
				[ui.SUBJECTIVE_BUTTON] = function(child,item)
					uikits.event(child,function(sender)
						uikits.pushScene(TeacherSubjective.create(self._args,self._args_class,self._student_list_table,v.itemid))
					end)
				end
			}
			local layout = uikits.scroll(item,nil,ui.SUBJECTIVE_IMAGE,'mix',16,ui.SUBJECTIVE_AUDIO)
			layout:clear()
			if v.attachs and type(v.attachs) == 'table' then
				local imgs = {}
				for i,p in pairs(v.attachs) do
					if p and type(p)=='table' and p.filename then
						local suffix = string.lower(string.sub(p.filename,-4))
						if suffix == '.jpg' or suffix == '.png' or suffix == '.gif' then
							local it = layout:additem()
							local img = uikits.child(it,'tu1')
							self:load_clip_texture( img,p.filename)
							table.insert(imgs,1,p.filename)
							img:setTouchEnabled(true)
							uikits.event( img,function(sender)
								for i,v in pairs(imgs) do
									if v == p.filename then
										uikits.pushScene( imagepreview.create(i,imgs) )
										break
									end
								end
							end,"click")
						elseif suffix == '.amr' then
							local it = layout:additem(nil,2)
							local filename = kits.get_cache_path()..p.filename
							if it then
								local play = uikits.child(it,ui.SUBJECTIVE_AUDIO_BUTTON)
								local txt = uikits.child(it,ui.SUBJECTIVE_AUDIO_TIME)
								uikits.event(play,function(sender)
									uikits.playSound( filename )
								end)
								local length = uikits.voiceLength( filename )
								txt:setString( kits.time_to_string_simple(math.floor(length)) )
							end
						end
					end
				end
			end
			layout:relayout()
		end
		self._subjectives:relayout()
	end
	local n = 0
	local loadbox = loadingbox.open(self)
	cache.request_resources( rtable,
		function(rs,i,b)
			n = n + 1
			if b and rs.urls[i] then
				kits.log('download -> '..rs.urls[i].url )
				kits.log('cahce ->' ..rs.urls[i].filename)
				kits.log('file is '..tostring(kits.exist_cache(rs.urls[i].filename )))
			end
			if n >= #rs.urls then --complete
				self._busy = false
				if not loadbox:removeFromParent() then
					return
				end
				init_subjective_by_table( t )
			end
		end)
end

--主观题
function Batch:init_subjective()
	if self._busy then return end
	
	if not self._exam_data then 
		kits.log("INFO : wait paper data download complete")
		return 
	end
	cache.request_cancel()
	self._topicsview:setVisible(false)
	self._subjectiveview:setVisible(true)
	self._studentview:setVisible(false)
	
	self:tips(2)
	if self._init_subjective_done then
	else
		self._init_subjective_done = true
		self:load_subjective()
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
		self._statuents_num = 0
		local total_score = self._args.real_score or 100
		if total_score<= 0 then total_score = 1 end
		--没有实现分布加载
		for i,appr in pairs(appraise) do
			local st = {}
			for k,v in pairs(self._student_list_table) do
				local score = v.real_score/total_score
				if score >= appr.low and score < appr.up 
				 and (v.status==10 or v.status==11) then --FIXME:暂时将未提交的加入进去
					self._statuents_num = self._statuents_num + 1
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
								login.get_logo(v.student_id,function(filename)
									if filename and child then
										child:loadTexture( filename )
										--uikits.fitsize( child,300,300 )
									end
								end,3)
						end
					}
				end
			end --for
		end
		self:tips(3)
		self._students:relayout()
		if loadbox_student_list then
			loadbox_student_list:removeFromParent()
			loadbox_student_list = nil
		end
	end
end

function Batch:load_student_list()
	self._students:clear()
	loadbox_student_list = loadingbox.open(self)
	uikits.delay_call(self._studentview,self.init_student_list_func,0,self)
end

function Batch:init_student_list()
	if self._busy then return end
	cache.request_cancel()
	self._topicsview:setVisible(false)
	self._subjectiveview:setVisible(false)
	self._studentview:setVisible(true)
	
	self:tips(3)
	if self._init_student_done then
	else
		self._init_student_done = true
		self:load_student_list()
	end
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
	self._tips = uikits.child(self._root,ui.TIPS)
	self._tips_text = uikits.child(self._tips,ui.TIPS_TEXT)
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
	self:addChild(self._topics_root,100)
	self._papers:refresh(function(state)
		self:load_topics()
	end)
	--初始化主观题列表
	self._subjective_root = uikits.fromJson{file_9_16=ui.FILE_SUBJECTIVE_LIST,file_3_4=ui.FILE_SUBJECTIVE_LIST_3_4}
	self._subjectiveview = uikits.child(self._subjective_root,ui.SUBJECTIVE_VIEW)
	self._subjectives = uikits.scroll(self._subjective_root,ui.SUBJECTIVE_VIEW,ui.SUBJECTIVE_ITEM)
	self._subjectives:refresh(function(state)
		self:load_subjective()
	end)
	
	self:addChild(self._subjective_root)	
	self._subjectiveview:setVisible(false)
	--学生列表
	self._student_root = uikits.fromJson{file_9_16=ui.FILE_STUDENT_LIST,file_3_4=ui.FILE_STUDENT_LIST_3_4}
	self._studentview = uikits.child(self._student_root,ui.STUDENT_LIST)
	self._students = uikits.scroll(self._student_root,ui.STUDENT_LIST,ui.STUDENT_ITEM,false,0,ui.STUDENT_ITEM_TITLE)
	self._students:refresh(function(state)
		self:load_student_list()
	end)
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