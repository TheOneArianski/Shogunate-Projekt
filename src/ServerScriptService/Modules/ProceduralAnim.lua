-- Animationen per Code für R6, solange keine echten AnimationIds eingetragen sind.
-- Es werden die C0-Werte der Motor6D-Gelenke verändert; der Server tut das, damit alle Spieler es sehen.
-- Die Posen unten sind "semantisch" und werden für R6 umgerechnet:
--   RS/LS: x negativ = Arm nach vorn heben, z positiv (rechts) bzw. negativ (links) = Arm nach außen, y = Drehung
--   WA:    x positiv = Oberkörper nach vorn lehnen, y = Oberkörper drehen
-- ACHTUNG: Winkel sind Schätzwerte und müssen in Studio nachjustiert werden.
local TweenService = game:GetService("TweenService")

local ProceduralAnim = {}

local function A(x, y, z)
	return { x = x, y = y, z = z }
end
local function rad(n) return math.rad(n) end

-- Kürzel: RS = rechte Schulter, LS = linke Schulter, WA = Oberkörper (RootJoint)
local JOINTS = { RS = "Right Shoulder", LS = "Left Shoulder", WA = "RootJoint" }

-- Semantische Winkel -> Offset. R6-Gelenke sind gedreht (C0 hat eine Rotation), daher die vertauschten Achsen.
local function toOffset(key, a)
	if key == "RS" then
		return CFrame.Angles(rad(-a.z), rad(a.y), rad(-a.x))
	elseif key == "LS" then
		return CFrame.Angles(rad(a.z), rad(a.y), rad(a.x))
	elseif key == "WA" then
		-- RootJoint dreht Torso samt Beinen, daher nur halbe Neigung
		return CFrame.Angles(rad(a.x * 0.5), 0, rad(a.y))
	end
	return CFrame.new()
end

-- Jeder Kampfstil hat seine EIGENEN 4 Schläge (M1) und seinen EIGENEN Block.
-- Pro Schlag: windup (Ausholen) und strike (Treffer-Moment).
local STYLES = {
	-- Rare: ausgewogen, klassische Schnitte, Block = Schwert senkrecht vor dem Körper
	Kiken = {
		M1 = {
			{ windup = { RS = A(-60, 40, 60), WA = A(0, 50, 0), LS = A(-40, 0, -30) },
			  strike = { RS = A(-90, -20, -30), WA = A(0, -60, 0), LS = A(-40, 0, -30) } },
			{ windup = { RS = A(-90, -20, -30), WA = A(0, -60, 0), LS = A(-40, 0, -30) },
			  strike = { RS = A(-70, 40, 50), WA = A(0, 55, 0), LS = A(-40, 0, -30) } },
			{ windup = { RS = A(-150, 0, 40), WA = A(-10, 30, 0), LS = A(-60, 0, -30) },
			  strike = { RS = A(-60, -30, -20), WA = A(25, -40, 0), LS = A(-30, 0, -30) } },
			{ windup = { RS = A(-170, 0, 0), WA = A(-15, 0, 0), LS = A(-160, 0, 0) },
			  strike = { RS = A(-60, 0, 0), WA = A(30, 0, 0), LS = A(-60, 0, 0) } },
		},
		Block = { RS = A(-100, 0, 20), LS = A(-100, 0, -20) },
	},

	-- Epic: tiefe, schräge Schnitte, Stoß und X-Schnitt, Block = Schwert diagonal quer
	Tsuken = {
		M1 = {
			{ windup = { RS = A(-30, 60, 50), WA = A(10, 60, 0), LS = A(-20, 0, -30) },
			  strike = { RS = A(-80, -30, -10), WA = A(20, -50, 0), LS = A(-20, 0, -30) } },
			{ windup = { RS = A(-80, -30, -10), WA = A(20, -50, 0), LS = A(-20, 0, -30) },
			  strike = { RS = A(-30, 60, 60), WA = A(10, 55, 0), LS = A(-20, 0, -30) } },
			{ windup = { RS = A(-60, 0, 30), WA = A(0, 35, 0), LS = A(-50, 0, -20) },
			  strike = { RS = A(-95, 0, 0), WA = A(15, -20, 0), LS = A(-50, 0, -20) } },
			{ windup = { RS = A(-160, 30, 40), WA = A(-10, 50, 0), LS = A(-100, 0, -30) },
			  strike = { RS = A(-40, -40, -10), WA = A(35, -55, 0), LS = A(-40, 0, -30) } },
		},
		Block = { RS = A(-80, 40, -10), LS = A(-60, 0, -60), WA = A(0, 30, 0) },
	},

	-- Legendary: schnelle Stöße, schneller Schnitt, Drehschlag; Block = Schwert tief, seitlich versetzt
	Shiken = {
		M1 = {
			{ windup = { RS = A(-50, 0, 25), WA = A(0, 30, 0), LS = A(-30, 0, -20) },
			  strike = { RS = A(-95, 0, 0), WA = A(8, -15, 0), LS = A(-30, 0, -20) } },
			{ windup = { RS = A(-50, 20, 35), WA = A(0, 40, 0), LS = A(-30, 0, -20) },
			  strike = { RS = A(-100, -10, 5), WA = A(8, -25, 0), LS = A(-30, 0, -20) } },
			{ windup = { RS = A(-70, 40, 70), WA = A(0, 60, 0), LS = A(-30, 0, -40) },
			  strike = { RS = A(-90, -20, -30), WA = A(0, -70, 0), LS = A(-30, 0, -40) } },
			{ windup = { RS = A(-70, 0, 80), WA = A(0, 90, 0), LS = A(-30, 0, -60) },
			  strike = { RS = A(-90, 0, -40), WA = A(0, -150, 0), LS = A(-30, 0, -60) } },
		},
		Block = { RS = A(-30, 0, 15), LS = A(-10, 0, -20), WA = A(-8, -20, 0) },
	},

	-- Shogun: schwere Zweihand-Schläge, Block = Schwert über dem Kopf
	King = {
		M1 = {
			{ windup = { RS = A(-175, 0, 10), LS = A(-165, 0, -10), WA = A(-20, 0, 0) },
			  strike = { RS = A(-65, 0, 0), LS = A(-65, 0, 0), WA = A(35, 0, 0) } },
			{ windup = { RS = A(-60, 50, 80), WA = A(0, 70, 0), LS = A(-60, 0, -50) },
			  strike = { RS = A(-90, -30, -40), WA = A(0, -80, 0), LS = A(-60, 0, -50) } },
			{ windup = { RS = A(-20, 30, 40), WA = A(15, 50, 0), LS = A(-20, 0, -30) },
			  strike = { RS = A(-160, -20, -10), WA = A(-15, -50, 0), LS = A(-120, 0, -20) } },
			{ windup = { RS = A(-180, 0, 0), LS = A(-180, 0, 0), WA = A(-30, 0, 0) },
			  strike = { RS = A(-50, 0, 0), LS = A(-50, 0, 0), WA = A(45, 0, 0) } },
		},
		Block = { RS = A(-170, 0, 20), LS = A(-170, 0, -20), WA = A(-10, 0, 0) },
	},
}

