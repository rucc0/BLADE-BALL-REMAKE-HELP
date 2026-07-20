local Players = game:GetService("Players")

local function stripForceField(character)
	character.ChildAdded:Connect(function(child)
		if child:IsA("ForceField") then
			child:Destroy()
		end
	end)

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("ForceField") then
			child:Destroy()
		end
	end
end

local function onCharacterAdded(character)
	stripForceField(character)
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end