require "Cocos2d"
require "Cocos2dConstants"
require "qwxt/globalSettings"
local public=require("qwxt/public")
local protocol=require("qwxt/protocol")
require "qwxt/userInfo"

--创建TableView
local function newTableView(viewSize,cellItem,setItem)
	local myTableView=class("rankView",function()
		return cc.TableView:create(viewSize)
	end)
	myTableView.__index=myTableView

	function myTableView:setData(data)
		self.data=nil
		self.data=data
		self:reloadData()
		self.top=math.max(self.viewSize.height-self:getContentSize().height,0)
		self.bottom=math.min(self.viewSize.height-self:getContentSize().height,self.viewSize.height)
	end

	local tableView=myTableView.new(viewSize)
	tableView:setTouchEnabled(true)
	tableView:setDelegate()
	tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
	tableView:setBounceable(false)
	tableView.item=cellItem:clone()
	local function disableTouch(node)
		node:setTouchEnabled(false)
		local children=node:getChildren()
		if children then
			for _,v in pairs(children) do
				disableTouch(v)
			end
		end
	end
	disableTouch(tableView.item)
	tableView.item:retain()

	tableView.viewSize=viewSize
	tableView.cellSize=cellItem:getContentSize()
	tableView.top=0
	tableView.bottom=0

	--键盘和鼠标滚轮支持
	public.addMouseScrollAndKeyboard(tableView,function(line,page)
		local offset=tableView:getContentOffset()
		local distance=0
		if line then
			distance=line*tableView.cellSize.height
		elseif page then
			distance=page*viewSize.height
		end
		local newy=math.max(tableView:minContainerOffset().y,math.min(offset.y+distance,0))
		if newy~=offset.y then
			offset.y=newy
			tableView:setContentOffset(offset)
		end
	end,function()
		local offset=tableView:getContentOffset()
		offset.y=tableView.bottom
		tableView:setContentOffset(offset)
	end,function()
		local offset=tableView:getContentOffset()
		offset.y=tableView.top
		tableView:setContentOffset(offset)
	end)
	function tableView:onCleanup()
		--释放内存
		tableView.item:release()
	end

	--TableView事件
	tableView:registerScriptHandler(function(table)
		if tableView.data and #tableView.data>0 then
			return #tableView.data
		end
		return 0
	end,cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
	tableView:registerScriptHandler(function(table,index)
		return tableView.cellSize.height,tableView.cellSize.width
	end,cc.TABLECELL_SIZE_FOR_INDEX)
	tableView:registerScriptHandler(function(table,index)
		local function newItem(cell)
			item=tableView.item:clone()
			item:setAnchorPoint(cc.p(0,0))
			item:setPosition(0,0)
			item:setTag(1)
			cell:addChild(item)
			return item
		end
		local cell=tableView:dequeueCell()
		local item=nil
		if cell then
			item=cell:getChildByTag(1)
		else
			cell=cc.TableViewCell:create()
			item=newItem(cell)
		end
		if tableView.data and tableView.data[index+1] then
			setItem(item,tableView.data[index+1],index+1)
		else
			setItem(item,nil,index+1)
		end
		return cell
	end,cc.TABLECELL_SIZE_AT_INDEX)

	return tableView
end

--创建TableView
local function createTableView(parent,viewPosition,viewSize,cellItem,setItem)
	local tableView=newTableView(viewSize,cellItem,setItem)

	tableView:setPosition(viewPosition)
	tableView:setData(nil)
	parent:addChild(tableView)

	return tableView
end

--创建排行榜
local function createRankView(parent,viewPosition,viewSize,cellItem,rankId,rankParam,setItem,sortFunc,beforeSort,afterRefresh,refresh)
	local tableView=newTableView(viewSize,cellItem,function(item,data,index)
		if data==nil then
			--只是用来刷新的
			item:setVisible(false)
			if item.mask==nil then
				item.mask=ccui.Layout:create()
				item.mask:setContentSize(cc.size(item:getContentSize().width,item:getContentSize().height))
				item.mask:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
				item.mask:setBackGroundColor(cc.c3b(95,158,160))
				item.mask:setBackGroundColorOpacity(item:getBackGroundColorOpacity())
				item.mask:setTouchEnabled(false)
				item:getParent():addChild(item.mask)
			end
		else
			if item.mask then
				item.mask:removeFromParent()
				item.mask=nil
			end
			if data.user_id==userInfo.uid then
				item:setBackGroundColor(cc.c3b(95,158,160))
			else
				item:setBackGroundColor(cc.c3b(0,0,0))
			end
			item:setVisible(true)
			setItem(item,data,index)
		end
	end)

	local text=cc.Label:createWithSystemFont("↓下拉更新排行榜","fonts/Marker Felt.ttf",30)
	text:setVisible(false)
	text:setColor(cc.c3b(255,0,0))
	text:setAnchorPoint(cc.p(0.5,1))
	text:setPosition(viewPosition.x+viewSize.width/2,viewPosition.y+viewSize.height)
	if parent.setLayoutType then
		parent:setLayoutType(ccui.LayoutType.ABSOLUTE)
	end
	parent:addChild(text)

	local bounceHeight=tableView.cellSize.height

	tableView:registerScriptHandler(function(table)
		if tableView.data and #tableView.data>0 then
			return #tableView.data
		end
		--返回1用来刷新
		return 1
	end,cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
	local check=false
	tableView:registerScriptHandler(function(table)
		text:setString("↓下拉更新排行榜")
		text:setVisible(false)
		--限制拖动范围
		local offset=tableView:getContentOffset()
		if offset.y<tableView.bottom then
			if tableView:isDragging() then
				if tableView.bottom-offset.y>bounceHeight then
					--触底准备触发刷新
					offset.y=tableView.bottom-bounceHeight
					tableView:setContentOffset(offset)
					check=true
					text:setString("↑释放更新排行榜")
				else
					--尚未触底或者取消触发刷新
					if check and tableView.bottom-offset.y<bounceHeight*2/3 then
						check=false
					end
					if check then
						text:setString("↑释放更新排行榜")
					end
					text:setVisible(true)
				end
			elseif check then
				--释放拖动并触发刷新
				offset.y=tableView.bottom
				tableView:setBounceable(false)			--暂停回弹，免得画面乱跑
				tableView:setContentOffset(offset)
				tableView:refresh()
				check=false
			end
			return
		elseif offset.y>tableView.top then
			if tableView:isDragging() and offset.y-tableView.top>bounceHeight then
				offset.y=tableView.top+bounceHeight
				tableView:setContentOffset(offset)
			end
			return
		end
	end,cc.SCROLLVIEW_SCRIPT_SCROLL)

	--刷新排行榜
	function tableView:refresh()
		if rankId~=nil then
			protocol.getRankData(rankId,rankParam,function(success,obj)
				if success and obj then
					--刷新完毕要把数据设置进去
					if obj then
						--排序
						if beforeSort then beforeSort(obj) end
						table.sort(obj,sortFunc)
					end
					self:setData(obj)
				end
				self:setBounceable(true)
				if afterRefresh then afterRefresh(self.data) end
			end,{node=self:getParent(),text="正在刷新......"})
		end
	end
	if refresh~=nil then
		tableView.refresh=refresh
	end

	function tableView:onEnterTransitionFinish()
		if self.data==nil then
			performWithDelay(self,function()
				self:refresh()
			end,0)
		end
	end

	tableView:setPosition(viewPosition)
	tableView:setData(nil)
	tableView:setBounceable(true)
	parent:addChild(tableView)

	return tableView
end

--设置排名图标
local function setRankItemImage(rank,image,text)
	if rank==1 then
		image:loadTexture("qwxt/diyi.png")
		text:setVisible(false)
	elseif rank==2 then
		image:loadTexture("qwxt/dier.png")
		text:setVisible(false)
	elseif rank==3 then
		image:loadTexture("qwxt/disan.png")
		text:setVisible(false)
	else
		image:loadTexture("qwxt/disi.png")
		text:setVisible(true)
	end
end

--设置排行榜用户头像
local function setRankUserImage(userId,userName,userImage)
	userImage._userId=userId
	public.getBigLogo(userId,function(fileName)
		if userImage._userId==userId then
			userImage:loadTexture(fileName)
		end
	end)
	userImage:setTouchEnabled(true)
	public.buttonEvent(userImage,function(sender,event)
		require("qwxt/popup").classmateInfo(userId,userName)
	end)
end

return
{
	createTableView=createTableView,
	createRankView=createRankView,
	setRankItemImage=setRankItemImage,
	setRankUserImage=setRankUserImage,
}
