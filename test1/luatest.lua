local game = require("gameLogic")
local room = {{"hxl","wpp","mm"}}
local data = game.init(1,room)

for i=1,#data.players do
	print(table.concat(data.players[data.players[i]].resCards," "))
end
print(table.concat(data.baseCards," "))
print("curplayer index = ",data.curPlayIndex)

print(game.callLoard(1,data.players[data.curPlayIndex],2))
print("curplayer index = ",data.curPlayIndex)

print(game.callLoard(1,data.players[data.curPlayIndex],1))
print("curplayer index = ",data.curPlayIndex)

print(game.callLoard(1,data.players[data.curPlayIndex],0))
print("curplayer index = ",data.curPlayIndex)
for i=1,#data.players do
	print(table.concat(data.players[data.players[i]].resCards," "))
end

game.play(1,"mm",{data.players.mm.resCards[5]})

for i=1,#data.players do
	print(table.concat(data.players[data.players[i]].resCards," "))
end
print("curplayer index = ",data.curPlayIndex)