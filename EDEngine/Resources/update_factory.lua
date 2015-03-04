local login = require "login"
local kits = require "kits"
local json = require "json-c"
local ljshell = require "ljshell"
local resume = require "resume"
local mt = require "mt"

local local_dir = ljshell.getDirectory(ljshell.AppDir)
local liexue_server = "http://file.lejiaolexue.com/upgrade/luaapp/v"..resume.getversion().."/"
local local_server = "http://192.168.2.211:81/lgh/v"..resume.getversion().."/"
--返回类的存储根目录
local function getClassRootDirectory()
	return local_dir..'/class/'
end

local function getServerRootDirectory()
	return local_server.."class/"
end

local function deleteClassFile( classId,name )
	local df = getClassRootDirectory()..classId..'/'..tostring(name)
	kits.del_file( df )
end

local function renameClassFile( classId,old,new )
	local o = getClassRootDirectory()..classId..'/'..tostring(old)
	local n = getClassRootDirectory()..classId..'/'..tostring(new)
	kits.rename_file(o,n)
end

local function writeClassFile( classId,jsonFile,buf )
	local df = getClassRootDirectory()..classId..'/'..tostring(jsonFile)
	local file = io.open(df,'wb')
	if file then
		file:write(buf)
		file:close()
		return true
	end
end

local function loadClassJson( classId,jsonFile )
	local df = getClassRootDirectory()..classId..'/'..tostring(jsonFile)
	local file = io.read( df,"rb" )
	if file then
		local all = file:read("*a")
		file:close()
		local destable = json.decode( all )
		return destable
	else
		kits.log("ERROR can not read file "..tostring(df))
	end
end

local function isExisted( classId,name,md5 )
	local df = getClassRootDirectory()..classId..'/'..tostring(name)
	local file = io.read( df,"rb" )
	if file then
		local all = file:read("*a")
		file:close()
		if md5.sumhexa(all) == md5 then
			return true
		end
	end
end

local function request( url,func )
	local mh,msg = mt.new('GET',url,login.cookie(),
			function(obj)
				if obj.state == 'OK' or obj.state == 'CANCEL' or obj.state == 'FAILED'  then
					if obj.state == 'OK' and obj.data then
						func( true,obj.data )
					else
						func( false,obj.errmsg )
					end
				end
			end )
	if not mh then
		func( false,msg )
		kits.log('ERROR : request failed! url = '..tostring(url))
		kits.log('	reason:'..tostring(msg))
	end
end

--[[
检查类版本是否需要跟新
通过func(id)通知结果,id是下面的一个值
2本地存在，需要跟新
1本地不存在，需要跟新
0确定不需要跟新
-1没有正确检查但有本地版本,
-2没有正确检查并且不存在本地版本
--]]
local function CheckClassVersion( classId,func )
	local df = getClassRootDirectory()..classId..'desc.json'
	local isexist = kits.exist_file(df)
	local url = getServerRootDirectory()..classId..'version.json'
	request( url,function(b,data)
		if b then
			if isexist then
				local v = loadClassJson( classId,'version.json')
				local local_v = json.decode(data)
				if local_v and local_v.version then --确定下载成功
					writeClassFile( classId,'version.json~',data)
				end
				if v and v.version and local_v and local_v.version then
					if v.version == local_v then
						func(0)
					else
						func(2)
					end
				else
					func(1)
				end
			else
				func(1)
			end
		else
			if isexist then
				func(-1)
			else
				func(-2)
			end
		end
	end)
end

--[[
跟新类的特定文件，成功func(true),失败func(false)
UpdateClassFiles有一个隐含规则，如果文件名结尾加入~
将寻找下载去除~的文件名，但是存储时加入~
例如下载文件{'depends.json~'},将下载depends.json并存储
为depends.json~
UpdateClassFiles的files可以有两种格式
{'file1','file2'}
{[1]={name='file1',md5=''}} 需要额外的校验
如果isTemp=true,文件后面都相当于加入~
progress是一个进度回调，第一参数为一个0~1的数表示进度
第二参数是表述字串
--]]
local function UpdateClassFiles( classId,func,files,isTemp,progress )
	local function getRealName( v )
		if string.sub(v,-1) == '~' then
			return string.sub(v,0,-2)
		else
			return v
	end
	local function progressFunc(d,txt)
		if progress then
			progress(d,txt or '')
		end
	end
	local ut = {}
	local count = 0
	local total = 0
	for k,v in pairs(files) do
		if type(v)=='table' then
			if isTemp then v.name = v.name..'~' end
			local name = getRealName( v.name )
			local url = getServerRootDirectory()..classId..'/'..name
			if not isExisted(classId,v.name,v.md5) then
				ut[v] = {url=url,readName=name,writeName=v.name,md5=v.md5}
				total = total + 1
			end
		else
			local name = getRealName( v )
			local url = getServerRootDirectory()..classId..'/'..name
			ut[v] = {url=url,readName=name,writeName=v}
			total = total + 1
		end		
	end
	local trycount = 0
	local function isalldown()
		total = 0
		for k,v in pairs(ut) do
			if not v.result then
				total = total + 1
			end
		end
		return total == 0
	end
	local function download()
		for k,v in pairs(ut) do
			if not v.result then
				request( v.url,function(b,data)
						count = count + 1
						if trycount==0 then
							progressFunc( count/total,v.readName )
						end
						if v.md5 and b then
							if md5.sumhexa(data)~=v.md5 then
								kits.log("WARNING UpdateClassFiles checksum failed!"..tostring(v.readName))
								b = false
							end
						end
						ut[v].result = b
						if b then
							writeClassFile(classId,v.writeName,data)
						end
						if count == total then
							if isalldown() then
								progressFunc(1)
								func(true)
							elseif trycount < 3 then
								count = 0
								trycount = trycount + 1
								download()
							else
								func(false)
							end
						end
				end )
			end
		end
	end
	if total == 0 then
		progressFunc(1)
		func(true)
	else
		progressFunc(0)
		download()
	end
