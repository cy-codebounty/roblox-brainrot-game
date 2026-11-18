-- 威胁：酱汁海啸周期性从海边扫向基地，田野里没躲进避难所的玩家会被拍飞并丢掉扛着的角色
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)
local WorldBuilder = require(script.Parent.WorldBuilder)
local FieldService = require(script.Parent.FieldService)
local BaseService = require(script.Parent.BaseService)

local WaveService = {}
WaveService.onWaveEnd = nil :: (() -> ())?

local W = Config.WAVE
local wave: Model
local notify: RemoteEvent

-- 海浪外形：前倾的酱汁巨浪，浪尖翻白沫，正面长着两张大脸（眼睛 + 獠牙大嘴）
local function buildWave(): Model
	local m = Instance.new("Model")
	m.Name = "SauceWave"
	local H = W.height
	local WIDTH = Config.FIELD.halfZ * 2 + 12
	local lean = CFrame.Angles(0, 0, math.rad(14)) -- 顶部朝前进方向（-X）倾
	local function p(size: Vector3, offset: Vector3, color: Color3, mat: Enum.Material?, transp: number?, cls: string?)
		local part = Instance.new(cls or "Part")
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.Size = size
		part.Color = color
		part.Material = mat or Enum.Material.SmoothPlastic
		part.Transparency = transp or 0
		part.CFrame = lean * CFrame.new(offset)
		part.Parent = m
		return part
	end
	local body = p(Vector3.new(14, H, WIDTH), Vector3.new(0, H / 2, 0), Color3.fromRGB(215, 35, 25), Enum.Material.Neon, 0.05)
	body.Name = "Body"
	body.PivotOffset = body.CFrame:Inverse()
	m.PrimaryPart = body
	-- 后浪、上半截亮橙色、浪尖卷边和泡沫
	p(Vector3.new(40, H * 0.7, WIDTH), Vector3.new(26, H * 0.35, 0), Color3.fromRGB(160, 20, 15), nil, 0.15)
	p(Vector3.new(14.4, H * 0.28, WIDTH), Vector3.new(-0.2, H * 0.86, 0), Color3.fromRGB(255, 110, 40), Enum.Material.Neon)
	p(Vector3.new(12, 5, WIDTH), Vector3.new(-7, H + 1.5, 0), Color3.fromRGB(255, 245, 225))
	for z = -126, 126, 12 do
		p(Vector3.new(8, 8, 8), Vector3.new(-11, H + 2, z), Color3.fromRGB(255, 250, 240), nil, nil).Shape = Enum.PartType.Ball
	end
	-- 两张大脸
	for _, faceZ in { -62, 62 } do
		for _, dz in { -16, 16 } do
			p(Vector3.new(2, 13, 11), Vector3.new(-7.6, H * 0.66, faceZ + dz), Color3.fromRGB(255, 255, 255))
			p(Vector3.new(2, 6, 5), Vector3.new(-8.7, H * 0.63, faceZ + dz - 2), Color3.fromRGB(20, 10, 10))
		end
		p(Vector3.new(1.6, 7, 46), Vector3.new(-7.4, H * 0.32, faceZ), Color3.fromRGB(70, 5, 10))
		for z = faceZ - 20, faceZ + 20, 5 do
			-- 两块楔形拼成朝下的三角獠牙
			for _, half in { { CFrame.Angles(math.pi, 0, 0), 0.625 }, { CFrame.Angles(0, 0, math.pi), -0.625 } } do
				local tooth = p(Vector3.new(1, 3, 1.25), Vector3.new(-8.3, H * 0.32 + 2, z + half[2]), Color3.fromRGB(255, 255, 255), nil, nil, "WedgePart")
				tooth.CFrame *= half[1]
			end
		end
	end
	m:PivotTo(CFrame.new(W.startX + 200, 0, 0))
	m.Parent = workspace
	return m
end

local function setPhase(phase: string, endsAt: number)
	ReplicatedStorage:SetAttribute("WavePhase", phase)
	ReplicatedStorage:SetAttribute("WaveEndsAt", endsAt)
end

-- 浪头扫过时检查每个玩家
local function sweepPlayers(x: number)
	for _, player in Players:GetPlayers() do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 and not char:GetAttribute("WipedOut") then
			local px = hrp.Position.X
			if px > x - 7 and px < x + 10 and px > -8 and not WorldBuilder.inShelter(hrp.Position) then
				char:SetAttribute("WipedOut", true)
				FieldService.dropAll(player, "wave")
				notify:FireClient(player, "wiped", {})
				local plot = BaseService.plotOf(player)
				task.delay(0.6, function()
					if plot and char.Parent then
						char:PivotTo(plot.spawnCF)
					end
					char:SetAttribute("WipedOut", nil)
				end)
			end
		end
	end
end

local function runWave()
	local dist = W.startX - W.endX
	local duration = dist / W.speed
	setPhase("active", workspace:GetServerTimeNow() + duration)
	local t0 = os.clock()
	while true do
		local t = math.min(1, (os.clock() - t0) / duration)
		local x = W.startX - dist * t
		wave:PivotTo(CFrame.new(x, 0, 0))
		ReplicatedStorage:SetAttribute("WaveX", x)
		sweepPlayers(x)
		if t >= 1 then
			break
		end
		RunService.Heartbeat:Wait()
	end
	-- 撞上安全线后碎掉退回海里
	wave:PivotTo(CFrame.new(W.startX + 200, 0, 0))
	ReplicatedStorage:SetAttribute("WaveX", W.startX + 200)
end

function WaveService.init(notifyRemote: RemoteEvent)
	notify = notifyRemote
	wave = buildWave()
	task.spawn(function()
		while true do
			setPhase("calm", workspace:GetServerTimeNow() + W.interval)
			task.wait(W.interval)
			setPhase("warning", workspace:GetServerTimeNow() + W.warn)
			task.wait(W.warn)
			runWave()
			if WaveService.onWaveEnd then
				WaveService.onWaveEnd()
			end
		end
	end)
end

return WaveService
