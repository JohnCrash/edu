local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"
local login = require "login"
local loadingbox = require "loadingbox"
local StudentList = require "homework/studentlist"

local ui = {
	FILE = 'homework/laoshizuoye/jinruzgt.json',
	FILE_3_4 = 'homework/laoshizuoye/jinruzgt43.json',
	BACK = 'ding/back',
	LIST = 'newview',
	ITEM = 'newview/subject1',
	STUDENT_LIST_BUTTON = 'ding/liebiao',
	SUBJECTIVE_LIST = 'gundong',
	SUBJECTIVE_ITEM = 'xuesheng1',
	TITLE = 'ding/kewen',
	CLASS = 'ding/banji',
	ITEM_LOGO = 'touxiang',
	ITEM_NAME = 'mingzhi',
	ITEM_TIME = 'tijiaoshijian',
	ITEM_ANSWER = 'xswenzi',
	ITEM_VOICE = 'voice',
	ITEM_AUDIO = 'yuyin',
	ITEM_AUDIO_TIME = 'shijian',
	ITEM_IMAGE = 'xszp',
	ITEM_GOOD = 'zan',
	ITEM_DIAPING = 'dianping',
	ITEM_INPUT = 'dianping/dpwenzi',
}

local TeacherSubjective = class("TeacherSubjective")
TeacherSubjective.__index = TeacherSubjective

function TeacherSubjective.create(args,class_args,student_list,item_id)
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),TeacherSubjective)
	
	scene:addChild(layer)
	layer._args = args
	layer._args_class = class_args
	layer._student_list_table = student_list
	layer._item_id = item_id
	local function onNodeEvent(event)
		if "enter" == event then
			layer:init()
		elseif "exit" == event then
			layer:release()
		end
	end	
	layer:registerScriptHandler(onNodeEvent)
	return scene
end

function TeacherSubjective:init_student_list()
	local examId = self._args.exam_id
	local itemId = self._item_id
	local teacherId = self._args.teacher_id
	local ldt = {}
	for k,v in pairs(self._student_list_table) do
		local url = "http://new.www.lejiaolexue.com/student/handler/WorkItem.ashx?examId="
			..examId
			.."&itemId="..itemId
			.."&teacherId="..teacherId
			.."&uid="..v.student_id
		if v.status == 10 or v.status == 11 then
			table.insert(ldt,{url=url,uid=v.student_id,name=v.student_name,finish_time=v.finish_time})
		end
	end
	uikits.scrollview_step_add(self._subjectives._scrollview,ldt,5,
		function(v)
			if v then
				local layout = self._subjectives:additem()
				layout.student_id = v.uid
				local scrollview = uikits.scrollex(layout,nil,{ui.ITEM_VOICE,ui.ITEM_IMAGE},
					{ui.ITEM_ANSWER,ui.ITEM_LOGO,ui.ITEM_NAME,ui.ITEM_TIME,ui.ITEM_GOOD},
					{ui.ITEM_DIAPING})
				local name = uikits.child(layout,ui.ITEM_NAME)
				if name then
					name:setString( v.name )
				end
				local tim = uikits.child(layout,ui.ITEM_TIME)
				if tim and v.finish_time then
					local ft = kits.unix_date_by_string(v.finish_time)
					tim:setString( kits.time_abs_string(ft) )
				end
				local logo = uikits.child(layout,ui.ITEM_LOGO)
				if logo then
					login.get_logo(v.uid,function(filename)
							if filename then
								logo:loadTexture( filename )
							end
						end,3)
				end
				local answer_item = uikits.child(layout,ui.ITEM_ANSWER)
				answer_item:setString('')
				local good = uikits.child(layout,ui.ITEM_GOOD)
				if good then
					uikits.event( good,function(sender)
							
						end)
				end
				local input = uikits.child(layout,ui.ITEM_INPUT)
				if input then
					input:setPlaceHolder("请在此输入点评!")
				end
				local circle = loadingbox.circle(layout)
				cache.request_json( v.url,function(t)
						if cc_isobj(circle) then
							circle:removeFromParent()
						end
						if t and t.detail then
							local answer = t.detail
							local p = {}
							if answer.answer and string.len(answer.answer) > 0 then
								local t = json.decode(answer.answer)
								if t and type(t)=='table' and t.answers and type(t.answers)=='table' then
									if t.answers[1] then
										answer_item:setString(tostring( t.answers[1].content))
									end
								end
							end
							--点评
							local old = answer.comment or ''
							input:setText( old )
							layout.old_comment = old
							--准备下载附件
							local rsts = {}
							rsts.urls = {}							
							local attachments = {}
							if answer.val_attach and string.len(answer.val_attach) > 0 then
								local attach = json.decode(answer.val_attach)
								if attach and attach.attachments then
									for k,v in pairs(attach.attachments) do
										if v.value and v.name then
											table.insert(attachments,{filename=v.name,url=v.value})
											table.insert(rsts.urls,{url=v.value,filename=v.name})
										else
											kits.log("ERROR attachments value = nil or name = nil")
										end
									end
								end								
							end
							local circle = loadingbox.circle(layout)
							local n = 0
							local r,msg = cache.request_resources( rsts,function(rs,i,b)
									n = n + 1
									if n >= #rs.urls then
										if cc_isobj(circle) then
											circle:removeFromParent()
										end
										--附加都下载了
										for i,v in pairs(attachments) do
											if v.filename then
												local suffix = string.lower(string.sub(v.filename,-4))
												if suffix == '.jpg' or suffix == '.png' or suffix == '.gif' then
													local img = scrollview:additem(2)
													img:loadTexture( v.filename )
												elseif suffix == '.amr' then
													local voice = scrollview:additem(1)
													uikits.event( uikits.child(voice,ui.ITEM_AUDIO),
													function(sender)
														uikits.playSound(v.filename)
													end)
													local length = cc_getVoiceLength(filename)
													uikits.child(voice,ui.ITEM_AUDIO_TIME):setString(  kits.time_to_string_simple(math.floor(length)) )
												end
											end
										end
										scrollview:relayout()
										self._subjectives:relayout()
									end
								end)
						else
							--下载失败
							answer_item:setString("下载失败")
						end
					end)
			else
				self._subjectives:relayout()
			end
		end)
