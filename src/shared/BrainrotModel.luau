-- 用基础零件拼出搞怪角色模型 + 头顶名牌（名字 / 稀有度 / 突变 / 每秒金币）
local Config = require(script.Parent.Config)
local Econ = require(script.Parent.Econ)

local BrainrotModel = {}

local BLACK = Color3.fromRGB(25, 20, 30)
local WHITE = Color3.fromRGB(255, 255, 255)

local function part(model: Model, root: BasePart, size: Vector3, cf: CFrame, color: Color3, kind: string?): BasePart
	local p = Instance.new("Part")
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.CanQuery = false
	p.Massless = true
	p.Anchored = false
	if kind == "ball" then
		local m = Instance.new("SpecialMesh")
		m.MeshType = Enum.MeshType.Sphere
		m.Parent = p
	elseif kind == "cyl" then
		p.Shape = Enum.PartType.Cylinder
		p.Size = Vector3.new(size.Y, size.X, size.Z)
		cf = cf * CFrame.Angles(0, 0, math.rad(90))
	end
	p.CFrame = root.CFrame * cf
	local w = Instance.new("WeldConstraint")
	w.Part0 = root
	w.Part1 = p
	w.Parent = p
	p.Parent = model
	return p
end

-- 装饰件：每个函数接收 (model, root, 身体尺寸 s, 身体中心高度 y, 主色, 辅色)
local Feats = {}
function Feats.legs(m, r, s, y, _, a)
	for _, x in { -0.28, 0.28 } do
		part(m, r, Vector3.new(0.5, 1.3, 0.5), CFrame.new(s.X * x, 0.65, 0), a)
		part(m, r, Vector3.new(0.8, 0.35, 1), CFrame.new(s.X * x, 0.18, -0.2), BLACK)
	end
end
function Feats.arms(m, r, s, y, _, a)
	for _, x in { -1, 1 } do
		part(m, r, Vector3.new(0.45, 1.6, 0.45), CFrame.new(x * (s.X / 2 + 0.25), y, -0.2) * CFrame.Angles(0, 0, x * 0.5), a)
	end
end
function Feats.hat(m, r, s, y, _, a)
	local top = y + s.Y / 2
	part(m, r, Vector3.new(s.X * 1.1, 0.25, s.X * 1.1), CFrame.new(0, top + 0.1, 0), a, "cyl")
	part(m, r, Vector3.new(s.X * 0.6, 1, s.X * 0.6), CFrame.new(0, top + 0.7, 0), a, "cyl")
end
function Feats.shades(m, r, s, y)
	part(m, r, Vector3.new(s.X * 0.9, 0.45, 0.2), CFrame.new(0, y + s.Y * 0.18, -s.Z / 2 - 0.25), BLACK).Material = Enum.Material.Glass
end
function Feats.crown(m, r, s, y)
	local top = y + s.Y / 2
	local gold = Color3.fromRGB(255, 210, 40)
	part(m, r, Vector3.new(1.6, 0.5, 1.6), CFrame.new(0, top + 0.25, 0), gold)
	for i = 0, 3 do
		local ang = i * math.pi / 2
		part(m, r, Vector3.new(0.35, 0.6, 0.35), CFrame.new(math.cos(ang) * 0.6, top + 0.75, math.sin(ang) * 0.6), gold)
	end
end
function Feats.antenna(m, r, s, y, _, a)
	local top = y + s.Y / 2
	part(m, r, Vector3.new(0.15, 1.4, 0.15), CFrame.new(0, top + 0.7, 0), BLACK)
	part(m, r, Vector3.new(0.6, 0.6, 0.6), CFrame.new(0, top + 1.5, 0), a, "ball").Material = Enum.Material.Neon
end
function Feats.horns(m, r, s, y)
	local top = y + s.Y / 2
	for _, x in { -1, 1 } do
		part(m, r, Vector3.new(0.4, 1.2, 0.4), CFrame.new(x * s.X * 0.3, top + 0.4, 0) * CFrame.Angles(0, 0, -x * 0.4), WHITE)
	end
end
function Feats.tail(m, r, s, y, _, a)
	part(m, r, Vector3.new(0.4, 0.4, 1.8), CFrame.new(0, y - s.Y * 0.2, s.Z / 2 + 0.6) * CFrame.Angles(0.5, 0, 0), a)
end
function Feats.wings(m, r, s, y, _, a)
	for _, x in { -1, 1 } do
		part(m, r, Vector3.new(2.4, 0.2, 1.4), CFrame.new(x * (s.X / 2 + 1), y + 0.4, 0.3) * CFrame.Angles(0, 0, x * 0.5), a)
	end
end
function Feats.mustache(m, r, s, y)
	part(m, r, Vector3.new(s.X * 0.6, 0.3, 0.2), CFrame.new(0, y - s.Y * 0.05, -s.Z / 2 - 0.15), BLACK)
end
function Feats.halo(m, r, s, y)
	local h = part(m, r, Vector3.new(2.2, 0.15, 2.2), CFrame.new(0, y + s.Y / 2 + 1.6, 0), Color3.fromRGB(255, 250, 150), "cyl")
	h.Material = Enum.Material.Neon
