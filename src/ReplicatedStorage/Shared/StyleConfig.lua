-- Seltenheiten, Kampfstile und Katanas.
local StyleConfig = {}

-- Reihenfolge = Rang. Chancen in Prozent, Summe 100.
StyleConfig.Rarities = {
	{ Name = "Rare", Chance = 65, DamageMultiplier = 1.00, Color = Color3.fromRGB(80, 140, 255) },
	{ Name = "Epic", Chance = 28, DamageMultiplier = 1.05, Color = Color3.fromRGB(170, 80, 255) },
	{ Name = "Legendary", Chance = 5, DamageMultiplier = 1.10, Color = Color3.fromRGB(255, 170, 30) },
	{ Name = "Shogun", Chance = 2, DamageMultiplier = 1.15, Color = Color3.fromRGB(255, 50, 50) },
}

StyleConfig.Styles = {
	Rare = { "Kiken" },
	Epic = { "Tsuken" },
	Legendary = { "Shiken" },
	Shogun = { "King" },
}

-- Katanas ändern nur die Optik.
StyleConfig.Katanas = {
	Rare = { "Tetsu", "Kage" },
	Epic = { "Tsuki", "Hayate" },
	Legendary = { "Murasame", "Kusanagi" },
	Shogun = { "Tenka Goken" },
}

StyleConfig.StartStyle = "Kiken"
StyleConfig.StartKatana = "Tetsu"

-- Developer-Product-IDs (in Roblox anlegen und hier eintragen). 0 = nicht gesetzt.
StyleConfig.Products = {
	StyleReroll = 0,
	KatanaReroll = 0,
}

function StyleConfig.rarityOfStyle(styleName)
	for rarity, list in pairs(StyleConfig.Styles) do
		if table.find(list, styleName) then return rarity end
	end
end

function StyleConfig.rarityData(rarityName)
	for _, r in ipairs(StyleConfig.Rarities) do
		if r.Name == rarityName then return r end
	end
end

return StyleConfig
