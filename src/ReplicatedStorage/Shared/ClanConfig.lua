-- Alle Clan-Werte an einer Stelle. Multiplikatoren sind 1 = unverändert.
return {
	Hao = {
		DisplayName = "Hao Clan",
		Color = Color3.fromRGB(255, 220, 40), -- Gelb
		Health = 90,
		Blocks = 2,
		DamageMultiplier = 1.1,
		AttackSpeedMultiplier = 1.6,
		SpeedMultiplier = 1,
		DashCooldownMultiplier = 1,
	},
	Rengoku = {
		DisplayName = "Rengoku",
		Color = Color3.fromRGB(220, 30, 30), -- Rot
		Health = 100,
		Blocks = 3,
		DamageMultiplier = 1.3,
		LowHealthThreshold = 30,
		LowHealthDamageMultiplier = 1.5, -- ersetzt DamageMultiplier unter der Schwelle
		AttackSpeedMultiplier = 1,
		SpeedMultiplier = 1,
		DashCooldownMultiplier = 1,
	},
	Seirin = {
		DisplayName = "Seirin Clan",
		Color = Color3.fromRGB(20, 20, 20), -- Schwarz
		Health = 100,
		Blocks = 3,
		DamageMultiplier = 1,
		AttackSpeedMultiplier = 1,
		SpeedMultiplier = 1,
		DashCooldownMultiplier = 1 / 1.75,
	},
	Genji = {
		DisplayName = "Genji Clan",
		Color = Color3.fromRGB(40, 180, 70), -- Grün
		Health = 120,
		Blocks = 4,
		DamageMultiplier = 1,
		AttackSpeedMultiplier = 1,
		SpeedMultiplier = 0.8,
		DashCooldownMultiplier = 1,
	},
}
