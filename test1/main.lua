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


	local register = skynet.newservice("SerRegister")
	skynet.call(register,"lua","open",{
		address = skynet.getenv("serRegister_host"),
		port = skynet.getenv("serRegister_port"),
		maxclient = skynet.getenv("serRegister_maxclient"),
		name = skynet.getenv("serRegister_name"),
	})

	local login = skynet.newservice("SerLogin")

	local gate = skynet.newservice("SerGame",login)
	skynet.call(gate,"lua","open",{
		address = skynet.getenv("serGate_host"),
		port = skynet.getenv("serGate_port"),
		maxclient = skynet.getenv("serGate_maxclient"),
		servername = skynet.getenv("serGate_name"),
	})

	
	-- local res = skynet.call("dbmgr","lua","load","test1","where id = 1")
	-- helper.dump(res)
	-- local res = skynet.call("dbmgr","lua","load","user","where uid = ".."'abc'")
	-- helper.dump(res)
	-- skynet.call("dbmgr","lua","stop")


	-- local res = skynet.call("dbmgr","lua","delete","user","where sex = 45")
	-- helper.dump(res)

	-- local res = skynet.call("dbmgr","lua","delete","test1")
	-- helper.dump(res)

	-- local str = {uid = "test1",pass = 123,name = "test1",sex="1"}
	-- local res = skynet.call("dbmgr","lua","add","user",str)
	-- helper.dump(res)

	-- local str = {id = 10,phone = 1,name = "wpp",sex = 3}
	-- local res = skynet.call("dbmgr","lua","update","test1",str,"where id = 4")
	-- helper.dump(res)

	skynet.exit()
end)
