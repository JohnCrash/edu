local fio
local se = {}

local tab = 
{
	[0] = '',
	'\t',
	'\t\t',
	'\t\t\t',
	'\t\t\t\t',
	'\t\t\t\t\t',
	'\t\t\t\t\t\t',
	'\t\t\t\t\t\t\t',
	'\t\t\t\t\t\t\t\t',
}
local function out( s,n )
	if fio then
		n = n or 1
		if n > 8 then n = 8 end
		fio:write( tab[n]..tostring(s)..'\n' )
	end
end

local function put_begin( f,msg )
	se = {}
	fio = io.open( f,'w+' )
	out( tostring(msg)..'={',0 )
end

local function put_end()
	if fio then
		out('}',0 )
		fio:close()
	end
end


local function put_table( t,n )
	n = n or 1
	if n > 8 then
		out( 'deep level > 8 ...' )
		return
	end
	if t and type(t) == 'table' then
		se[t] = 1
		for k,v in pairs(t) do
			if v and type(v) == 'table' and not se[v] then
				se[v] = 1
				out( '['..tostring(k)..']='..tostring(v)..'{',n )
				put_table( v,n+1 )
				out( '}'..tostring(k),n )
				local mt = getmetatable( v )
				if mt then --如果该表有一个元表，打印他
					out( '['..tostring(v)..'](metatable)'..tostring(mt)..'{',n )
					put_table( mt,n+1 )
					out( '}'..tostring(v),n )
				end
			elseif v and type(v) == 'userdata' and not se[v] then
				se[v] = 1
				out( '['..tostring(k)..']='..tostring(v)..'{',n )
				put_table( getmetatable( v ),n+1 )
				out( '}'..tostring(k),n )			
			else
				out( '['..tostring(k)..']\t\t= '..tostring( v )..',',n )
				if v and (type(v)=='table' or type(v)=='userdata') then
					local mt = getmetatable( v )
					if mt and not se[mt] then
						se[mt] = 1
						out( '['..tostring(v)..'](metatable)'..tostring(mt)..'{',n )
						put_table( mt,n+1 )
						out( '}'..tostring(v),n )
					else
						out( '['..tostring(v)..'](metatable)'..tostring(mt),n )
					end
				end
			end
		end
	end
end

return {
	put_begin = put_begin,
	put_end = put_end,
	put_table = put_table,
}