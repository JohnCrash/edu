require "Cocos2d"
local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"
local md5 = require "md5"
local json = require "json-c"
local resume = require "resume"
local mt = require "mt"

if not kits.exist_file then
	kits.exist_file = kits.exists_file
end

local local_dir = kits.get_local_directory()
local platform = CCApplication:getInstance():getTargetPlatform()
 
local versionNUM = resume.getversion()
--local liexue_server_dl = 'http://dl-lejiaolexue.qiniudn.com/upgrade/luaapp/v'..versionNUM..'/'
--local liexue_server_sr = 'http://file.lejiaolexue.com/upgrade/luaapp/v'..versionNUM..'/'
local liexue_server_dl = 'http://dl-lejiaolexue.qiniudn.com/upgrade/luaapp/debug/'
local liexue_server_sr = 'http://file.lejiaolexue.com/upgrade/luaapp/debug/'
local local_server = 'http://192.168.2.211:81/lgh/v'..versionNUM..'/'
--local local_server = 'http://192.168.2.182/v'..versionNUM..'/'
local update_server
local config_server = kits.config("update_server","get")
if config_server and string.len(config_server)>10 then
	kits.log("===============================")
	kits.log("use configure server:"..config_server)
	kits.log("===============================")
	update_server = config_server
else
	kits.log("===============================")
	kits.log("use default server:"..liexue_server_sr)
	kits.log("===============================")
	update_server = liexue_server_sr
end
kits.config("current_server",update_server )

local ui = {
	FILE = 'loadscreen/jiazhan.json',
	FILE_43 = 'loadscreen/jiazhan43/jiazhan43.json',
	PROGRESS = 'bo2',
	PROGRESS_BG = 'bo',
	EXIT_BUTTON = 'exit',
	TRY_BUTTON = 'try',
	CAPTION = 'text',
}

local function splite(s,ext)
	local i = 0
	local e = 0
	while i do
		i = i+1
		i = string.find(s,ext,i)
		if not i and e ~= 0 then
			return string.sub(s,1,e-1),string.sub(s,e)
		end
		e = i
	end
	return "",s
end

local function runScene( scene )
	if scene then
		director = cc.Director:getInstance()
		if director then
			if director:getRunningScene() then
				director:replaceScene(scene)
			else
				director:runWithScene(scene)
			end
		end
	end
end

local thread_count = 0
local done_count = 0
local download_error_table = {}
local UpdateProgram = class("UpdateProgram")
UpdateProgram.__index = UpdateProgram
--2网络问题，1本地问题，0没有问题，3算法结构问题
local function download_file(t,m5)
	local url
	local local_file
	if m5 then
		local prefix,surfix = splite(t,'%.')
		url = kits.encode_space(liexue_server_dl..prefix..'_'..m5..surfix)
		local_file = local_dir..prefix..'_'..m5..surfix
	else
		url = kits.encode_space(liexue_server_sr..t)
		local_file = local_dir..t..'_'
	end

	if kits.exist_file(local_file) then
		local result = kits.read_file(local_file)
		if result and md5.sumhexa(result)==m5 then
			return true,0
		end
	end
	
	local mh,msg = mt.new('GET',url,'',function(obj)
		if obj.state == 'OK' or obj.state == 'CANCEL' or obj.state == 'FAILED' then
			if obj.state == 'OK' and obj.data then
				if md5.sumhexa(obj.data)==m5 or not m5 then
					if not kits.write_file(local_file,obj.data) then
						--可能没有目录创建目录
						local i = 1
						local dirs = {}
						while i do
							local s = i
							i = string.find(t,'/',i)
							local e = i
							if i then
								table.insert(dirs,string.sub(t,s,e-1))
								i = i + 1
							end
						end
						local dir = local_dir
						for k,v in pairs(dirs) do
							dir = dir..v
							kits.make_directory( dir )
							dir = dir..'/'
						end
						--重新写入
						if not kits.write_file(local_file,obj.data) then
							--非正常结束,不能正常写入
							kits.log('error download_file write file failed '..tostring(url))
							table.insert(download_error_table,{file=t,md5=m5,err=1})
						end
					end
					done_count = done_count + 1
					thread_count = thread_count - 1 --正常结束
				else
					--非正常结束校验错误
					kits.log('error download_file verify md5 failed '..tostring(url))
					table.insert(download_error_table,{file=t,md5=m5,err=2})
					done_count = done_count + 1
					thread_count = thread_count - 1
				end
			else
				--非正常结束FAILED or CANCEL
				kits.log('error download_file failed '..tostring(url))
				table.insert(download_error_table,{download=t,md5=m5,err=3})
				done_count = done_count + 1
				thread_count = thread_count - 1
			end
		end
	end)
	if not mh then
		kits.log('ERROR : download failed url:'..tostring(url))
		kits.log('	reason:'..tostring(msg))
		return false,2 --没有正常启动
	end
	thread_count = thread_count + 1 --正常启动
	return true,0
