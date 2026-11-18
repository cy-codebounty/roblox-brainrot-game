-- 标题画面：3D 镜头环绕展示台上的稀有角色，按 PLAY 或空格开始
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotModel = require(Shared.BrainrotModel)
local Ui = require(script.Parent.Ui)

local TitleScreen = {}

local SHOWCASE = {
	{ "Il Grande Sauceboss", "Normal" },
	{ "Spaghetti Kraken", "Gold" },
	{ "Duckzilla Bathbomba", "Rainbow" },
	{ "Moai Gelatoso", "Diamond" },
	{ "Toastini Toastolini", "Normal" },
	{ "Cactusso Disco", "Lava" },
	{ "Nonna 8-Bit", "Normal" },
}
local STAGE = Vector3.new(34, 0, 0)

function TitleScreen.show(onPlay: () -> ())
	local cam = workspace.CurrentCamera
	local gui = Ui.screen("Title", 20)
	local stage = Instance.new("Model")
	stage.Name = "TitleShowcase"
	local podium = Instance.new("Part")
	podium.Anchored = true
	podium.Size = Vector3.new(16, 2, 84)
	podium.Position = STAGE + Vector3.new(0, 1, 0)
	podium.Color = Color3.fromRGB(255, 214, 60)
	podium.Material = Enum.Material.SmoothPlastic
	podium.Parent = stage
	for i, entry in SHOWCASE do
		local m = BrainrotModel.build(entry[1], entry[2])
		local z = (i - (#SHOWCASE + 1) / 2) * 11
		local pos = STAGE + Vector3.new(0, 2, z)
		m:PivotTo(CFrame.lookAt(pos, pos + Vector3.new(-1, 0, 0)))
		m.Parent = stage
	end
	stage.Parent = workspace

	-- 上下黑边 + 标题，留出中间 3D 画面
	Ui.frame(gui, { Size = UDim2.new(1, 0, 0.2, 0), BackgroundColor3 = Color3.fromRGB(20, 12, 36), BackgroundTransparency = 0.25 })
	Ui.frame(gui, { Size = UDim2.new(1, 0, 0.2, 0), Position = UDim2.fromScale(0, 0.8), BackgroundColor3 = Color3.fromRGB(20, 12, 36), BackgroundTransparency = 0.25 })
	local title = Ui.label(gui, "BRAINROT BAY", { Size = UDim2.new(0.8, 0, 0.17, 0), Position = UDim2.new(0.1, 0, 0.02, 0), TextColor3 = Ui.GOLD })
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(220, 40, 120)
	s.Thickness = 5
	s.Parent = title
	Ui.label(gui, "CATCH 20 BRAINROTS - EARN $ EVERY SECOND - OUTRUN THE SAUCE TSUNAMI", { Size = UDim2.new(0.8, 0, 0.05, 0), Position = UDim2.new(0.1, 0, 0.82, 0), TextColor3 = Ui.MINT })
	Ui.button(gui, "PLAY", Color3.fromRGB(40, 190, 90), { Size = UDim2.new(0.18, 0, 0.09, 0), Position = UDim2.new(0.41, 0, 0.885, 0) }, function()
		TitleScreen.hide()
	end)

	-- 标题期间本地隐藏田野里乱跑的野生角色，让展示台干净
	local function setWildHidden(hidden: boolean)
		local wild = workspace:FindFirstChild("Wild")
		if not wild then
			return
		end
		for _, d in wild:GetDescendants() do
			if d:IsA("BasePart") then
				d.LocalTransparencyModifier = hidden and 1 or 0
			elseif d:IsA("BillboardGui") or d:IsA("ParticleEmitter") or d:IsA("Sparkles") or d:IsA("Fire") then
				d.Enabled = not hidden
			end
		end
	end

	local t0 = os.clock()
	cam.CameraType = Enum.CameraType.Scriptable
	local conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		setWildHidden(true)
		local ang = math.rad(180) + math.sin(t * 0.15) * 0.2
		local eye = STAGE + Vector3.new(math.cos(ang) * 40, 12 + math.sin(t * 0.3) * 2, math.sin(ang) * 40)
		cam.CFrame = CFrame.lookAt(eye, STAGE + Vector3.new(20, 5, 0))
	end)
	local keyConn = UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.Space then
			TitleScreen.hide()
		end
	end)
	TitleScreen.hide = function()
		if not gui.Parent then
			return
		end
		conn:Disconnect()
		keyConn:Disconnect()
		gui:Destroy()
		stage:Destroy()
		setWildHidden(false)
		cam.CameraType = Enum.CameraType.Custom
		onPlay()
	end
end

return TitleScreen
