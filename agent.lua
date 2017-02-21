local skynet = require "skynet"
local netpack = require "netpack"
local socket = require "socket"
local helper = require "helper"

local WATCHDOG
local host
local send_request

local CMD = {}
local REQUEST = {}
local client_fd

function REQUEST:get()
	print("get", self.key)
	local r = skynet.call("SIMPLEDB", "lua", "get", self.key)
	return { result = r }
end

function REQUEST:set()
	print("set", self.key, self.value)
	local r = skynet.call("SIMPLEDB", "lua", "set", self.key, self.value)
end

function REQUEST:handshake()
	return { msg = "Welcome to skynet, I will send heartbeat every 5 sec." }
end

function REQUEST:quit()
	skynet.call(WATCHDOG, "lua", "close", client_fd)
end

local function request(str)
	print("agent recive str = "..str)
	local cmd = helper.unserialize(str)
	for k,v in pairs(cmd) do
		print(k,v)
	end
	local f = assert(REQUEST[cmd.cmd])
	local r = f(cmd)
	return r
end

local function send_package(pack)
	pack = helper.serialize(pack)
	local package = string.pack(">s2", pack)
	socket.write(client_fd, package)
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = skynet.tostring,
	dispatch = function (_, _, str)
		-- if type == "REQUEST" then
		-- 	local ok, result  = pcall(request, str)
		-- 	if ok then
		-- 		if result then
		-- 			send_package(result)
		-- 		end
		-- 	else
		-- 		skynet.error(result)
		-- 	end
		-- else
		-- 	assert(type == "RESPONSE")
		-- 	error "This example doesn't support request client"
		-- end
		local ok, result  = pcall(request, str)
		if ok then
			if result then
				send_package(result)
			end
		else
			skynet.error(result)
		end
	end
}

function CMD.start(conf)
	local fd = conf.client
	local gate = conf.gate
	WATCHDOG = conf.watchdog
	-- skynet.fork(function()
	-- 	while true do
	-- 		send_package(send_request "heartbeat")
	-- 		skynet.sleep(500)
	-- 	end
	-- end)

	client_fd = fd
	skynet.call(gate, "lua", "forward", fd)
end

function CMD.disconnect()
	-- todo: do something before exit
	skynet.exit()
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
