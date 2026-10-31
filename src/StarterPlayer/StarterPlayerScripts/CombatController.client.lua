local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

local ClanConfig = require(RS.Shared.ClanConfig)
local CombatConfig = require(RS.Shared.CombatConfig)
local AnimationConfig = require(RS.Shared.AnimationConfig)

local player = Players.LocalPlayer
local Remotes = RS:WaitForChild("Remotes")

-- ===== GUI =====
local gui = Instance.new("ScreenGui")
gui.Name = "ShogunateGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Clanwahl
local clanFrame = Instance.new("Frame")
clanFrame.Size = UDim2.fromOffset(520, 120)
clanFrame.Position = UDim2.fromScale(0.5, 0.5)
clanFrame.AnchorPoint = Vector2.new(0.5, 0.5)
clanFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
clanFrame.BackgroundTransparency = 0.2
clanFrame.Visible = player:GetAttribute("Clan") == nil
clanFrame.Parent = gui

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.Padding = UDim.new(0, 10)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Parent = clanFrame

for _, name in ipairs({ "Hao", "Rengoku", "Seirin", "Genji" }) do
	local data = ClanConfig[name]
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(115, 90)
	b.BackgroundColor3 = data.Color
	b.TextColor3 = (name == "Seirin") and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
	b.TextWrapped = true
	b.Font = Enum.Font.GothamBold
	b.TextSize = 16
	b.Text = data.DisplayName
	b.Parent = clanFrame
	b.Activated:Connect(function()
		Remotes.ChooseClan:FireServer(name)
	end)
end

player:GetAttributeChangedSignal("Clan"):Connect(function()
	clanFrame.Visible = player:GetAttribute("Clan") == nil
end)

-- Block-Anzeige + Schild
local pips = Instance.new("Frame")
pips.Size = UDim2.fromOffset(200, 30)
pips.Position = UDim2.new(0.5, 0, 1, -70)
pips.AnchorPoint = Vector2.new(0.5, 1)
pips.BackgroundTransparency = 1
pips.Parent = gui
local pl = Instance.new("UIListLayout")
pl.FillDirection = Enum.FillDirection.Horizontal
pl.Padding = UDim.new(0, 6)
pl.HorizontalAlignment = Enum.HorizontalAlignment.Center
pl.Parent = pips

local shield = Instance.new("TextLabel")
shield.Size = UDim2.fromOffset(90, 90)
shield.Position = UDim2.new(0.5, 0, 1, -110)
shield.AnchorPoint = Vector2.new(0.5, 1)
shield.BackgroundTransparency = 1
shield.Text = "🛡"
shield.TextScaled = true
shield.Visible = false
shield.Parent = gui

local function renderBlocks(blocks, maxBlocks)
	for _, c in ipairs(pips:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
	for i = 1, maxBlocks do
		local p = Instance.new("Frame")
		p.Size = UDim2.fromOffset(24, 24)
		p.BackgroundColor3 = i <= blocks and Color3.fromRGB(80, 170, 255) or Color3.fromRGB(60, 60, 60)
		p.BorderSizePixel = 0
		p.Parent = pips
	end
end

Remotes.StateUpdate.OnClientEvent:Connect(function(data)
	renderBlocks(data.blocks, data.maxBlocks)
end)

-- ===== Animationen =====
local function playAnim(id, speed)
	if not id or id == "" then return end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	if not animator then return end
	local a = Instance.new("Animation")
	a.AnimationId = id
	local track = animator:LoadAnimation(a)
	track:Play()
	if speed then track:AdjustSpeed(speed) end
end

Remotes.M1Anim.OnClientEvent:Connect(function(style, index, speed)
	local cfg = AnimationConfig[style] or AnimationConfig.Basic
	playAnim(cfg.M1[index], speed)
end)

-- ===== Dash =====
Remotes.DashStart.OnClientEvent:Connect(function()
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root then return end
	local dir = hum and hum.MoveDirection.Magnitude > 0 and hum.MoveDirection or root.CFrame.LookVector
	local att = Instance.new("Attachment", root)
	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = att
	lv.MaxForce = math.huge
	lv.VectorVelocity = dir.Unit * CombatConfig.DashSpeed
	lv.Parent = root
	task.delay(CombatConfig.DashDuration, function()
		lv:Destroy()
		att:Destroy()
	end)
	playAnim(AnimationConfig.Basic.Dash)
end)

-- ===== Eingaben =====
UIS.InputBegan:Connect(function(input, processed)
	if processed or not player:GetAttribute("Clan") then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		Remotes.M1:FireServer()
	elseif input.KeyCode == Enum.KeyCode.F then
		Remotes.Block:FireServer(true)
		shield.Visible = true
	elseif input.KeyCode == Enum.KeyCode.Q then
		Remotes.Dash:FireServer()
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.F then
		Remotes.Block:FireServer(false)
		shield.Visible = false
	end
end)

-- ===== Reroll-Menü =====
local rerollFrame = Instance.new("Frame")
rerollFrame.Size = UDim2.fromOffset(200, 100)
rerollFrame.Position = UDim2.new(1, -10, 0.5, 0)
rerollFrame.AnchorPoint = Vector2.new(1, 0.5)
rerollFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
rerollFrame.BackgroundTransparency = 0.3
rerollFrame.Parent = gui
local rl = Instance.new("UIListLayout")
rl.Padding = UDim.new(0, 6)
rl.Parent = rerollFrame

local result = Instance.new("TextLabel")
result.Size = UDim2.new(1, 0, 0, 30)
result.BackgroundTransparency = 1
result.TextColor3 = Color3.new(1, 1, 1)
result.Font = Enum.Font.GothamBold
result.TextSize = 14
result.Text = ""
result.Parent = rerollFrame

for _, kind in ipairs({ "Style", "Katana" }) do
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, 30)
	b.Text = kind == "Style" and "Kampfstil rerollen" or "Katana rerollen"
	b.Font = Enum.Font.Gotham
	b.TextSize = 14
	b.Parent = rerollFrame
	b.Activated:Connect(function() Remotes.RequestReroll:FireServer(kind) end)
end

local StyleConfig = require(RS.Shared.StyleConfig)
Remotes.RerollResult.OnClientEvent:Connect(function(kind, name, rarity)
	result.Text = ("%s: %s (%s)"):format(kind == "Style" and "Stil" or "Katana", name, rarity)
	result.TextColor3 = StyleConfig.rarityData(rarity).Color
end)
