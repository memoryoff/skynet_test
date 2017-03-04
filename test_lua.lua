--
-- Author: hxl
-- Date: 2017-02-26 00:28:33
--
g_teset = 10

local classA = {}
setmetatable(classA,{__index = _G})
 local _ENV = classA 
 


function fun1()

	print("classA:fun1")

end

local function fun2()
	print("classA:fun2")
	end

	g_classA = "classA"

	local l_classA = "classA"

return classA