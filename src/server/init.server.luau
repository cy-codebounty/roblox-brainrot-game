-- 服务端入口：建图、创建远程事件、串起各服务、处理玩家进出与客户端请求
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldBuilder = require(script.WorldBuilder)
local PlayerData = require(script.PlayerData)
local BaseService = require(script.BaseService)
local FieldService = require(script.FieldService)
local WaveService = require(script.WaveService)
local EventService = require(script.EventService)
local ThiefService = require(script.ThiefService)
local ShopService = require(script.ShopService)

local function remote(name: string): RemoteEvent
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = ReplicatedStorage
	return r
end
local stateRemote = remote("State")
local notifyRemote = remote("Notify")
local requestRemote = remote("Request")

local plots = WorldBuilder.build()
PlayerData.init(stateRemote)
BaseService.init(plots, notifyRemote)
FieldService.init(notifyRemote)
WaveService.init(notifyRemote)
ThiefService.init(notifyRemote)
ShopService.init(notifyRemote)
WaveService.onWaveEnd = function()
	EventService.trigger()
end
ReplicatedStorage:SetAttribute("EventName", "")
ReplicatedStorage:SetAttribute("ThiefTarget", 0)

local function onCharacter(player: Player, char: Model)
	local plot = BaseService.plotOf(player)
	local hum = char:WaitForChild("Humanoid") :: Humanoid
	char:WaitForChild("HumanoidRootPart")
	task.wait()
	if plot then
		char:PivotTo(plot.spawnCF)
	end
	FieldService.refreshSpeed(player)
	hum.Died:Connect(function()
		FieldService.dropAll(player, "fell")
	end)
end

local function onPlayer(player: Player)
	PlayerData.load(player)
	BaseService.assign(player)
	player.CharacterAdded:Connect(function(char)
		onCharacter(player, char)
	end)
	if player.Character then
		task.spawn(onCharacter, player, player.Character)
	end
	PlayerData.push(player)
end

Players.PlayerAdded:Connect(onPlayer)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayer, player)
end
Players.PlayerRemoving:Connect(function(player)
	FieldService.dropAll(player)
	BaseService.release(player)
	PlayerData.remove(player)
end)

-- 客户端请求（简单限流）
local lastRequest = {} :: { [Player]: number }
requestRemote.OnServerEvent:Connect(function(player, action, arg)
	local now = os.clock()
	if lastRequest[player] and now - lastRequest[player] < 0.15 then
		return
	end
	lastRequest[player] = now
	if action == "upgrade" and type(arg) == "string" then
		ShopService.buyUpgrade(player, arg)
	elseif action == "rebirth" then
		ShopService.rebirth(player)
	elseif action == "lock" then
		BaseService.lock(player)
	elseif action == "home" then
		local plot = BaseService.plotOf(player)
		if plot and player.Character and not player.Character:GetAttribute("WipedOut") then
			FieldService.dropAll(player, "home")
			player.Character:PivotTo(plot.spawnCF)
		end
	elseif action == "sync" then
		PlayerData.push(player)
	end
end)

-- 每秒产金币
task.spawn(function()
	while true do
		task.wait(1)
		BaseService.tick()
	end
end)

-- 自动存档
task.spawn(function()
	while true do
		task.wait(90)
		for _, player in Players:GetPlayers() do
			PlayerData.save(player)
		end
	end
end)
game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		PlayerData.save(player)
	end
end)
