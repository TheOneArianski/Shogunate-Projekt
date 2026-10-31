local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CombatConfig = require(RS.Shared.CombatConfig)
local PlayerState = require(script.Parent.PlayerState)
local ProceduralAnim = require(script.Parent.ProceduralAnim)
local AnimationConfig = require(RS.Shared.AnimationConfig)

local Remotes = RS:WaitForChild("Remotes")
local Combat = {}

local lastHitBy = setmetatable({}, { __mode = "k" }) -- [Humanoid-Modell] = {player, time}
local diedHooked = setmetatable({}, { __mode = "k" })

local function now() return os.clock() end

local function getHumanoid(player)
	local c = player.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	if h and h.Health > 0 then return h, c end
end

local function pushState(player)
	local s = PlayerState.get(player)
	if not s then return end
	Remotes.StateUpdate:FireClient(player, {
		blocks = s.blocks,
		maxBlocks = s.maxBlocks,
		dashReadyIn = math.max(0, s.dashReadyAt - now()),
	})
end

function Combat.inCombat(s) return now() < s.combatUntil end

function Combat.refreshSpeed(player)
	local h = getHumanoid(player)
	local s = PlayerState.get(player)
	if not (h and s) then return end
	local clan = PlayerState.clanData(s)
	if now() < s.stunUntil then
		h.WalkSpeed = 0
		return
	end
	local speed = CombatConfig.BaseWalkSpeed * (clan and clan.SpeedMultiplier or 1)
	if Combat.inCombat(s) then speed *= CombatConfig.CombatSpeedMultiplier end
	h.WalkSpeed = speed
end

local function tagCombat(player)
	local s = PlayerState.get(player)
	if not s then return end
	s.combatUntil = now() + CombatConfig.CombatSeconds
	Combat.refreshSpeed(player)
	local mark = s.combatUntil
	task.delay(CombatConfig.CombatSeconds + 0.05, function()
		if s.combatUntil == mark then Combat.refreshSpeed(player) end
	end)
end

function Combat.applyClanStats(player, fullHeal)
	local s = PlayerState.get(player)
	local clan = s and PlayerState.clanData(s)
	local h = getHumanoid(player)
	if not (clan and h) then return end
	h.MaxHealth = clan.Health
	if fullHeal or h.Health > clan.Health then h.Health = clan.Health end
	s.maxBlocks = clan.Blocks
	s.blocks = clan.Blocks
	Combat.refreshSpeed(player)
	pushState(player)
end

local function damageMultiplier(s, humanoid)
	local clan = PlayerState.clanData(s)
	if not clan then return 1 end
	if clan.LowHealthThreshold and humanoid.Health < clan.LowHealthThreshold then
		return clan.LowHealthDamageMultiplier
	end
	return clan.DamageMultiplier
end

local function hookDeath(model, humanoid)
	if diedHooked[model] then return end
	diedHooked[model] = true
	humanoid.Died:Connect(function()
		local info = lastHitBy[model]
		if not info then return end
		if now() - info.time > CombatConfig.CombatSeconds then return end
		local ah = getHumanoid(info.player)
		if ah then
			ah.Health = math.min(ah.MaxHealth, ah.Health + CombatConfig.KillHeal)
		end
	end)
end

local function stun(player, seconds)
	local s = PlayerState.get(player)
	s.stunUntil = now() + seconds
	s.blocking = false
	if player.Character then ProceduralAnim.reset(player.Character, 0.1) end
	Combat.refreshSpeed(player)
	task.delay(seconds + 0.05, function() Combat.refreshSpeed(player) end)
end

-- Gibt true zurück, wenn der Treffer Schaden verursacht hat.
local function applyHit(attacker, victimModel, victimHumanoid, damage)
	local victimPlayer = Players:GetPlayerFromCharacter(victimModel)
	local vs = victimPlayer and PlayerState.get(victimPlayer)

	if vs then
		if not vs.clan then return false end -- Spieler ohne Clan sind unverwundbar (Lobby)
		if now() < vs.iframeUntil then return false end -- Dash-Ausweichen
		if vs.blocking then
			if vs.blocks > 0 then
				vs.blocks -= 1
				if vs.blocks < vs.maxBlocks and vs.nextBlockRegen == 0 then
					vs.nextBlockRegen = now() + CombatConfig.BlockRegenSeconds
				end
				tagCombat(victimPlayer)
				pushState(victimPlayer)
				return false
			else
				stun(victimPlayer, CombatConfig.NoBlockStunSeconds)
			end
		end
		tagCombat(victimPlayer)
	end

	lastHitBy[victimModel] = { player = attacker, time = now() }
	hookDeath(victimModel, victimHumanoid)
	victimHumanoid:TakeDamage(damage)
	return true
