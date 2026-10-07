--!strict
-- Una función por cada tipo de objeto comprable (Kind en TycoonConfig).
-- Cada función construye el objeto dentro del tycoon que lo compró.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.TycoonConfig)
local PlotBuilder = require(script.Parent.PlotBuilder)
local Util = require(script.Parent.Util)

-- Lo que los constructores necesitan saber del tycoon.
export type TycoonLike = {
	plot: PlotBuilder.Plot,
	owner: Player?,
	setConveyorSpeed: (self: any, speed: number) -> (),
}

type Builder = (tycoon: TycoonLike, item: Config.Item) -> ()

local ItemBuilders: { [string]: Builder } = {}

local function at(tycoon: TycoonLike, x: number, y: number, z: number): CFrame
	return tycoon.plot.Origin * CFrame.new(x, y, z)
end

-- Gotero: suelta un bloque con valor cada cierto tiempo sobre la cinta.
ItemBuilders.Dropper = function(tycoon, item)
	local x = PlotBuilder.CONVEYOR_X
	local z = assert(item.Z, "El gotero necesita Z")
	local value = assert(item.Value, "El gotero necesita Value")
	local interval = item.Interval or 2
	local color = item.Color or Color3.new(1, 1, 1)

	local body = Util.makePart({
		Name = item.Id,
		Size = Vector3.new(4, 4, 4),
		CFrame = at(tycoon, x, 8.5, z),
		Color = color,
		Material = Enum.Material.Metal,
		Parent = tycoon.plot.Items,
	})
	Util.makePart({
		Name = "Nozzle",
		Size = Vector3.new(2, 1, 2),
		CFrame = at(tycoon, x, 6, z),
		Color = Color3.fromRGB(27, 42, 53),
		Parent = body,
	})

	task.spawn(function()
		-- Cuando el tycoon se reinicia, el gotero se borra y el ciclo termina.
		while body.Parent do
			task.wait(interval)
			if not body.Parent then
				break
			end
			local drop = Util.makePart({
				Name = "Drop",
				Size = Vector3.new(1.2, 1.2, 1.2),
				CFrame = at(tycoon, x, 4.8, z),
				Color = color,
				Material = Enum.Material.SmoothPlastic,
				Anchored = false,
				Parent = tycoon.plot.Drops,
			})
			drop:SetAttribute("Value", value)
			drop:SetNetworkOwner(nil)
			Debris:AddItem(drop, Config.DROP_LIFETIME)
		end
	end)
end

-- Cinta rápida: los bloques llegan antes al recolector.
ItemBuilders.FastConveyor = function(tycoon, _item)
	tycoon:setConveyorSpeed(Config.FAST_CONVEYOR_SPEED)
	tycoon.plot.Conveyor.Color = Color3.fromRGB(0, 120, 255)
end

-- Mejorador: multiplica el valor de cada bloque que pasa por él.
ItemBuilders.Upgrader = function(tycoon, item)
	local x = PlotBuilder.CONVEYOR_X
	local z = 16
	local model = Instance.new("Model")
	model.Name = item.Id

	for _, side in { -1, 1 } do
		Util.makePart({
			Name = "Pillar",
			Size = Vector3.new(1, 5, 1),
			CFrame = at(tycoon, x + side * 3, 3.5, z),
			Color = Color3.fromRGB(27, 42, 53),
			Parent = model,
		})
	end
	Util.makePart({
		Name = "Top",
		Size = Vector3.new(7, 1, 1),
		CFrame = at(tycoon, x, 6.5, z),
		Color = Color3.fromRGB(27, 42, 53),
		Parent = model,
	})
	local field = Util.makePart({
		Name = "Field",
		Size = Vector3.new(4, 4, 1),
		CFrame = at(tycoon, x, 4, z),
		Color = Color3.fromRGB(170, 0, 255),
		Material = Enum.Material.Neon,
		Transparency = 0.5,
		CanCollide = false,
		Parent = model,
	})
	Util.makeLabel(field, "x" .. Config.UPGRADER_MULTIPLIER, 4)

	field.Touched:Connect(function(hit)
		if hit.Parent ~= tycoon.plot.Drops or hit:GetAttribute("Upgraded") then
			return
		end
		local value = hit:GetAttribute("Value")
		if typeof(value) == "number" then
			hit:SetAttribute("Value", value * Config.UPGRADER_MULTIPLIER)
			hit:SetAttribute("Upgraded", true)
			hit.Material = Enum.Material.Neon
		end
	end)

	model.Parent = tycoon.plot.Items
end

-- Paredes alrededor del terreno, con un hueco al frente para la puerta.
ItemBuilders.Walls = function(tycoon, item)
	local half = Config.PLOT_SIZE / 2
	local height = 10
	local y = 1 + height / 2
	local gap = 14
	local frontWidth = (Config.PLOT_SIZE - gap) / 2
	local model = Instance.new("Model")
	model.Name = item.Id

	local walls = {
		-- { tamaño, posición }
		{ Vector3.new(1, height, Config.PLOT_SIZE), Vector3.new(-half + 0.5, y, 0) }, -- izquierda
		{ Vector3.new(1, height, Config.PLOT_SIZE), Vector3.new(half - 0.5, y, 0) }, -- derecha
		{ Vector3.new(Config.PLOT_SIZE, height, 1), Vector3.new(0, y, half - 0.5) }, -- atrás
		{ Vector3.new(frontWidth, height, 1), Vector3.new(-half + frontWidth / 2, y, -half + 0.5) },
		{ Vector3.new(frontWidth, height, 1), Vector3.new(half - frontWidth / 2, y, -half + 0.5) },
	}
	for _, wall in walls do
		local size, position = wall[1], wall[2]
		Util.makePart({
			Name = "Wall",
			Size = size,
			CFrame = at(tycoon, position.X, position.Y, position.Z),
			Color = Color3.fromRGB(215, 197, 154),
			Material = Enum.Material.Brick,
			Parent = model,
		})
	end

	model.Parent = tycoon.plot.Items
end

-- Techo encima de las paredes.
ItemBuilders.Roof = function(tycoon, item)
	Util.makePart({
		Name = item.Id,
		Size = Vector3.new(Config.PLOT_SIZE, 1, Config.PLOT_SIZE),
		CFrame = at(tycoon, 0, 11.5, 0),
		Color = Color3.fromRGB(105, 64, 40),
		Material = Enum.Material.WoodPlanks,
		Parent = tycoon.plot.Items,
	})
end

-- Estatua dorada con el nombre del dueño: el premio final.
ItemBuilders.Statue = function(tycoon, item)
	local model = Instance.new("Model")
	model.Name = item.Id

	Util.makePart({
		Name = "Base",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(2, 8, 8),
		CFrame = at(tycoon, 15, 2, 18) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(99, 95, 98),
		Material = Enum.Material.Marble,
		Parent = model,
	})
	local orb = Util.makePart({
		Name = "Orb",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(5, 5, 5),
		CFrame = at(tycoon, 15, 5.5, 18),
		Color = Color3.fromRGB(255, 215, 0),
		Material = Enum.Material.Neon,
		Parent = model,
	})
	local ownerName = if tycoon.owner then tycoon.owner.DisplayName else "?"
	Util.makeLabel(orb, "👑 Magnate " .. ownerName .. " 👑", 4, UDim2.fromOffset(320, 60))

	model.Parent = tycoon.plot.Items
end

return ItemBuilders
