﻿local uikits = require "uikits"
local cache = require "cache"
local login = require 'login'
local kits = require "kits"
local json = require "json-c"
local loadingbox = require "homework/loadingbox"
local topics = require "homework/topics"

local ui = {
	FILE = 'laoshizuoye/jinruzuoye.json',
	FILE_3_4 = 'laoshizuoye/jinruzuoye43.json',
	FILE_TOPICS_LIST = 'laoshizuoye/keguanti.json',
	FILE_TOPICS_LIST_3_4 = 'laoshizuoye/keguanti43.json',
	FILE_SUBJECTIVE_LIST = 'laoshizuoye/zhuguanti.json',
	FILE_SUBJECTIVE_LIST_3_4 = 'laoshizuoye/zhuguanti43.json',
	FILE_STUDENT_LIST = 'laoshizuoye/xuesheng.json',
	FILE_STUDENT_LIST_3_4 = 'laoshizuoye/xuesheng43.json',	
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
	TOPICS_ITEM = 'yanse/ti',
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

function Batch:add_paper_item( topicType,topicID )
	if topics.types[topicType] then
		self._papers:additem{
			[ui.TOPICS_TYPE] = topics.types[topicType].name,
			[ui.TOPICS_DIFF] = '', --难度
			[ui.TOPICS_AVG] = '', --平均错误率
			[ui.TOPICS_RATE] = '', --班错误率
		}
	end
end

function Batch:init_paper_list_by_table( p )
	for k,v in pairs(p.part) do
		for i,t in pairs(p.detail) do
			if t.part_id == v.part_id then --属于这部分的
				self:add_paper_item( t.item_type,t.item_id )
			end
		end
	end
	self._papers:relayout()
end

function Batch:init_topics_paper_list()
	if self._papers then
		self._papers:clear()
		local loadbox = loadingbox.open(self)
		
		local url = "http://new.www.lejiaolexue.com/paper/handler/LoadPaperItem.ashx?pid="..
			self._args.paper_id..'&uid='..
			self._args.teacher_id
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
				[ui.HIGH_TIME] = kits.time_to_string(t.high_time,true),
				[ui.LOW_TIME] = kits.time_to_string(t.low_time,true),
				[ui.AVG_TIME] = kits.time_to_string(t.avg_time,true),
			}
		)
	end
end

function Batch:init_commits_list( t )
	local count = 1
	self._commits:clear()
	for k,v in pairs(t) do
		if v.status==10 or v.status==11 or v.status == 0 then
			self._commits:additem{
				[ui.COMMIT_NAME] =v.student_name..'('..v.real_score..')',
				[ui.COMMIT_ICON] = function(child,item)
						local url = login.get_logo(v.student_id,3)
						cache.request(url,function(b)
							if b and child then
								child:loadTexture( cache.get_name(url) )
								uikits.fitsize( child,250,250 )
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
			loadbox:removeFromParent()
		end)
	return true
end

function Batch:init_subjective()
	cache.request_cancel()
	self._topicsview:setVisible(false)
	self._subjectiveview:setVisible(true)
	self._studentview:setVisible(false)
	return true
end

local appraise = {
	{low=90,up=100,title = '优秀'},
	{low=80,up=90,title = '优'},
	{low=70,up=80,title = '良'},
	{low=60,up=70,title = '中'},
	{low=0,up=60,title = '待提高'},
}

function Batch:init_student_list()
	cache.request_cancel()
	self._topicsview:setVisible(false)
	self._subjectiveview:setVisible(false)
	self._studentview:setVisible(true)
	
	self._students:clear()
	if self._student_list_table then
		local total_score = self._args.real_score or 100
		if total_score<= 0 then total_score = 1 end
		for i,appr in pairs(appraise) do
			local st = {}
			for k,v in pairs(self._student_list_table) do
				local score = v.real_score/total_score
				if score >= appr.low and score < appr.up then
				-- and (v.status==10 or v.status==11) then --FIXME:暂时将未提交的加入进去
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
										uikits.fitsize( child,300,300 )
									end
								end)
						end
					}
				end
				self._students:relayout()
			end
		end
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
	self:addChild(self._topics_root)
	--初始化主观题列表
	self._subjective_root = uikits.fromJson{file_9_16=ui.FILE_SUBJECTIVE_LIST,file_3_4=ui.FILE_SUBJECTIVE_LIST_3_4}
	self._subjectiveview = uikits.child(self._subjective_root,ui.SUBJECTIVE_VIEW)
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