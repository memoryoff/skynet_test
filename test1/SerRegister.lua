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

function socketHandler.register(msg)
	print(mgs)
	local id, secret = string.match(msg, "([^:]*):([^:]*)")
	local res = skynet.call("dbmgr","load","where id = "..id)
	helper.dump(res)
	skynet
end

function handler.command(cmd, source, ...)
		local f = assert(CMD[cmd])
		return f(...)
	end



return gameserver.start(handler)