end

local function download_one_by_one(t)
	if t and t.download then
		return download_file(t.download,t.md5)
	end
	return true,0
end

local function update_one_by_one(t)
	if t then
		if t.download then --做文件删除和改名
			local oldfile =  local_dir..t.download
			local prefix,surfix = splite(t.download,'%.')
			local newfile
			if t.md5 then
				newfile = local_dir..prefix..'_'..t.md5..surfix
			else
				newfile = local_dir..t.download..'_'
			end
			local e,msg = kits.del_file(oldfile)
			if kits.rename_file( newfile,oldfile ) then
				return true,0
			else
				kits.log('ERROR  file failed '..tostring(newfile))
				kits.log('	reason : '..tostring(msg))	
				return false,1					
			end
		elseif t.mkdir then --创建目录
			kits.make_directory(local_dir..t.mkdir)
			return true,0
		elseif t.remove then --做文件删除
			--delete file
			local e,msg = kits.del_file(local_dir..t.remove)
			if not e then
				kits.log('ERROR delete file failed '..tostring(t.remove))
				kits.log('	reason : '..tostring(msg))				
				return false,1
			end
			return true,0
		elseif t.remove_dir then --空目录删除
			--delete directory
			kits.del_directory(local_dir..t.remove_dir)
			return true,0
		else
			kits.log('ERROR update_one_by_one unkown operation')
			return false,3
		end
	else
		kits.log('ERROR update_one_by_one t=nil')
		return false,3
	end
end

function UpdateProgram.create(t)
	if t and type(t)=='table' and t.updates and t.run 
	and type(t.updates)=='table' and type(t.run)=='function' then
		--[[
		if platform==kTargetWindows then
			resume.clearflag("update") --update isok
			local scene = t.run()
			if scene then
				runScene(scene)
				return
			else
				kits.log('ERROR UpdateProgram:init run return nil')
			end		
		end --]]
		
		--需要跟新,打开启动界面
		local scene = cc.Scene:create()
		local layer = uikits.extend(cc.Layer:create(),UpdateProgram)
		
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
		--cc.Director:getInstance():runWithScene(scene)
		runScene(scene)
	else
		kit.log('ERROR UpdateProgram.create invalid param')
	end
end

local TRY = 1

function UpdateProgram:ErrorAndExit(msg,t)
	self._mode = TRY
	self._count = self._count-1
	self._text:setText(msg)
	self._exit:setVisible(true)
	self._try:setVisible(true)
	if t==1 then --正常启动
		self._try:setTitleText("启动")
		uikits.event(self._try,function(sender)
			kits.log('Update complate!')
			local scene = self._args.run()
			--cc.Director:getInstance():replaceScene(scene)
			runScene(scene)
		end)
	elseif t==2 then --退出
		self._try:setEnabled(false)
		self._try:setHighlighted(false)
	end
end

local function build_fast_table(s)
	local fast = {}
	for k,v in pairs(s) do
		fast[v.name] = v.md5
	end
	return fast
end

