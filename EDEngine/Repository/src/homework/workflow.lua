local uikits = require "uikits"

print( "Hello World!" )
print( "====================" )
local res_root = 'homework/z21_1/'
local ui = {
	FILE = res_root..'z21_1.json',
	BACK = 'milk_write/back',
	LIST = 'milk_write/state_view',
	PAGE_VIEW = 'questions_view',
	NEXT_BUTTON = 'milk_write/next_problem',
	ITEM_CURRENT = 'state_past',
	ITEM_FINISHED = 'state_now',
	ITEM_UNFINISHED = 'state_future',
	ITEM_NUM = 'number',
	STATE_CURRENT = 1,
	STATE_FINISHED = 2,
	STATE_UNFINISHED = 3,
	ANSWER_FIELD = 'milk_side',
	TYPE_IMG = 'item',
	OPTION_A = 'option_a',
	OPTION_B = 'option_b',
	OPTION_C = 'option_c',
	OPTION_D = 'option_d',
	OPTION_E = 'option_e',
	OPTION_F = 'option_f',
	OPTION_G = 'option_g',
	OPTION_H = 'option_h',
	OPTION_YES = 'option_right',
	OPTION_NO = 'option_wrong',
	OPTION_NO_SUPPORT = 'option_not',
	EDIT_1 = 'option_write_1',
	EDIT_2 = 'option_write_2',
	EDIT_3 = 'option_write_3',
	EDIT_4 = 'option_write_4',
	LINK_TEXT = 'option_connection',
	DRAG_TEXT = 'option_drag',
	POSITION_TEXT = 'option_position',
	POSITION_SORT = 'option_sort',
	ANSWER_TEXT = 'answer_text',
}

--[[
item
{
	image,
	isload, --图片已经存在
	item_type, --题型
	isdone,
}
--]]
local WorkFlow = class("WorkFlow")
WorkFlow.__index = WorkFlow

function WorkFlow.create()
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),WorkFlow)
	
	scene:addChild(layer)
	
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

function WorkFlow:init_data()
	self._data = self:load_original_data( "job1.json" )
end

--[[
	将原数据转换为我定义的数据
--]]
WorkFlow._type_convs=
{
	[1] = {name='判断',
				conv=function(s,e)
					return true
				end
			},
	[2] = {name='单选',
				conv=function(s,e)
					local op = kits.decode_json( s.options )
					if op and op.options and type(op.options)=='table' then
						e.options = #op.options --取得选择题个数
					else
						return false
					end
					return true
				end
			},
	[3] = {name='多选',
				conv=function(s,e)
					local op = kits.decode_json( s.options )
					if op and op.options and type(op.options)=='table' then
						e.options = #op.options --取得选择题个数
					else
						return false
					end
					return true
				end
			},
	[4] = {name='连线',
				conv=function(s,e)
					return true
				end
			},	
	[5] = {name='填空',
				conv=function(s,e)
					local ca = kits.decode_json( s.correct_answer )
					if ca and ca.answers and type(ca.answers)=='table' then
						e.options = #ca.answers --多少个空
					end
					return true
				end	
			},
	[7] = {name='横排序',
				conv=function(s,e)
					return true
				end	
			},
	[8] = {name='竖排序',
				conv=function(s,e)
					return true
				end		
			},
	[9] = {name='点图单选',
				conv=function(s,e)
					return true
				end		
			},
	[10] = {name='点图多选',
				conv=function(s,e)
					return true
				end		
			},
	[11] = {name='单拖放',
				conv=function(s,e)
					return true
				end		
			},
	[12] = {name='多拖放',
				conv=function(s,e)
					return true
				end		
			}
}

