-- Snackrot Market: builds the 3D model of a snackrot character. A body, a head,
-- a rarity ring, a name/rate label and the buy/sell/steal prompts. Server only.
-- The model is positioned with PivotTo, so every part is placed relative to
-- the body (the PrimaryPart) and the whole model moves as one.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Data = require(ReplicatedStorage.Shared.Data)

local CharacterFactory = {}

local BODY_Y = 1.55 -- body centre above the ground point
local HEAD_Y = 3.6 -- head centre above the ground point
local RING_Y = 0.35 -- rarity ring above the ground point

local function displayName(def, mutation)
	if mutation.name == "Normal" then
		return def.name
	end
	return mutation.name .. " " .. def.name
end

function CharacterFactory.displayName(def, mutation)
	return displayName(def, mutation)
end

function CharacterFactory.build(def, mutation, id)
	local rarity = Data.RARITIES[def.rarity]
	local model = Instance.new("Model")
	model.Name = def.name .. "_" .. tostring(id)

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Block
	body.Size = Vector3.new(3, 2.5, 3)
	body.Color = def.body
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.CFrame = CFrame.new(0, BODY_Y, 0)
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(2.4, 2.4, 2.4)
	head.Color = def.accent
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.CFrame = CFrame.new(0, HEAD_Y, 0)
	head.Parent = model

	-- Flat disc under the body, coloured by rarity. A cylinder's long axis is
	-- its X, so it is rotated 90 degrees about Z to lie flat.
	local ring = Instance.new("Part")
	ring.Name = "Ring"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.3, 4.4, 4.4)
	ring.Color = rarity.color
	ring.Material = Enum.Material.Neon
	ring.Anchored = true
	ring.CanCollide = false
	ring.CFrame = CFrame.new(0, RING_Y, 0) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = model

	model.PrimaryPart = body

	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(150, 56)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 4.6, 0)
	gui.AlwaysOnTop = true
	gui.Adornee = body
	gui.Parent = model

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = displayName(def, mutation)
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.Parent = gui

	local subLabel = Instance.new("TextLabel")
	subLabel.Name = "Sub"
	subLabel.Position = UDim2.new(0, 0, 0.5, 0)
	subLabel.Size = UDim2.new(1, 0, 0.5, 0)
	subLabel.BackgroundTransparency = 1
	subLabel.Text = def.rarity .. "  $" .. tostring(def.rate * mutation.mult) .. "/s"
	subLabel.TextColor3 = rarity.labelColor
	subLabel.TextScaled = true
	subLabel.Font = Enum.Font.SourceSans
	subLabel.Parent = gui

	return model
end

-- Places the model so its feet stand on the given ground point.
function CharacterFactory.place(model, groundPosition)
	model:PivotTo(CFrame.new(groundPosition + Vector3.new(0, BODY_Y, 0)))
end

function CharacterFactory.addBuyPrompt(model, def)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Buy"
	prompt.ObjectText = def.name .. " — $" .. tostring(def.price)
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = model
	return prompt
end

function CharacterFactory.addBasePrompts(model, def)
	local sell = Instance.new("ProximityPrompt")
	sell.Name = "SellPrompt"
	sell.ActionText = "Sell"
	sell.ObjectText = def.name .. " — +$" .. tostring(math.floor(def.price * Data.SELL_REFUND))
	sell.HoldDuration = 0.5
	sell.MaxActivationDistance = 10
	sell.RequiresLineOfSight = false
	sell.Parent = model

	local steal = Instance.new("ProximityPrompt")
	steal.Name = "StealPrompt"
	steal.ActionText = "Steal"
	steal.ObjectText = def.name
	steal.HoldDuration = Data.STEAL_HOLD
	steal.MaxActivationDistance = 10
	steal.RequiresLineOfSight = false
	steal.Parent = model

	return sell, steal
end

return CharacterFactory
