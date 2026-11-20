-- Snackrot Market: client HUD. Shows money, income, rebirths, the Snack Storm
-- warning, a feed of game events and the rebirth button. All state comes from
-- the server; the client never decides money or ownership itself.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local stateEvent = ReplicatedStorage.Events.StateUpdate
local rebirthEvent = ReplicatedStorage.Events.Rebirth

local gui = Instance.new("ScreenGui")
gui.Name = "SnackrotGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

-- Money bar, top centre (kept clear of Roblox's own menu buttons top-left).
local bar = Instance.new("Frame")
bar.Name = "MoneyBar"
bar.AnchorPoint = Vector2.new(0.5, 0)
bar.Position = UDim2.new(0.5, 0, 0, 12)
bar.Size = UDim2.fromOffset(420, 64)
bar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
bar.BackgroundTransparency = 0.2
bar.BorderSizePixel = 0
bar.Parent = gui

local moneyLabel = Instance.new("TextLabel")
moneyLabel.Name = "Money"
moneyLabel.Size = UDim2.new(1, 0, 0.6, 0)
moneyLabel.BackgroundTransparency = 1
moneyLabel.Text = "$0"
moneyLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
moneyLabel.TextScaled = true
moneyLabel.Font = Enum.Font.SourceSansBold
moneyLabel.Parent = bar

local incomeLabel = Instance.new("TextLabel")
incomeLabel.Name = "Income"
incomeLabel.Position = UDim2.new(0, 0, 0.6, 0)
incomeLabel.Size = UDim2.new(1, 0, 0.4, 0)
incomeLabel.BackgroundTransparency = 1
incomeLabel.Text = "$0/s  •  Rebirths: 0 (x1.0)"
incomeLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
incomeLabel.TextScaled = true
incomeLabel.Font = Enum.Font.SourceSans
incomeLabel.Parent = bar

local title = Instance.new("TextLabel")
title.Name = "Title"
title.AnchorPoint = Vector2.new(1, 0)
title.Position = UDim2.new(1, -12, 0, 12)
title.Size = UDim2.fromOffset(280, 40)
title.BackgroundTransparency = 1
title.Text = "Snackrot Market"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.SourceSansBold
title.TextXAlignment = Enum.TextXAlignment.Right
title.Parent = gui

local hint = Instance.new("TextLabel")
hint.Name = "Hint"
hint.AnchorPoint = Vector2.new(1, 0)
hint.Position = UDim2.new(1, -12, 0, 52)
hint.Size = UDim2.fromOffset(320, 24)
hint.BackgroundTransparency = 1
hint.Text = "Walk to a snackrot on the belt, hold E to buy it"
hint.TextColor3 = Color3.fromRGB(220, 220, 220)
hint.TextSize = 16
hint.Font = Enum.Font.SourceSans
hint.TextXAlignment = Enum.TextXAlignment.Right
hint.Parent = gui

-- Snack Storm warning, shown only while a storm is near.
local wave = Instance.new("TextLabel")
wave.Name = "WaveWarning"
wave.AnchorPoint = Vector2.new(0.5, 0)
wave.Position = UDim2.new(0.5, 0, 0, 88)
wave.Size = UDim2.fromOffset(480, 36)
wave.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
wave.BackgroundTransparency = 0.2
wave.Text = ""
wave.TextColor3 = Color3.fromRGB(255, 255, 255)
wave.TextScaled = true
wave.Font = Enum.Font.SourceSansBold
wave.Visible = false
wave.Parent = gui

-- Event feed, bottom left, newest first.
local feed = Instance.new("Frame")
feed.Name = "Feed"
feed.AnchorPoint = Vector2.new(0, 1)
feed.Position = UDim2.new(0, 12, 1, -12)
feed.Size = UDim2.fromOffset(440, 110)
feed.BackgroundTransparency = 1
feed.Parent = gui

local feedLines = {}
local function addFeed(text)
	table.insert(feedLines, 1, text)
	if #feedLines > 4 then
		table.remove(feedLines)
	end
	for _, child in ipairs(feed:GetChildren()) do
		child:Destroy()
	end
	for i, line in ipairs(feedLines) do
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 24)
		label.Position = UDim2.new(0, 0, 0, (i - 1) * 26)
		label.BackgroundTransparency = 0.4
		label.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
		label.Text = line
		label.TextColor3 = Color3.fromRGB(240, 240, 240)
		label.TextSize = 15
		label.Font = Enum.Font.SourceSans
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = feed
	end
end

-- Rebirth button, bottom right.
local rebirthBtn = Instance.new("TextButton")
rebirthBtn.Name = "RebirthButton"
rebirthBtn.AnchorPoint = Vector2.new(1, 1)
rebirthBtn.Position = UDim2.new(1, -12, 1, -12)
rebirthBtn.Size = UDim2.fromOffset(230, 52)
rebirthBtn.BackgroundColor3 = Color3.fromRGB(150, 60, 200)
rebirthBtn.Text = "Rebirth ($5,000)"
rebirthBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rebirthBtn.TextScaled = true
rebirthBtn.Font = Enum.Font.SourceSansBold
rebirthBtn.Parent = gui

rebirthBtn.MouseButton1Click:Connect(function()
	rebirthEvent:FireServer()
end)

stateEvent.OnClientEvent:Connect(function(state)
	moneyLabel.Text = "$" .. tostring(state.Money)
	incomeLabel.Text = "$" .. tostring(state.Income) .. "/s  •  Rebirths: " .. tostring(state.Rebirths) .. " (x" .. string.format("%.1f", state.Multiplier) .. ")"
	rebirthBtn.Text = "Rebirth ($" .. tostring(state.RebirthCost) .. ")"
	if state.Feed and state.Feed ~= "" then
		addFeed(state.Feed)
		if string.find(state.Feed, "SNACK STORM in") then
			wave.Text = state.Feed
			wave.Visible = true
		elseif string.find(state.Feed, "Storm has passed") then
			wave.Visible = false
		end
	end
end)
