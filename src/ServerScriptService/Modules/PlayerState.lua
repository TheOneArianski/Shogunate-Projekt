local CombatConfig = require(game.ReplicatedStorage.Shared.CombatConfig)
local ClanConfig = require(game.ReplicatedStorage.Shared.ClanConfig)

local PlayerState = {}
local states = {}

function PlayerState.init(player)
	states[player] = {
		clan = nil,
		style = "Basic",
		blocks = CombatConfig.BaseBlocks,
		maxBlocks = CombatConfig.BaseBlocks,
		nextBlockRegen = 0,
		blocking = false,
		combatUntil = 0,
		stunUntil = 0,
		dashReadyAt = 0,
		iframeUntil = 0,
		comboIndex = 0,
		lastM1 = 0,
		nextM1 = 0,
	}
	return states[player]
end

function PlayerState.get(player)
	return states[player]
end

function PlayerState.remove(player)
	states[player] = nil
end

function PlayerState.all()
	return states
end

function PlayerState.clanData(state)
	return state.clan and ClanConfig[state.clan] or nil
end

return PlayerState
