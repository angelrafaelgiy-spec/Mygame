--!strict
-- Guarda el dinero y las compras de cada jugador (DataStore) y
-- muestra el dinero en la tabla de jugadores (leaderstats).
--
-- En Roblox Studio, para que se guarde hay que activar:
-- Game Settings -> Security -> "Enable Studio Access to API Services".

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.TycoonConfig)

type Profile = {
	Cash: number,
	Purchases: { string },
	CashValue: IntValue,
	CanSave: boolean, -- false si no se pudo cargar, para no borrar datos guardados
}

local PlayerData = {}

local profiles: { [Player]: Profile } = {}

local store: DataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore("TycoonData_v1")
	end)
	if ok then
		store = result
	else
		warn("No se pudo abrir el DataStore, el progreso no se guardará:", result)
	end
end

local function keyFor(player: Player): string
	return "player_" .. player.UserId
end

function PlayerData.load(player: Player)
	local saved: any = nil
	local canSave = false
	if store then
		local ok, result = pcall(function()
			return store:GetAsync(keyFor(player))
		end)
		if ok then
			saved = result
			canSave = true
		else
			warn("No se pudieron cargar los datos de " .. player.Name .. ":", result)
		end
	end

	if not player.Parent then
		return -- se fue mientras cargaba
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local cashValue = Instance.new("IntValue")
	cashValue.Name = "Dinero"

	local profile: Profile = {
		Cash = if saved and typeof(saved.Cash) == "number" then saved.Cash else Config.STARTING_CASH,
		Purchases = if saved and typeof(saved.Purchases) == "table" then saved.Purchases else {},
		CashValue = cashValue,
		CanSave = canSave,
	}
	cashValue.Value = profile.Cash
	cashValue.Parent = leaderstats
	leaderstats.Parent = player

	profiles[player] = profile
end

function PlayerData.isLoaded(player: Player): boolean
	return profiles[player] ~= nil
end

function PlayerData.getCash(player: Player): number
	local profile = profiles[player]
	return if profile then profile.Cash else 0
end

function PlayerData.addCash(player: Player, amount: number)
	local profile = profiles[player]
	if not profile then
		return
	end
	profile.Cash += amount
	profile.CashValue.Value = profile.Cash
end

-- Resta dinero si alcanza. Devuelve true si se pudo pagar.
function PlayerData.trySpend(player: Player, amount: number): boolean
	local profile = profiles[player]
	if not profile or profile.Cash < amount then
		return false
	end
	PlayerData.addCash(player, -amount)
	return true
end

function PlayerData.getPurchases(player: Player): { string }
	local profile = profiles[player]
	return if profile then profile.Purchases else {}
end

function PlayerData.addPurchase(player: Player, itemId: string)
	local profile = profiles[player]
	if profile and not table.find(profile.Purchases, itemId) then
		table.insert(profile.Purchases, itemId)
	end
end

function PlayerData.save(player: Player)
	local profile = profiles[player]
	if not store or not profile or not profile.CanSave then
		return
	end
	local data = {
		Cash = profile.Cash,
		Purchases = profile.Purchases,
	}
	local ok, err = pcall(function()
		store:SetAsync(keyFor(player), data, { player.UserId })
	end)
	if not ok then
		warn("No se pudieron guardar los datos de " .. player.Name .. ":", err)
	end
end

-- Guarda y olvida al jugador (cuando sale del juego).
function PlayerData.release(player: Player)
	PlayerData.save(player)
	profiles[player] = nil
end

function PlayerData.saveAll()
	local pending = 0
	for player in profiles do
		pending += 1
		task.spawn(function()
			PlayerData.save(player)
			pending -= 1
		end)
	end
	while pending > 0 do
		task.wait()
	end
end

return PlayerData
