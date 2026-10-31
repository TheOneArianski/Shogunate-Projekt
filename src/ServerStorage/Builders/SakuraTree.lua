-- Sakura-Baum aus Roblox-Parts.
-- In Studio (Command Bar, unten "View → Command Bar"):
--   require(game.ServerStorage.Builders.SakuraTree).build(Vector3.new(0, 0, 0))
-- Optionen: build(position, { scale = 1, seed = 42, parent = workspace, petals = true })
--   scale  = Größe (1 ≈ 25 Studs hoch), seed = andere Zahl → anders geformter Baum

local SakuraTree = {}

local TRUNK = Color3.fromRGB(70, 48, 38)
local PINKS = {
	Color3.fromRGB(255, 183, 197),
	Color3.fromRGB(255, 205, 215),
	Color3.fromRGB(244, 154, 180),
	Color3.fromRGB(255, 228, 235),
	Color3.fromRGB(236, 132, 165),
}

local function newPart(parent, shape, color, material)
	local p = Instance.new("Part")
	p.Shape = shape
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- Zylinder von a nach b (Roblox-Zylinder liegen entlang der X-Achse)
local function branchPart(parent, a, b, thickness)
	local len = (b - a).Magnitude
	if len < 0.05 then return end
	local p = newPart(parent, Enum.PartType.Cylinder, TRUNK, Enum.Material.Wood)
	p.Size = Vector3.new(len + thickness * 0.4, thickness, thickness)
	p.CFrame = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.rad(90), 0)
	-- Kugel am Ende verdeckt Lücken an Knicken
	local j = newPart(parent, Enum.PartType.Ball, TRUNK, Enum.Material.Wood)
	j.Size = Vector3.new(thickness, thickness, thickness)
	j.Position = b
	return p
end

local function blossom(parent, center, size, rng, acc)
	for _ = 1, rng:NextInteger(3, 5) do
		local s = size * rng:NextNumber(0.6, 1.1)
		local ball = newPart(parent, Enum.PartType.Ball, PINKS[rng:NextInteger(1, #PINKS)], Enum.Material.SmoothPlastic)
		ball.Size = Vector3.new(s, s, s)
		ball.Position = center + Vector3.new(
			rng:NextNumber(-1, 1),
			rng:NextNumber(-0.4, 0.6),
			rng:NextNumber(-1, 1)
		) * size * 0.8
		ball.CanCollide = false
		acc.sum += ball.Position
		acc.n += 1
	end
end

local function spreadDir(base, spread, rng)
	local d = base + Vector3.new(
		rng:NextNumber(-spread, spread),
		rng:NextNumber(-0.2, 0.5) * spread,
		rng:NextNumber(-spread, spread)
	)
	-- Sakura wächst breit: Y abschwächen
	return Vector3.new(d.X, d.Y * 0.6, d.Z).Unit
end

local function grow(wood, leaves, start, dir, length, thickness, depth, rng, scale, acc)
	local finish = start + dir * length
	branchPart(wood, start, finish, thickness)
	if depth <= 0 then
		blossom(leaves, finish, 5 * scale, rng, acc)
		return
	end
	for _ = 1, rng:NextInteger(2, 3) do
		grow(wood, leaves, finish, spreadDir(dir, 0.9, rng), length * rng:NextNumber(0.65, 0.8),
			thickness * 0.65, depth - 1, rng, scale, acc)
	end
	if depth == 1 then
		blossom(leaves, finish, 4 * scale, rng, acc)
	end
end

function SakuraTree.build(position, options)
	options = options or {}
	local scale = options.scale or 1
	local rng = Random.new(options.seed or math.random(1, 1e6))

	local model = Instance.new("Model")
	model.Name = "SakuraTree"
	local wood = Instance.new("Folder")
	wood.Name = "Wood"
	wood.Parent = model
	local leaves = Instance.new("Folder")
	leaves.Name = "Blossoms"
	leaves.Parent = model

	local base = position
	local acc = { sum = Vector3.zero, n = 0 }

	-- Wurzeln
	for i = 1, 4 do
		local ang = (i / 4) * math.pi * 2 + rng:NextNumber(-0.4, 0.4)
		local out = Vector3.new(math.cos(ang), 0, math.sin(ang))
		branchPart(wood, base + Vector3.new(0, 1.2 * scale, 0), base + out * 3.2 * scale - Vector3.new(0, 0.3 * scale, 0), 1.1 * scale)
	end

	-- Stamm: zwei leicht geneigte Stücke
	local lean = Vector3.new(rng:NextNumber(-0.25, 0.25), 1, rng:NextNumber(-0.25, 0.25)).Unit
	local p1 = base + lean * 8 * scale
	local trunk = branchPart(wood, base, p1, 2.6 * scale)
	local lean2 = (lean + Vector3.new(rng:NextNumber(-0.35, 0.35), 0, rng:NextNumber(-0.35, 0.35))).Unit
	local p2 = p1 + lean2 * 6 * scale
	branchPart(wood, p1, p2, 2.1 * scale)

	-- Hauptäste
	local mainCount = rng:NextInteger(4, 5)
	for i = 1, mainCount do
		local ang = (i / mainCount) * math.pi * 2 + rng:NextNumber(-0.3, 0.3)
		local dir = Vector3.new(math.cos(ang), rng:NextNumber(0.5, 0.9), math.sin(ang)).Unit
		grow(wood, leaves, p2, dir, 8 * scale, 1.4 * scale, 2, rng, scale, acc)
	end

	-- Fallende Blütenblätter
	if options.petals ~= false and acc.n > 0 then
		local center = acc.sum / acc.n
		local emitterPart = Instance.new("Part")
		emitterPart.Name = "PetalEmitter"
		emitterPart.Size = Vector3.new(26, 2, 26) * scale
		emitterPart.Position = center
		emitterPart.Transparency = 1
		emitterPart.Anchored = true
		emitterPart.CanCollide = false
		emitterPart.CanQuery = false
		emitterPart.CastShadow = false
		emitterPart.Parent = model

		local pe = Instance.new("ParticleEmitter")
		pe.Color = ColorSequence.new(PINKS[1], PINKS[4])
		pe.Size = NumberSequence.new(0.3 * scale)
		pe.Lifetime = NumberRange.new(6, 9)
		pe.Rate = 4
		pe.Speed = NumberRange.new(0.5, 1.5)
		pe.SpreadAngle = Vector2.new(180, 180)
		pe.Acceleration = Vector3.new(0.6, -1.5, 0.3)
		pe.Rotation = NumberRange.new(0, 360)
		pe.RotSpeed = NumberRange.new(-90, 90)
		pe.Shape = Enum.ParticleEmitterShape.Box
		pe.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		pe.Parent = emitterPart
	end

	model.PrimaryPart = trunk
	model.Parent = options.parent or workspace
	return model
end

return SakuraTree
