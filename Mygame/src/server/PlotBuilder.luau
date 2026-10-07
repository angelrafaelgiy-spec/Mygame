--!strict
-- Construye el terreno vacío de un tycoon: piso, puerta para reclamar,
-- cinta transportadora, recolector y el botón para cobrar.
--
-- Coordenadas dentro del terreno: el frente (la puerta) está en Z negativo
-- y mira hacia el centro del mapa. La cinta va del frente hacia atrás.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.TycoonConfig)
local Util = require(script.Parent.Util)

export type Plot = {
	Model: Model,
	Origin: CFrame,
	Gate: Part,
	GateLabel: TextLabel,
	Conveyor: Part,
	Collector: Part,
	CollectPad: Part,
	CollectLabel: TextLabel,
	Buttons: Folder,
	Items: Folder,
	Drops: Folder,
}

local PlotBuilder = {}

PlotBuilder.CONVEYOR_X = -15
PlotBuilder.CONVEYOR_TOP = 2 -- altura de la superficie de la cinta

local function makeFolder(name: string, parent: Instance): Folder
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

function PlotBuilder.build(index: number, origin: CFrame, parent: Instance): Plot
	local size = Config.PLOT_SIZE
	local half = size / 2
	local x = PlotBuilder.CONVEYOR_X

	local model = Instance.new("Model")
	model.Name = "Tycoon" .. index

	local function at(px: number, py: number, pz: number): CFrame
		return origin * CFrame.new(px, py, pz)
	end

	Util.makePart({
		Name = "Floor",
		Size = Vector3.new(size, 1, size),
		CFrame = at(0, 0.5, 0),
		Color = Color3.fromRGB(91, 154, 76),
		Material = Enum.Material.Grass,
		Parent = model,
	})

	local gate = Util.makePart({
		Name = "ClaimGate",
		Size = Vector3.new(12, 6, 1),
		CFrame = at(0, 4, -half + 1),
		Color = Color3.fromRGB(0, 255, 0),
		Material = Enum.Material.Neon,
		Transparency = 0.5,
		CanCollide = false,
		Parent = model,
	})
	local gateLabel = Util.makeLabel(gate, "Toca para reclamar", 5, UDim2.fromOffset(300, 60))

	-- Cinta transportadora con barandas para que los bloques no se caigan.
	local conveyor = Util.makePart({
		Name = "Conveyor",
		Size = Vector3.new(4, 1, 40),
		CFrame = at(x, PlotBuilder.CONVEYOR_TOP - 0.5, 2),
		Color = Color3.fromRGB(50, 50, 50),
		Material = Enum.Material.DiamondPlate,
		Parent = model,
	})
	for _, side in { -1, 1 } do
		Util.makePart({
			Name = "Rail",
			Size = Vector3.new(0.5, 2, 40),
			CFrame = at(x + side * 2.25, PlotBuilder.CONVEYOR_TOP + 0.5, 2),
			Color = Color3.fromRGB(27, 42, 53),
			Parent = model,
		})
	end

	-- Recolector al final de la cinta: convierte los bloques en dinero.
	local collector = Util.makePart({
		Name = "Collector",
		Size = Vector3.new(4.5, 3, 3),
		CFrame = at(x, PlotBuilder.CONVEYOR_TOP + 1, 23.5),
		Color = Color3.fromRGB(255, 89, 89),
		Material = Enum.Material.Neon,
		Parent = model,
	})
	Util.makeLabel(collector, "Recolector", 3)

	-- Botón para pasar el dinero acumulado al jugador.
	local collectPad = Util.makePart({
		Name = "CollectPad",
		Size = Vector3.new(6, 0.4, 6),
		CFrame = at(-5, 1.2, 22),
		Color = Color3.fromRGB(0, 200, 90),
		Material = Enum.Material.Neon,
		Parent = model,
	})
	local collectLabel = Util.makeLabel(collectPad, "Cobrar: $0", 3)

	local plot: Plot = {
		Model = model,
		Origin = origin,
		Gate = gate,
		GateLabel = gateLabel,
		Conveyor = conveyor,
		Collector = collector,
		CollectPad = collectPad,
		CollectLabel = collectLabel,
		Buttons = makeFolder("Buttons", model),
		Items = makeFolder("Items", model),
		Drops = makeFolder("Drops", model),
	}

	model.Parent = parent
	return plot
end

return PlotBuilder
