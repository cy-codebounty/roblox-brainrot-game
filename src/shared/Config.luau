-- 全局配置：稀有度阶梯、突变、角色图鉴、区域、升级与重生数值。单一数据源，服务端与客户端共享。
local Config = {}

Config.GAME_NAME = "BRAINROT BAY"

-- 稀有度阶梯（越往后越稀有）
Config.Rarities = {
	{ id = "Common", color = Color3.fromRGB(200, 200, 200), scale = 1.25 },
	{ id = "Uncommon", color = Color3.fromRGB(110, 230, 110), scale = 1.35 },
	{ id = "Rare", color = Color3.fromRGB(80, 170, 255), scale = 1.45 },
	{ id = "Epic", color = Color3.fromRGB(190, 100, 255), scale = 1.55 },
	{ id = "Legendary", color = Color3.fromRGB(255, 200, 40), scale = 1.65 },
	{ id = "Mythic", color = Color3.fromRGB(255, 70, 90), scale = 1.75 },
	{ id = "Secret", color = Color3.fromRGB(20, 20, 20), scale = 1.9 },
}
Config.RarityIndex = {}
for i, r in Config.Rarities do
	Config.RarityIndex[r.id] = i
end

-- 突变：收入倍率 + 外观
Config.Mutations = {
	{ id = "Normal", mult = 1, chance = 0 },
	{ id = "Gold", mult = 2, chance = 0.10, color = Color3.fromRGB(255, 205, 50), material = Enum.Material.Foil },
	{ id = "Diamond", mult = 3, chance = 0.05, color = Color3.fromRGB(150, 235, 255), material = Enum.Material.Glass },
	{ id = "Lava", mult = 5, chance = 0.025, color = Color3.fromRGB(255, 90, 20), material = Enum.Material.Neon },
	{ id = "Rainbow", mult = 10, chance = 0.01, color = Color3.fromRGB(255, 120, 220), material = Enum.Material.Neon },
}
Config.MutationById = {}
for _, m in Config.Mutations do
	Config.MutationById[m.id] = m
end

local C = Color3.fromRGB
-- 角色图鉴：body 为形体，feats 为装饰件，income 为每秒金币
Config.Cast = {
	{ name = "Toastini Toastolini", rarity = "Common", income = 2, body = "block", size = Vector3.new(3, 3.4, 1.2), main = C(222, 170, 90), accent = C(140, 85, 40), feats = { "legs", "arms" } },
	{ name = "Bobbo Bananini", rarity = "Common", income = 3, body = "cyl", size = Vector3.new(1.6, 4, 1.6), main = C(255, 225, 60), accent = C(110, 80, 30), feats = { "legs", "shades" } },
	{ name = "Socko Goblino", rarity = "Common", income = 4, body = "block", size = Vector3.new(1.6, 3.6, 1.6), main = C(240, 240, 240), accent = C(230, 60, 60), feats = { "legs", "antenna" } },
	{ name = "Cupcakko Spinnerino", rarity = "Uncommon", income = 8, body = "cyl", size = Vector3.new(3, 2.4, 3), main = C(255, 150, 200), accent = C(120, 70, 40), feats = { "legs", "hat" } },
	{ name = "Teapotto Tornado", rarity = "Uncommon", income = 11, body = "ball", size = Vector3.new(3.2, 3.2, 3.2), main = C(90, 200, 190), accent = C(255, 255, 255), feats = { "legs", "tail", "mustache" } },
	{ name = "Croissanto Cowboyo", rarity = "Uncommon", income = 14, body = "ball", size = Vector3.new(3.6, 2.2, 2.2), main = C(230, 160, 70), accent = C(120, 70, 30), feats = { "legs", "hat", "mustache" } },
	{ name = "Mopperino Wetfloor", rarity = "Rare", income = 30, body = "cyl", size = Vector3.new(1, 5, 1), main = C(250, 220, 30), accent = C(60, 60, 200), feats = { "legs", "antenna", "shades" } },
	{ name = "Cactusso Disco", rarity = "Rare", income = 40, body = "cyl", size = Vector3.new(2, 4.6, 2), main = C(60, 170, 70), accent = C(255, 80, 200), feats = { "arms", "shades", "crown" } },
	{ name = "Fridgezilla Coolini", rarity = "Rare", income = 55, body = "block", size = Vector3.new(2.8, 4.6, 2.4), main = C(220, 235, 245), accent = C(40, 120, 220), feats = { "legs", "horns", "tail" } },
	{ name = "Moai Gelatoso", rarity = "Epic", income = 120, body = "block", size = Vector3.new(2.6, 5, 2.4), main = C(150, 140, 130), accent = C(255, 170, 200), feats = { "hat", "mustache" } },
	{ name = "Sushi Samuraino", rarity = "Epic", income = 160, body = "cyl", size = Vector3.new(3, 2.6, 3), main = C(250, 250, 245), accent = C(240, 110, 70), feats = { "legs", "horns", "arms" } },
	{ name = "Nonna 8-Bit", rarity = "Epic", income = 210, body = "block", size = Vector3.new(2.6, 3.6, 2.6), main = C(160, 110, 200), accent = C(240, 240, 240), feats = { "legs", "shades", "hat" } },
	{ name = "Duckzilla Bathbomba", rarity = "Legendary", income = 480, body = "ball", size = Vector3.new(4.4, 4, 4.4), main = C(255, 220, 30), accent = C(255, 140, 20), feats = { "legs", "wings", "crown" } },
	{ name = "Cappuccino Satellito", rarity = "Legendary", income = 640, body = "cyl", size = Vector3.new(3, 3.4, 3), main = C(120, 80, 50), accent = C(200, 200, 220), feats = { "wings", "antenna", "halo" } },
	{ name = "Dumplingo Dynamo", rarity = "Legendary", income = 820, body = "ball", size = Vector3.new(4, 3, 4), main = C(250, 240, 220), accent = C(255, 60, 60), feats = { "legs", "arms", "horns" } },
	{ name = "Spaghetti Kraken", rarity = "Mythic", income = 2000, body = "ball", size = Vector3.new(5, 4, 5), main = C(250, 200, 90), accent = C(200, 30, 30), feats = { "tentacles", "shades", "crown" } },
	{ name = "Disco Moai Supremo", rarity = "Mythic", income = 2800, body = "block", size = Vector3.new(3.6, 6.4, 3.2), main = C(70, 60, 80), accent = C(255, 60, 220), feats = { "halo", "shades", "wings" } },
	{ name = "Lasagnatron 3000", rarity = "Mythic", income = 3600, body = "block", size = Vector3.new(5, 3, 3.6), main = C(230, 120, 50), accent = C(130, 220, 255), feats = { "legs", "antenna", "arms" } },
	{ name = "Il Grande Sauceboss", rarity = "Secret", income = 12000, body = "ball", size = Vector3.new(6, 6, 6), main = C(200, 20, 20), accent = C(255, 230, 60), feats = { "crown", "mustache", "tentacles", "halo" } },
	{ name = "Glitchy Pigeonardo", rarity = "Secret", income = 18000, body = "ball", size = Vector3.new(4.4, 5, 4.4), main = C(80, 255, 140), accent = C(255, 0, 255), feats = { "wings", "legs", "shades", "halo" } },
}
Config.CastByName = {}
for i, c in Config.Cast do
	c.index = i
	Config.CastByName[c.name] = c