end

local function doHitbox(player, s, damage)
	local h, char = getHumanoid(player)
	if not h then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local cf = root.CFrame * CFrame.new(0, 0, -CombatConfig.HitboxForwardOffset)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char }
	local seen = {}
	for _, part in ipairs(workspace:GetPartBoundsInBox(cf, CombatConfig.HitboxSize, params)) do
		local model = part:FindFirstAncestorOfClass("Model")
		local hum = model and model:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 and not seen[model] then
			seen[model] = true
			applyHit(player, model, hum, damage)
		end
	end
end

Remotes.M1.OnServerEvent:Connect(function(player)
	local s = PlayerState.get(player)
	local h = getHumanoid(player)
	if not (s and s.clan and h) then return end
	local t = now()
	if t < s.nextM1 or t < s.stunUntil or s.blocking then return end

	local clan = PlayerState.clanData(s)
	if t - s.lastM1 > CombatConfig.ComboResetSeconds then
		s.comboIndex = 1
	else
		s.comboIndex = s.comboIndex % CombatConfig.ComboLength + 1
	end
	s.lastM1 = t
	local idx = s.comboIndex
	local speed = clan.AttackSpeedMultiplier
	s.nextM1 = t + CombatConfig.M1Cooldown / speed

	local damage = CombatConfig.ComboDamage[idx] * damageMultiplier(s, h) * s.styleDamageMultiplier
	tagCombat(player)
	Remotes.M1Anim:FireClient(player, s.style, idx, speed)
	local animCfg = AnimationConfig[s.style] or AnimationConfig.Basic
	if animCfg.M1[idx] == "" and player.Character then
		ProceduralAnim.swing(player.Character, s.style, idx, CombatConfig.HitDelay / speed, CombatConfig.M1Cooldown / speed)
	end
	task.delay(CombatConfig.HitDelay / speed, function()
		if getHumanoid(player) and t >= s.stunUntil - 0 then
			doHitbox(player, s, damage)
		end
	end)
end)

Remotes.Block.OnServerEvent:Connect(function(player, on)
	local s = PlayerState.get(player)
	if not (s and s.clan) or type(on) ~= "boolean" then return end
	if on and now() < s.stunUntil then return end
	s.blocking = on
	local char = player.Character
	if char then
		char:SetAttribute("Blocking", on)
		local animCfg = AnimationConfig[s.style] or AnimationConfig.Basic
		if animCfg.Block == "" then ProceduralAnim.block(char, on) end
	end
end)

Remotes.Dash.OnServerEvent:Connect(function(player)
	local s = PlayerState.get(player)
	local clan = s and PlayerState.clanData(s)
	if not (clan and getHumanoid(player)) then return end
	local t = now()
	if t < s.dashReadyAt or t < s.stunUntil then return end
	s.dashReadyAt = t + CombatConfig.DashCooldown * clan.DashCooldownMultiplier
	s.iframeUntil = t + CombatConfig.DashIFrameSeconds
	Remotes.DashStart:FireClient(player)
	if player.Character and AnimationConfig.Basic.Dash == "" then
		ProceduralAnim.dash(player.Character, CombatConfig.DashDuration)
	end
	pushState(player)
end)

-- Block-Regeneration: 1 Block alle 2.5 s
RunService.Heartbeat:Connect(function()
	local t = now()
	for player, s in pairs(PlayerState.all()) do
		if s.clan and s.blocks < s.maxBlocks and s.nextBlockRegen > 0 and t >= s.nextBlockRegen then
			s.blocks += 1
			s.nextBlockRegen = s.blocks < s.maxBlocks and t + CombatConfig.BlockRegenSeconds or 0
			pushState(player)
		end
	end
end)

return Combat
