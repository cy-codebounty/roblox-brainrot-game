-- 复古像素风界面小工具：方角面板、粗描边、Arcade 字体
local Ui = {}

Ui.FONT = Enum.Font.Arcade
Ui.BG = Color3.fromRGB(34, 22, 58)
Ui.INK = Color3.fromRGB(255, 255, 255)
Ui.GOLD = Color3.fromRGB(255, 214, 60)
Ui.MINT = Color3.fromRGB(90, 255, 190)
Ui.RED = Color3.fromRGB(255, 70, 90)
Ui.PINK = Color3.fromRGB(255, 110, 200)

function Ui.stroke(obj: GuiObject, color: Color3?, thick: number?)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(0, 0, 0)
	s.Thickness = thick or 3
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = obj
	return s
end

function Ui.frame(parent: Instance, props: { [string]: any }): Frame
	local f = Instance.new("Frame")
	f.BackgroundColor3 = Ui.BG
	f.BorderSizePixel = 0
	for k, v in props do
		f[k] = v
	end
	f.Parent = parent
	return f
end

function Ui.label(parent: Instance, text: string, props: { [string]: any }?): TextLabel
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Font = Ui.FONT
	t.Text = text
	t.TextColor3 = Ui.INK
	t.TextScaled = true
	t.TextStrokeTransparency = 0
	t.Size = UDim2.fromScale(1, 1)
	for k, v in props or {} do
		t[k] = v
	end
	t.Parent = parent
	return t
end

function Ui.button(parent: Instance, text: string, color: Color3, props: { [string]: any }, onClick: () -> ()): TextButton
	local b = Instance.new("TextButton")
	b.Font = Ui.FONT
	b.Text = text
	b.TextScaled = true
	b.TextColor3 = Ui.INK
	b.TextStrokeTransparency = 0
	b.BackgroundColor3 = color
	b.BorderSizePixel = 0
	b.AutoButtonColor = true
	for k, v in props do
		b[k] = v
	end
	Ui.stroke(b, Color3.fromRGB(0, 0, 0), 3)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.PaddingLeft = UDim.new(0, 6)
	pad.PaddingRight = UDim.new(0, 6)
	pad.Parent = b
	b.Parent = parent
	b.Activated:Connect(onClick)
	return b
end

function Ui.screen(name: string, order: number): ScreenGui
	local g = Instance.new("ScreenGui")
	g.Name = name
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.DisplayOrder = order
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	return g
end

return Ui