function WorkFlow:load_original_data( file )
	local reslut = kits.read_cache(file)
	local res = {}
	if reslut then
		local data = kits.decode_json(reslut)
		if data then
			for i,v in ipairs(data) do
				local k = {}
				k.item_type = v.item_type
				k.state = ui.STATE_UNFINISHED
				k.isload = true --is downloaded?
				k.image = v.image
				if WorkFlow._type_convs[k.item_type] and WorkFlow._type_convs[k.item_type].conv then
					if WorkFlow._type_convs[k.item_type].conv( v,k ) then
						res[#res+1] = k
					else
						print('WorkFlow 不能转'..WorkFlow._type_convs[k.item_type].name..'题: '..tostring(v.Id))
					end
				else
					print('WorkFlow 支持的题型: '..v.item_type)
				end
			end
		end
	end
	return res
end

function WorkFlow:init_gui()
	self._root = uikits.fromJson{file=ui.FILE}
	self:addChild(self._root)
	uikits.event(uikits.child(self._root,ui.BACK),function(sender)
		uikits.popScene()
		end)
	self._scrollview = uikits.child(self._root,ui.LIST)
	self._pageview = uikits.child(self._root,ui.PAGE_VIEW)
	self._pageview_size = self._pageview:getSize()
	uikits.event(self._pageview,
			function(sender,eventType)
				if eventType == ccui.PageViewEventType.turning then
					local i = sender:getCurPageIndex()
					self:set_current( i+1 )
				end				
			end)
	self._item_current = uikits.child(self._scrollview,ui.ITEM_CURRENT)
	self._item_finished = uikits.child(self._scrollview,ui.ITEM_FINISHED)
	self._item_unfinished = uikits.child(self._scrollview,ui.ITEM_UNFINISHED)
	
	self._item_current:setVisible(false)
	self._item_finished:setVisible(false)
	self._item_unfinished:setVisible(false)

	self._item_size = self._item_current:getSize()
	
	self._next_button = uikits.child(self._root,ui.NEXT_BUTTON )
	uikits.event( self._next_button,
				function(sender)
					self:next_item()
				end,'click')
				
	self:init_anser_gui()
	
	local x
	x,self._item_y = self._item_current:getPosition()
	for i,v in pairs(self._data) do
		self:add_item( v )
	end
	self:set_current(1)
	self:relayout()
end

function WorkFlow:relayout()
	if self._scrollview and #self._list > 0 then
		self._scrollview:setInnerContainerSize(cc.size(self._item_size.width,self._item_size.height*(#self._list)))
		for i,v in ipairs(self._list) do
			v:setPosition(cc.p(i*self._item_size.width,self._item_y))
		end
	end
end

function WorkFlow:set_item_state( i,ste )
	if self._list[i] then
		local item = self._list[i]
		local num = uikits.child(item,ui.ITEM_NUM)
		local s = num:getString()
		local x,y = item:getPosition()
		item:removeFromParent()
		item = self:clone_item(ste)
		local n = uikits.child(item,ui.ITEM_NUM )
		n:setString( s )
		item:setPosition( cc.p(x,y) )
		item:setVisible(true)
		self._list[i] = item
		self._scrollview:addChild(item)	
		local index = i
		uikits.event(item,function(sender) self:set_current( index ) end,'click')
	end
end

function WorkFlow:clone_item( state )
	if state == ui.STATE_CURRENT then
		return self._item_current:clone()
	elseif state == ui.STATE_FINISHED then
		return self._item_finished:clone()
	elseif state == ui.STATE_UNFINISHED then
		return self._item_unfinished:clone()
	end
end

function WorkFlow:next_item()
	if self._current and self._current < #self._list then
		self:set_current( self._current+1 )
	end
end

function WorkFlow:set_current( i )
	if self._current ~= i then
		self:set_item_state( i,ui.STATE_CURRENT )
		if self._current then
				self:set_item_state(self._current,self._data[self._current].state)
		end
		self._current = i
		local ps = self._pageview:getCurPageIndex()+1
		if ps ~= i then
			self._pageview:scrollToPage(i-1)
		end
		self:set_anwser_field(i)
	end
end

function WorkFlow:set_image( i )
	if not self._data[i].isset and self._data[i].isload then
		local layout = self._pageview:getPage( i-1 )
		if layout then
			local img = uikits.image{image=self._data[i].image,x=self._pageview_size.width/2,y=self._pageview_size.height/2,anchorX=0.5,anchorY=0.5}
			img:setScaleX(2)
			img:setScaleY(2)
			layout:addChild(img)
			self._data[i].isset = true
		end
	elseif not self._data[i].isload then
		--download?
	end
end

function WorkFlow:add_item( t )
	local item = self:clone_item( t.state )
	if item then
		local n = uikits.child(item,ui.ITEM_NUM)
		n:setString( tostring(#self._list + 1) )
		self._list[#self._list+1] = item
		item:setVisible(true)
		self._scrollview:addChild(item)
		local index = #self._list
		uikits.event(item,function(sender) self:set_current( index ) end,'click')
		--add page
		local layout = uikits.layout{bgcolor=cc.c3b(255,255,255)}
		layout:addChild(uikits.text{caption='Page'..#self._list,fontSize=32})
		self._pageview:addPage( layout )
		self:set_image( #self._list )
	end
end

function WorkFlow:init_anser_gui()
	self._option_img = {}
	self._answer_items = {}
	
	local a = uikits.child(self._root,ui.ANSWER_FIELD)
	self._answer_field = a
	self._answer_type = uikits.child(a,ui.TYPE_IMG)
	--选择
	self._option_img[1] = uikits.child(a,ui.OPTION_A)
	self._option_img[2] = uikits.child(a,ui.OPTION_B)
	self._option_img[3] = uikits.child(a,ui.OPTION_C)
	self._option_img[4] = uikits.child(a,ui.OPTION_D)
	self._option_img[5] = uikits.child(a,ui.OPTION_E)
	self._option_img[6] = uikits.child(a,ui.OPTION_F)
	self._option_img[7] = uikits.child(a,ui.OPTION_G)
	self._option_img[8] = uikits.child(a,ui.OPTION_H)
	
	self._option_link = uikits.child(a,ui.LINK_TEXT)
	self._option_drag = uikits.child(a,ui.DRAG_TEXT)
	self._option_sort = uikits.child(a,ui.POSITION_SORT)
	self._option_yes = uikits.child(a,ui.OPTION_YES)
	self._option_no = uikits.child(a,ui.OPTION_NO)
	self._option_not_support = uikits.child(a,ui.OPTION_NO_SUPPORT)
	
	self._option_edit = {}
	self._option_edit[1] = uikits.child(a,ui.EDIT_1)
	self._option_edit[2] = uikits.child(a,ui.EDIT_2)
	self._option_edit[3] = uikits.child(a,ui.EDIT_3)
	self._option_edit[4] = uikits.child(a,ui.EDIT_4)
end

function WorkFlow:clear_all_option_check()
	for i = 1,#self._option_img do
		self._option_img[i]:setSelectedState(false)
	end
end

WorkFlow._topics = {
	--answer = 1 表示A, 2 = B ...
	[1] = {name='判断',img='true_or_false_item.png',
				init=function(self,frame,data,op)
					self._option_yes:setVisible(true)
					self._option_no:setVisible(true)
					if data.answer == 1 then
						self._option_yes:setSelectedState(true)
						self._option_no:setSelectedState(false)
					elseif data.answer == 2 then
						self._option_yes:setSelectedState(false)
						self._option_no:setSelectedState(true)	
					else
						self._option_yes:setSelectedState(false)
						self._option_no:setSelectedState(false)
					end
					uikits.event(self._option_yes,
						function (sender,b)
							if b then
								if data.answer == 2 then
									self._option_no:setSelectedState(false)
								end
								data.answer = 1	
								data.state = ui.STATE_FINISHED
							else
								data.answer = nil
								data.state = ui.STATE_UNFINISHED
							end
						end)
					uikits.event(self._option_no,
						function (sender,b)
							if b then
								if data.answer == 1 then
									self._option_yes:setSelectedState(false)
								end
								data.answer = 2
								data.state = ui.STATE_FINISHED
							else
								data.answer = nil
								data.state = ui.STATE_UNFINISHED
							end						
						end)
				end},
	[2] = {name='单选',img='single_item.png',
				init=function(self,frame,data,op)
					for i = 1,op do
						self._option_img[i]:setVisible(true)
						if i == data.answer then
							self._option_img[i]:setSelectedState(true)
						else
							self._option_img[i]:setSelectedState(false)
						end
						local m = i
						uikits.event(self._option_img[i],
							function(sender,b)
								if b then
									data.answer = m
									self:clear_all_option_check()
									sender:setSelectedState(true)
									data.state = ui.STATE_FINISHED
								else
									data.answer = nil
									data.state = ui.STATE_UNFINISHED
								end
							end)
					end
				end},
	[3] = {name='多选',img='multiple_item.png',
				init=function(self,frame,data,op)
					for i = 1, op do
						self._option_img[i]:setVisible(true)
						if data.answer and type(data.answer)=='table' and data.answer[i] then
							self._option_img[i]:setSelectedState(true)
						else
							self._option_img[i]:setSelectedState(false)
						end
						local m = i
						uikits.event(self._option_img[i],
							function(sender,b)
								data.answer = data.answer or {}
								
								if data.answer[m] then
									data.answer[m] = nil
									data.state = ui.STATE_UNFINISHED
								else
									data.answer[m] = 1
									data.state = ui.STATE_FINISHED
								end
							end)
					end
				end},
	[4] = {name='连线',img='connection_item.png',
				init=function(self,frame,data,op)
					self._option_link:setVisible(true)
				end},
	[5] = {name='填空',img='write_item.png',
				init=function(self,frame,data,op)
					if op then
						data.answer = data.answer or {}
						for i = 1,op do
							self._option_edit[i]:setVisible(true)
							local e = uikits.child(self._option_edit[i],ui.ANSWER_TEXT)
							if data.answer and data.answer[i] then
								e:setText(data.answer[i])
							else
								e:setText('')
							end
							uikits.event(e,
									function(sender,eventType)
										if eventType == ccui.TextFiledEventType.insert_text then
											data.state = ui.STATE_FINISHED
											data.answer[i] = sender:getStringValue()
										elseif eventType == ccui.TextFiledEventType.delete_backward then
											data.state = ui.STATE_FINISHED
											data.answer[i] = sender:getStringValue()
										end
									end)							
						end
					end
				end},
	[7] = {name='横排序',img='sort_item.png',
				init=function(self,frame,data,op)
					self._option_sort:setVisible(true)
				end},
	[8] = {name='竖排序',img='sort_item.png',
				init=function(self,frame,data,op)
					self._option_sort:setVisible(true)
				end},
	[9] = {name='点图单选',
				init=function(self,frame,data,op)
				end},
	[10] = {name='点图多选',
				init=function(self,frame,data,op)
				end},
	[11] = {name='单拖放',img='drag_item.png',
				init=function(self,frame,data,op)
					self._option_drag:setVisible(true)
				end},
	[12] = {name='多拖放',img='drag_item.png',
				init=function(self,frame,data,op)
					self._option_drag:setVisible(true)
				end},
}

function WorkFlow:set_anwser_field( i )
	if self._data[i] then
		if self._answer_items then
			for i,v in pairs(self._answer_items) do
				v:removeFromParent()
			end
			self._answer_items = {}
			for i=1,8 do
				self._option_img[i]:setVisible(false)
			end
			for i=1,4 do
				self._option_edit[i]:setVisible(false)
			end
			self._option_link:setVisible(false)
			self._option_yes:setVisible(false)
			self._option_no:setVisible(false)			
			self._option_drag:setVisible(false)
			self._option_sort:setVisible(false)
			self._option_not_support:setVisible(false)
		end
		local t = self._data[i].item_type
		
		if self._topics[t] and self._topics[t].img and self._topics[t].init then
			self._answer_type:loadTexture(res_root..self._topics[t].img)
			
			if self._prev_option_index then
				local prev_t = self._data[self._prev_option_index].item_type
				if self._topics[prev_t] and self._topics[prev_t].release then
					--上一个的释放
					self._topics[prev_t].release( self,self._answer_field,self._data[self._prev_option_index],self._data[self._prev_option_index].options)
				end
			end
			self._topics[t].init(self,self._answer_field,self._data[i],self._data[i].options)
		else
			--不支持的类型
			if  self._topics[t] and  self._topics[t].name then
				print( "Can't support type "..t.."	name : "..self._topics[t].name )
			else
				print( "Can't support type "..t )
			end
			self._option_not_support:setVisible(true)
		end
		self._prev_option_index = i
	end
end

function WorkFlow:init()
	if not self._root then
		self:init_data()
		
		self._list = {}
		self:init_gui()
	end
end

function WorkFlow:release()
end

return WorkFlow