end

function TeacherSubjective:commit_comment( done_func ) --提交点评
	local count = 0
	local n = 0
	local urls = {}
	local loadbox = loadingbox.open(self)
	for i,layout in pairs(self._subjectives._list) do
		local input = uikits.child(layout,ui.ITEM_INPUT)
		if input then
			local text = input:getStringValue()
			if text ~= old_comment then
				local url = "http://new.www.lejiaolexue.com/exam/handler/examhandler.ashx?action=pigai&exam_id="
				..self._args.exam_id
				.."&c_id="..self._args_class.class_id
				.."&student_id="..layout.student_id
				.."&item_id="..self._item_id
				.."&score=-1&comment="..tostring(text)
				.."&isright=-1"
				count = count + 1
				table.insert(urls,url)
			end
		end
	end
	for i,url in pairs(urls) do
		cache.request(url,function(b)
			n = n + 1
			if n >= count then
				if not loadbox:removeFromParent() then
					return
				end
				done_func()
			end
		end)
	end
	if count <= 0 then
		done_func()
	end
end

function TeacherSubjective:init_gui()
	self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
	self:addChild(self._root)
	local back = uikits.child(self._root,ui.BACK)
	uikits.event(back,function(sender)
		self:commit_comment(function()
			uikits.popScene()
		end)
	end)	
	local student_but = uikits.child(self._root,ui.STUDENT_LIST_BUTTON)
	uikits.event(student_but,function(sender)
			uikits.pushScene(StudentList.create())
		end)
	
	self._subjectives = uikits.scroll(self._root,ui.SUBJECTIVE_LIST,ui.SUBJECTIVE_ITEM)
	
	self:init_student_list()
	
	local result = kits.read_cache("sujective_work.json")
	if result then
		local t = json.decode(result)
		if t then
			for k,v in pairs(t) do
				local item = self._subjectives:additem{
					[ui.ITEM_NAME] = v.name or '',
					[ui.ITEM_TIME] = v.time or '',
					[ui.ITEM_ANSWER] = v.answer or '',
					[ui.ITEM_AUDIO] = function(child,item)
						if v.audio and type(v.audio)=='string' and string.len(v.audio) > 0 then
							uikits.event(child,function(sender)
								uikits.playSound(v.audio)
							end)
						else
							child:setVisible(false)
						end
					end
				}
				local layout = uikits.scroll(item,nil,ui.ITEM_IMAGE,true,16)
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
end

function TeacherSubjective:init()
	if not self._root then
		self:init_gui()
	end
end

function TeacherSubjective:release()
	
end

return TeacherSubjective