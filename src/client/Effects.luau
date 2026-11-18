-- 客户端特效：彩虹突变变色、海浪逼近时屏幕泛红与镜头震动、金币飘字、音效
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Ui = require(script.Parent.Ui)

local Effects = {}

local player = Players.LocalPlayer
local tint: Frame
local shake = 0

local SOUNDS = {
	grab = "rbxasset://sounds/electronicpingshort.wav",
	place = "rbxasset://sounds/electronicpingshort.wav",
	wiped = "rbxasset://sounds/uuhhh.mp3",
	alarm = "rbxasset://sounds/electronicpingshort.wav",
}

function Effects.play(name: string, pitch: number?)
	local id = SOUNDS[name]
	if not id then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = 0.6
	s.PlaybackSpeed = pitch or 1
	s.Parent = SoundService
	s:Play()
	s.Ended:Connect(function()
		s:Destroy()
	end)
	task.delay(4, function()
		if s.Parent then
			s:Destroy()
		end
	end)
end

function Effects.build()
	local gui = Ui.screen("Fx", 1)
	tint = Ui.frame(gui, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 30, 20), BackgroundTransparency = 1 })
end

function Effects.shake(amount: number)
	shake = math.max(shake, amount)
end

function Effects.flash(color: Color3)
	tint.BackgroundColor3 = color
	tint.BackgroundTransparency = 0.45
	TweenService:Create(tint, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
end

-- 每帧：彩虹件变色、根据浪头距离泛红和震屏
function Effects.step(dt: number)
	local hue = (os.clock() * 0.25) % 1
	for _, p in CollectionService:GetTagged("RainbowPart") do
		p.Color = Color3.fromHSV((hue + p.Position.X * 0.01) % 1, 0.8, 1)
	end
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local cam = workspace.CurrentCamera
	if hrp and ReplicatedStorage:GetAttribute("WavePhase") == "active" then
		local d = (ReplicatedStorage:GetAttribute("WaveX") or 999) - hrp.Position.X
		if d > 0 and d < 120 then
			Effects.shake(0.6 * (1 - d / 120))
			if tint.BackgroundTransparency > 0.75 then
				tint.BackgroundTransparency = 0.75 + 0.25 * (d / 120)
			end
		end
	end
	if shake > 0.01 and cam.CameraType == Enum.CameraType.Custom then
		cam.CFrame *= CFrame.new((math.random() - 0.5) * shake, (math.random() - 0.5) * shake, 0)
		shake *= math.max(0, 1 - dt * 6)
	end
end

-- 金币飘字（在角色头顶）
function Effects.popup(text: string, color: Color3)
	local hrp = player.Character and player.Character:FindFirstChild("Head")
	if not hrp then
		return
	end
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(240, 50)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	local t = Ui.label(bb, text, { TextColor3 = color })
	bb.Adornee = hrp
	bb.Parent = player.PlayerGui
	TweenService:Create(bb, TweenInfo.new(1.4), { StudsOffset = Vector3.new(0, 9, 0) }):Play()
	TweenService:Create(t, TweenInfo.new(1.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(1.5, function()
		bb:Destroy()
	end)
end

return Effects
