local skynet = require "skynet"
require "skynet.manager"
local mysql = require "mysql"

local CMD = {}
local pool = {}

local maxconn
local index = 0
local function getconn(sync)
	index = index % maxconn + 1
	return pool[index]
end

function CMD.start()
	maxconn = tonumber(skynet.getenv("mysql_maxconn")) or 10
	assert(maxconn >= 2)
	for i = 1, maxconn do
		local db = mysql.connect{
			host = skynet.getenv("mysql_host"),
			port = tonumber(skynet.getenv("mysql_port")),
			database = skynet.getenv("mysql_db"),
			user = skynet.getenv("mysql_user"),
			password = skynet.getenv("mysql_pwd"),
			max_packet_size = 1024 * 1024
		}
		if db then
			table.insert(pool, db)
			db:query("set charset utf8")
		else
			skynet.error("mysql connect error")
		end
	end
end

function CMD.execute(sql)
	local db = getconn(sync)
	local ok,res, err, errno, sqlstate = pcall(db.query,db,sql)
	if not ok then
		skynet.error(res)
		return
	end
	if not res then
		skynet.error("execute sql error : ".. res.. " , errno : ".. errno.." sqlstate : ".. sqlstate)
		return db:disconnect()
	end
	return res
end

function CMD.stop()
	for _, db in pairs(pool) do
		db:disconnect()
	end
	-- pool = {}
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = assert(CMD[cmd], cmd .. "not found")
		skynet.retpack(f(...))
	end)

	skynet.register(SERVICE_NAME)
end)
