local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local ClanConfig = require(RS.Shared.ClanConfig)
local PlayerState = require(script.Parent.Modules.PlayerState)
local Combat = require(script.Parent.Modules.Combat)

local Remotes = RS:WaitForChild("Remotes")

local function applyAppearance(character, clan)
	local color = clan.Color
	for _, d in ipairs(character:GetChildren()) do
		if d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic") then
			d:Destroy()
		end
	end
	local bc = character:FindFirstChildOfClass("BodyColors") or Instance.new("BodyColors", character)
	bc.HeadColor3, bc.TorsoColor3 = color, color
	bc.LeftArmColor3, bc.RightArmColor3 = color, color
	bc.LeftLegColor3, bc.RightLegColor3 = color, color

	-- Clan-Aura (Barriere)
	if not character:FindFirstChild("ClanAura") then
		local hl = Instance.new("Highlight")
		hl.Name = "ClanAura"
		hl.FillColor, hl.OutlineColor = color, color
		hl.FillTransparency, hl.OutlineTransparency = 0.85, 0.3
		hl.Parent = character

		local root = character:WaitForChild("HumanoidRootPart")
		local p = Instance.new("ParticleEmitter")
		p.Name = "ClanAuraParticles"
		p.Color = ColorSequence.new(color)
		p.Rate = 12
		p.Lifetime = NumberRange.new(0.8, 1.4)
		p.Speed = NumberRange.new(1, 3)
		p.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
		p.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
		p.LightEmission = 0.5
		p.Parent = root
	end
end

local function setupCharacter(player, character)
	local state = PlayerState.get(player)
	if not state then return end
	character:WaitForChild("Humanoid")
	-- Kleidung wird teils verzögert geladen: erneut anwenden und neue Kleidung entfernen
	character.ChildAdded:Connect(function(c)
		if state.clan and (c:IsA("Shirt") or c:IsA("Pants") or c:IsA("ShirtGraphic")) then
			task.defer(c.Destroy, c)
		end
	end)
	if state.clan then
		task.wait(1)
		applyAppearance(character, ClanConfig[state.clan])
		Combat.applyClanStats(player)
	end
end

Players.PlayerAdded:Connect(function(player)
	PlayerState.init(player)
	player.CharacterAdded:Connect(function(char) setupCharacter(player, char) end)
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerState.remove(player)
end)

Remotes.ChooseClan.OnServerEvent:Connect(function(player, clanName)
	local state = PlayerState.get(player)
	if not state or state.clan then return end -- Clan nur einmal am Anfang wählbar
	if type(clanName) ~= "string" or not ClanConfig[clanName] then return end
	state.clan = clanName
	player:SetAttribute("Clan", clanName)
	if player.Character then
		applyAppearance(player.Character, ClanConfig[clanName])
		Combat.applyClanStats(player, true)
	end
end)