end

-- 地图：基地在 X 负方向，田野向 +X 延伸到酱汁海；越远越稀有
Config.FIELD = { minX = 10, maxX = 400, halfZ = 120 }
Config.SEA_X = 410
Config.Zones = {
	{ name = "Candy Meadow", minX = 10, maxX = 90, tile = { C(130, 220, 110), C(110, 200, 95) }, weights = { 70, 25, 5, 0, 0, 0, 0 } },
	{ name = "Toast Dunes", minX = 90, maxX = 170, tile = { C(240, 210, 140), C(225, 190, 120) }, weights = { 30, 45, 20, 5, 0, 0, 0 } },
	{ name = "Moai Ruins", minX = 170, maxX = 250, tile = { C(170, 160, 190), C(150, 140, 170) }, weights = { 5, 30, 40, 20, 5, 0, 0 } },
	{ name = "Lava Flats", minX = 250, maxX = 330, tile = { C(90, 60, 70), C(70, 45, 55) }, weights = { 0, 5, 30, 40, 20, 5, 0 } },
	{ name = "Sauce Shore", minX = 330, maxX = 400, tile = { C(255, 150, 120), C(240, 130, 100) }, weights = { 0, 0, 10, 35, 35, 17, 3 } },
}
Config.WILD_PER_ZONE = 8

-- 基地：4 块地皮，沿 Z 排开
Config.PLOT_X = -45
Config.PLOT_Z = { -105, -35, 35, 105 }
Config.PLOT_SIZE = Vector3.new(66, 1, 62)
Config.PLOT_COLORS = { C(255, 90, 90), C(80, 160, 255), C(255, 200, 60), C(170, 100, 255) }

-- 海浪威胁
Config.WAVE = { interval = 42, warn = 8, speed = 24, height = 34, startX = 440, endX = -6 }
Config.SHELTERS = { Vector3.new(130, 0, -70), Vector3.new(130, 0, 70), Vector3.new(290, 0, 0), Vector3.new(210, 0, -95), Vector3.new(210, 0, 95) }
Config.SHELTER_RADIUS = 9

-- 小偷 NPC 与基地锁
Config.THIEF = { interval = 50, speed = 21, grabTime = 1.2 }
Config.LOCK = { duration = 25, cooldown = 45 }

-- 升级：等级 0 起，价格 = base * growth^lv
Config.Upgrades = {
	speed = { label = "SPEED", max = 8, base = 120, growth = 2.1 },
	carry = { label = "CARRY", max = 3, base = 600, growth = 6 },
	slots = { label = "PEDESTALS", max = 4, base = 300, growth = 3.6 },
}
Config.BASE_SPEED = 20
Config.SPEED_PER_LV = 3
Config.BASE_SLOTS = 4
Config.SLOTS_PER_LV = 2

-- 重生
Config.REBIRTH_BASE = 40000
Config.REBIRTH_GROWTH = 6
Config.REBIRTH_MULT = 0.5
Config.SELL_SECONDS = 15
Config.START_COINS = 0

-- 每次海浪后的随机事件
Config.Events = {
	{ id = "DOUBLE CASH", desc = "All income x2", duration = 30 },
	{ id = "MUTATION STORM", desc = "Mutations x4 more likely", duration = 30 },
	{ id = "LEGEND RAIN", desc = "Rare brainrots everywhere", duration = 30 },
}

return Config
