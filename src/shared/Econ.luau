-- 经济公式：价格、收入、随机抽取与数字格式化（纯函数，两端共用）
local Config = require(script.Parent.Config)

local Econ = {}

local SUFFIX = { "", "K", "M", "B", "T", "Qa", "Qi" }

function Econ.format(n: number): string
	n = math.floor(n)
	if n < 1000 then
		return tostring(n)
	end
	local i = 1
	local v = n
	while v >= 1000 and i < #SUFFIX do
		v /= 1000
		i += 1
	end
	return string.format(v < 10 and "%.2f%s" or (v < 100 and "%.1f%s" or "%d%s"), v, SUFFIX[i])
end

function Econ.upgradePrice(id: string, lv: number): number
	local u = Config.Upgrades[id]
	return math.floor(u.base * u.growth ^ lv)
end

function Econ.rebirthCost(rebirths: number): number
	return math.floor(Config.REBIRTH_BASE * Config.REBIRTH_GROWTH ^ rebirths)
end

function Econ.rebirthMult(rebirths: number): number
	return 1 + Config.REBIRTH_MULT * rebirths
end

-- 单只角色每秒收入（不含事件倍率）
function Econ.incomeOf(name: string, mutation: string, rebirths: number): number
	local c = Config.CastByName[name]
	local m = Config.MutationById[mutation] or Config.MutationById.Normal
	return c.income * m.mult * Econ.rebirthMult(rebirths)
end

function Econ.sellValue(name: string, mutation: string): number
	local c = Config.CastByName[name]
	local m = Config.MutationById[mutation] or Config.MutationById.Normal
	return c.income * m.mult * Config.SELL_SECONDS
end

-- 按权重抽一个稀有度，再在该稀有度里随机挑角色
function Econ.rollCast(weights: { number }, rng: Random): any
	local total = 0
	for _, w in weights do
		total += w
	end
	local pick = rng:NextNumber() * total
	local rarity = Config.Rarities[1].id
	for i, w in weights do
		pick -= w
		if pick <= 0 and w > 0 then
			rarity = Config.Rarities[i].id
			break
		end
	end
	local pool = {}
	for _, c in Config.Cast do
		if c.rarity == rarity then
			table.insert(pool, c)
		end
	end
	return pool[rng:NextInteger(1, #pool)]
end

function Econ.rollMutation(luck: number, rng: Random): string
	for i = #Config.Mutations, 2, -1 do
		local m = Config.Mutations[i]
		if rng:NextNumber() < m.chance * luck then
			return m.id
		end
	end
	return "Normal"
end

return Econ
