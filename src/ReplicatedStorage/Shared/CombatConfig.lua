return {
	BaseHealth = 100,
	BaseWalkSpeed = 16,

	-- M1-Kombo
	ComboLength = 4,
	ComboDamage = { 8, 8, 8, 12 },
	ComboResetSeconds = 1.2,
	M1Cooldown = 0.55, -- wird durch Angriffsgeschwindigkeit geteilt
	HitDelay = 0.15, -- Verzögerung bis zum Treffer, auch durch Angriffsgeschwindigkeit geteilt
	HitboxSize = Vector3.new(6, 5, 7),
	HitboxForwardOffset = 4,

	-- Block
	BaseBlocks = 3,
	BlockRegenSeconds = 2.5,
	NoBlockStunSeconds = 0.8,

	-- Kampfzustand
	CombatSeconds = 6,
	CombatSpeedMultiplier = 0.7,

	-- Dash
	DashCooldown = 4,
	DashIFrameSeconds = 0.4,
	DashSpeed = 80,
	DashDuration = 0.2,

	-- Kills
	KillHeal = 60,
}
