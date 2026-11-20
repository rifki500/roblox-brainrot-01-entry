-- Snackrot Market: server game logic. Owns the belt, the bases, the economy,
-- stealing, rebirths and the Snack Storm. All state lives here; the client
-- only renders what the server sends it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Data = require(ReplicatedStorage.Shared.Data)
local CharacterFactory = require(script.Parent.CharacterFactory)

local Game = {}

local rebirthEvent = ReplicatedStorage.Events.Rebirth
local stateEvent = ReplicatedStorage.Events.StateUpdate

-- player state: [player] = { money, rebirths, baseIndex, slots, marker }
local players = {}
local claimedBases = {}
-- belt records, in spawn order: { id, kind, def, mutation, model, x, buyPrompt }
local belt = {}
-- every live character record, by its model, belt or base alike.
local recordsByModel = {}
local nextId = 1
local waveActive = false
local waveWallX = nil

local function pickWeighted(list)
	local total = 0
	for _, item in ipairs(list) do
		total += item.weight
	end
	local roll = math.random() * total
	for _, item in ipairs(list) do
		roll -= item.weight
		if roll <= 0 then
			return item
		end
	end
	return list[1]
end

local function rollCharacter()
	-- Pick a rarity by weight, then a character of that rarity.
	local rarityList = {}
	for _, name in ipairs(Data.RARITY_ORDER) do
		table.insert(rarityList, { name = name, weight = Data.RARITIES[name].weight })
	end
	local rarityName = pickWeighted(rarityList).name
	local pool = {}
	for _, def in ipairs(Data.CHARACTERS) do
		if def.rarity == rarityName then
			table.insert(pool, def)
		end
	end
	local def = pool[math.random(#pool)]
	local mutation = pickWeighted(Data.MUTATIONS)
	return def, mutation
end

local function incomePerSecond(state)
	local total = 0
	for _, record in pairs(state.slots) do
		if record then
			total += record.def.rate * record.mutation.mult
		end
	end
	return total * Data.rebirthMultiplier(state.rebirths)
end

local function sendState(player, feed)
	local state = players[player]
	if not state then
		return
	end
	stateEvent:FireClient(player, {
		Money = math.floor(state.money),
		Income = math.floor(incomePerSecond(state)),
		Rebirths = state.rebirths,
		Multiplier = Data.rebirthMultiplier(state.rebirths),
		RebirthCost = Data.rebirthCost(state.rebirths),
		Feed = feed or "",
	})
end

local function broadcast(feed)
	for player, _ in pairs(players) do
		sendState(player, feed)
	end
end

local function freeSlot(state)
	for i = 1, Data.BASE_SLOTS do
		if not state.slots[i] then
			return i
		end
	end
	return nil
end

local function removeFromBelt(record)
	for i, item in ipairs(belt) do
		if item == record then
			table.remove(belt, i)
			return
		end
	end
end

local function tryBuy(player, record)
	if not record.model.Parent then
		return -- already swept, sold or stolen away
	end
	if record.kind ~= "belt" then
		return
	end
	local state = players[player]
	if not state then
		return
	end
	if state.money < record.def.price then
		sendState(player, "Not enough money for " .. CharacterFactory.displayName(record.def, record.mutation) .. " ($" .. tostring(record.def.price) .. ").")
		return
	end
	local slot = freeSlot(state)
	if not slot then
		sendState(player, "Your base is full! Sell a snackrot or rebirth.")
		return
	end
	state.money -= record.def.price
	removeFromBelt(record)
	record.kind = "base"
	record.owner = player
	record.slot = slot
	state.slots[slot] = record
	record.buyPrompt:Destroy()
	record.buyPrompt = nil
	local sellPrompt, stealPrompt = CharacterFactory.addBasePrompts(record.model, record.def)
	record.sellPrompt = sellPrompt
	record.stealPrompt = stealPrompt
	sellPrompt.Triggered:Connect(function(other)
		Game._onSellPrompt(sellPrompt, other)
	end)
	stealPrompt.Triggered:Connect(function(other)
		Game._onStealPrompt(stealPrompt, other)
	end)
	local pos = Data.slotPosition(Data.BASES[state.baseIndex].center, slot)
	CharacterFactory.place(record.model, pos)
	sendState(player, "Bought " .. CharacterFactory.displayName(record.def, record.mutation) .. " for $" .. tostring(record.def.price) .. "!")
end

function Game._onSellPrompt(prompt, player)
	local record = recordsByModel[prompt.Parent]
	if not record or record.kind ~= "base" or not record.model.Parent then
		return
	end
	if record.owner ~= player then
		sendState(player, "That snackrot is not yours.")
		return
	end
	local state = players[player]
	if not state then
		return
	end
	local refund = math.floor(record.def.price * Data.SELL_REFUND)
	state.money += refund
	state.slots[record.slot] = nil
	recordsByModel[record.model] = nil
	record.model:Destroy()
	sendState(player, "Sold " .. CharacterFactory.displayName(record.def, record.mutation) .. " for $" .. tostring(refund) .. ".")
end

function Game._onStealPrompt(prompt, player)
	local record = recordsByModel[prompt.Parent]
	if not record or record.kind ~= "base" or not record.model.Parent then
		return
	end
	local owner = record.owner
	if owner == player then
		sendState(player, "That snackrot is already yours.")
		return
	end
	local state = players[player]
	if not state then
		return
	end
	-- Defence: an owner standing near their own base blocks the steal.
	local ownerState = players[owner]
	if ownerState and owner.Character then
		local root = owner.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local baseCenter = Data.BASES[ownerState.baseIndex].center
			if (root.Position - baseCenter).Magnitude < Data.STEAL_DEFEND_RADIUS then
				sendState(player, owner.Name .. " is defending their base! Steal blocked.")
				sendState(owner, player.Name .. " tried to steal your " .. CharacterFactory.displayName(record.def, record.mutation) .. "!")
				return
			end
		end
	end
	local slot = freeSlot(state)
	if not slot then
		sendState(player, "Your base is full! Sell a snackrot or rebirth.")
		return
	end
	ownerState.slots[record.slot] = nil
	record.owner = player
	record.slot = slot
	state.slots[slot] = record
	local pos = Data.slotPosition(Data.BASES[state.baseIndex].center, slot)
	CharacterFactory.place(record.model, pos)
	sendState(player, "You stole " .. CharacterFactory.displayName(record.def, record.mutation) .. " from " .. owner.Name .. "!")
	sendState(owner, player.Name .. " stole your " .. CharacterFactory.displayName(record.def, record.mutation) .. "! Steal it back!")
end

local function onRebirth(player)
	local state = players[player]
	if not state then
		return
	end
	local cost = Data.rebirthCost(state.rebirths)
	if state.money < cost then
		sendState(player, "Rebirth needs $" .. tostring(cost) .. ". You have $" .. tostring(math.floor(state.money)) .. ".")
		return
	end
	for _, record in pairs(state.slots) do
		if record then
			recordsByModel[record.model] = nil
			record.model:Destroy()
		end
	end
	state.slots = {}
	state.money = Data.START_MONEY
	state.rebirths += 1
	sendState(player, "REBIRTH! Income x" .. string.format("%.1f", Data.rebirthMultiplier(state.rebirths)) .. " forever. Your base is empty — start again, richer.")
end

local function spawnBeltCharacter()
	if #belt >= Data.BELT_MAX then
		return
	end
	local def, mutation = rollCharacter()
	local id = nextId
	nextId += 1
	local model = CharacterFactory.build(def, mutation, id)
	model.Parent = Workspace
	local record = { id = id, kind = "belt", def = def, mutation = mutation, model = model, x = Data.BELT_START_X }
	local buyPrompt = CharacterFactory.addBuyPrompt(model, def)
	record.buyPrompt = buyPrompt
	buyPrompt.Triggered:Connect(function(player)
		tryBuy(player, record)
	end)
	CharacterFactory.place(model, Vector3.new(Data.BELT_START_X, Data.BELT_GROUND_Y, 0))
	recordsByModel[model] = record
	table.insert(belt, record)
end

local function runWave()
	broadcast("SNACK STORM in 10 seconds! Grab a snackrot and run home!")
	task.wait(Data.WAVE_WARN)
	waveActive = true
	local wall = Instance.new("Part")
	wall.Name = "SnackStormWall"
	wall.Size = Vector3.new(8, 40, 320)
	wall.Color = Color3.fromRGB(80, 180, 255)
	wall.Transparency = 0.5
	wall.Material = Enum.Material.Neon
	wall.Anchored = true
	wall.CanCollide = false
	wall.CFrame = CFrame.new(-160, 20, 0)
	wall.Parent = Workspace
	waveWallX = -160
	local track = RunService.Heartbeat:Connect(function()
		waveWallX = wall.Position.X
	end)
	local tween = TweenService:Create(wall, TweenInfo.new(6, Enum.EasingStyle.Linear), { CFrame = CFrame.new(160, 20, 0) })
	tween:Play()
	tween.Completed:Wait()
	track:Disconnect()
	waveActive = false
	waveWallX = nil
	wall:Destroy()
	broadcast("The Snack Storm has passed. The belt is clear — fresh snackrots are coming!")
end

local function onPlayerAdded(player)
	-- First free base, in order.
	local baseIndex = 1
	for i = 1, #Data.BASES do
		if not claimedBases[i] then
			baseIndex = i
			break
		end
	end
	claimedBases[baseIndex] = player
	local state = { money = Data.START_MONEY, rebirths = 0, baseIndex = baseIndex, slots = {} }
	players[player] = state

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Value = state.money
	money.Parent = leaderstats
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = 0
	rebirths.Parent = leaderstats
	leaderstats.Parent = player

	-- A neon marker over the player's base so they can find it.
	local base = Data.BASES[baseIndex]
	local marker = Instance.new("Part")
	marker.Name = "BaseMarker_" .. player.Name
	marker.Size = Vector3.new(2, 20, 2)
	marker.Position = base.center + Vector3.new(0, 10, -20)
	marker.Color = base.color
	marker.Material = Enum.Material.Neon
	marker.Anchored = true
	marker.CanCollide = false
	marker.Parent = Workspace
	local tag = Instance.new("BillboardGui")
	tag.Name = "BaseTag"
	tag.Size = UDim2.fromOffset(180, 44)
	tag.StudsOffsetWorldSpace = Vector3.new(0, 11, 0)
	tag.AlwaysOnTop = true
	tag.Adornee = marker
	tag.Parent = marker
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = player.Name .. "'s Base"
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.Parent = tag
	state.marker = marker

	sendState(player, "Welcome to Snackrot Market! Grab a snackrot from the belt (hold E) and grow rich.")
end

local function onPlayerRemoving(player)
	local state = players[player]
	if state then
		for _, record in pairs(state.slots) do
			if record then
				recordsByModel[record.model] = nil
				record.model:Destroy()
			end
		end
		if state.marker then
			state.marker:Destroy()
		end
		claimedBases[state.baseIndex] = nil
		players[player] = nil
	end
end

function Game.Start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
	rebirthEvent.OnServerEvent:Connect(onRebirth)

	-- Belt movement: every frame, advance each belt snackrot; sweep away the
	-- ones the storm wall has passed, and despawn the ones that reach the end.
	RunService.Heartbeat:Connect(function(dt)
		for i = #belt, 1, -1 do
			local record = belt[i]
			record.x += Data.BELT_SPEED * dt
			if record.x > Data.BELT_END_X then
				recordsByModel[record.model] = nil
				record.model:Destroy()
				table.remove(belt, i)
			elseif waveActive and waveWallX and record.x < waveWallX then
				recordsByModel[record.model] = nil
				record.model:Destroy()
				table.remove(belt, i)
			else
				CharacterFactory.place(record.model, Vector3.new(record.x, Data.BELT_GROUND_Y, 0))
			end
		end
	end)

	-- Spawner: a new snackrot rolls onto the belt every few seconds.
	task.spawn(function()
		while true do
			task.wait(Data.BELT_SPAWN_INTERVAL)
			spawnBeltCharacter()
		end
	end)

	-- Income: every second, each base pays out its snackrots' rates.
	task.spawn(function()
		while true do
			task.wait(1)
			for player, state in pairs(players) do
				state.money = math.floor(state.money + incomePerSecond(state))
				local leaderstats = player:FindFirstChild("leaderstats")
				if leaderstats then
					local moneyValue = leaderstats:FindFirstChild("Money")
					if moneyValue then
						moneyValue.Value = state.money
					end
					local rebirthValue = leaderstats:FindFirstChild("Rebirths")
					if rebirthValue then
						rebirthValue.Value = state.rebirths
					end
				end
				sendState(player)
			end
		end
	end)

	-- The Snack Storm: a wall sweeps the map on a timer, clearing the belt.
	task.spawn(function()
		task.wait(Data.WAVE_FIRST)
		while true do
			runWave()
			task.wait(Data.WAVE_INTERVAL)
		end
	end)
end

return Game
