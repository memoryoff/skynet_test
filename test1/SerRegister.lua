--
-- Author: hxl
-- Date: 2017-03-10 10:32:14
--
local skynet = require "skynet"
local gateserver = require "snax.gateserver"
local netpack = require "netpack"
local crypt = require "crypt"
local socketdriver = require "socketdriver"
local assert = assert
local b64encode = crypt.base64encode
local b64decode = crypt.base64decode
local helper = require "helper"

local handler = {}

local socketHandler = {}
local handshake = {}

local function register(fd,msg)
	local uid, secret,name,sex = string.match(msg, "([^:]*):([^:]*):([^:]*):([^:]*)")
	print(uid, secret,name,sex)
	local res = skynet.call("dbmgr","lua","load","test1","where uid = "..uid)
	helper.dump(res)
	if next(res) == nil then
		socketdriver.send(fd, netpack.pack(b64encode("mysql error")))
	elseif res[1] then
		socketdriver.send(fd, netpack.pack(b64encode("already have id")))
	else
		res = skynet.call("dbmgr","lua","add","test1",{ uid = uid,pass = secret,name = name,sex = sex})
		if res.affected_rows then
			socketdriver.send(fd, netpack.pack(b64encode("register ok !")))
		elseif res.err then
			socketdriver.send(fd, netpack.pack(b64encode(res.err)))
		else 
			socketdriver.send(fd, netpack.pack(b64encode("some wrong")))
		end
	end
	
end

local function handlerPhase(fd,msg,sz)
	if handshake[fd].phase == 1 then -- 主动向客户端发送挑战
		handshake[fd].challenge = crypt.randomkey()
		local sendData = b64encode(handshake[fd].challenge)
		socketdriver.send(fd, netpack.pack(sendData))
		print("challenge = "..handshake[fd].challenge)
		print("sendData = "..sendData)
		print(helper.hex(handshake[fd].challenge))
	elseif handshake[fd].phase == 2 then -- 等待client发送clientkey，向client发送dhexchange(serverkey),保存secret
		print("receive clientkey")
		local base64ClientKey = netpack.tostring(msg, sz)
		handshake[fd].clientkey = b64decode(base64ClientKey)
		if #handshake[fd].clientkey ~= 8 then
			skynet.error("wrong client link")
			gateserver.closeclient(fd)
			return
		end
		handshake[fd].serverkey = crypt.randomkey()
		socketdriver.send(fd, netpack.pack(b64encode(crypt.dhexchange(handshake[fd].serverkey))))
		handshake[fd].secret = crypt.dhsecret(handshake[fd].clientkey, handshake[fd].serverkey)
	elseif handshake[fd].phase == 3 then-- 接受client发送的hmac，确认挑战是否正确
		print("receive client hmac")
		local base64Response = netpack.tostring(msg, sz)
		local hmac = crypt.hmac64(handshake[fd].challenge, handshake[fd].secret)
		if hmac ~= b64decode(base64Response) then
			socketdriver.send(fd, netpack.pack(b64encode("fail")))
			gateserver.closeclient(fd)
			skynet.error("challenge failed")
		else
			socketdriver.send(fd, netpack.pack(b64encode("ok")))
		end
	elseif handshake[fd].phase == 4 then
		local data = netpack.tostring(msg, sz)
		data = b64decode(data)
		data = crypt.desdecode(handshake[fd].secret, data)
		local res = register(fd,data)
		gateserver.closeclient(fd)
		return
	end
	handshake[fd].phase = handshake[fd].phase + 1
end



function handler.command(cmd, source, ...)
		local f = assert(socketHandler[cmd])
		return f(...)
end


function handler.connect(fd, addr)
		handshake[fd] = {addr,phase = 1}
		gateserver.openclient(fd)
		handlerPhase(fd)
		print("new connect")
end

function handler.disconnect(fd)
	print("disconnect")
	handshake[fd] = nil
	-- local c = connection[fd]
	-- if c then
	-- 	c.fd = nil
	-- 	connection[fd] = nil
	-- 	if conf.disconnect_handler then
	-- 		conf.disconnect_handler(c.username)
	-- 	end
	-- end
end

function handler.message(fd, msg, sz)
		print("recieve msg")
		local client = handshake[fd]
		if client then
			handlerPhase(fd,msg,sz)
		else
			skynet.error("no handshake")
		end

		-- local data = netpack.tostring(msg, sz)
		-- print("data = "..data)

		-- data = "0123456789"
		-- local data = string.pack(">s2",data)
		-- print(type(data))
		-- print(#data)
		-- print(data)
		-- socketdriver.send(fd,data)

		-- print("data = "..string.unpack(">s2",data))
end

function handler.open(source,conf)
	-- for k,v in pairs(conf) do
	-- 	print(k,v)
	-- end
	-- print(SERVICE_NAME)
	-- skynet.register(SERVICE_NAME)
end



return gateserver.start(handler)