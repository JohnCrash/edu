local json = require 'json'
local lfs = require 'lfs'

local function read_local_file( name )
  local file = name
  local alls
  for line in io.lines(file) do
    if not alls then
      alls = line
    else
      alls = alls..line
    end
  end
  return alls
end

local function resize_widget( w,t )
	if w and w.options then
		w.options.width = w.options.width/2
		w.options.height = w.options.height/2
		w.options.x = w.options.x/2
		w.options.y = w.options.y/2
	end
	if w and w.children and type(w.children) == 'table' then
		for m,n in pairs(w.children) do
			if type(n) == 'table' then
				resize_widget( n )
			end
		end	
	end	
end

local function write_local_file( name,buf )
  local filename = name
  local file = io.open(filename,'wb')
  if file then
    file:write(buf)
    file:close()
  else
     --local file error?
     cclog('Can not write file '..filename)
  end
end

local function json_format( )
end

function resize_json( file )
	local s = read_local_file( file )
	local t = json.decode( s )
	if type(t)=='table' then
		for k,v in pairs(t) do
			if k == 'designHeight' then
				t[k] = v/2
			elseif k == 'designWidth' then
				t[k] = v/2
			elseif k == 'widgetTree' and type(v) == 'table' then
				for i,j in pairs(v) do
					if i == 'children' and type(j) == 'table' then
						for m,n in pairs(j) do
							if type(n) == 'table' then
								resize_widget( n,t )
							end
						end
					end
				end
			end
		end
	end
	s = json.encode( t )
	
	write_local_file( file,s )
end

--resize_json('D:/1Source/Edu/EDEngine/proj.win32/Debug.win32/res/amouse/jie_mian_4/jie_mian_4.json')
--local function resize_image( d )
--	local lfs.dir( d )
--end

