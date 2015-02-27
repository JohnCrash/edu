--继承链测试
local A={
	init = function(self)
		print("A::init")
		self._a = "asset A _a"
	end,
	release =function(self)
		print("A::release")
		print("A my asset "..self._a)
	end,
	f = function(self)
		print("A::f")
	end,
	a = function(self)
		print("A::a")
	end ,
	c =function(self)
		print("A::c")
	end 
}

local B={
	init = function(self)
		self.super.init(self)
		print("B::init")
		self._b = "asset B _b"
		self._a = "asset B _a"
	end,
	release = function(self)
		self.super.release(self)
		print("B::release")
		print("B'A my asset "..self._a)
		print("B my asset "..self._b)
	end,
	f = function(self)
		print("B::f")
	end,
	b = function(self)
		print("B::b")
	end,
	a = function(self)
		self.super.a(self)
		print("B::a is call")
	end
}

local function newindex(t,k,v)
	print("read-only")
end

local function new_A()
	local a = {}
	A.this = A
	setmetatable(A,{__index=nil,__newindex=newindex})
	setmetatable(a,{__index=A})
	return a
end

local function new_B()
	local b = {}
	B.this = B
	B.super = A	
	setmetatable(B,{__index=A,__newindex=newindex})
	setmetatable(b,{__index=B})
	return b
end

local function isKindOf( instance,class )
	local this = instance
	if this.this == class then return true end
	while  this do
		if this.super == class then
			return true
		end
		this = this.super
	end
	return false
end

--测试
print("test")
local a = new_A()
a:init()
a.this._a = "a"
a:f()
a:a()
a:c()
a:release()
local b = new_B()
b:init()
b.this._a = "a"
b:f()
b:b()
b:a()
b:c()
b:release()
print( "isKindOf(a,B) "..tostring(isKindOf(a,B)) )
print( "isKindOf(a,A) "..tostring(isKindOf(a,A)) )
print( "isKindOf(b,B) "..tostring(isKindOf(b,B)) )
print( "isKindOf(b,A) "..tostring(isKindOf(b,A)) )
print("test end")