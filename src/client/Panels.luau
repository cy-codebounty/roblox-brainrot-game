-- 弹出面板：商店（升级）、重生、图鉴
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Econ = require(Shared.Econ)
local Ui = require(script.Parent.Ui)

local Panels = {}

local gui: ScreenGui
local modal: Frame
local title: TextLabel
local body: Frame
local current: string? = nil
local state: any = nil
local request: RemoteEvent

local UPGRADE_DESC = {
	speed = function(lv)
		return "WALK " .. (Config.BASE_SPEED + Config.SPEED_PER_LV * lv)
	end,
	carry = function(lv)
		return "HOLD " .. (1 + lv) .. " AT ONCE"
	end,
	slots = function(lv)
		return (Config.BASE_SLOTS + Config.SLOTS_PER_LV * lv) .. " PEDESTALS"
	end,
}

function Panels.build(requestRemote: RemoteEvent)
	request = requestRemote
	gui = Ui.screen("Panels", 10)
	modal = Ui.frame(gui, { Size = UDim2.fromOffset(620, 430), Position = UDim2.new(0.5, -310, 0.5, -200), Visible = false })
	Ui.stroke(modal, Ui.GOLD, 5)
	title = Ui.label(modal, "", { Size = UDim2.new(1, -80, 0, 50), Position = UDim2.fromOffset(16, 10), TextColor3 = Ui.GOLD, TextXAlignment = Enum.TextXAlignment.Left })
	Ui.button(modal, "X", Ui.RED, { Size = UDim2.fromOffset(48, 48), Position = UDim2.new(1, -60, 0, 10) }, function()
		Panels.close()
	end)
	body = Ui.frame(modal, { Size = UDim2.new(1, -32, 1, -80), Position = UDim2.fromOffset(16, 68), BackgroundTransparency = 1 })
end

local function clear()
	for _, c in body:GetChildren() do
		c:Destroy()
	end
end

local function renderShop()
	title.Text = "UPGRADE SHOP"
	local order = { "speed", "carry", "slots" }
	for i, id in order do
		local u = Config.Upgrades[id]
		local lv = state.upgrades[id]
		local row = Ui.frame(body, { Size = UDim2.new(1, 0, 0, 96), Position = UDim2.fromOffset(0, (i - 1) * 110), BackgroundColor3 = Color3.fromRGB(55, 38, 90) })
		Ui.stroke(row, Color3.fromRGB(0, 0, 0), 3)
		Ui.label(row, u.label .. "  LV " .. lv .. "/" .. u.max, { Size = UDim2.new(0.6, 0, 0, 40), Position = UDim2.fromOffset(12, 8), TextXAlignment = Enum.TextXAlignment.Left })
		local nextText = lv < u.max and ("NEXT: " .. UPGRADE_DESC[id](lv + 1)) or "MAXED OUT"
		Ui.label(row, nextText, { Size = UDim2.new(0.6, 0, 0, 30), Position = UDim2.fromOffset(12, 54), TextColor3 = Ui.MINT, TextXAlignment = Enum.TextXAlignment.Left })
		local price = Econ.upgradePrice(id, lv)
		local can = lv < u.max and state.coins >= price
		Ui.button(row, lv < u.max and ("$" .. Econ.format(price)) or "MAX", can and Color3.fromRGB(40, 180, 80) or Color3.fromRGB(100, 90, 110), { Size = UDim2.new(0.34, 0, 0, 70), Position = UDim2.new(0.64, 0, 0, 13) }, function()
			request:FireServer("upgrade", id)
		end)
	end
end

local function renderRebirth()
	title.Text = "REBIRTH"
	local cost = Econ.rebirthCost(state.rebirths)
	local nextMult = Econ.rebirthMult(state.rebirths + 1)
	Ui.label(body, "REBIRTHS: " .. state.rebirths, { Size = UDim2.new(1, 0, 0, 40), TextColor3 = Ui.PINK })
	Ui.label(body, "COST  $" .. Econ.format(cost), { Size = UDim2.new(1, 0, 0, 44), Position = UDim2.fromOffset(0, 50), TextColor3 = Ui.GOLD })
	Ui.label(body, "LOSE: coins, brainrots, upgrades\nKEEP: your Index\nGAIN: ALL INCOME x" .. nextMult .. " FOREVER", { Size = UDim2.new(1, 0, 0, 120), Position = UDim2.fromOffset(0, 104), TextScaled = false, TextSize = 26 })
	local can = state.coins >= cost
	Ui.button(body, can and "REBIRTH NOW!" or "NEED MORE $", can and Ui.PINK or Color3.fromRGB(100, 90, 110), { Size = UDim2.new(0.6, 0, 0, 70), Position = UDim2.new(0.2, 0, 1, -76) }, function()
		request:FireServer("rebirth")
		Panels.close()
	end)
end

local function renderIndex()
	title.Text = string.format("BRAINROT INDEX  %d/%d", state.found, #Config.Cast)
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(110, 64)
	grid.CellPadding = UDim2.fromOffset(6, 6)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = body
	for i, c in Config.Cast do
		local seen = state.discovered[c.name]
		local rc = Config.Rarities[Config.RarityIndex[c.rarity]].color
		local cell = Ui.frame(body, { LayoutOrder = i, BackgroundColor3 = seen and Color3.fromRGB(60, 45, 95) or Color3.fromRGB(30, 30, 35) })
		Ui.stroke(cell, seen and rc or Color3.fromRGB(70, 70, 70), 3)
		Ui.label(cell, seen and c.name or "???", { Size = UDim2.new(1, -6, 0.62, 0), Position = UDim2.fromOffset(3, 2) })
		Ui.label(cell, string.upper(c.rarity), { Size = UDim2.new(1, -6, 0.34, 0), Position = UDim2.new(0, 3, 0.64, 0), TextColor3 = c.rarity == "Secret" and Ui.INK or rc })
	end
end

function Panels.open(which: string)
	if not state then
		return
	end
	if current == which and modal.Visible then
		Panels.close()
		return
	end
	current = which
	clear()
	if which == "shop" then
		renderShop()
	elseif which == "rebirth" then
		renderRebirth()
	else
		renderIndex()
	end
	modal.Visible = true
end

function Panels.close()
	modal.Visible = false
	current = nil
end

function Panels.update(s: any)
	state = s
	if modal.Visible and current then
		local which = current
		current = nil
		Panels.open(which)
	end
end

return Panels
