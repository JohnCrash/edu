local mt = require "mt"

--local result = mt.do_curl("GET","http://www.google.com","")
local function progress( obj )
	print( obj.state.."	"..obj.progress )

	if obj.state == "CANCEL" then
		print( "err code : "..obj.errcode )
		print( "err string : "..obj.errmsg )
	elseif obj.state == "FAILED" then
		print( "err code : "..obj.errcode )
		print( "err string : "..obj.errmsg )		
		print( "restart .... " )
		print( "offset : "..(obj.size/1024).." K")
		if obj.errcode == 33 then
			print( "服务器不支持断点续传!" )
		else
			obj:restart()
		end
	elseif obj.state == "OK" then
		print( "File Size :" .. obj.size )
		kits.write_local_file( "mindterm_4.1.5-doc.zip",obj.data )
	end
end

--local mh,msg = mt.new('GET','http://tech.cryptzone.com/download/MindTerm-4.1.5/mindterm_4.1.5-doc.zip','',progress)
local mh,msg = mt.new('GET','ftp://sourceware.org/pub/pthreads-win32/pthreads-w32-2-9-1-release.zip','',progress)

if mh then
	print( "State:"..mh.state  )
end
print("=====================")
print( mh )
print( msg )
print("=====================")