end

--[[
成功func(true),失败func(false)
progress是一个进度回调，第一参数为一个0~1的数表示进度
第二参数是表述字串
--]]
local function UpdateClass( classId,func,progress )
	local delete_files = {}
	local update_files
	local function complete(b)
		if b and update_files then
			for k,v in pairs(delete_files) do
				deleteClassFile( classId,v )
			end
			for k,v in pairs(update_files) do
				deleteClassFile( classId,v.name )
				renameClassFile( classId,v.name..'~',v.name )
			end
			func(true)
		else
			func(false)
		end
	end
	local function build_fast_table(s)
		local fast = {}
		for k,v in pairs(s) do
			if v.name and v.md5 then
				fast[v.name] = v.md5
			else
				kits.log("ERROR UpdateClass local filelist.json file corruption")
				kits.log("	classId="..tostring(classId))
			end
		end
		return fast
	end
	local function different( l,r )
		local result = {}
		local fast_l = build_fast_table(l)
		local fast_r = build_fast_table(r)
		--sub operate
		for k,v in pairs(l) do
			if v.name and not fast_r[v.name] then
				table.insert(delete_files,v.name)
			end
		end
		--add operate
		for k,v in pairs(r) do
			if v.name and v.md5 then
				if not fast_l[v.name] or (fast_l[v.name] and fast_l[v.name]~=v.md5) then
					table.insert(result,v)
				end
			else
				kits.log("ERROR UpdateClass remote filelist.json file corruption")
				kits.log("	classId="..tostring(classId))			
			end
		end
		return result
	end
	local function compare( b )
		if b then
			local local_list = loadClassJson( classId,'filelist.json' )
			local remote_list = loadClassJson( classId,'filelist.json~' )
			if remote_list then
				if local_list then
					update_files = differnet(local_list,remote_list)					
				else
					update_files = remote_list
				end
				UpdateClassFiles(classId,complete,update_files,true,progress)
			else
				kits.log("ERROR UpdateClass decode error,filelist.json")
				kits.log("	classId="..tostring(classId))
				func(false)
			end
		else
			kits.log('ERROR UpdateClass can not download filelist.json')
			kits.log("	classId="..tostring(classId))
			func(false)
		end
	end
	UpdateClassFiles( classId,compare,{'filelist.json'},true,progress)
end

--[[
跟新表中全部的类
成功func(true),失败func(false)
progress是一个进度回调，第一参数为一个0~1的数表示进度
第二参数是表述字串
--]]
local function UpdateClassByTable( classIds,func,progress )
	local i = 1
	local N = #classIds
	local progressValue = 0
	local function progressFunc( d,txt )
		if progress then
			progress( d,txt or '' )
		end
	end
	local function progressSubFunc( d,txt )
		progressValue = d/N+progressValue
		progressFunc(progressValue,txt)
	end
	local function onResult(b)
		if b then
			if classIds[i+1] then
				i=i+1
				progressValue = (i-1)/N
				progressFunc(progressValue,classIds[i])				
				UpdateClass(classIds[i],onResult,progressSubFunc )
			else
				func(true)
				progressFunc(1)
			end
		else
			func(false)
		end
	end
	if N>0 then
		progressValue = (i-1)/N
		progressFunc(progressValue,classIds[1])	
		UpdateClass(classIds[1],onResult,progressSubFunc )
	else
		func(true)
		progressFunc(1)
	end
end

return {
	CheckClassVersion = CheckClassVersion,
	UpdateClass = UpdateClass,
	loadClassJson = loadClassJson,
	UpdateClassByTable = UpdateClassByTable,
	UpdateClassFiles = UpdateClassFiles,
	getClassRootDirectory = getClassRootDirectory,
}