end
function Feats.tentacles(m, r, s, y, _, a)
	for i = 0, 5 do
		local ang = i * math.pi / 3
		part(m, r, Vector3.new(0.5, 2, 0.5), CFrame.new(math.cos(ang) * s.X * 0.35, 1, math.sin(ang) * s.Z * 0.35) * CFrame.Angles(math.sin(ang) * 0.4, 0, -math.cos(ang) * 0.4), a)
	end
end

-- 头顶名牌
local function makeLabel(root: BasePart, info: any, mutation: string, height: number, scale: number)
	local rarity = Config.Rarities[Config.RarityIndex[info.rarity]]
	local mut = Config.MutationById[mutation]
	local gui = Instance.new("BillboardGui")
	gui.Name = "Tag"
	-- 以 stud 为单位，远处自动变小，避免名牌互相糊住
	gui.Size = UDim2.fromScale(6 * scale, 2.2 * scale)
	gui.StudsOffsetWorldSpace = Vector3.new(0, height + 1.4 * scale, 0)
	gui.MaxDistance = 140
	gui.LightInfluence = 0
	local function line(text: string, color: Color3, y: number, h: number)
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, h / 78)
		t.Position = UDim2.fromScale(0, y / 78)
		t.Font = Enum.Font.Arcade
		t.TextScaled = true
		t.Text = text
		t.TextColor3 = color
		t.TextStrokeTransparency = 0
		t.TextStrokeColor3 = info.rarity == "Secret" and WHITE or BLACK
		t.Parent = gui
		return t
	end
	if mutation ~= "Normal" then
		line(string.upper(mutation), mut.color, 0, 16).Name = "Mutation"
	end
	line(info.name, WHITE, 16, 22).Name = "Name"
	line(string.upper(info.rarity), info.rarity == "Secret" and BLACK or rarity.color, 38, 18).Name = "Rarity"
	local inc = line("$" .. Econ.format(Econ.incomeOf(info.name, mutation, 0)) .. "/s", Color3.fromRGB(120, 255, 120), 56, 20)
	inc.Name = "Income"
	gui.Parent = root
	return gui
end

-- 生成角色模型；Root 为脚底的透明锚点，其余零件焊在 Root 上
function BrainrotModel.build(name: string, mutation: string): Model
	local info = Config.CastByName[name]
	local model = Instance.new("Model")
	model.Name = info.name
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(1, 1, 1)
	root.Transparency = 1
	root.CanCollide = false
	root.CanQuery = false
	root.Anchored = true
	root.CFrame = CFrame.new()
	root.Parent = model
	model.PrimaryPart = root

	local s = info.size
	local lift = 0.2
	if table.find(info.feats, "legs") then
		lift = 1.3
	elseif table.find(info.feats, "tentacles") then
		lift = 1.6
	end
	local y = lift + s.Y / 2
	local body = part(model, root, s, CFrame.new(0, y, 0), info.main, info.body ~= "block" and info.body or nil)
	body.Name = "Body"
	-- 大眼睛 + 嘴：搞怪的灵魂
	local eyeY = y + s.Y * 0.18
	local faceZ = -s.Z / 2
	if info.body == "ball" then
		faceZ = -s.Z * 0.42
	end
	for _, x in { -1, 1 } do
		part(model, root, Vector3.new(0.9, 0.9, 0.3), CFrame.new(x * s.X * 0.2, eyeY, faceZ - 0.1), WHITE, "ball")
		part(model, root, Vector3.new(0.4, 0.4, 0.2), CFrame.new(x * s.X * 0.2 + x * 0.1, eyeY - 0.05, faceZ - 0.25), BLACK, "ball")
	end
	part(model, root, Vector3.new(s.X * 0.35, 0.25, 0.2), CFrame.new(0, y - s.Y * 0.15, faceZ - 0.1), Color3.fromRGB(150, 30, 40))
	for _, f in info.feats do
		Feats[f](model, root, s, y, info.main, info.accent)
	end

	local mut = Config.MutationById[mutation]
	if mutation ~= "Normal" then
		body.Color = mut.color
		body.Material = mut.material
		local fx = mutation == "Lava" and Instance.new("Fire") or Instance.new("Sparkles")
		if fx:IsA("Sparkles") then
			fx.SparkleColor = mut.color
		else
			fx.Size = 4
			fx.Heat = 6
		end
		fx.Parent = body
		if mutation == "Rainbow" then
			body:AddTag("RainbowPart")
		end
	end
	model:SetAttribute("Brainrot", info.name)
	model:SetAttribute("Mutation", mutation)
	model:SetAttribute("Rarity", info.rarity)
	-- 越稀有体型越大
	local scale = Config.Rarities[Config.RarityIndex[info.rarity]].scale
	model:ScaleTo(scale)
	model:SetAttribute("Height", (y + s.Y / 2) * scale)
	makeLabel(root, info, mutation, (y + s.Y / 2) * scale, scale)
	return model
end

-- 名牌收入随重生倍率刷新
function BrainrotModel.setIncomeText(model: Model, perSecond: number)
	local tag = model.PrimaryPart and model.PrimaryPart:FindFirstChild("Tag")
	local inc = tag and tag:FindFirstChild("Income")
	if inc then
		inc.Text = "$" .. Econ.format(perSecond) .. "/s"
	end
end

return BrainrotModel
