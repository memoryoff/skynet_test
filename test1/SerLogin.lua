--
-- Author: hxl
-- Date: 2017-03-15 15:16:33
--
local login = require "snax.loginserver"
local crypt = require "crypt"
local skynet = require "skynet"
local helper = require "helper"

local server = {
	host = skynet.getenv("serLogin_host"),
	port = skynet.getenv("serLogin_port"),
	multilogin = skynet.getenv("serLogin_multilogin"),
	name = skynet.getenv("serLogin_name"),
}

local server_list = {}
local user_online = {}
local user_login = {}

function server.auth_handler(token)
	-- the token is base64(user)@base64(server):base64(password)
	local user,password = token:match("([^:]*):([^:]*)")

	local res = skynet.call("dbmgr","lua","load","user","where uid = ".."'"..user.."'".." and ".."pass = ".."'"..password.."'")
	helper.dump(res)
	if res == nil or next(res) == nil then
		error("not the user or invalid password")
	end
	
	local server = skynet.call(".serLogin","lua","getfirst_gate")
	return server, user
end

function server.login_handler(server, uid, secret)
	print(string.format("%s@%s is login, secret is %s", uid, server, crypt.hexencode(secret)))
	local gameserver = assert(server_list[server], "Unknown server")
	-- only one can login, because disallow multilogin
	local last = user_online[uid]
	if last then
		skynet.call(last.address, "lua", "kick", uid, last.subid)
	end
	if user_online[uid] then
		error(string.format("user %s is already online", uid))
	end

	local subid = tostring(skynet.call(gameserver, "lua", "login", uid, secret))
	user_online[uid] = { address = gameserver, subid = subid , server = server}
	print("subid = ",subid)
	return subid
end

local CMD = {}

function CMD.register_gate(server, address)
	server_list[server] = address
end

function CMD.getfirst_gate()
	return next(server_list)
end

function CMD.logout(uid, subid)
	local u = user_online[uid]
	if u then
		print(string.format("%s@%s is logout", uid, u.server))
		user_online[uid] = nil
	end
end

function server.command_handler(command, ...)
	print("command = "..command)
	local f = assert(CMD[command])
	return f(...)
end

login(server)
