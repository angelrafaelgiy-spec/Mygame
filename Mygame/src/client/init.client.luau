--!strict
-- Pantalla del jugador: muestra su dinero y los mensajes del servidor.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Format = require(ReplicatedStorage.Shared.Format)

local player = Players.LocalPlayer
local notifyEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify") :: RemoteEvent

local screen = Instance.new("ScreenGui")
screen.Name = "TycoonHud"
screen.ResetOnSpawn = false

local cashLabel = Instance.new("TextLabel")
cashLabel.Name = "Cash"
cashLabel.AnchorPoint = Vector2.new(0.5, 1)
cashLabel.Position = UDim2.new(0.5, 0, 1, -20)
cashLabel.Size = UDim2.fromOffset(260, 60)
cashLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
cashLabel.BackgroundTransparency = 0.3
cashLabel.Font = Enum.Font.FredokaOne
cashLabel.TextColor3 = Color3.fromRGB(85, 255, 127)
cashLabel.TextScaled = true
cashLabel.Text = "$0"
cashLabel.Parent = screen
Instance.new("UICorner").Parent = cashLabel

local messageLabel = Instance.new("TextLabel")
messageLabel.Name = "Message"
messageLabel.AnchorPoint = Vector2.new(0.5, 0)
messageLabel.Position = UDim2.new(0.5, 0, 0, 60)
messageLabel.Size = UDim2.new(0.6, 0, 0, 40)
messageLabel.BackgroundTransparency = 1
messageLabel.Font = Enum.Font.FredokaOne
messageLabel.TextColor3 = Color3.new(1, 1, 1)
messageLabel.TextScaled = true
messageLabel.TextTransparency = 1
messageLabel.TextStrokeTransparency = 1
messageLabel.Parent = screen

screen.Parent = player:WaitForChild("PlayerGui")

-- Dinero: se lee de leaderstats, que crea el servidor.
local leaderstats = player:WaitForChild("leaderstats")
local cashValue = leaderstats:WaitForChild("Dinero") :: IntValue

local function updateCash()
	cashLabel.Text = Format.money(cashValue.Value)
end
cashValue.Changed:Connect(updateCash)
updateCash()

-- Mensajes: aparecen arriba y se desvanecen.
local fadeInfo = TweenInfo.new(0.5)
local messageId = 0

notifyEvent.OnClientEvent:Connect(function(message: string)
	messageId += 1
	local myId = messageId
	messageLabel.Text = message
	messageLabel.TextTransparency = 0
	messageLabel.TextStrokeTransparency = 0
	task.wait(2.5)
	if myId == messageId then
		TweenService:Create(messageLabel, fadeInfo, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end
end)