local function compare_filelist(s,t,d)
	local fast_st = build_fast_table(s)
	local fast_tt = build_fast_table(t)
	local filelist = {}
	--sub operate
	for k,v in pairs(t) do
		if v.name and not fast_st[v.name] then
			filelist[#filelist+1] = {remove=d..'/'..v.name,md5=v.md5}
		end
	end
	--add operate
	for k,v in pairs(s) do
		if v.name  then
			if not fast_tt[v.name] or (fast_tt[v.name] and fast_tt[v.name]~=v.md5) then
				--如果目标不存在该文件，或者目标的md5和原的不相同
				filelist[#filelist+1] = {download=d..'/'..v.name,md5=v.md5}
			end
		end
	end
	return filelist
end

--根据filelist.json来跟新文件
function UpdateProgram:update_directory(dir)
	local n_dir = liexue_server_sr..dir..'/filelist.json'
	local l_dir = local_dir..dir
	local nbuf = kits.http_get(n_dir)
	if not nbuf then
		--self._try:setHighlighted(false)
		--self._try:setEnabled(false)
		kits.log("ERROR : update_directory request "..tostring(n_dir).." failed")
		self:ErrorAndExit("跟新服务器暂时不可用请稍后再试."..tostring(dir),1)
	else
		local n_table = json.decode(nbuf)
		if n_table and type(n_table)=='table' then
			if kits.directory_exists(l_dir) then	--创建本地目录
				kits.make_directory(l_dir)
			end
			--开始读取本地json
			local l_table
			local lbuf = kits.read_file( l_dir..'/filelist.json')
			if lbuf then
				l_table = json.decode(lbuf)
			end
			l_table = l_table or {}
			local op_table = compare_filelist(n_table,l_table,dir)
			for i,v in pairs(op_table) do
				table.insert(self._oplist,v)
			end
			--最后将filelist.json和version.json跟新下
			table.insert(self._oplist,{download=dir..'/filelist.json'})
			table.insert(self._oplist,{download=dir..'/version.json'})
		else
			--self._try:setHighlighted(false)
			--self._try:setEnabled(false)
			self:ErrorAndExit('跟新服务器异常.'..tostring(dir),1)
		end
	end
end

local local_not_exist
function UpdateProgram:NErrorCheckLocal(dir)
	local src_local = local_dir..'src/'..dir..'/filelist.json' 
	if not kits.exist_file( src_local ) then --看看有没有本地版本
		local_not_exist = true
		kits.log("INFO : not exists "..src_local)
		if cc_getNetworkState() == 0 then --没有网络
			self:ErrorAndExit('网络连接错误，请检查您的网络连接再试!'..tostring(dir))
		else
			self:ErrorAndExit('网络或者服务器异常,请稍后再试!'..tostring(dir))
		end
	end
end

function UpdateProgram:get_resource_suffix( test )
	local res_suffix
	if not self._args.res_level or self._args.res_level==0 then --默认
		res_suffix = 'res/'
	elseif self._args.res_level == 1 then
		local Director = cc.Director:getInstance()
		local glview = Director:getOpenGLView()
		local ss = glview:getFrameSize()
		local f = ss.height/ss.width
		if f > (3/4+9/16)/2 then
			res_suffix = "res43/"
		else
			res_suffix = "res169/"
		end		
	elseif self._args.res_level > 1 then
		local Director = cc.Director:getInstance()
		local glview = Director:getOpenGLView()
		local ss = glview:getFrameSize()
		local f = ss.height/ss.width
		local w = math.max(ss.height,ss.width)
		if f > (3/4+9/16)/2 then
			res_suffix = "res43"
		else
			res_suffix = "res169"
		end		
		if w >= 1280 then
			res_suffix = res_suffix..'hd/'
		else
			res_suffix = res_suffix..'/'
		end
	end
	kits.log("INFO luaapp resource redirect to "..res_suffix)
	kits.log("INFO luaapp resource level :"..tostring(self._args.res_level))
	return res_suffix
end

function UpdateProgram:check_directory(dir,n)
		local res_url = update_server..self:get_resource_suffix()..dir..'/version.json'
		local src_url = update_server..'src/'..dir..'/version.json'
		local res_local = local_dir..'res/'..dir..'/version.json'
		local src_local = local_dir..'src/'..dir..'/version.json'
		--只有在确定下载成功的情况下才跟新
		kits.log("check "..tostring(res_url))
		local res = kits.http_get(res_url,'',2)
		if res then
			kits.log("check "..tostring(src_url))
			local src = kits.http_get(src_url,'',2)
			if src then
				local res_v = json.decode(res)
				local src_v = json.decode(src)
				if res_v and src_v and type(res_v)=='table' and type(src_v)=='table'
					and res_v.version and src_v.version then
					--比较本地和网络版本
					local l_res_v = kits.read_file(res_local)
					local l_src_v = kits.read_file(src_local)
					if not l_res_v then return true end --没有本地版本文件，需要跟新
					if not l_src_v then return true end
					local j_res_v = json.decode(l_res_v)
					local j_src_v = json.decode(l_src_v)
					if j_res_v.version and j_src_v.version and
					j_res_v.version==res_v.version and j_src_v.version==src_v.version then
						return false --完全相同不需要跟新
					else
						return true --需要跟新
					end
				else
					kits.log('ERROR check_directory version file error!')
					kits.log('	res version='..tostring(res))
					kits.log('	src version='..tostring(src))
					--网络失败，本机有没有
					if n==2 then
						self:NErrorCheckLocal(dir)
					end
					return false,1 --下传失败,本次不跟新
				end
			else
				kits.log('ERROR check_directory request '..tostring(src_url)..' failed')
				--网络失败，本机有没有
				if n==2 then
					self:NErrorCheckLocal(dir)
				end
				return false,1 --下传失败,本次不跟新
			end
		else
			kits.log('ERROR check_directory request '..tostring(res_url)..' failed')
			--网络失败，本机有没有
			if n==2 then				
				self:NErrorCheckLocal(dir)
			end
			return false,1 --下传失败,本次不跟新
		end
end

function UpdateProgram:check_update(t)
	local outer = false
	t.need_updates={}
	kits.log("INFO check "..tostring(update_server))
	for i,v in pairs(t.updates) do
		local b,e = self:check_directory(v,2)
		if e then --如果网络错误不在等待，直接不跟新
			--尝试使用外网的
			outer = true
			break
		elseif b then
			if v == 'luacore' then
				self._luacore_update = true
			end
			table.insert(t.need_updates,v) --将需要跟新的都加入到，需要跟新列表
		end
	end
	if outer then
		--尝试外网的服务器
		update_server = liexue_server_sr
		kits.log("INFO check "..tostring(update_server))
		t.need_updates={}
		for i,v in pairs(t.updates) do
			local b,e = self:check_directory(v,2)
			if e then --如果网络错误不在等待，直接不跟新
				return false
			elseif b then
				if v == 'luacore' then
					self._luacore_update = true
				end			
				table.insert(t.need_updates,v) --将需要跟新的都加入到，需要跟新列表
			end
		end
		self._text:setText("正在加载请稍等...")
	else
		self._text:setText("正在加载请稍候...")
	end
	return not (#t.need_updates == 0)
end

local try_count = 0
local oplist
local maxcount
function UpdateProgram:update()
	if self._mode==TRY then
		return
	end
	if self._step == 1 then --检查跟新
		self._count = 0
		self._maxcount = 0
		self._oplist = {}
		--不需要跟新直接启动
		if not self:check_update(self._args) then
			resume.clearflag("update") --update isok
			if local_not_exist then return end --如果本地不存在
			
			local b,scene = pcall(self._args.run)
			if b and scene then
				cc.Director:getInstance():replaceScene(scene)
			elseif scene then
				kits.log("ERROR UpdateProgram:update pcall failed")
				kits.log("error message:")
				kits.log(tostring(scene))
				local errmsg = tostring(scene)
				self:ErrorAndExit('没有成功更新('..tostring(self._args.name).."\n"..errmsg.."),\n请检查您的网络",2)
			end
			return
		end
		--收集目录中需要跟新个文件
		for i,v in pairs(self._args.need_updates) do
			self:update_directory(self:get_resource_suffix()..v)
			self:update_directory('src/'..v)
		end
		self._maxcount = #self._oplist
		self._progress:setVisible(true)
		self._progress_bg:setVisible(true)
		self._step = 2
		done_count = 0
		kits.log("Ceck version done")
		kits.log("Download file")
	elseif self._step == 2 then --现在文件，将下载的文件存为临时文件
		if thread_count >=10 then return end --队列满
		
		if self._count <= self._maxcount then
			--self._progress:setPercent(self._count*100/self._maxcount)
			self._progress:setPercent(done_count*100/self._maxcount)
			self._count = self._count+1
		end
		if self._count > self._maxcount then
			if thread_count <= 0 then
				--操作完成
				--检查错误列表，看看是否有没有下载的数据
				if #download_error_table > 0 then
					--有错误，将其重新加载到_oplist，然后继续下载
					if try_count > 3 then --总是重试，次数太多
						self:ErrorAndExit('下载失败，重试次数太多。',2)
						return
					end
					kits.log("INFO : Try download again!")
					self._count = 0
					if not oplist then
						oplist = self._oplist
						maxcount = self._maxcount
					end
					self._oplist = download_error_table
					thread_count = 0
					done_count = 0
					download_error_table = {}
					self._maxcount = #self._oplist
					try_count = try_count + 1
				else
					--没有错误,进入下一个步骤
					self._step = 3
					self._count = 0
					if oplist then
						self._oplist = oplist
						self._maxcount = maxcount
					end
					self._progress:setPercent(0)
					kits.log("Download file done")
					kits.log("Operation file")
				end
			else
				--还有线程在工作等待全部线程结束
			end
		else
			local b,e = download_one_by_one(self._oplist[self._count])
			if not b then
				local t = self._oplist[self._count]
				if e==1 then --本地问题
					self:ErrorAndExit('文件操作失败:'..tostring(t.download))
				elseif e==2 then --网络问题
					self:ErrorAndExit('下载失败:'..tostring(t.download))
				elseif e==3 then --算法问题
					self:ErrorAndExit('跟新出现错误')
				else
					self:ErrorAndExit('未知错误')
				end
			end
		end
	elseif self._step == 3 then		--操作文件，将临时文件重新命名为正式文件
		self._count = self._count+1
		self._progress:setPercent(self._count*100/self._maxcount)
		if self._count > self._maxcount then
			if self._luacore_update then
				--self:ErrorAndExit('本次跟新需要重新启动,请退出再启动程序!',2)
				--要求重新加载这些文件
				package.loaded['kits'] = nil
				package.loaded['uikits'] = nil
				package.loaded['cache'] = nil
				package.loaded['login'] = nil
			end

			kits.log('Update complate!')
			resume.clearflag("update") --update isok
			local b,scene = pcall(self._args.run)
			if b and scene then
				cc.Director:getInstance():replaceScene(scene)
			elseif scene then
				kits.log("ERROR UpdateProgram:update pcall failed!")
				kits.log("error message:")
				kits.log(tostring(scene))
				local text = tostring(self._args.name).."\n"..tostring(scene)
				self:ErrorAndExit('没有成功更新('..text..")",2)
			end		
		else
			self._count = self._count - 1 --抵消上面的+1
			for i=0,10 do --这样做主要是为了加快速度
				self._count = self._count + 1
				if self._count > self._maxcount then
					return
				end
				local b,e = update_one_by_one(self._oplist[self._count])
				if not b then
					local t = self._oplist[self._count]
					if e==1 then --本地问题
						self:ErrorAndExit('文件操作失败:'..tostring(t.download))
						return
					elseif e==2 then --网络问题
						self:ErrorAndExit('下载失败:'..tostring(t.download))
						return
					elseif e==3 then --算法问题
						self:ErrorAndExit('跟新出现错误')
						return
					else
						self:ErrorAndExit('未知错误')
						return
					end
				end
			end
		end
	end
end

function UpdateProgram:init()
	if not self._root then
		self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_43}
		self._progress = uikits.child(self._root,ui.PROGRESS)
		self._exit = uikits.child(self._root,ui.EXIT_BUTTON)
		self._try = uikits.child(self._root,ui.TRY_BUTTON)
		self._text = uikits.child(self._root,ui.CAPTION)
		self._progress_bg = uikits.child(self._root,ui.PROGRESS_BG)
		self._exit:setVisible(false)
		self._try:setVisible(false)
		self:addChild(self._root)
		uikits.event(self._exit,function(sender)
				kits.quit()
			end)
		uikits.event(self._try,function(sender)
				self._exit:setVisible(false)
				self._try:setVisible(false)
				self._mode = nil
				self._text:setText("")
			end)	
	end
	self._step = 1
	kits.log("Ceck version")
	self._progress:setPercent(0)
	self._scheduler = self:getScheduler()
	if self._scheduler then
		self._sid = self._scheduler:scheduleScriptFunc(function()
			self:update()
		end,0,false)
	end
	self._progress:setVisible(false)
	self._progress_bg:setVisible(false)
end

function UpdateProgram:release()
	if self._scheduler and self._sid then
		self._scheduler:unscheduleScriptEntry(self._sid)
		self._sid = nil
	end
end

return UpdateProgram
