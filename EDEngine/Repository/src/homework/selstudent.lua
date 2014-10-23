local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local worklist = require "homework/worklist"
local loadingbox = require "loadingbox"
--local selstudent = require "errortitile/selstudent"
--local WrongSubjectList = require "errortitile/WrongSubjectList"
local selstudent = class("selstudent")
selstudent.__index = selstudent

local ui = {
	FILE = 'homework/xuanze.json',
	FILE_3_4 = 'homework/xuanze43.json',
	student_view = '4770',
	per_student_view = '4770/4771',
	student_name = '4773',
	student_checkbox = '4774',
}
local student_space = 40
local get_child_info_url = 'http://api.lejiaolexue.com/rest/user/current/closefriend/child'

function create()
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),selstudent)		
--	cur_layer.childinfo = {}
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

--local cookie_1 = "sc1=D3F1DC81D98457FE8E1085CB4262CAAD5C443773akl%2bNQbvBYOcjHsDK0Fu4kV%2fbgv3ZBi7sFKU19KP5ks0GkvPwGpmMWe%2b8Q6O%2fkT7EuHjkQ%3d%3d"

function selstudent:getdatabyurl()
--[[	local result = kits.http_get(get_child_info_url,login.cookie(),1)
	print(result)
	local tb_result = json.decode(result)
	if 	tb_result.result ~= 0 then				
		print(tb_result.result.." : "..tb_result.message)			
	else
		--local tb_uig = json.decode(tb_result.uig)
		self.childinfo = tb_result.uis
	end	--]]
	local loadbox = loadingbox.open(self)
	cache.request_json( get_child_info_url,function(t)
			if t and type(t)=='table' then
				if t.result ~= 0 then
					loadbox:removeFromParent()
					return false
				else
					self.childinfo = t.uis
					self:show_children()
				end
			else
				--既没有网络也没有缓冲
				messagebox.open(self,function(e)
					if e == messagebox.TRY then
						self:getdatabyurl()
					elseif e == messagebox.CLOSE then
						uikits.popScene()
					end
				end,messagebox.RETRY)	
			end
			loadbox:removeFromParent()
		end,'N')
	return true
	
end

function selstudent:show_children()	
	local student_view = uikits.child(self._widget,ui.student_view)
	local src_student_view = uikits.child(self._widget,ui.per_student_view)
	src_student_view:setVisible(false)
	local size_student_view = student_view:getContentSize()
	local size_per_student_view = src_student_view:getContentSize()
	local all_student_width = (size_per_student_view.width * (#self.childinfo)) + (student_space*(#self.childinfo-1))
	local pos_x_start = (size_student_view.width - all_student_width)/2

    local function selectedEvent(sender,eventType)
		local checkBox = sender
        if eventType == ccui.CheckBoxEventType.selected then
            _G.hw_cur_child_id = checkBox.uid
			local scene_next = worklist.create()								
			cc.Director:getInstance():replaceScene(scene_next)			
        end
    end  

	for i = 1,#self.childinfo do 
		local cur_student_view = src_student_view:clone()
		cur_student_view:setVisible(true)
		student_view:addChild(cur_student_view)
		cur_student_view:setPositionX(pos_x_start)
		local student_name = uikits.child(cur_student_view,ui.student_name)
		local checkBox = uikits.child(cur_student_view,ui.student_checkbox)
		student_name:setString(self.childinfo[i].uname)
		checkBox.uid = self.childinfo[i].uid
		checkBox:addEventListener(selectedEvent)  
		pos_x_start = pos_x_start+size_per_student_view.width+student_space
	end	
end

function selstudent:init()	
--	loadArmature("errortitile/silver/Export/NewAnimation/NewAnimation.ExportJson")	
	self._widget = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
	self:addChild(self._widget)
--	uikits.initDR(design)
	self:getdatabyurl()
end

function selstudent:release()

end
return {
create = create,
}