-- 商店：购买升级（速度 / 背负数 / 底座数）与重生（清空换永久收入倍率）
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Econ = require(Shared.Econ)
local PlayerData = require(script.Parent.PlayerData)
local BaseService = require(script.Parent.BaseService)
local FieldService = require(script.Parent.FieldService)

local ShopService = {}

local notify: RemoteEvent

function ShopService.init(notifyRemote: RemoteEvent)
	notify = notifyRemote
end

function ShopService.buyUpgrade(player: Player, id: string)
	local p = PlayerData.get(player)
	local u = Config.Upgrades[id]
	if not p or not u then
		return
	end
	local lv = p.upgrades[id]
	if lv >= u.max then
		return
	end
	local price = Econ.upgradePrice(id, lv)
	if p.coins < price then
		notify:FireClient(player, "broke", { need = price })
		return
	end
	PlayerData.addCoins(player, -price)
	p.upgrades[id] = lv + 1
	if id == "slots" then
		BaseService.render(player)
	end
	FieldService.refreshSpeed(player)
	notify:FireClient(player, "upgraded", { id = id, lv = lv + 1 })
	PlayerData.push(player)
end

function ShopService.rebirth(player: Player)
	local p = PlayerData.get(player)
	if not p then
		return
	end
	local cost = Econ.rebirthCost(p.rebirths)
	if p.coins < cost then
		notify:FireClient(player, "broke", { need = cost })
		return
	end
	FieldService.dropAll(player)
	p.rebirths += 1
	p.coins = 0
	p.upgrades = { speed = 0, carry = 0, slots = 0 }
	table.clear(p.owned)
	PlayerData.addCoins(player, 0)
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		ls.Rebirths.Value = p.rebirths
	end
	BaseService.render(player)
	FieldService.refreshSpeed(player)
	notify:FireClient(player, "rebirth", { n = p.rebirths, mult = Econ.rebirthMult(p.rebirths) })
	PlayerData.push(player)
end

return ShopService
