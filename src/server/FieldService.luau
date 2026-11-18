-- 田野：刷新野生角色、按住 E 抓取、扛在头顶、带回基地自动上底座、被浪拍到会丢失
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Econ = require(Shared.Econ)
local BrainrotModel = require(Shared.BrainrotModel)
local PlayerData = require(script.Parent.PlayerData)
local BaseService = require(script.Parent.BaseService)
local WorldBuilder = require(script.Parent.WorldBuilder)

local FieldService = {}
FieldService.luck = 1 -- 突变概率倍率（事件修改）
FieldService.rarityBoost = 0 -- 稀有度上移档数（事件修改）

local rng = Random.new()
local wildFolder: Folder
local notify: RemoteEvent
local zoneCount = {} :: { [number]: number }

local function boostedWeights(weights: { number }): { number }
	if FieldService.rarityBoost <= 0 then
		return weights
	end
	local out = table.create(#weights, 0)
	for i, w in weights do
		local j = math.min(#weights, i + FieldService.rarityBoost)
		out[j] += w
	end
	return out
end

local function speedFor(player: Player)
	local p = PlayerData.get(player)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not p or not hum then
		return
	end
	local penalty = 0
	for _, c in p.carrying do
		penalty += 1.2 * (Config.RarityIndex[Config.CastByName[c.name].rarity] - 1)
	end
	hum.WalkSpeed = math.max(10, PlayerData.walkSpeed(p) - penalty)
end

-- 抓取：把野生模型焊到玩家头顶
local function grab(player: Player, model: Model)
	local p = PlayerData.get(player)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not p or not hrp or model.Parent ~= wildFolder then
		return
	end
	if #p.carrying >= PlayerData.carryCap(p) then
		notify:FireClient(player, "full", { what = "hands" })
		return
	end
	local zone = model:GetAttribute("Zone")
	zoneCount[zone] -= 1
	local root = model.PrimaryPart
	local prompt = root:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt:Destroy()
	end
	local stackY = 3.2
	for _, c in p.carrying do
		stackY += c.model:GetAttribute("Height") + 0.4
	end
	root.Anchored = false
	model:PivotTo(hrp.CFrame * CFrame.new(0, stackY, 0))
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hrp
	weld.Part1 = root
	weld.Parent = root
	model.Parent = player.Character
	table.insert(p.carrying, { name = model:GetAttribute("Brainrot"), mutation = model:GetAttribute("Mutation"), model = model })
	speedFor(player)
	notify:FireClient(player, "grabbed", { name = model:GetAttribute("Brainrot"), mutation = model:GetAttribute("Mutation") })
	PlayerData.push(player)
end

function FieldService.spawnOne(zoneIndex: number)
	local zone = Config.Zones[zoneIndex]
	local info = Econ.rollCast(boostedWeights(zone.weights), rng)
	local mutation = Econ.rollMutation(FieldService.luck, rng)
	local model = BrainrotModel.build(info.name, mutation)
	local pos = Vector3.new(rng:NextNumber(zone.minX + 6, zone.maxX - 6), 0, rng:NextNumber(-Config.FIELD.halfZ + 10, Config.FIELD.halfZ - 10))
	model:PivotTo(CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0))
	model:SetAttribute("Zone", zoneIndex)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Grab"
	prompt.ObjectText = info.name
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.15 * Config.RarityIndex[info.rarity]
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		grab(player, model)
	end)
	model.Parent = wildFolder
	zoneCount[zoneIndex] += 1
end

-- 野生角色原地蹦跶、转向，看起来是活的
local function wander()
	for _, m in wildFolder:GetChildren() do
		local root = m.PrimaryPart
		if root and root.Anchored and rng:NextNumber() < 0.35 then
			local step = Vector3.new(rng:NextNumber(-6, 6), 0, rng:NextNumber(-6, 6))
			local target = root.Position + step
			local zone = Config.Zones[m:GetAttribute("Zone")]
			target = Vector3.new(math.clamp(target.X, zone.minX + 4, zone.maxX - 4), 0, math.clamp(target.Z, -Config.FIELD.halfZ + 6, Config.FIELD.halfZ - 6))
			local cf = CFrame.lookAt(target, target + step.Unit * Vector3.new(1, 0, 1))
			TweenService:Create(root, TweenInfo.new(1.2, Enum.EasingStyle.Quad), { CFrame = cf }):Play()
		end
	end
end

-- 丢掉扛着的全部角色（被浪拍、死亡、重生时）
function FieldService.dropAll(player: Player, reason: string?)
	local p = PlayerData.get(player)
	if not p or #p.carrying == 0 then
		return
	end
	local lost = {}
	for _, c in p.carrying do
		table.insert(lost, c.name)
		if c.model then
			c.model:Destroy()
		end
	end
	table.clear(p.carrying)
	speedFor(player)
	if reason then
		notify:FireClient(player, "lost", { names = lost, reason = reason })
	end
	PlayerData.push(player)
end

-- 进入自家基地时把扛着的角色放上底座
local function deliver(player: Player)
	local p = PlayerData.get(player)
	local plot = BaseService.plotOf(player)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not p or not plot or not hrp or #p.carrying == 0 or not WorldBuilder.inPlot(plot, hrp.Position) then
		return
	end
	while #p.carrying > 0 do
		local c = p.carrying[1]
		if not BaseService.place(player, c.name, c.mutation) then
			notify:FireClient(player, "full", { what = "base" })
			break
		end
		table.remove(p.carrying, 1)
		c.model:Destroy()
	end
	-- 剩下的重新堆叠
	local stackY = 3.2
	for _, c in p.carrying do
		local weld = c.model.PrimaryPart:FindFirstChildOfClass("WeldConstraint")
		if weld then
			weld.Enabled = false
			c.model:PivotTo(hrp.CFrame * CFrame.new(0, stackY, 0))
			weld.Enabled = true
		end
		stackY += c.model:GetAttribute("Height") + 0.4
	end
	speedFor(player)
	PlayerData.push(player)
end

function FieldService.refreshSpeed(player: Player)
	speedFor(player)
end

function FieldService.init(notifyRemote: RemoteEvent)
	notify = notifyRemote
	wildFolder = Instance.new("Folder")
	wildFolder.Name = "Wild"
	wildFolder.Parent = workspace
	for i = 1, #Config.Zones do
		zoneCount[i] = 0
		for _ = 1, Config.WILD_PER_ZONE do
			FieldService.spawnOne(i)
		end
	end
	task.spawn(function()
		while true do
			task.wait(0.25)
			for _, player in Players:GetPlayers() do
				deliver(player)
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(1.5)
			wander()
			for i = 1, #Config.Zones do
				if zoneCount[i] < Config.WILD_PER_ZONE then
					FieldService.spawnOne(i)
				end
			end
		end
	end)
end

-- 事件“稀有雨”：把整片田野换一批
function FieldService.reroll()
	for _, m in wildFolder:GetChildren() do
		zoneCount[m:GetAttribute("Zone")] -= 1
		m:Destroy()
	end
	for i = 1, #Config.Zones do
		for _ = 1, Config.WILD_PER_ZONE do
			FieldService.spawnOne(i)
		end
	end
end

return FieldService
