-- 小偷 NPC“鸽子大盗 Pinchy”：定期潜入某个基地偷走一只角色往海边逃；上锁可挡，撞到它可夺回
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local BrainrotModel = require(Shared.BrainrotModel)
local Econ = require(Shared.Econ)
local PlayerData = require(script.Parent.PlayerData)
local BaseService = require(script.Parent.BaseService)

local ThiefService = {}

local rng = Random.new()
local notify: RemoteEvent

local function buildThief(): Model
	local m = Instance.new("Model")
	m.Name = "Pinchy the Pigeon Burglar"
	local function p(size: Vector3, offset: CFrame, color: Color3, ball: boolean?)
		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.Size = size
		part.Color = color
		part.Material = Enum.Material.SmoothPlastic
		part.CFrame = offset
		if ball then
			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent = part
		end
		part.Parent = m
		return part
	end
	local root = p(Vector3.new(4, 5, 4), CFrame.new(0, 4, 0), Color3.fromRGB(150, 150, 170), true)
	root.Name = "Root"
	root.PivotOffset = CFrame.new(0, -4, 0)
	m.PrimaryPart = root
	p(Vector3.new(3, 3, 3), CFrame.new(0, 7.5, -0.6), Color3.fromRGB(120, 200, 160), true)
	p(Vector3.new(3.2, 0.9, 3.2), CFrame.new(0, 7.8, -0.6), Color3.fromRGB(20, 20, 25))
	p(Vector3.new(0.8, 0.6, 1.6), CFrame.new(0, 7.2, -2.6), Color3.fromRGB(255, 170, 40))
	for _, x in { -0.7, 0.7 } do
		p(Vector3.new(0.6, 0.6, 0.3), CFrame.new(x, 7.9, -2.2), Color3.fromRGB(255, 255, 255), true)
		p(Vector3.new(0.4, 1.8, 0.4), CFrame.new(x, 0.9, 0), Color3.fromRGB(255, 140, 40))
	end
	p(Vector3.new(3, 3, 3), CFrame.new(0, 4.5, 2.4), Color3.fromRGB(200, 170, 110), true).Name = "Sack"
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(200, 40)
	bb.StudsOffset = Vector3.new(0, 7, 0)
	bb.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.Arcade
	t.TextScaled = true
	t.Text = "THIEF! TOUCH TO STOP"
	t.TextColor3 = Color3.fromRGB(255, 80, 80)
	t.TextStrokeTransparency = 0
	t.Parent = bb
	bb.Parent = root
	return m
end

-- 让小偷沿直线走到目标；途中返回 true 表示被玩家撞到
local function walk(thief: Model, from: Vector3, to: Vector3, speed: number, carried: Model?): boolean
	local dist = (to - from).Magnitude
	local t0 = os.clock()
	while true do
		local a = math.min(1, (os.clock() - t0) * speed / dist)
		local pos = from:Lerp(to, a)
		local hop = math.abs(math.sin(os.clock() * 12)) * 1.2
		thief:PivotTo(CFrame.lookAt(pos, to + Vector3.new(0, 0, 0.001)) * CFrame.new(0, hop, 0))
		if carried then
			carried:PivotTo(thief:GetPivot() * CFrame.new(0, 9.5, 0))
		end
		for _, player in Players:GetPlayers() do
			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if hrp and (hrp.Position - pos).Magnitude < 7 then
				return true, player
			end
		end
		if a >= 1 then
			return false
		end
		RunService.Heartbeat:Wait()
	end
end

-- 一次完整的偷窃：潜入 → 偷 → 逃跑
local function heist(victim: Player)
	local plot = BaseService.plotOf(victim)
	local p = PlayerData.get(victim)
	if not plot or not p or #p.owned == 0 then
		return
	end
	local thief = buildThief()
	local start = Vector3.new(70, 0, plot.center.Z)
	local gate = Vector3.new(plot.center.X + plot.size.X / 2 + 3, 0, plot.center.Z)
	thief:PivotTo(CFrame.new(start))
	thief.Parent = workspace
	ReplicatedStorage:SetAttribute("ThiefTarget", victim.UserId)
	notify:FireClient(victim, "thief", { stage = "incoming" })

	local caught, by = walk(thief, start, gate, Config.THIEF.speed)
	if not caught and BaseService.isLocked(victim) then
		notify:FireClient(victim, "thief", { stage = "blocked" })
		walk(thief, gate, start + Vector3.new(60, 0, 0), Config.THIEF.speed * 1.4)
		thief:Destroy()
		ReplicatedStorage:SetAttribute("ThiefTarget", 0)
		return
	end
	local stolen, slotModel
	if not caught then
		-- 挑最值钱的那只
		local best = 1
		for i, b in p.owned do
			if Config.CastByName[b.name].income > Config.CastByName[p.owned[best].name].income then
				best = i
			end
		end
		local ped = plot.pedestals[best]
		caught, by = walk(thief, gate, ped.part.Position, Config.THIEF.speed)
		if not caught and p.owned[best] and not BaseService.isLocked(victim) then
			task.wait(Config.THIEF.grabTime)
			stolen = table.remove(p.owned, best)
			BaseService.render(victim)
			PlayerData.push(victim)
			slotModel = BrainrotModel.build(stolen.name, stolen.mutation)
			for _, part in slotModel:GetDescendants() do
				if part:IsA("BasePart") then
					part.Anchored = true
				end
			end
			slotModel.Parent = thief
			notify:FireClient(victim, "thief", { stage = "stolen", name = stolen.name })
			caught, by = walk(thief, ped.part.Position, Vector3.new(Config.SEA_X + 10, 0, plot.center.Z), Config.THIEF.speed, slotModel)
		end
	end
	if caught and stolen then
		-- 被拦下：角色还给失主（底座满了就折现）
		if not BaseService.place(victim, stolen.name, stolen.mutation) then
			PlayerData.addCoins(victim, Econ.sellValue(stolen.name, stolen.mutation))
		end
		notify:FireClient(victim, "thief", { stage = "recovered", name = stolen.name, by = by and by.DisplayName })
	elseif caught then
		notify:FireClient(victim, "thief", { stage = "scared" })
	elseif stolen then
		notify:FireClient(victim, "thief", { stage = "escaped", name = stolen.name })
	end
	thief:Destroy()
	ReplicatedStorage:SetAttribute("ThiefTarget", 0)
end

function ThiefService.init(notifyRemote: RemoteEvent)
	notify = notifyRemote
	task.spawn(function()
		while true do
			task.wait(Config.THIEF.interval)
			local candidates = {}
			for _, player in Players:GetPlayers() do
				local p = PlayerData.get(player)
				if p and #p.owned > 0 then
					table.insert(candidates, player)
				end
			end
			if #candidates > 0 then
				heist(candidates[rng:NextInteger(1, #candidates)])
			end
		end
	end)
end

ThiefService.heist = heist
return ThiefService
