-- 搭建 3D 世界：复古棋盘格田野、五个区域、玩家基地、避难所、酱汁海与装饰
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)

local WorldBuilder = {}

local map: Folder
local rng = Random.new(2026)

local function block(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		p[k] = v
	end
	p.Parent = props.Parent or map
	return p
end

local function sign(parent: BasePart, face: Enum.NormalId, text: string, color: Color3, bg: Color3?)
	local g = Instance.new("SurfaceGui")
	g.Face = face
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 20
	g.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundColor3 = bg or Color3.fromRGB(30, 20, 50)
	t.BackgroundTransparency = bg and 0 or 1
	t.Font = Enum.Font.Arcade
	t.TextScaled = true
	t.Text = text
	t.TextColor3 = color
	t.TextStrokeTransparency = 0
	t.Parent = g
	g.Parent = parent
	return t
end

-- 棋盘格地面：每个区域两种颜色交替
local function buildField()
	local tile = 20
	for _, z in Config.Zones do
		for x = z.minX, z.maxX - 1, tile do
			for zz = -Config.FIELD.halfZ, Config.FIELD.halfZ - 1, tile do
				local w = math.min(tile, z.maxX - x)
				local odd = (math.floor((x - z.minX) / tile) + math.floor(zz / tile)) % 2 == 0
				block({ Name = "Tile", Size = Vector3.new(w, 2, tile), Position = Vector3.new(x + w / 2, -1, zz + tile / 2), Color = odd and z.tile[1] or z.tile[2] })
			end
		end
		-- 区域入口拱门
		local gx = z.minX
		for _, side in { -1, 1 } do
			block({ Name = "ArchPost", Size = Vector3.new(3, 22, 3), Position = Vector3.new(gx, 11, side * 60), Color = z.tile[2] })
		end
		local beam = block({ Name = "ArchSign", Size = Vector3.new(2, 7, 124), Position = Vector3.new(gx, 23, 0), Color = Color3.fromRGB(40, 25, 60) })
		sign(beam, Enum.NormalId.Left, z.name, z.tile[1])
		sign(beam, Enum.NormalId.Right, z.name, z.tile[1])
	end
	-- 回家的路
	for x = -10, 9, 10 do
		for zz = -Config.FIELD.halfZ, Config.FIELD.halfZ - 1, 10 do
			local odd = ((x / 10) + (zz / 10)) % 2 == 0
			block({ Name = "Road", Size = Vector3.new(10, 2, 10), Position = Vector3.new(x + 5, -1, zz + 5), Color = odd and Color3.fromRGB(60, 50, 80) or Color3.fromRGB(240, 240, 240) })
		end
	end
	-- 两侧糖果栏杆
	for x = 0, 400, 8 do
		for _, side in { -1, 1 } do
			local striped = (x / 8) % 2 == 0
			block({ Name = "Fence", Size = Vector3.new(2, 6, 2), Position = Vector3.new(x, 3, side * (Config.FIELD.halfZ + 2)), Color = striped and Color3.fromRGB(255, 70, 90) or Color3.fromRGB(255, 255, 255) })
		end
	end
	block({ Name = "FenceRail", Size = Vector3.new(404, 1, 1), Position = Vector3.new(200, 5.5, Config.FIELD.halfZ + 2), Color = Color3.fromRGB(255, 255, 255) })
	block({ Name = "FenceRail", Size = Vector3.new(404, 1, 1), Position = Vector3.new(200, 5.5, -Config.FIELD.halfZ - 2), Color = Color3.fromRGB(255, 255, 255) })
	-- 安全线：海浪在这里撞碎
	block({ Name = "SafeLine", Size = Vector3.new(2, 0.3, 250), Position = Vector3.new(-9, 0.1, 0), Color = Color3.fromRGB(80, 255, 200), Material = Enum.Material.Neon })
	local safeSign = block({ Name = "SafeSign", Size = Vector3.new(1, 6, 40), Position = Vector3.new(-12, 14, 0), Color = Color3.fromRGB(30, 20, 50) })
	sign(safeSign, Enum.NormalId.Right, "SAFE ZONE", Color3.fromRGB(80, 255, 200))
end

-- 酱汁海（威胁的源头）
local function buildSea()
	block({ Name = "Beach", Size = Vector3.new(14, 2, 250), Position = Vector3.new(Config.FIELD.maxX + 7, -1.2, 0), Color = Color3.fromRGB(255, 225, 160), Material = Enum.Material.Sand })
	block({ Name = "SauceSea", Size = Vector3.new(400, 4, 600), Position = Vector3.new(Config.SEA_X + 200, -2.5, 0), Color = Color3.fromRGB(220, 50, 30), Material = Enum.Material.Neon, Transparency = 0.15, CanCollide = false })
	block({ Name = "SeaFloor", Size = Vector3.new(400, 2, 600), Position = Vector3.new(Config.SEA_X + 200, -6, 0), Color = Color3.fromRGB(120, 20, 20) })
	-- 远处的意面礁石
	for i = 1, 10 do
		local x = Config.SEA_X + rng:NextNumber(40, 300)
		local z = rng:NextNumber(-260, 260)
		block({ Name = "MeatballRock", Shape = Enum.PartType.Ball, Size = Vector3.one * rng:NextNumber(8, 20), Position = Vector3.new(x, 0, z), Color = Color3.fromRGB(110, 60, 40), Material = Enum.Material.Slate })
	end
end

-- 避难所：海浪来时站在下面就安全
local function buildShelters()
	for i, pos in Config.SHELTERS do
		local r = Config.SHELTER_RADIUS
		block({ Name = "ShelterPad", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, r * 2, r * 2), CFrame = CFrame.new(pos + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(80, 255, 200), Material = Enum.Material.Neon })
		for a = 0, 3 do
			local ang = a * math.pi / 2 + math.pi / 4
			block({ Name = "ShelterPillar", Size = Vector3.new(1.6, 14, 1.6), Position = pos + Vector3.new(math.cos(ang) * (r - 1.5), 7, math.sin(ang) * (r - 1.5)), Color = Color3.fromRGB(255, 255, 255) })
		end
		local roof = block({ Name = "ShelterRoof", Size = Vector3.new(r * 2 + 2, 1.5, r * 2 + 2), Position = pos + Vector3.new(0, 14.5, 0), Color = Color3.fromRGB(40, 200, 170) })
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(160, 50)
		bb.StudsOffset = Vector3.new(0, 4, 0)
		bb.MaxDistance = 400
		bb.LightInfluence = 0
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.Arcade
		t.TextScaled = true
		t.Text = "SAFE"
		t.TextColor3 = Color3.fromRGB(80, 255, 200)
		t.TextStrokeTransparency = 0
		t.Parent = bb
		bb.Parent = roof
		roof:SetAttribute("Shelter", i)
	end
end

-- 每个区域的装饰：棕榈、摩艾石像、熔岩池、意面柱
local function palm(pos: Vector3)
	for i = 0, 4 do
		block({ Name = "Trunk", Size = Vector3.new(2, 3, 2), Position = pos + Vector3.new(i * 0.4, 1.5 + i * 3, 0), Color = i % 2 == 0 and Color3.fromRGB(150, 100, 50) or Color3.fromRGB(120, 80, 40) })
	end
	for a = 0, 3 do
		local ang = a * math.pi / 2
		block({ Name = "Leaf", Size = Vector3.new(9, 0.8, 2.5), CFrame = CFrame.new(pos + Vector3.new(2, 15.5, 0)) * CFrame.Angles(0, ang, 0) * CFrame.new(4, 0, 0) * CFrame.Angles(0, 0, -0.35), Color = Color3.fromRGB(60, 190, 80) })
	end
end

local function moai(pos: Vector3)
	local stone = Color3.fromRGB(120, 115, 125)
	block({ Name = "MoaiHead", Size = Vector3.new(6, 12, 5), Position = pos + Vector3.new(0, 6, 0), Color = stone, Material = Enum.Material.Slate })
	block({ Name = "MoaiNose", Size = Vector3.new(1.6, 4, 1.6), Position = pos + Vector3.new(-3.2, 7, 0), Color = stone, Material = Enum.Material.Slate })
	block({ Name = "MoaiBrow", Size = Vector3.new(1.4, 1.2, 5), Position = pos + Vector3.new(-3.1, 9.6, 0), Color = Color3.fromRGB(90, 85, 95), Material = Enum.Material.Slate })
end

local function lavaPool(pos: Vector3)
	block({ Name = "LavaPool", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 14, 14), CFrame = CFrame.new(pos + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(255, 110, 20), Material = Enum.Material.Neon, CanCollide = false })
end

local function decorate()
	local makers = { palm, palm, moai, lavaPool, palm }
	for i, z in Config.Zones do
		for _ = 1, 6 do
			local side = rng:NextInteger(0, 1) == 0 and -1 or 1
			local pos = Vector3.new(rng:NextNumber(z.minX + 8, z.maxX - 8), 0, side * rng:NextNumber(70, 112))
			makers[i](pos)
		end
	end
	-- 基地背后的复古像素山
	for i = 0, 14 do
		local h = 20 + (i % 3) * 14
		block({ Name = "PixelHill", Size = Vector3.new(30, h, 24), Position = Vector3.new(-100 - (i % 2) * 18, h / 2 - 1, -168 + i * 24), Color = i % 2 == 0 and Color3.fromRGB(90, 70, 140) or Color3.fromRGB(110, 85, 165) })
	end
end

-- 玩家基地：地板、矮墙、底座、锁按钮、护盾、名牌
local function buildPlot(i: number)
	local center = Vector3.new(Config.PLOT_X, 0, Config.PLOT_Z[i])
	local size = Config.PLOT_SIZE
	local color = Config.PLOT_COLORS[i]
	local folder = Instance.new("Folder")
	folder.Name = "Plot" .. i
	folder.Parent = map
	block({ Name = "Floor", Size = Vector3.new(size.X, 2, size.Z), Position = center + Vector3.new(0, -0.9, 0), Color = color:Lerp(Color3.new(1, 1, 1), 0.55), Parent = folder })
	block({ Name = "Rug", Size = Vector3.new(size.X - 8, 0.2, size.Z - 30), Position = center + Vector3.new(0, 0.2, 0), Color = color:Lerp(Color3.new(0, 0, 0), 0.15), Parent = folder })
	-- 三面矮墙，朝田野一侧敞开
	block({ Name = "Wall", Size = Vector3.new(2, 4, size.Z), Position = center + Vector3.new(-size.X / 2, 2, 0), Color = color, Parent = folder })
	for _, s in { -1, 1 } do
		block({ Name = "Wall", Size = Vector3.new(size.X, 4, 2), Position = center + Vector3.new(0, 2, s * size.Z / 2), Color = color, Parent = folder })
	end
	-- 底座：两排，每排 6 个
	local pedestals = {}
	for row = 0, 1 do
		for col = 0, 5 do
			local pos = center + Vector3.new(-26.25 + col * 10.5, 0, (row == 0 and -1 or 1) * 20)
			local ped = block({ Name = "Pedestal", Size = Vector3.new(8, 1.2, 8), Position = pos + Vector3.new(0, 0.6, 0), Color = Color3.fromRGB(245, 245, 245), Parent = folder })
			ped:SetAttribute("Slot", #pedestals + 1)
			block({ Name = "PedestalRim", Size = Vector3.new(9, 0.5, 9), Position = pos + Vector3.new(0, 0.25, 0), Color = color, Material = Enum.Material.Neon, Parent = folder })
			ped.Transparency = 0.6
			table.insert(pedestals, { part = ped, cframe = CFrame.lookAt(pos + Vector3.new(0, 1.2, 0), pos + Vector3.new(0, 1.2, -(row == 0 and -1 or 1) * 10)) })
		end
	end
	-- 锁按钮
	local lockPad = block({ Name = "LockPad", Size = Vector3.new(6, 1, 6), Position = center + Vector3.new(-size.X / 2 + 6, 0.5, 12), Color = Color3.fromRGB(255, 60, 60), Material = Enum.Material.Neon, Parent = folder })
	local lockPost = block({ Name = "LockSign", Size = Vector3.new(1, 4.4, 8), Position = center + Vector3.new(-size.X / 2 + 1.5, 3.2, 12), Color = Color3.fromRGB(30, 20, 50), Parent = folder })
	sign(lockPost, Enum.NormalId.Right, "LOCK BASE", Color3.fromRGB(255, 90, 90))
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Lock Base"
	prompt.ObjectText = "Laser Shield"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 10
	prompt.Parent = lockPad
	-- 激光护盾（上锁时显形）
	local shield = block({ Name = "Shield", Size = Vector3.new(size.X + 1, 16, size.Z + 1), Position = center + Vector3.new(0, 8, 0), Color = Color3.fromRGB(255, 60, 90), Material = Enum.Material.ForceField, Transparency = 1, CanCollide = false, CanQuery = false, Parent = folder })
	-- 基地招牌
	local signPart = block({ Name = "Sign", Size = Vector3.new(1, 8, 34), Position = center + Vector3.new(-size.X / 2 - 1, 10, 0), Color = color, Parent = folder })
	local label = sign(signPart, Enum.NormalId.Right, "EMPTY PLOT", Color3.fromRGB(255, 255, 255), Color3.fromRGB(30, 20, 50))
	local spawnCF = CFrame.lookAt(center + Vector3.new(-size.X / 2 + 14, 4, 0), center + Vector3.new(40, 4, 0))
	return { index = i, center = center, size = size, color = color, folder = folder, pedestals = pedestals, lockPad = lockPad, lockPrompt = prompt, shield = shield, label = label, spawnCF = spawnCF }
end

function WorldBuilder.build()
	local old = workspace:FindFirstChild("Map")
	if old then
		old:Destroy()
	end
	map = Instance.new("Folder")
	map.Name = "Map"
	map.Parent = workspace
	local atmo = Instance.new("Atmosphere")
	atmo.Density = 0.28
	atmo.Color = Color3.fromRGB(255, 205, 170)
	atmo.Decay = Color3.fromRGB(150, 100, 170)
	atmo.Glare = 0.2
	atmo.Haze = 1.4
	atmo.Parent = game:GetService("Lighting")
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.5
	bloom.Size = 20
	bloom.Threshold = 1.6
	bloom.Parent = game:GetService("Lighting")
	buildField()
	buildSea()
	buildShelters()
	decorate()
	local plots = {}
	for i = 1, #Config.PLOT_Z do
		plots[i] = buildPlot(i)
	end
	return plots
end

-- 坐标是否在某块基地内
function WorldBuilder.inPlot(plot, pos: Vector3): boolean
	local d = pos - plot.center
	return math.abs(d.X) < plot.size.X / 2 and math.abs(d.Z) < plot.size.Z / 2
end

function WorldBuilder.inShelter(pos: Vector3): boolean
	for _, s in Config.SHELTERS do
		if (Vector3.new(pos.X, 0, pos.Z) - s).Magnitude < Config.SHELTER_RADIUS then
			return true
		end
	end
	return false
end

return WorldBuilder
