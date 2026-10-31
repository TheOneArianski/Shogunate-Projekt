-- Jeder Kampfstil hat eigene Schlaganimationen.
-- Hier die AnimationIds eintragen, z. B. "rbxassetid://123456789". Leer = keine Animation.
local function empty()
	return { M1 = { "", "", "", "" }, Block = "", Dash = "" } -- M1 = Schlag 1 bis 4
end

return {
	Basic = empty(), -- Fallback
	Kiken = empty(),
	Tsuken = empty(),
	Shiken = empty(),
	King = empty(),
}
