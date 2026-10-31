-- Animationen per Code für R6 und R15, solange keine echten AnimationIds eingetragen sind.
-- Es werden die C0-Werte der Motor6D-Gelenke verändert; der Server tut das, damit alle Spieler es sehen.
-- Die Posen unten sind rig-unabhängig ("semantisch") und werden pro Rig umgerechnet:
--   RS/LS: x negativ = Arm nach vorn heben, z positiv (rechts) bzw. negativ (links) = Arm nach außen, y = Drehung
--   WA:    x positiv = Oberkörper nach vorn lehnen, y = Oberkörper drehen
--   RE:    x negativ = Unterarm beugen (nur R15)
-- ACHTUNG: Winkel sind Schätzwerte und müssen in Studio nachjustiert werden.
local TweenService = game:GetService("TweenService")

local ProceduralAnim = {}

local function A(x, y, z)
	return { x = x, y = y, z = z }
end
local function rad(n) return math.rad(n) end

-- Kürzel: RS = rechte Schulter, RE = rechter Ellbogen, LS = linke Schulter, WA = Hüfte/Oberkörper
local JOINTS = {
	R15 = { RS = "RightShoulder", RE = "RightElbow", LS = "LeftShoulder", WA = "Waist" },
	R6 = { RS = "Right Shoulder", LS = "Left Shoulder", WA = "RootJoint" }, -- R6 hat keinen Ellbogen
}

-- Semantische Winkel -> Offset für das jeweilige Rig.
local function toOffset(rig, key, a)
	if rig == "R15" then
		-- R15: nach vorn heben bzw. nach vorn lehnen ist je nach Gelenk +X bzw. -X
		return CFrame.Angles(rad(-a.x), rad(a.y), rad(a.z))
	end
	-- R6: Gelenke sind gedreht (C0 hat eine Rotation), daher andere Achsen
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
	if o then return o.motors, o.c0, o.rig end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rig = (humanoid and humanoid.RigType == Enum.HumanoidRigType.R6) and "R6" or "R15"
	local motors, c0 = {}, {}
	for key, name in pairs(JOINTS[rig]) do
		local m = character:FindFirstChild(name, true)
		if m and m:IsA("Motor6D") then
			motors[key] = m
			c0[key] = m.C0
		end
	end
	originals[character] = { motors = motors, c0 = c0, rig = rig }
	return motors, c0, rig
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
	local motors, c0, rig = getMotors(character)
	local list = activeTweens[character] or {}
	activeTweens[character] = list
	local info = TweenInfo.new(math.max(duration, 0.01), style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	for key, motor in pairs(motors) do
		local a = pose and pose[key]
		local offset = a and toOffset(rig, key, a) or CFrame.new()
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
