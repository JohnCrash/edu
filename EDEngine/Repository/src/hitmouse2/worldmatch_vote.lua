local kits = require "kits"
local uikits = require "uikits"
local state = require "hitmouse2/state"
local http = require "hitmouse2/hitconfig"
local global = require "hitmouse2/global"
local login = require "login"
local md5 = require "md5"
local cache = require "cache"

local local_dir = kits.get_local_directory()..'res/'

local ui = {
	FILE = 'hitmouse2/shijieyan.json',
	FILE_3_4 = 'hitmouse2/shijieyan43.json',
	designWidth = 1920,
	designHeight = 1080,
	BACK = 'ding/fan',
	
	LIST = 'tpz',
	ITEM = 'ren1',
	ITEM2 = 'ren2',
	TOP = 'duifang',
	TOP_LOGO = 'toux',
	TOP_NAME = 'mingzi',
	TOP_CLASS = 'banj',
	TOP_SCHOOL = 'xuexiao',
	TOP_VOTES = 'yinpiao',
	TOP_VOTE_BUT = 'tou',
	TOP_MY_VOTES = 'wodepiao',
	TOP_ASK_VOTE_BUT = 'fabu',
	
	ITEM_LOGO = 'toux',
	ITEM_NAME = 'mingz',
	ITEM_TEXT = 'shij',
	ITEM_ACC_VOTE = 'tou',
	ITEM_IMAGE = 'tu',
	
	COMMIT_PLANE = 'wenz',
	VOTE_PLANE = 'tou',
	ASK_PLANE = 'fa',
	
	INPUT_TEXT = 'bai/shuru',
	CAM_BUT = 'bai/pai',
	IMG_BUT = 'bai/chuan',
	IMG_IMG = 'bai/tu',
	VOTE_BUT = 'bai/tou',
	ASK_BUT = 'bai/fa',
	
	WARNING_PLANE = 'meipiao',
	WARNING_CANCEL = 'hei/guan',
	WARNING_BUY = 'hei/mai',
	BUY_COUNT = 'hei/cishu',
	BUY_CAST = 'hei/yinbi',
	BUT_DESC = 'hei/w3',
}
local commitText1={
	"太棒了，加油吧！我的票给你了。",
	"不投给你，我还能给谁？加油！",
	"我的票可是相当珍贵的，好好加油啊！",
	"我相信你，你一定成功的，不说了，投你一票。",
}
local commitText2={
	"请大家相信我，我一定会努力的，把你们的票统统给我吧！",
	"实力决定我一定能绽放光彩，把你们的票都给我吧！",
	"有什么好说的，我爱你们。你们把票投给我吧！",
	"我，你们还不相信，一定会成功的。所以，把你们的票给我吧！",
}
local commit_select = 1
local worldmatch_vote = uikits.SceneClass("worldmatch_vote",ui)

local function closeIMEKeyboard()
	local Director = cc.Director:getInstance()
	local glview = Director:getOpenGLView()
	glview:setIMEKeyboardState(false)
end

