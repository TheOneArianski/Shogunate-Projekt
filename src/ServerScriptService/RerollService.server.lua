local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local StyleConfig = require(RS.Shared.StyleConfig)
local PlayerState = require(script.Parent.Modules.PlayerState)
local Remotes = RS:WaitForChild("Remotes")

local rng = Random.new()

local function rollRarity()
	local pick = rng:NextNumber(0, 100)
	local acc = 0
	for _, r in ipairs(StyleConfig.Rarities) do
		acc += r.Chance
		if pick < acc then return r.Name end
	end
	return StyleConfig.Rarities[1].Name
end

local function attachKatana(character, katanaName, rarity)
	local old = character:FindFirstChild("Katana")
	if old then old:Destroy() end
	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if not hand then return end

	-- Eigenes Modell aus ServerStorage.Katanas.<Name> hat Vorrang, sonst Platzhalter.
	local template = game:GetService("ServerStorage"):FindFirstChild("Katanas")
	template = template and template:FindFirstChild(katanaName)
	local handle
	if template then
		handle = template:Clone()
	else
		handle = Instance.new("Part")
		handle.Size = Vector3.new(0.2, 0.2, 4)
		handle.Material = Enum.Material.Metal
		handle.Color = StyleConfig.rarityData(rarity).Color
	end
	handle.Name = "Katana"
	handle.Massless = true
	handle.CanCollide = false
	handle.Parent = character
	local weld = Instance.new("Weld")
	weld.Part0 = hand
	weld.Part1 = handle:IsA("Model") and handle.PrimaryPart or handle
	weld.C0 = CFrame.new(0, -1, -1.5)
	weld.Parent = handle
end

local function equip(player)
	local s = PlayerState.get(player)
	if not s then return end
	player:SetAttribute("Style", s.style)
	player:SetAttribute("Katana", s.katana)
	if player.Character then
		attachKatana(player.Character, s.katana, s.katanaRarity)
	end
end

local function rerollStyle(player)
	local s = PlayerState.get(player)
	if not s then return end
	local rarity = rollRarity()
	local list = StyleConfig.Styles[rarity]
	s.style = list[rng:NextInteger(1, #list)]
	s.styleRarity = rarity
	s.styleDamageMultiplier = StyleConfig.rarityData(rarity).DamageMultiplier
	equip(player)
	Remotes.RerollResult:FireClient(player, "Style", s.style, rarity)
end

local function rerollKatana(player)
	local s = PlayerState.get(player)
	if not s then return end
	local rarity = rollRarity()
	local list = StyleConfig.Katanas[rarity]
	s.katana = list[rng:NextInteger(1, #list)]
	s.katanaRarity = rarity
	equip(player)
	Remotes.RerollResult:FireClient(player, "Katana", s.katana, rarity)
end

Players.PlayerAdded:Connect(function(player)
	task.defer(function()
		player.CharacterAdded:Connect(function() task.wait(1.5) equip(player) end)
		equip(player)
	end)
end)

-- Robux-Kauf
MarketplaceService.ProcessReceipt = function(info)
	local player = Players:GetPlayerByUserId(info.PlayerId)
	if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
	if info.ProductId == StyleConfig.Products.StyleReroll and info.ProductId ~= 0 then
		rerollStyle(player)
	elseif info.ProductId == StyleConfig.Products.KatanaReroll and info.ProductId ~= 0 then
		rerollKatana(player)
	else
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- Client fragt Kauf an; gerollt wird erst nach dem Kauf auf dem Server.
Remotes.RequestReroll.OnServerEvent:Connect(function(player, kind)
	local key = (kind == "Style" and "StyleReroll") or (kind == "Katana" and "KatanaReroll")
	if not key then return end
	local id = StyleConfig.Products[key]
	if id ~= 0 then
		MarketplaceService:PromptProductPurchase(player, id)
	elseif RunService:IsStudio() then
		-- Zum Testen in Studio gratis, solange keine Product-ID gesetzt ist.
		if kind == "Style" then rerollStyle(player) else rerollKatana(player) end
	end
end)
