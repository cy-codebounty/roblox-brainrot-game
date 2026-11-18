-- 常驻 HUD：顶部金币与每秒收入、海浪倒计时、事件横幅、扛着的角色、右侧按钮、提示与大字
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Econ = require(Shared.Econ)
local Ui = require(script.Parent.Ui)

local Hud = {}

local gui: ScreenGui
local coinsText, rateText, multText, waveText, waveFill, waveBox, eventText, eventBox, carryBox, carryList, lockBtn, bigText, toastHolder
local state: any = nil
local shownCoins = 0

function Hud.build(actions: { [string]: () -> () })
	gui = Ui.screen("Hud", 5)
	-- 顶部金币（避开左上角的 Roblox 菜单）
	local top = Ui.frame(gui, { Size = UDim2.fromOffset(380, 92), Position = UDim2.new(0.5, -190, 0, 10) })
	Ui.stroke(top, Ui.GOLD, 4)
	coinsText = Ui.label(top, "$0", { Size = UDim2.new(1, -16, 0, 56), Position = UDim2.fromOffset(8, 4), TextColor3 = Ui.GOLD })
	rateText = Ui.label(top, "+$0/s", { Size = UDim2.new(0.62, 0, 0, 26), Position = UDim2.fromOffset(8, 60), TextColor3 = Ui.MINT, TextXAlignment = Enum.TextXAlignment.Left })
	multText = Ui.label(top, "REBIRTH x1", { Size = UDim2.new(0.38, -12, 0, 22), Position = UDim2.new(0.62, 0, 0, 62), TextColor3 = Ui.PINK, TextXAlignment = Enum.TextXAlignment.Right })
	-- 海浪倒计时条
	waveBox = Ui.frame(gui, { Size = UDim2.fromOffset(460, 40), Position = UDim2.new(0.5, -230, 0, 110), BackgroundColor3 = Color3.fromRGB(60, 20, 30) })
	Ui.stroke(waveBox, Ui.RED, 3)
	waveFill = Ui.frame(waveBox, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(220, 50, 40) })
	waveText = Ui.label(waveBox, "", { Size = UDim2.new(1, -10, 1, -8), Position = UDim2.fromOffset(5, 4), ZIndex = 2 })
	-- 事件横幅
	eventBox = Ui.frame(gui, { Size = UDim2.fromOffset(460, 34), Position = UDim2.new(0.5, -230, 0, 158), BackgroundColor3 = Color3.fromRGB(90, 40, 140), Visible = false })
	Ui.stroke(eventBox, Ui.PINK, 3)
	eventText = Ui.label(eventBox, "", { Size = UDim2.new(1, -10, 1, -6), Position = UDim2.fromOffset(5, 3), TextColor3 = Ui.GOLD })
	-- 左侧：扛着的角色
	carryBox = Ui.frame(gui, { Size = UDim2.fromOffset(250, 150), Position = UDim2.new(0, 14, 0.5, -60), BackgroundTransparency = 0.15 })
	Ui.stroke(carryBox, Ui.MINT, 3)
	Ui.label(carryBox, "CARRYING", { Name = "Title", Size = UDim2.new(1, -12, 0, 28), Position = UDim2.fromOffset(6, 4), TextColor3 = Ui.MINT })
	carryList = Ui.label(carryBox, "nothing yet", { Size = UDim2.new(1, -12, 1, -40), Position = UDim2.fromOffset(6, 34), TextScaled = false, TextSize = 20, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, RichText = true })
	-- 右侧按钮列
	local col = Ui.frame(gui, { Size = UDim2.fromOffset(150, 330), Position = UDim2.new(1, -164, 0.5, -150), BackgroundTransparency = 1 })
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.Parent = col
	Ui.button(col, "SHOP", Color3.fromRGB(230, 160, 20), { Size = UDim2.new(1, 0, 0, 56) }, actions.shop)
	Ui.button(col, "REBIRTH", Color3.fromRGB(220, 60, 170), { Size = UDim2.new(1, 0, 0, 56) }, actions.rebirth)
	lockBtn = Ui.button(col, "LOCK", Color3.fromRGB(210, 50, 60), { Size = UDim2.new(1, 0, 0, 56) }, actions.lock)
	Ui.button(col, "INDEX", Color3.fromRGB(60, 120, 230), { Size = UDim2.new(1, 0, 0, 56) }, actions.index)
	Ui.button(col, "HOME", Color3.fromRGB(40, 170, 120), { Size = UDim2.new(1, 0, 0, 56) }, actions.home)
	-- 底部提示
	Ui.label(gui, "HOLD [E] GRAB  -  CARRY HOME  -  HIDE FROM THE SAUCE WAVE", { Size = UDim2.new(0.7, 0, 0, 26), Position = UDim2.new(0.15, 0, 1, -40), TextColor3 = Ui.INK })
	-- 中央大字与消息
	bigText = Ui.label(gui, "", { Size = UDim2.new(0.8, 0, 0, 90), Position = UDim2.new(0.1, 0, 0.3, 0), TextColor3 = Ui.GOLD, TextTransparency = 1, TextStrokeTransparency = 1 })
	toastHolder = Ui.frame(gui, { Size = UDim2.fromOffset(520, 200), Position = UDim2.new(0.5, -260, 0.58, 0), BackgroundTransparency = 1 })
	local tl = Instance.new("UIListLayout")
	tl.VerticalAlignment = Enum.VerticalAlignment.Bottom
	tl.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tl.Padding = UDim.new(0, 4)
	tl.Parent = toastHolder
	return gui
