--!strict
-- Script principal del servidor: crea los tycoons y maneja a los jugadores.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.TycoonConfig)
local PlayerData = require(script.PlayerData)
local Tycoon = require(script.Tycoon)

-- Los tycoons se reparten en círculo alrededor del spawn, mirando al centro.
local tycoonsFolder = Instance.new("Folder")
tycoonsFolder.Name = "Tycoons"
tycoonsFolder.Parent = workspace

for index = 1, Config.PLOT_COUNT do
	local angle = (index - 1) / Config.PLOT_COUNT * math.pi * 2 + math.pi / 4
	local position = Vector3.new(math.cos(angle), 0, math.sin(angle)) * Config.PLOT_DISTANCE
	Tycoon.new(index, CFrame.lookAt(position, Vector3.zero), tycoonsFolder)
end

local function onPlayerAdded(player: Player)
	PlayerData.load(player)
end

local function onPlayerRemoving(player: Player)
	PlayerData.release(player)
	local tycoon = Tycoon.getOwnedBy(player)
	if tycoon then
		tycoon:reset()
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

-- Guardado automático cada cierto tiempo.
task.spawn(function()
	while true do
		task.wait(Config.AUTOSAVE_INTERVAL)
		PlayerData.saveAll()
	end
end)

-- Guardar a todos si el servidor se apaga.
game:BindToClose(function()
	PlayerData.saveAll()
end)
