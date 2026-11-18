-- 每波海浪退去后随机触发一个限时事件：双倍收入 / 突变风暴 / 稀有雨
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)
local FieldService = require(script.Parent.FieldService)
local BaseService = require(script.Parent.BaseService)

local EventService = {}

local rng = Random.new()
local active = false

local function apply(id: string, on: boolean)
	if id == "DOUBLE CASH" then
		BaseService.incomeMult = on and 2 or 1
	elseif id == "MUTATION STORM" then
		FieldService.luck = on and 4 or 1
		if on then
			FieldService.reroll()
		end
	elseif id == "LEGEND RAIN" then
		FieldService.rarityBoost = on and 2 or 0
		FieldService.reroll()
	end
end

function EventService.trigger(id: string?)
	if active then
		return
	end
	local ev = Config.Events[rng:NextInteger(1, #Config.Events)]
	if id then
		for _, e in Config.Events do
			if e.id == id then
				ev = e
			end
		end
	end
	active = true
	apply(ev.id, true)
	ReplicatedStorage:SetAttribute("EventName", ev.id)
	ReplicatedStorage:SetAttribute("EventDesc", ev.desc)
	ReplicatedStorage:SetAttribute("EventEndsAt", workspace:GetServerTimeNow() + ev.duration)
	task.delay(ev.duration, function()
		apply(ev.id, false)
		ReplicatedStorage:SetAttribute("EventName", "")
		active = false
	end)
end

return EventService
