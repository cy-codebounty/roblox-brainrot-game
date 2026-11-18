-- 客户端入口：标题画面 → HUD；接收服务端状态与通知，转成界面反馈和特效
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Econ = require(Shared.Econ)
local Ui = require(script.Ui)
local Hud = require(script.Hud)
local Panels = require(script.Panels)
local Effects = require(script.Effects)
local TitleScreen = require(script.TitleScreen)

local stateRemote = ReplicatedStorage:WaitForChild("State") :: RemoteEvent
local notifyRemote = ReplicatedStorage:WaitForChild("Notify") :: RemoteEvent
local request = ReplicatedStorage:WaitForChild("Request") :: RemoteEvent

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
end)

Effects.build()
Panels.build(request)
Hud.build({
	shop = function()
		Panels.open("shop")
	end,
	rebirth = function()
		Panels.open("rebirth")
	end,
	index = function()
		Panels.open("index")
	end,
	lock = function()
		request:FireServer("lock")
	end,
	home = function()
		request:FireServer("home")
	end,
})
Hud.setVisible(false)

local lastCoins: number? = nil
stateRemote.OnClientEvent:Connect(function(s)
	Hud.update(s)
	Panels.update(s)
	if lastCoins and s.coins > lastCoins + 0.5 then
		Effects.popup("+$" .. Econ.format(s.coins - lastCoins), Ui.GOLD)
	end
	lastCoins = s.coins
end)

local function rarityColor(name: string): Color3
	-- Secret 的稀有度色是黑色，屏幕大字上看不清，改用白色
	if Config.CastByName[name].rarity == "Secret" then
		return Ui.INK
	end
	return Config.Rarities[Config.RarityIndex[Config.CastByName[name].rarity]].color
end

local THIEF_TEXT = {
	incoming = { "PINCHY THE PIGEON IS COMING FOR YOUR BASE!", Ui.RED },
	blocked = { "LASER SHIELD BLOCKED THE THIEF!", Ui.MINT },
	stolen = { "STOLEN! CATCH PINCHY BEFORE THE SEA!", Ui.RED },
	recovered = { "YOU GOT IT BACK!", Ui.MINT },
	scared = { "PINCHY RAN AWAY EMPTY-HANDED", Ui.MINT },
	escaped = { "PINCHY ESCAPED WITH YOUR BRAINROT...", Ui.RED },
}

notifyRemote.OnClientEvent:Connect(function(kind: string, d: any)
	if kind == "grabbed" then
		local mut = d.mutation ~= "Normal" and (string.upper(d.mutation) .. " ") or ""
		Hud.toast("GOT " .. mut .. d.name .. "! RUN HOME!", rarityColor(d.name))
		Effects.play("grab", 1.2)
	elseif kind == "placed" then
		if d.new then
			Hud.big("NEW BRAINROT: " .. d.name, rarityColor(d.name))
		end
		Hud.toast(d.name .. " is earning at your base", Ui.MINT)
		Effects.play("place", 1.6)
	elseif kind == "full" then
		Hud.toast(d.what == "base" and "BASE FULL! SELL [F] OR BUY PEDESTALS" or "HANDS FULL! BRING THEM HOME", Ui.RED)
	elseif kind == "lost" then
		if d.reason == "wave" then
			Hud.toast("THE SAUCE ATE: " .. table.concat(d.names, ", "), Ui.RED)
		end
	elseif kind == "wiped" then
		Hud.big("WIPEOUT!", Ui.RED)
		Effects.flash(Color3.fromRGB(255, 40, 20))
		Effects.shake(2)
		Effects.play("wiped")
	elseif kind == "sold" then
		Hud.toast("SOLD " .. d.name .. " +$" .. Econ.format(d.value), Ui.GOLD)
	elseif kind == "locked" then
		Hud.toast("BASE LOCKED FOR " .. d.duration .. "s", Ui.MINT)
	elseif kind == "upgraded" then
		Hud.toast(Config.Upgrades[d.id].label .. " UPGRADED TO LV " .. d.lv, Ui.MINT)
		Effects.play("place", 2)
	elseif kind == "broke" then
		Hud.toast("NEED $" .. Econ.format(d.need), Ui.RED)
	elseif kind == "rebirth" then
		Hud.big("REBIRTH " .. d.n .. "! INCOME x" .. d.mult, Ui.PINK)
		Effects.flash(Color3.fromRGB(255, 120, 220))
	elseif kind == "thief" then
		local t = THIEF_TEXT[d.stage]
		if t then
			if d.stage == "incoming" or d.stage == "stolen" then
				Hud.big(t[1], t[2])
				Effects.play("alarm", 0.6)
			else
				Hud.toast(t[1], t[2])
			end
		end
	end
end)

-- 海浪阶段切换时的大字提醒
ReplicatedStorage:GetAttributeChangedSignal("WavePhase"):Connect(function()
	local phase = ReplicatedStorage:GetAttribute("WavePhase")
	if phase == "warning" then
		Hud.big("SAUCE TSUNAMI INCOMING!", Ui.RED)
		Effects.play("alarm", 0.5)
	elseif phase == "calm" then
		Hud.toast("The wave is gone. Go catch more!", Ui.MINT)
	end
end)
ReplicatedStorage:GetAttributeChangedSignal("EventName"):Connect(function()
	local ev = ReplicatedStorage:GetAttribute("EventName")
	if ev and ev ~= "" then
		Hud.big(ev .. "!", Ui.PINK)
	end
end)

RunService.RenderStepped:Connect(function(dt)
	Hud.step(dt)
	Effects.step(dt)
end)

TitleScreen.show(function()
	Hud.setVisible(true)
	request:FireServer("sync")
end)
