-- Snackrot Market: shared data. One source of truth for the cast, rarities,
-- mutations, bases and economy, used by the server and the client alike.

local Data = {}

Data.GAME_NAME = "Snackrot Market"
Data.START_MONEY = 150
Data.BASE_SLOTS = 6
Data.BELT_START_X = -100
Data.BELT_END_X = 100
Data.BELT_GROUND_Y = 1 -- top of the conveyor belt
Data.BELT_SPEED = 8 -- studs per second
Data.BELT_SPAWN_INTERVAL = 3 -- seconds between spawns
Data.BELT_MAX = 8 -- most snackrots on the belt at once
Data.WAVE_INTERVAL = 120 -- seconds between Snack Storms
Data.WAVE_FIRST = 90 -- first storm, seconds after the server starts
Data.WAVE_WARN = 10 -- warning seconds before the storm hits
Data.SELL_REFUND = 0.5 -- share of the buy price a sale returns
Data.STEAL_HOLD = 3 -- seconds a steal takes to channel
Data.STEAL_DEFEND_RADIUS = 30 -- owner within this many studs of their base blocks a steal

Data.RARITIES = {
	Common = { weight = 60, color = Color3.fromRGB(220, 220, 220), labelColor = Color3.fromRGB(255, 255, 255) },
	Rare = { weight = 25, color = Color3.fromRGB(80, 140, 255), labelColor = Color3.fromRGB(150, 190, 255) },
	Epic = { weight = 11, color = Color3.fromRGB(180, 80, 255), labelColor = Color3.fromRGB(210, 150, 255) },
	Legendary = { weight = 4, color = Color3.fromRGB(255, 200, 40), labelColor = Color3.fromRGB(255, 220, 120) },
}

Data.RARITY_ORDER = { "Common", "Rare", "Epic", "Legendary" }

Data.MUTATIONS = {
	{ name = "Normal", mult = 1, weight = 86, color = Color3.fromRGB(255, 255, 255) },
	{ name = "Golden", mult = 2, weight = 10, color = Color3.fromRGB(255, 215, 0) },
	{ name = "Diamond", mult = 5, weight = 3, color = Color3.fromRGB(120, 220, 255) },
	{ name = "Rainbow", mult = 10, weight = 1, color = Color3.fromRGB(255, 120, 200) },
}

-- The cast: original snack-animal hybrids, each with a rarity, a money rate
-- and a buy price. Rates are money per second once the snackrot is on a base.
Data.CHARACTERS = {
	{ name = "Mie Meong", rarity = "Common", rate = 4, price = 60, body = Color3.fromRGB(255, 220, 130), accent = Color3.fromRGB(255, 150, 60) },
	{ name = "Burger Banteng", rarity = "Common", rate = 6, price = 100, body = Color3.fromRGB(190, 120, 60), accent = Color3.fromRGB(120, 200, 90) },
	{ name = "Pisang Penguin", rarity = "Common", rate = 9, price = 160, body = Color3.fromRGB(255, 235, 90), accent = Color3.fromRGB(60, 60, 70) },
	{ name = "Kopi Kucing", rarity = "Rare", rate = 16, price = 320, body = Color3.fromRGB(120, 80, 50), accent = Color3.fromRGB(240, 220, 190) },
	{ name = "Durian Dino", rarity = "Rare", rate = 28, price = 600, body = Color3.fromRGB(140, 190, 60), accent = Color3.fromRGB(230, 220, 90) },
	{ name = "Sambal Shark", rarity = "Epic", rate = 50, price = 1100, body = Color3.fromRGB(230, 60, 50), accent = Color3.fromRGB(255, 255, 255) },
	{ name = "Rendang Robot", rarity = "Epic", rate = 90, price = 2000, body = Color3.fromRGB(90, 90, 100), accent = Color3.fromRGB(255, 180, 40) },
	{ name = "Nasi Naga", rarity = "Legendary", rate = 160, price = 4000, body = Color3.fromRGB(255, 240, 180), accent = Color3.fromRGB(255, 90, 60) },
}

-- The four player bases, one per corner of the map.
Data.BASES = {
	{ name = "Base Merah", color = Color3.fromRGB(220, 60, 60), center = Vector3.new(-70, 0, -70) },
	{ name = "Base Biru", color = Color3.fromRGB(60, 110, 235), center = Vector3.new(70, 0, -70) },
	{ name = "Base Hijau", color = Color3.fromRGB(60, 200, 90), center = Vector3.new(-70, 0, 70) },
	{ name = "Base Kuning", color = Color3.fromRGB(235, 200, 40), center = Vector3.new(70, 0, 70) },
}

function Data.rebirthCost(rebirths)
	return 5000 * (2 ^ rebirths)
end

function Data.rebirthMultiplier(rebirths)
	return 1 + 0.5 * rebirths
end

-- Ground position of a base slot: 6 slots in 3 columns x 2 rows, 10 studs
-- apart, centred on the base. The pad top is y = 1.
function Data.slotPosition(baseCenter, slotIndex)
	local col = (slotIndex - 1) % 3
	local row = math.floor((slotIndex - 1) / 3)
	return Vector3.new(baseCenter.X - 10 + col * 10, 1, baseCenter.Z - 6 + row * 12)
end

return Data
