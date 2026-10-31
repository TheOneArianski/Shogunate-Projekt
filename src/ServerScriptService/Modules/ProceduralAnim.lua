-- Animationen per Code (R15), solange keine echten AnimationIds eingetragen sind.
-- Es werden die C0-Werte der Motor6D-Gelenke verändert; der Server tut das, damit alle Spieler es sehen.
-- ACHTUNG: Die Winkel sind Schätzwerte und müssen in Studio nachjustiert werden (siehe POSES unten).
local TweenService = game:GetService("TweenService")

local ProceduralAnim = {}

local function A(x, y, z)
	return CFrame.Angles(math.rad(x), math.rad(y), math.rad(z))
end
local IDENT = CFrame.new()

-- Kürzel: RS = rechte Schulter, RE = rechter Ellbogen, LS = linke Schulter, WA = Hüfte/Oberkörper
local JOINTS = { RS = "RightShoulder", RE = "RightElbow", LS = "LeftShoulder", WA = "Waist" }

-- Posen pro Schlagtyp. Fehlende Gelenke = Grundstellung.
local POSES = {
	Horizontal = {
		windup = { RS = A(-60, 40, 60), RE = A(-40, 0, 0), WA = A(0, 50, 0), LS = A(-40, 0, -30) },
		strike = { RS = A(-90, -20, -30), RE = A(-10, 0, 0), WA = A(0, -60, 0), LS = A(-40, 0, -30) },
	},
	Diagonal = {
		windup = { RS = A(-150, 0, 40), RE = A(-30, 0, 0), WA = A(-10, 40, 0), LS = A(-60, 0, -30) },
		strike = { RS = A(-60, -30, -20), RE = A(-10, 0, 0), WA = A(25, -45, 0), LS = A(-30, 0, -30) },
	},
	Overhead = {
		windup = { RS = A(-170, 0, 0), RE = A(-20, 0, 0), WA = A(-15, 0, 0), LS = A(-160, 0, 0) },
		strike = { RS = A(-60, 0, 0), RE = A(0, 0, 0), WA = A(30, 0, 0), LS = A(-60, 0, 0) },
	},
	Thrust = {
		windup = { RS = A(-60, 0, 30), RE = A(-70, 0, 0), WA = A(0, 30, 0), LS = A(-50, 0, -20) },
		strike = { RS = A(-95, 0, 0), RE = A(0, 0, 0), WA = A(10, -20, 0), LS = A(-50, 0, -20) },
	},
	Spin = {
		windup = { RS = A(-70, 0, 80), RE = A(-20, 0, 0), WA = A(0, 90, 0), LS = A(-30, 0, -60) },
		strike = { RS = A(-90, 0, -40), RE = A(-5, 0, 0), WA = A(0, -120, 0), LS = A(-30, 0, -60) },
	},
	Block = {
		hold = { RS = A(-100, 0, 40), RE = A(-90, 0, 0), LS = A(-100, 0, -40), WA = A(-5, 0, 0) },
	},
	Dash = {
		lean = { WA = A(25, 0, 0), RS = A(20, 0, 20), LS = A(20, 0, -20) },
	},
}

-- Welcher Schlagtyp bei Schlag 1 bis 4 je Kampfstil.
local STYLE_COMBOS = {
	Kiken = { "Horizontal", "Diagonal", "Horizontal", "Overhead" },
	Tsuken = { "Diagonal", "Diagonal", "Thrust", "Overhead" },
	Shiken = { "Thrust", "Horizontal", "Thrust", "Spin" },
	King = { "Diagonal", "Horizontal", "Overhead", "Spin" },
}

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
		local t = TweenService:Create(motor, info, { C0 = c0[key] * (pose and pose[key] or IDENT) })
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
	local combo = STYLE_COMBOS[styleName] or STYLE_COMBOS.Kiken
	local pose = POSES[combo[index] or "Horizontal"]
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

function ProceduralAnim.block(character, on)
	cancel(character)
	tweenTo(character, on and POSES.Block.hold or nil, 0.1)
end

function ProceduralAnim.dash(character, duration)
	local token = cancel(character)
	tweenTo(character, POSES.Dash.lean, 0.05)
	task.delay(duration, function()
		if tokens[character] == token then tweenTo(character, nil, 0.15) end
	end)
end

return ProceduralAnim
