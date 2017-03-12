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

local handler = {}

local socketHandler = {}
local handshake = {}

local function register(msg)
	print(mgs)
	local uid, secret,name,sex = string.match(msg, "([^:]*):([^:]*):([^:]*):([^:]*)")
	local res = skynet.call("dbmgr","load","where uid = "..uid)
	if res[1] then
		socketdriver.send(fd, netpack.pack(b64encode("already have id")))
	else
		skynet.call("dbmgr","add",{ uid = uid,pass = secret,name = name,sex = sex})
		res = socketdriver.send(fd, netpack.pack(b64encode("")))
		if res.affected_rows then
			socketdriver.send(fd, netpack.pack(b64encode("register ok !")))
		elseif res.err then
			socketdriver.send(fd, netpack.pack(b64encode(res.err)))
		else 
			socketdriver.send(fd, netpack.pack(b64encode("some wrong")))
		end
	end
	gateserver.closeclient(fd)
end

local function handlerPhase(fd,msg,sz)
	if handshake[fd].phase == 1 then
		handshake[fd].challenge = crypt.randomkey()
		socketdriver.send(fd, netpack.pack(b64encode(handshake[fd].challenge)))
	elseif handshake[fd].phase == 2 then
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
	elseif handshake[fd].phase == 3 then
		local base64Response = netpack.tostring(msg, sz)
		local hmac = crypt.hmac64(handshake[fd].challenge, handshake[fd].secret)
		if hmac ~= b64decode(base64Response) then
			skynet.error("challenge failed")
			gateserver.closeclient(fd)
		end
	elseif handshake[fd].phase == 4 then
		local base64Msg = netpack.tostring(msg, sz)
		local userMsg = b64decode(base64Msg)
		local res = register(userMsg)
		if res == 1 then 
			--todo
		elseif res
		end
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
end

function handler.disconnect(fd)
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
		local client = handshake[fd]
		if client then
			handlerPhase(fd,msg,sz)
		else
			skynet.error("no handshake")
		end
end



return gameserver.start(handler)