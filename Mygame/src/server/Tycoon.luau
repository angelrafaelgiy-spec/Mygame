--!strict
-- Un tycoon: dueño, dinero acumulado en el recolector, botones y compras.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.TycoonConfig)
local Format = require(ReplicatedStorage.Shared.Format)
local ItemBuilders = require(script.Parent.ItemBuilders)
local PlayerData = require(script.Parent.PlayerData)
local PlotBuilder = require(script.Parent.PlotBuilder)
local Util = require(script.Parent.Util)

local notifyEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify") :: RemoteEvent

local NOTIFY_COOLDOWN = 1.5
local FREE_COLOR = Color3.fromRGB(0, 170, 255)
local BUTTON_COLOR = Color3.fromRGB(0, 255, 0)

local Tycoon = {}
Tycoon.__index = Tycoon

export type Tycoon = typeof(setmetatable(
	{} :: {
		plot: PlotBuilder.Plot,
		owner: Player?,
		bank: number,
		purchased: { [string]: boolean },
		buttons: { [string]: Part },
		conveyorSpeed: number,
		lastNotify: number,
	},
	Tycoon
))

local ownedBy: { [Player]: Tycoon } = {}

function Tycoon.getOwnedBy(player: Player): Tycoon?
	return ownedBy[player]
end

function Tycoon.new(index: number, origin: CFrame, parent: Instance): Tycoon
	local self = setmetatable({
		plot = PlotBuilder.build(index, origin, parent),
		owner = nil :: Player?,
		bank = 0,
		purchased = {},
		buttons = {},
		conveyorSpeed = Config.CONVEYOR_SPEED,
		lastNotify = 0,
	}, Tycoon)

	self:_createButtons()
	self:_connectEvents()
	self:setConveyorSpeed(Config.CONVEYOR_SPEED)
	self:_refreshButtons()
	return self
end

function Tycoon.setConveyorSpeed(self: Tycoon, speed: number)
	self.conveyorSpeed = speed
	-- Una parte anclada con velocidad empuja lo que está encima: así funciona la cinta.
	local conveyor = self.plot.Conveyor
	conveyor.AssemblyLinearVelocity = self.plot.Origin:VectorToWorldSpace(Vector3.new(0, 0, speed))
end

function Tycoon.notify(self: Tycoon, message: string)
	if self.owner then
		notifyEvent:FireClient(self.owner, message)
	end
end

function Tycoon._setBank(self: Tycoon, amount: number)
	self.bank = amount
	self.plot.CollectLabel.Text = "Cobrar: " .. Format.money(amount)
end

function Tycoon._createButtons(self: Tycoon)
	for _, item in Config.Items do
		local button = Util.makePart({
			Name = item.Id .. "Button",
			Size = Vector3.new(4, 0.4, 4),
			CFrame = self.plot.Origin * CFrame.new(item.Button.X, 1.2, item.Button.Y),
			Color = if item.Price == 0 then FREE_COLOR else BUTTON_COLOR,
			Material = Enum.Material.Neon,
		})
		local priceText = if item.Price == 0 then "GRATIS" else Format.money(item.Price)
		Util.makeLabel(button, item.Name .. "\n" .. priceText, 3, UDim2.fromOffset(180, 60))

		button.Touched:Connect(function(hit)
			local player = Util.getPlayerFromHit(hit)
			if player then
				self:_tryBuy(item, player)
			end
		end)
		self.buttons[item.Id] = button
	end
end

function Tycoon._connectEvents(self: Tycoon)
	self.plot.Gate.Touched:Connect(function(hit)
		local player = Util.getPlayerFromHit(hit)
		if player then
			self:_tryClaim(player)
		end
	end)

	self.plot.Collector.Touched:Connect(function(hit)
		if hit.Parent ~= self.plot.Drops then
			return
		end
		local value = hit:GetAttribute("Value")
		hit:Destroy() -- se borra primero para no contarlo dos veces
		if self.owner and typeof(value) == "number" then
			self:_setBank(self.bank + value)
		end
	end)

	self.plot.CollectPad.Touched:Connect(function(hit)
		local player = Util.getPlayerFromHit(hit)
		if player and player == self.owner and self.bank > 0 then
			PlayerData.addCash(player, self.bank)
			self:_setBank(0)
		end
	end)
end

function Tycoon._canShowButton(self: Tycoon, item: Config.Item): boolean
	if not self.owner or self.purchased[item.Id] then
		return false
	end
	return item.Requires == nil or self.purchased[item.Requires] == true
end

function Tycoon._refreshButtons(self: Tycoon)
	for _, item in Config.Items do
		local button = self.buttons[item.Id]
		button.Parent = if self:_canShowButton(item) then self.plot.Buttons else nil
	end
end

function Tycoon._tryClaim(self: Tycoon, player: Player)
	if self.owner or ownedBy[player] or not PlayerData.isLoaded(player) then
		return
	end
	self.owner = player
	ownedBy[player] = self

	self.plot.Gate.Transparency = 0.8
	self.plot.Gate.Color = Color3.fromRGB(255, 170, 0)
	self.plot.GateLabel.Text = "Tycoon de " .. player.DisplayName

	-- Reconstruir lo que el jugador ya había comprado en otras partidas.
	local saved = PlayerData.getPurchases(player)
	for _, item in Config.Items do
		if table.find(saved, item.Id) then
			self:_build(item)
		end
	end
	self:_refreshButtons()
	self:notify("¡Este tycoon es tuyo! Pisa los botones para comprar.")
end

function Tycoon._build(self: Tycoon, item: Config.Item)
	self.purchased[item.Id] = true
	local builder = ItemBuilders[item.Kind]
	if builder then
		builder(self :: any, item)
	else
		warn("No hay constructor para el tipo " .. item.Kind)
	end
end

function Tycoon._tryBuy(self: Tycoon, item: Config.Item, player: Player)
	if player ~= self.owner or not self:_canShowButton(item) then
		return
	end
	if not PlayerData.trySpend(player, item.Price) then
		local now = os.clock()
		if now - self.lastNotify > NOTIFY_COOLDOWN then
			self.lastNotify = now
			local missing = item.Price - PlayerData.getCash(player)
			self:notify("Te faltan " .. Format.money(missing) .. " para " .. item.Name)
		end
		return
	end
	PlayerData.addPurchase(player, item.Id)
	self:_build(item)
	self:_refreshButtons()
end

-- Deja el tycoon libre otra vez (cuando el dueño sale del juego).
function Tycoon.reset(self: Tycoon)
	if self.owner then
		ownedBy[self.owner] = nil
	end
	self.owner = nil
	self.purchased = {}
	self:_setBank(0)
	self.plot.Items:ClearAllChildren()
	self.plot.Drops:ClearAllChildren()
	self.plot.Conveyor.Color = Color3.fromRGB(50, 50, 50)
	self:setConveyorSpeed(Config.CONVEYOR_SPEED)

	self.plot.Gate.Transparency = 0.5
	self.plot.Gate.Color = Color3.fromRGB(0, 255, 0)
	self.plot.GateLabel.Text = "Toca para reclamar"
	self:_refreshButtons()
end

return Tycoon
