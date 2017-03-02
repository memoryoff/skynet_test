package.cpath = "F:/skynet-vs2013new/luaclib/?.so"
package.path = "F:/skynet-vs2013new/lualib/?.lua;F:/skynet-vs2013new/mypro/?.lua"


if _VERSION ~= "Lua 5.3" then
	error "Use lua 5.3"
end
local helper = require "helper"
local socket = require "clientsocket"

print("hello 1 ")
local fd = assert(socket.connect("127.0.0.1", 8888))

print("hello 2")

local function send_package(fd, pack)
	print(pack.. " "..#pack)
	local package = string.pack(">s2", pack)
	print(helper.hex(package,10))
	socket.send(fd, package)
end

local function unpack_package(text)
	local size = #text
	if size < 2 then
		return nil, text
	end
	local s = text:byte(1) * 256 + text:byte(2)
	if size < s+2 then
		return nil, text
	end

	return text:sub(3,2+s), text:sub(3+s)
end

local function recv_package(last)
	local result
	result, last = unpack_package(last)
	if result then
		return result, last
	end
	local r = socket.recv(fd)
	if not r then
		return nil, last
	end
	if r == "" then
		error "Server closed"
	end
	return unpack_package(last .. r)
end

local session = 0

local function send_request(args)
	session = session + 1
	local str = helper.serialize(args)
	send_package(fd, str)
	print("Request:", session)
end

local last = ""

local function print_package(t)

	print("response =" ..t)
end

local function dispatch_package()
	while true do
		local v
		v, last = recv_package(last)
		if not v then
			break
		end

		print_package(v)
	end
end
print("hello 2")
send_request{cmd = "handshake"}
send_request{cmd = "set", key = "name", value = "hxl" }
while true do
	dispatch_package()
	local cmd = socket.readstdin()
	local cmdtbl = helper.split(cmd,' ')
	if cmdtbl then
		if cmdtbl[1] == "quit" then
			send_request{cmd = "quit"}
		elseif cmdtbl[1] == "get" then
			send_request{cmd = cmdtbl[1], key = cmdtbl[2]}
		elseif cmdtbl[1] == "set" then
			send_request{cmd = cmdtbl[1], key = cmdtbl[2],value = cmdtbl[3]}
		end
	else
		socket.usleep(100)
	end
end

print("hello")