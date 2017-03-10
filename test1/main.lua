--
-- Author: hxl
-- Date: 2017-03-10 10:32:56
--

local skynet = require "skynet"
local helper = require "helper"

local max_client = 64

skynet.start(function()
	skynet.error("Server start")
	if not skynet.getenv "daemon" then
		local console = skynet.newservice("console")
	end
	skynet.newservice("debug_console",8000)
	
	skynet.newservice("dbmgr")
	skynet.call("dbmgr", "lua", "start")


	-- local res = skynet.call("dbmgr","lua","load","test1","where sex = 6")
	-- helper.dump(res)

	-- local res = skynet.call("dbmgr","lua","delete","test1","where sex = 45")
	-- helper.dump(res)

	-- local res = skynet.call("dbmgr","lua","delete","test1")
	-- helper.dump(res)

	-- local str = {id = 1,phone = 1,name = 5,sex = 3}
	-- local res = skynet.call("dbmgr","lua","add","test1",str)
	-- helper.dump(res)

	local str = {id = 10,phone = 1,name = "wpp",sex = 3}
	local res = skynet.call("dbmgr","lua","update","test1",str,"where id = 4")
	helper.dump(res)

	skynet.exit()
end)