-- Dash ist für alle Stile gleich.
local DASH_POSE = { WA = A(25, 0, 0), RS = A(20, 0, 20), LS = A(20, 0, -20) }

local function styleData(styleName)
	return STYLES[styleName] or STYLES.Kiken
end

local originals = setmetatable({}, { __mode = "k" }) -- [Character] = {RS=C0,...}
local tokens = setmetatable({}, { __mode = "k" })
local activeTweens = setmetatable({}, { __mode = "k" })

local function getMotors(character)
	local o = originals[character]
	if o then return o.motors, o.c0 end
	local motors, c0 = {}, {}
	for key, name in pairs(JOINTS) do
		local m = character:FindFirstChild(name, true)
		if m and m:IsA("Motor6D") then
			motors[key] = m
			c0[key] = m.C0
		end
	end
	originals[character] = { motors = motors, c0 = c0 }
	return motors, c0
end

local function cancel(character)
	tokens[character] = (tokens[character] or 0) + 1
	local list = activeTweens[character]
	if list then
		for _, t in ipairs(list) do t:Cancel() end
		activeTweens[character] = nil
	end
	return tokens[character]
end

local function tweenTo(character, pose, duration, style)
	local motors, c0 = getMotors(character)
	local list = activeTweens[character] or {}
	activeTweens[character] = list
	local info = TweenInfo.new(math.max(duration, 0.01), style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for key, motor in pairs(motors) do
		local a = pose and pose[key]
		local offset = a and toOffset(key, a) or CFrame.new()
		local t = TweenService:Create(motor, info, { C0 = c0[key] * offset })
		table.insert(list, t)
		t:Play()
	end
end

-- Zurück in die Grundstellung.
function ProceduralAnim.reset(character, duration)
	cancel(character)
	tweenTo(character, nil, duration or 0.1)
end

-- Schlag Nr. index (1 bis 4). hitDelay = Sekunden bis zum Treffer, total = Gesamtdauer bis zum nächsten Schlag.
function ProceduralAnim.swing(character, styleName, index, hitDelay, total)
	local pose = styleData(styleName).M1[index]
	if not pose then return end
	local token = cancel(character)
	local windup, strike = hitDelay * 0.5, hitDelay * 0.5
	local recover = math.max(0.15, total - hitDelay)

	tweenTo(character, pose.windup, windup, Enum.EasingStyle.Sine)
	task.delay(windup, function()
		if tokens[character] ~= token then return end
		tweenTo(character, pose.strike, strike, Enum.EasingStyle.Quint)
		task.delay(strike, function()
			if tokens[character] ~= token then return end
			tweenTo(character, nil, recover, Enum.EasingStyle.Sine)
		end)
	end)
end

function ProceduralAnim.block(character, on, styleName)
	cancel(character)
	tweenTo(character, on and styleData(styleName).Block or nil, 0.1)
end

function ProceduralAnim.dash(character, duration)
	local token = cancel(character)
	tweenTo(character, DASH_POSE, 0.05)
	task.delay(duration, function()
		if tokens[character] == token then tweenTo(character, nil, 0.15) end
	end)
end

return ProceduralAnim