end

function Hud.setVisible(on: boolean)
	gui.Enabled = on
end

local function rarityHex(name: string): string
	local c = Config.Rarities[Config.RarityIndex[Config.CastByName[name].rarity]].color
	if Config.CastByName[name].rarity == "Secret" then
		c = Color3.fromRGB(255, 255, 255)
	end
	return string.format("#%02X%02X%02X", c.R * 255, c.G * 255, c.B * 255)
end

function Hud.update(s: any)
	state = s
	rateText.Text = "+$" .. Econ.format(s.perSecond) .. "/s"
	multText.Text = "REBIRTH x" .. tostring(Econ.rebirthMult(s.rebirths))
	carryBox.Title.Text = "CARRYING " .. #s.carrying .. "/" .. s.carryCap
	if #s.carrying == 0 then
		carryList.Text = "nothing yet\n- go grab one!"
	else
		local lines = {}
		for _, c in s.carrying do
			local mut = c.mutation ~= "Normal" and (string.upper(c.mutation) .. " ") or ""
			table.insert(lines, string.format('<font color="%s">%s%s</font>', rarityHex(c.name), mut, c.name))
		end
		carryList.Text = table.concat(lines, "\n")
	end
end

-- 每帧刷新：金币滚动、倒计时、事件、锁冷却
function Hud.step(dt: number)
	if not state then
		return
	end
	shownCoins += (state.coins - shownCoins) * math.min(1, dt * 8)
	if math.abs(state.coins - shownCoins) < 1 then
		shownCoins = state.coins
	end
	coinsText.Text = "$" .. Econ.format(shownCoins)
	local now = workspace:GetServerTimeNow()
	local phase = ReplicatedStorage:GetAttribute("WavePhase")
	local left = math.max(0, (ReplicatedStorage:GetAttribute("WaveEndsAt") or now) - now)
	local W = Config.WAVE
	if phase == "calm" then
		waveText.Text = string.format("SAUCE TSUNAMI IN %ds", math.ceil(left))
		waveText.TextColor3 = Ui.INK
		waveFill.Size = UDim2.fromScale(math.clamp(1 - left / W.interval, 0, 1), 1)
	elseif phase == "warning" then
		waveText.Text = string.format("!! TSUNAMI IN %d - RUN HOME !!", math.ceil(left))
		waveText.TextColor3 = (math.floor(now * 4) % 2 == 0) and Ui.GOLD or Ui.INK
		waveFill.Size = UDim2.fromScale(1, 1)
	else
		waveText.Text = "WAVE! HIDE AT BASE OR SAFE ROOF"
		waveText.TextColor3 = Ui.GOLD
		waveFill.Size = UDim2.fromScale(math.clamp(left / ((W.startX - W.endX) / W.speed), 0, 1), 1)
	end
	local ev = ReplicatedStorage:GetAttribute("EventName")
	if ev and ev ~= "" then
		eventBox.Visible = true
		local evLeft = math.max(0, (ReplicatedStorage:GetAttribute("EventEndsAt") or now) - now)
		eventText.Text = string.format("%s! %s  %ds", ev, ReplicatedStorage:GetAttribute("EventDesc") or "", math.ceil(evLeft))
	else
		eventBox.Visible = false
	end
	if now < state.lockedUntil then
		lockBtn.Text = string.format("LOCKED %d", math.ceil(state.lockedUntil - now))
		lockBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 90)
	elseif now < state.lockReadyAt then
		lockBtn.Text = string.format("LOCK %ds", math.ceil(state.lockReadyAt - now))
		lockBtn.BackgroundColor3 = Color3.fromRGB(90, 70, 90)
	else
		lockBtn.Text = "LOCK"
		lockBtn.BackgroundColor3 = Color3.fromRGB(210, 50, 60)
	end
end

function Hud.toast(text: string, color: Color3?)
	local t = Ui.label(toastHolder, text, { Size = UDim2.new(1, 0, 0, 30), TextColor3 = color or Ui.INK })
	task.delay(3, function()
		TweenService:Create(t, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		task.wait(0.5)
		t:Destroy()
	end)
	local kids = toastHolder:GetChildren()
	if #kids > 7 then
		for _, k in kids do
			if k:IsA("TextLabel") then
				k:Destroy()
				break
			end
		end
	end
end

function Hud.big(text: string, color: Color3?)
	bigText.Text = text
	bigText.TextColor3 = color or Ui.GOLD
	bigText.TextTransparency = 0
	bigText.TextStrokeTransparency = 0
	bigText.Size = UDim2.new(0.8, 0, 0, 130)
	TweenService:Create(bigText, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Size = UDim2.new(0.8, 0, 0, 90) }):Play()
	task.delay(1.8, function()
		if bigText.Text == text then
			TweenService:Create(bigText, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

return Hud
