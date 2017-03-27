-- local game = require("gameLogic")
-- local room = {{"hxl","wpp","mm"}}
-- local data = game.init(1,room)

local cardUtils = require "cardUtils"

-- for i=1,#data.players do
-- 	print(table.concat(data.players[data.players[i]].resCards," "))
-- end
-- print(table.concat(data.baseCards," "))
-- print("curplayer index = ",data.curPlayIndex)

-- print(game.callLoard(1,data.players[data.curPlayIndex],2))
-- print("curplayer index = ",data.curPlayIndex)

-- print(game.callLoard(1,data.players[data.curPlayIndex],1))
-- print("curplayer index = ",data.curPlayIndex)

-- print(game.callLoard(1,data.players[data.curPlayIndex],0))
-- print("curplayer index = ",data.curPlayIndex)
-- for i=1,#data.players do
-- 	print(table.concat(data.players[data.players[i]].resCards," "))
-- end

-- game.play(1,"mm",{data.players.mm.resCards[5]})

-- for i=1,#data.players do
-- 	print(table.concat(data.players[data.players[i]].resCards," "))
-- end
-- print("curplayer index = ",data.curPlayIndex)

local cardOder = {3,4,5,6,7,8,9,10,11,12,13,1,2,14,15}
local compData = {}
for i=1,#cardOder do
	compData[cardOder[i]] = i
end
local function comp(card1,card2) -- 比较单牌card1是否大于card2
	return compData[card1] > compData[card2]
end



local card = cardUtils.getOriginCard()
print(#card,table.concat(card," "))

table.sort(card,function(c1,c2)
		local v1 = cardUtils.getValue(c1)
		local v2 = cardUtils.getValue(c2)
		if v1 == v2 then
			return c1 < c2			
		elseif comp(v2,v1) then
			return true
		end
		
		return false
	end)

print(#card,table.concat(card," "))