function worldmatch_vote:init(b)
	if b then
		uikits.event(uikits.child(self._root,ui.BACK),function(sender)
			uikits.popScene()
		end)
		self._scrollview = uikits.scrollex(self._root,ui.LIST,{ui.ITEM,ui.ITEM2},{ui.TOP})
		
		self._cur = 1
		
		uikits.event(self._scrollview._scrollview,function(sender,state)
			if state == ccui.ScrollviewEventType.scrollToBottom then
				if not self._done_loading and self._tatolPags and self._cur < self._tatolPags then
					self._cur = self._cur + 1
					kits.log("continue loading...")
					self:initData(self._cur)
					self._done_loading = true
				end
			end
		end)
		
		uikits.enableMouseWheelIFWindows(self._scrollview)
		
		self._top = self._scrollview._tops[1]
		uikits.child(self._top,ui.TOP_NAME):setString(self._arg.name or '-')
		uikits.child(self._top,ui.TOP_SCHOOL):setString(self._arg.school or '-')
		uikits.child(self._top,ui.TOP_CLASS):setString(self._arg.class or '-')
		uikits.child(self._top,ui.TOP_VOTES):setString(self._arg.vote or '-')
		http.load_logo_pic(uikits.child(self._top,ui.TOP_LOGO),self._arg.uid or 0)
		
		self._commit_plane = uikits.child(self._root,ui.COMMIT_PLANE)
		self._warning_plane = uikits.child(self._root,ui.WARNING_PLANE)
		
		self._commit_plane:setVisible(false)
		self._warning_plane:setVisible(false)
		
		local vote_but = uikits.child(self._top,ui.TOP_VOTE_BUT)
		local ask_but = uikits.child(self._top,ui.TOP_ASK_VOTE_BUT)
		vote_but:setVisible(false)
		ask_but:setVisible(false)
		if not self._arg.isteacher then
			if self._arg.uid==login.uid() then
				ask_but:setVisible(true)
				uikits.event(ask_but,function(sender)
					self:commitDialog(1)
				end)
			else
				self._vote_flag = true
				vote_but:setVisible(true)
				uikits.child(vote_but,ui.TOP_MY_VOTES):setString( self._arg.my_vote or '-' )
				uikits.event(vote_but,function(sender)
					if self._arg.my_vote and self._arg.my_vote>0 then
						self:commitDialog(2)
					else
						self:buyVote()
					end
				end)
			end
		else
			uikits.child(vote_but,ui.TOP_MY_VOTES):setVisible(false)
		end
		self._scrollview:clear()
		self:initData(self._cur)
		self._commit_data = {}
	else
		local layout = self._scrollview._scrollview:getInnerContainer()
		if self._sc_x and self._sc_y then
			layout:setPosition(cc.p(self._sc_x,self._sc_y))
			self._sc_x = nil
			self._sc_y = nil
		end
		uikits.enableMouseWheelIFWindows(self._scrollview)
	end
end

function worldmatch_vote:buyVoteImp()
	local send_data = {v1=self._arg.worldmatch_id or 0}
	http.post_data(self._root,'buy_vote',send_data,function(t,v)
		if t and t==200 and v then
			kits.log("loading worldmatch_vote:buy_vote success!")
			http.logTable(v,1)
			if v.v1 then
				if v.v3 then
					state.set_sliver(v.v3)
				end
				self._arg.my_vote = v.v4
				local vote_but = uikits.child(self._top,ui.TOP_VOTE_BUT)
				if vote_but then
					uikits.child(vote_but,ui.TOP_MY_VOTES):setString( self._arg.my_vote or '-' )
				end
			elseif v.v2 then
				http.messagebox(self._root,http.OK_MSG,function(e)
				end,tostring(v.v2) )
			else
				state.messagebox("ERROR","buy_vote v.v2 = nil",1)
			end
		else
			http.messagebox(self._root,http.DIY_MSG,function(e)
				if e == http.RETRY then
					self:buyVoteImp(s)
				else
					uikits.popScene()
				end
			end,v)			
		end
	end)			
end

function worldmatch_vote:do_buyvote()
	self._warning_plane:setVisible(true)
	local cancel = uikits.child(self._warning_plane,ui.WARNING_CANCEL)
	local buy = uikits.child(self._warning_plane,ui.WARNING_BUY)
	local v1,v2,v3 = global.getBuyVoteInfo()
	local buy_count_label = uikits.child(self._warning_plane,ui.BUY_COUNT)
	local buy_cast_label = uikits.child(self._warning_plane,ui.BUY_CAST)
	local buy_cast_desc = uikits.child(self._warning_plane,ui.BUT_DESC)
	if buy_count_label then
		buy_count_label:setString(v1 or 5)
	end
	if buy_cast_label then
		buy_cast_label:setString(tostring(v3 or 1000).."银币")
	end
	if buy_cast_desc then
		buy_cast_desc:setString("购买"..tostring(v2 or 5).."次投票机会：")
	end
	if cancel then
		uikits.event(cancel,function(sender)
			self._warning_plane:setVisible(false)
		end)
	end
	if buy then
		uikits.event(buy,function(sender)
			self._warning_plane:setVisible(false)
			self:buyVoteImp()
		end)
	end
