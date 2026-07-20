local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PingFpsDisplayGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")
local container = Instance.new("Frame")
container.Name = "StatsContainer"
container.Size = UDim2.new(0, 170, 0, 68)
container.Position = UDim2.new(0, 10, 1, -10)
container.AnchorPoint = Vector2.new(0, 1)
container.BackgroundTransparency = 1
container.Parent = screenGui
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.Padding = UDim.new(0, 2)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = container
local function createLabel(name, order)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.new(1, 0, 0, 20)
	label.BackgroundTransparency = 1
	label.FontFace = Font.new("rbxassetid://12187372382", Enum.FontWeight.Regular)
	label.TextSize = 28
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.LayoutOrder = order
	label.Text = name .. ": --"
	label.Parent = container
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.5
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Parent = label
	return label
end
local fpsLabel = createLabel("FPS", 1)
local pingLabel = createLabel("Ping", 2)
local frameCount = 0
local elapsed = 0
RunService.RenderStepped:Connect(function(dt)
	frameCount += 1
	elapsed += dt
	if elapsed >= 0.2 then
		local fps = frameCount / elapsed
		fpsLabel.Text = string.format("FPS: %d", math.floor(fps + 0.5))
		frameCount = 0
		elapsed = 0
	end
end)
local pingRemote = ReplicatedStorage:WaitForChild("PingPong")
local PING_SAMPLE_WINDOW = 8
local pingSamples = {}
local function updatePingLabel()
	local sum = 0
	for _, v in pingSamples do
		sum += v
	end
	local avg = sum / #pingSamples
	pingLabel.Text = string.format("Ping: %dms", math.floor(avg + 0.5))
end
pingRemote.OnClientEvent:Connect(function(sentTime)
	local roundTrip = (os.clock() - sentTime) * 1000
	table.insert(pingSamples, roundTrip)
	while #pingSamples > PING_SAMPLE_WINDOW do
		table.remove(pingSamples, 1)
	end
	updatePingLabel()
end)
task.spawn(function()
	while true do
		pingRemote:FireServer(os.clock())
		task.wait(0.2)
	end
end)