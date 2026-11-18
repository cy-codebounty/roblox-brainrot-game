-- 基地：分配地皮、底座上摆放角色、每秒产金币、出售、上锁护盾
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Econ = require(Shared.Econ)
local BrainrotModel = require(Shared.BrainrotModel)
local PlayerData = require(script.Parent.PlayerData)

local BaseService = {}
BaseService.plots = {}
BaseService.owner = {} :: { [number]: Player }
BaseService.incomeMult = 1 -- 事件（双倍收入）修改

local notify: RemoteEvent

function BaseService.init(plots, notifyRemote: RemoteEvent)
	BaseService.plots = plots
	notify = notifyRemote
	for _, plot in plots do
		plot.lockPrompt.Triggered:Connect(function(player)
			if BaseService.owner[plot.index] == player then
				BaseService.lock(player)
			end
		end)
	end
end

function BaseService.plotOf(player: Player)
	local i = player:GetAttribute("Plot")
	return i and BaseService.plots[i]
end

-- 重绘某玩家底座上的全部角色
function BaseService.render(player: Player)
	local plot = BaseService.plotOf(player)
	local p = PlayerData.get(player)
	if not plot or not p then
		return
	end
	local slots = PlayerData.slotCount(p)
	for i, ped in plot.pedestals do
		local old = ped.part:FindFirstChild("Brainrot")
		local entry = p.owned[i]
		ped.part.Transparency = i <= slots and 0 or 0.85
		ped.part.Color = i <= slots and Color3.fromRGB(255, 244, 210) or Color3.fromRGB(80, 80, 80)
		local key = entry and (entry.name .. "|" .. entry.mutation) or nil
		if old and old:GetAttribute("Key") ~= key then
			old:Destroy()
			old = nil
		end
		if entry and not old then
			local m = BrainrotModel.build(entry.name, entry.mutation)
			m.Name = "Brainrot"
			m:SetAttribute("Key", key)
			m:SetAttribute("Owner", player.UserId)
			m:SetAttribute("Slot", i)
			m:PivotTo(ped.cframe)
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Sell $" .. Econ.format(Econ.sellValue(entry.name, entry.mutation))
			prompt.ObjectText = entry.name
			prompt.KeyboardKeyCode = Enum.KeyCode.F
			prompt.HoldDuration = 0.8
			prompt.MaxActivationDistance = 8
			prompt.RequiresLineOfSight = false
			prompt.Parent = m.PrimaryPart
			prompt.Triggered:Connect(function(who)
				if who == player then
					BaseService.sell(player, i)
				end
			end)
			m.Parent = ped.part
			old = m
		end
		if old and entry then
			BrainrotModel.setIncomeText(old, Econ.incomeOf(entry.name, entry.mutation, p.rebirths))
		end
	end
end

function BaseService.assign(player: Player)
	for i = 1, #BaseService.plots do
		if not BaseService.owner[i] then
			BaseService.owner[i] = player
			player:SetAttribute("Plot", i)
			BaseService.plots[i].label.Text = string.upper(player.DisplayName) .. "'S BASE"
			BaseService.render(player)
			return BaseService.plots[i]
		end
	end
	return nil
end

function BaseService.release(player: Player)
	local plot = BaseService.plotOf(player)
	if not plot then
		return
	end
	BaseService.owner[plot.index] = nil
	plot.label.Text = "EMPTY PLOT"
	plot.shield.Transparency = 1
	for _, ped in plot.pedestals do
		local m = ped.part:FindFirstChild("Brainrot")
		if m then
			m:Destroy()
		end
	end
end

-- 放到空底座；没位置返回 false
function BaseService.place(player: Player, name: string, mutation: string): boolean
	local p = PlayerData.get(player)
	if #p.owned >= PlayerData.slotCount(p) then
		return false
	end
	table.insert(p.owned, { name = name, mutation = mutation })
	local isNew = not p.discovered[name]
	p.discovered[name] = true
	BaseService.render(player)
	notify:FireClient(player, "placed", { name = name, mutation = mutation, new = isNew })
	return true
end

function BaseService.sell(player: Player, slot: number)
	local p = PlayerData.get(player)
	local entry = p and p.owned[slot]
	if not entry then
		return
	end
	table.remove(p.owned, slot)
	local value = Econ.sellValue(entry.name, entry.mutation)
	PlayerData.addCoins(player, value)
	BaseService.render(player)
	notify:FireClient(player, "sold", { name = entry.name, value = value })
	PlayerData.push(player)
end

function BaseService.isLocked(player: Player): boolean
	local p = PlayerData.get(player)
	return p ~= nil and workspace:GetServerTimeNow() < p.lockedUntil
end

function BaseService.lock(player: Player)
	local p = PlayerData.get(player)
	local plot = BaseService.plotOf(player)
	if not p or not plot or workspace:GetServerTimeNow() < p.lockReadyAt then
		return
	end
	p.lockedUntil = workspace:GetServerTimeNow() + Config.LOCK.duration
	p.lockReadyAt = p.lockedUntil + Config.LOCK.cooldown
	plot.shield.Transparency = 0.55
	plot.lockPad.Color = Color3.fromRGB(80, 255, 120)
	notify:FireClient(player, "locked", { duration = Config.LOCK.duration })
	PlayerData.push(player)
	task.delay(Config.LOCK.duration, function()
		if BaseService.plotOf(player) == plot then
			plot.shield.Transparency = 1
			plot.lockPad.Color = Color3.fromRGB(255, 60, 60)
		end
	end)
end

-- 每秒结算收入
function BaseService.tick()
	for player, p in PlayerData.profiles do
		local amount = PlayerData.incomePerSecond(p) * BaseService.incomeMult
		if amount > 0 then
			PlayerData.addCoins(player, amount)
		end
		PlayerData.push(player)
	end
end

return BaseService