end

function worldmatch_vote:buyVote()
	local send_data = {v1=self._arg.worldmatch_id or 0}
	http.post_data(self._root,'buy_vote_info',send_data,function(t,v)
		if t and t==200 and v then
			kits.log("loading worldmatch_vote:buy_vote_info success!")
			http.logTable(v,1)
			if v then
				global.setBuyVoteInfo(v.v1,v.v2,v.v3)
				self:do_buyvote()
			else
				http.messagebox(self._root,http.OK_MSG,function(e)end,"buy_vote_info v = nil")
			end
		else
			http.messagebox(self._root,http.DIY_MSG,function(e)
				if e == http.RETRY then
					self:buyVote(s)
				else
					uikits.popScene()
				end
			end,v)			
		end
	end)	
end

function worldmatch_vote:commitDialog(s)
	local plane
	self._commit_data = {} --清除	
	self._commit_plane:setVisible(true)
	if s==1 then
		plane = uikits.child(self._commit_plane,ui.ASK_PLANE)
		uikits.child(self._commit_plane,ui.VOTE_PLANE):setVisible(false)
	else
		plane = uikits.child(self._commit_plane,ui.VOTE_PLANE)
		uikits.child(self._commit_plane,ui.ASK_PLANE):setVisible(false)
	end
	local input = uikits.child(plane,ui.INPUT_TEXT)
	if input then
		input:setText("")
		commit_select = math.random(1,4)
		if s==1 then
			input:setPlaceHolder(commitText2[commit_select])
		else
			input:setPlaceHolder(commitText1[commit_select])
		end
	end
	if self._commit_data.text then
		input:setText(self._commit_data.text)
	end
	local imgs = {}
	for i=1,4 do
		local img = uikits.child(plane,ui.IMG_IMG..i..'/zp')
		img:setVisible(false)
		table.insert(imgs,img)
	end
	if self._commit_data.images and #self._commit_data.images>0 then
		for i,v in pairs(self._commit_data.images) do
			if imgs[i] then
				imgs[i]:setVisible(true)
				imgs[i]:loadTexture(v)
			end
		end
	end
	local function close_commit_interface()
		self._commit_data.text = input:getStringValue()
		self._commit_plane:setVisible(false)
		closeIMEKeyboard()
	end
	
	uikits.event(self._commit_plane,function(sender)
		close_commit_interface()
	end)
	uikits.event(uikits.child(plane,ui.CAM_BUT),function(sender)
			self._commit_data.images = self._commit_data.images or {}
			if self._commit_data.images and #self._commit_data.images>=4 then
				state.messagebox("错误","最多可以加4张图片")
				return
			end
			cc_takeResource(TAKE_PICTURE,function(t,result,res)
			kits.log('type ='..tostring(t)..' result='..tostring(result)..' res='..tostring(res))
			if result == RESULT_OK then
				local b,res = cc_adjustPhoto(res,1280)
				if b and kits.exist_file(res) then
					res = self:cacheRes(res)
					self._commit_data.images = self._commit_data.images or {}
					table.insert(self._commit_data.images,res)
					imgs[#self._commit_data.images]:loadTexture(res)
					imgs[#self._commit_data.images]:setVisible(true)
				else
					state.messagebox("错误","图像调整失败\n"..tostring(res))
				end
			else
				state.messagebox("提示","没有发现摄像头")
			end
		end)
	end)
	uikits.event(uikits.child(plane,ui.IMG_BUT),function(sender)
			if self._commit_data.images and #self._commit_data.images>=4 then
				state.messagebox("提示","最多可以加4张图片")
				return
			end	
			cc_takeResource(PICK_PICTURE,function(t,result,res)
			kits.log('type ='..tostring(t)..' result='..tostring(result)..' res='..tostring(res))
			if result == RESULT_OK then
				local b,res = cc_adjustPhoto(res,1280)
				if b and kits.exist_file(res) then
					res = self:cacheRes(res)
					self._commit_data.images = self._commit_data.images or {}
					table.insert(self._commit_data.images,res)
					imgs[#self._commit_data.images]:loadTexture(res)				
					imgs[#self._commit_data.images]:setVisible(true)
				else
					state.messagebox("错误","图像调整失败\n"..tostring(res))
				end		
			end
		end)		
	end)
	plane:setVisible(true)
	local but = uikits.child(plane,ui.VOTE_BUT)
	if but then
		uikits.event(but,function(sender)
			close_commit_interface()
			self:do_commit(s)
		end)
	end
	but = uikits.child(plane,ui.ASK_BUT)
	if but then
		uikits.event(but,function(sender)
			close_commit_interface()
			self:do_commit(s)
		end)
	end
end

function worldmatch_vote:do_commit2(s)
	local commit_text
	self._commit_data.text = self._commit_data.text or ""
	if self._commit_data.text and string.len(self._commit_data.text)==0 then
		if s==1 then
			commit_text = commitText2[commit_select]
		else
			commit_text = commitText1[commit_select]
		end
	else
		commit_text = self._commit_data.text
	end
	local send_data = {
		v1=self._arg.worldmatch_id,
		v2=self._arg.uid,
		v3=(s==1),
		v4='@'..commit_text,
		v5=self._commit_data.uploads or {}
		}
	kits.log("do worldmatch_vote:put_vote...")
	http.post_data(self._root,'put_vote',send_data,function(t,v)
		if t and t==200 and v then
			kits.log("loading worldmatch_vote:put_vote success!")
			http.logTable(v,1)
			if v.v1 then
				self._scrollview:clear()
				self._cur = 1
				self:initData(self._cur)
				uikits.child(self._top,ui.TOP_VOTES):setString(v.v3 or '-')
				if self._vote_flag then
					self._arg.my_vote = self._arg.my_vote-1
					local vote_but = uikits.child(self._top,ui.TOP_VOTE_BUT)
					if vote_but then
						uikits.child(vote_but,ui.TOP_MY_VOTES):setString( self._arg.my_vote or '-' )
					end
				end
			else
				state.messagebox("提示","投票失败",1)
			end
		else
			http.messagebox(self._root,http.DIY_MSG,function(e)
				if e == http.RETRY then
					self:do_commit2(s)
				else
					uikits.popScene()
				end
			end,v)			
		end
	end)
end

function worldmatch_vote:do_commit(s)
	if self._commit_data.images and #self._commit_data.images>0 then
		--上传
		local urls = {}
		local try_count = 1
		local function upload_files( images )
			local count = #images
			local c = 0
			local err = {}
			local progressbar = state.progressbar("正在上传")
			local url = 'http://file-stu.lejiaolexue.com/rest/user/upload/hw'
			local progress = {}
			for i,v in pairs(images) do
				local data = kits.read_cache(v)
				progress[i] = 0
				if data then
					kits.log("upload : "..tostring(v))
					cache.upload( url,v,data,function(b,t)
						c = c + 1
						if b and t and t.md5 then
							http.logTable(t,1)
							urls[i] = "http://file-stu.lejiaolexue.com/rest/dl/"..tostring(t.md5)
							kits.log("upload success : "..tostring(urls[i]))
						else
							table.insert(err,v)
							kits.log("upload failed : "..tostring(v))
						end
						if c == count and #err==0 then
							progressbar:close()
							kits.log("upload done! "..#urls)
							self._commit_data.uploads = urls
							self:do_commit2(s)
						elseif c==count and try_count<=3 then
							progressbar:close()
							try_count = try_count + 1
							upload_files( err )
						elseif try_count > 3 then
							state.messagebox("提示","文件上传失败了\n"..tostring(#err),1)
						end
					end,function(p)
						print("+"..tostring(v).."|"..tostring(p))
						progress[i] = p
						local s = 0
						for k=1,4 do
							if progress[k] then
								s = s + progress[k]
							end
						end
						progressbar:setProgress(s/count)
					end)
				else
					c = c + 1
					if c==count then
						progressbar:close()
					end
					table.insert(err,v)
				end
			end
		end
		upload_files( self._commit_data.images )
	else
		self:do_commit2(s)
	end
end

function worldmatch_vote:cacheRes( res )
	local cacheFile
	
	if string.sub(res,-4,-4)=='.' then
		cacheFile = md5.sumhexa(res)..string.sub(res,-4)
	else
		cacheFile = md5.sumhexa(res)
	end
	local cpFile = kits.get_cache_path()..cacheFile
	if kits.exist_file(cpFile) then
		return cacheFile
	else
		kits.copy_file(res,cpFile)
		return cacheFile
	end
end

function worldmatch_vote:initData(cur)
	local send_data = {v1=self._arg.worldmatch_id,v2=self._arg.uid,v3=cur,v4=20}
	kits.log("do worldmatch_vote:initData...("..tostring(self._arg.worldmatch_id)..")")
	http.post_data(self._root,'get_vote_board',send_data,function(t,v)
		if t and t==200 and v then
			self._scrollview._scrollview:setVisible(true)
			kits.log("loading worldmatch_vote:initData success!")
			http.logTable(v,1)
			if v and v.v1 and v.v2 and v.v3 and type(v.v3)=='table' then
				self._tatolPags = v.v2
				for i,s in pairs(v.v3) do
					self:additem(s)
				end
				self:relayout()
				uikits.child(self._top,ui.TOP_VOTES):setString(v.v4 or '-')
			else
				http.messagebox(self._root,http.DIY_MSG,function(e)
					if e == http.RETRY then
						self:initData(cur)
					else
						uikits.popScene()
					end
				end,v)			
			end
		end
		self._done_loading = nil
	end)			
end

function worldmatch_vote:additem(s)
	local b
	if s.images then
		local count = #s.images
		for k=1,count do
			if s.images[k] and string.len(s.images[k]) > 0 then
				b = true
			end
		end
	end
	local item
	if b then
		item = self._scrollview:additem(1)
	else
		item = self._scrollview:additem(2)
	end
	self._scrollview._list[#self._scrollview._list] = nil
	table.insert(self._scrollview._list,1,item)
	http.load_logo_pic(uikits.child(item,ui.ITEM_LOGO),s.uid or 0 )
	uikits.child(item,ui.ITEM_NAME):setString(s.name or '-')
	uikits.child(item,ui.ITEM_TEXT):setString(s.text or '-')
	uikits.child(item,ui.ITEM_ACC_VOTE):setString(s.acc_vote or '-')
	local imgs = {}
	for k=1,4 do
		local img = uikits.child(item,ui.ITEM_IMAGE..k..'/zp')
		if img then
			img:setVisible(false)
			table.insert( imgs,img )
		end
	end
	if s.images then
		local imgfiles = {}
		local count = #s.images
		count = math.min(count,#imgs)
		for k=1,count do
			if imgs[k] and s.images[k] and string.len(s.images[k]) > 0 then
				local file = kits.get_cache_path()..cache.get_name(s.images[k])
				table.insert(imgfiles,file)
				uikits.event(imgs[k]:getParent(),function(sender)
					local imagepreview = require "hitmouse2/imagepreview"
					local layout = self._scrollview._scrollview:getInnerContainer()
					self._sc_x,self._sc_y = layout:getPosition()
					uikits.pushScene( imagepreview.create(k,imgfiles) )
				end)
				http.load_image(imgs[k],s.images[k])
			end
		end
	end
end

function worldmatch_vote:relayout()
	self._scrollview:relayout()
end

function worldmatch_vote:release()
	uikits.enableMouseWheelIFWindows(nil)
end

return worldmatch_vote