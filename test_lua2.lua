local a = require("test_lua")

for k,v in pairs(a) do
	print(tostring(k)..':'..tostring(v))
end
a.fun1()

-- print("hello ")
