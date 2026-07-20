local ReplicatedStorage = game:GetService("ReplicatedStorage")

local pingRemote = Instance.new("UnreliableRemoteEvent")
pingRemote.Name = "PingPong"
pingRemote.Parent = ReplicatedStorage

pingRemote.OnServerEvent:Connect(function(player, clientSendTime)
	pingRemote:FireClient(player, clientSendTime)
end)