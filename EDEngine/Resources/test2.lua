local words = {"hello","world","good","bye","end"}
local count = 1
local function printa(a,n)
	print("a = "..tostring(a).." n = "..tostring(n))
	for i=1,10 do
		if count > #words then
			count = 1
		end
		local b,i,w = post(count,words[count])
		print( "ii="..tostring(i).."  ww="..tostring(w))
		count = count + 1
	end
end

return printa