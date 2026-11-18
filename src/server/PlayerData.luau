-- 玩家状态的唯一来源：金币、重生、升级、拥有的角色、图鉴；负责存档与向客户端推送快照
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Econ = require(Shared.Econ)

local PlayerData = {}
PlayerData.profiles = {} :: { [Player]: any }

local store
pcall(function()
	store = DataStoreService:GetDataStore("BrainrotBay_v1")
end)

local stateRemote: RemoteEvent

local function newProfile()
	return {
		coins = Config.START_COINS,
		rebirths = 0,
		upgrades = { speed = 0, carry = 0, slots = 0 },
		owned = {}, -- { {name=, mutation=} }，下标即底座编号
		discovered = {}, -- [name] = true
		carrying = {}, -- 运行时：扛在头上的角色
		lockedUntil = 0,
		lockReadyAt = 0,
		totalEarned = 0,
	}
end

function PlayerData.init(remote: RemoteEvent)
	stateRemote = remote
end

function PlayerData.get(player: Player)
	return PlayerData.profiles[player]
end

function PlayerData.slotCount(p): number
	return Config.BASE_SLOTS + Config.SLOTS_PER_LV * p.upgrades.slots
end

function PlayerData.carryCap(p): number
	return 1 + p.upgrades.carry
end

function PlayerData.walkSpeed(p): number
	return Config.BASE_SPEED + Config.SPEED_PER_LV * p.upgrades.speed
end

-- 基地每秒总收入（不含事件倍率）
function PlayerData.incomePerSecond(p): number
	local sum = 0
	for _, b in p.owned do
		sum += Econ.incomeOf(b.name, b.mutation, p.rebirths)
	end
	return sum
end

function PlayerData.addCoins(player: Player, amount: number)
	local p = PlayerData.profiles[player]
	if not p then
		return
	end
	p.coins += amount
	if amount > 0 then
		p.totalEarned += amount
	end
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		ls.Coins.Value = math.floor(p.coins)
	end
end

-- 把客户端需要的状态打包推送
function PlayerData.push(player: Player)
	local p = PlayerData.profiles[player]
	if not p or not stateRemote then
		return
	end
	local carrying = {}
	for _, c in p.carrying do
		table.insert(carrying, { name = c.name, mutation = c.mutation })
	end
	local found = 0
	for _ in p.discovered do
		found += 1
	end
	stateRemote:FireClient(player, {
		coins = p.coins,
		rebirths = p.rebirths,
		upgrades = p.upgrades,
		owned = p.owned,
		slots = PlayerData.slotCount(p),
		carryCap = PlayerData.carryCap(p),
		carrying = carrying,
		perSecond = PlayerData.incomePerSecond(p),
		discovered = p.discovered,
		found = found,
		lockedUntil = p.lockedUntil,
		lockReadyAt = p.lockReadyAt,
		plot = player:GetAttribute("Plot"),
	})
end

function PlayerData.load(player: Player)
	local p = newProfile()
	if store then
		local ok, saved = pcall(function()
			return store:GetAsync("u" .. player.UserId)
		end)
		if ok and type(saved) == "table" then
			p.coins = saved.coins or p.coins
			p.rebirths = saved.rebirths or 0
			p.upgrades = saved.upgrades or p.upgrades
			p.owned = saved.owned or {}
			p.discovered = saved.discovered or {}
		end
	end
	PlayerData.profiles[player] = p
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = math.floor(p.coins)
	coins.Parent = ls
	local reb = Instance.new("IntValue")
	reb.Name = "Rebirths"
	reb.Value = p.rebirths
	reb.Parent = ls
	ls.Parent = player
	return p
end

function PlayerData.save(player: Player)
	local p = PlayerData.profiles[player]
	if not p or not store then
		return
	end
	pcall(function()
		store:SetAsync("u" .. player.UserId, {
			coins = p.coins,
			rebirths = p.rebirths,
			upgrades = p.upgrades,
			owned = p.owned,
			discovered = p.discovered,
		})
	end)
end

function PlayerData.remove(player: Player)
	PlayerData.save(player)
	PlayerData.profiles[player] = nil
end

return PlayerData
