--!strict
-- Configuración del Tycoon: precios, valores y posiciones.
-- Cambia los números aquí para ajustar el juego sin tocar el resto del código.

export type Item = {
	Id: string,
	Name: string,
	Price: number,
	Requires: string?, -- Id del objeto que hay que comprar antes
	Kind: "Dropper" | "FastConveyor" | "Walls" | "Upgrader" | "Roof" | "Statue",
	Button: Vector2, -- posición del botón dentro del terreno (X, Z)
	-- Solo para goteros:
	Z: number?,
	Value: number?,
	Interval: number?,
	Color: Color3?,
}

local TycoonConfig = {}

TycoonConfig.PLOT_COUNT = 4 -- cuántos tycoons hay en el mapa
TycoonConfig.PLOT_SIZE = 60
TycoonConfig.PLOT_DISTANCE = 80 -- distancia de cada tycoon al centro del mapa
TycoonConfig.STARTING_CASH = 0
TycoonConfig.CONVEYOR_SPEED = 6
TycoonConfig.FAST_CONVEYOR_SPEED = 12
TycoonConfig.UPGRADER_MULTIPLIER = 2
TycoonConfig.DROP_LIFETIME = 30 -- segundos antes de borrar un bloque que se quedó atorado
TycoonConfig.AUTOSAVE_INTERVAL = 120

-- Lista de cosas que se pueden comprar, en orden.
local items: { Item } = {
	{
		Id = "Dropper1",
		Name = "Gotero",
		Price = 0,
		Kind = "Dropper",
		Button = Vector2.new(6, -20),
		Z = -14,
		Value = 2,
		Interval = 2,
		Color = Color3.fromRGB(163, 162, 165),
	},
	{
		Id = "Dropper2",
		Name = "Gotero 2",
		Price = 50,
		Requires = "Dropper1",
		Kind = "Dropper",
		Button = Vector2.new(14, -20),
		Z = -8,
		Value = 3,
		Interval = 2,
		Color = Color3.fromRGB(13, 105, 172),
	},
	{
		Id = "Walls",
		Name = "Paredes",
		Price = 150,
		Requires = "Dropper2",
		Kind = "Walls",
		Button = Vector2.new(22, -20),
	},
	{
		Id = "Dropper3",
		Name = "Gotero 3",
		Price = 250,
		Requires = "Dropper2",
		Kind = "Dropper",
		Button = Vector2.new(6, -12),
		Z = -2,
		Value = 6,
		Interval = 2,
		Color = Color3.fromRGB(75, 151, 75),
	},
	{
		Id = "FastConveyor",
		Name = "Cinta rápida",
		Price = 400,
		Requires = "Dropper3",
		Kind = "FastConveyor",
		Button = Vector2.new(14, -12),
	},
	{
		Id = "Dropper4",
		Name = "Gotero 4",
		Price = 700,
		Requires = "Dropper3",
		Kind = "Dropper",
		Button = Vector2.new(22, -12),
		Z = 4,
		Value = 12,
		Interval = 2,
		Color = Color3.fromRGB(196, 40, 28),
	},
	{
		Id = "Upgrader",
		Name = "Mejorador x2",
		Price = 1500,
		Requires = "Dropper4",
		Kind = "Upgrader",
		Button = Vector2.new(6, -4),
	},
	{
		Id = "Roof",
		Name = "Techo",
		Price = 2500,
		Requires = "Walls",
		Kind = "Roof",
		Button = Vector2.new(14, -4),
	},
	{
		Id = "GoldDropper",
		Name = "Gotero de oro",
		Price = 5000,
		Requires = "Upgrader",
		Kind = "Dropper",
		Button = Vector2.new(22, -4),
		Z = 10,
		Value = 40,
		Interval = 2,
		Color = Color3.fromRGB(245, 205, 48),
	},
	{
		Id = "Statue",
		Name = "Estatua de Magnate",
		Price = 25000,
		Requires = "GoldDropper",
		Kind = "Statue",
		Button = Vector2.new(14, 4),
	},
}
TycoonConfig.Items = items

return TycoonConfig
