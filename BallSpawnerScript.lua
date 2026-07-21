local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local ballBloom = Lighting:FindFirstChild("BallGlowBloom")
if not ballBloom then
	ballBloom = Instance.new("BloomEffect")
	ballBloom.Name = "BallGlowBloom"
	ballBloom.Intensity = 2.5
	ballBloom.Size = 18
	ballBloom.Threshold = 1.3
	ballBloom.Parent = Lighting
end

local spawner = Workspace:FindFirstChild("BallSpawner")
if not spawner then
	warn("BallSpawner part not found!")
	return
end

if spawner:IsA("BasePart") and spawner.Material == Enum.Material.Neon then
	spawner.Material = Enum.Material.SmoothPlastic
end

local starBurstModule = ReplicatedStorage:WaitForChild("StarBurstVFX", 5)
if not starBurstModule then
	warn("StarBurstVFX module not found in ReplicatedStorage! Make sure it's placed there.")
	return
end
local StarBurstVFX = require(starBurstModule)

local settingsFolder = ReplicatedStorage:FindFirstChild("BallSettings")
if not settingsFolder then
	settingsFolder = Instance.new("Folder")
	settingsFolder.Name = "BallSettings"
	settingsFolder.Parent = ReplicatedStorage
end

local BOT_USER_ID = -1
local botModel = Workspace:FindFirstChild("bot")
local botProxy = nil
if botModel then
	botProxy = {
		Name = botModel.Name,
		UserId = BOT_USER_ID,
		Character = botModel,
	}
end

local BALL_SIZE = 3
local MIN_PLAYERS_TO_SPAWN = 2

local settings = {
	baseSpeed = 30,
	maxBallSpeed = math.huge,
	speedIncrease = 6,
}

local defaultSettings = {}
for key, value in settings do
	defaultSettings[key] = value
end

local updateSettingsRemote = settingsFolder:FindFirstChild("UpdateSettings")
if not updateSettingsRemote then
	updateSettingsRemote = Instance.new("RemoteEvent")
	updateSettingsRemote.Name = "UpdateSettings"
	updateSettingsRemote.Parent = settingsFolder
end

local getSettingsRemote = settingsFolder:FindFirstChild("GetSettings")
if not getSettingsRemote then
	getSettingsRemote = Instance.new("RemoteFunction")
	getSettingsRemote.Name = "GetSettings"
	getSettingsRemote.Parent = settingsFolder
end

local ballSpeedRemote = settingsFolder:FindFirstChild("BallSpeedUpdate")
if not ballSpeedRemote then
	ballSpeedRemote = Instance.new("RemoteEvent")
	ballSpeedRemote.Name = "BallSpeedUpdate"
	ballSpeedRemote.Parent = settingsFolder
end

local respawnRemote = settingsFolder:FindFirstChild("RespawnBall")
if not respawnRemote then
	respawnRemote = Instance.new("RemoteEvent")
	respawnRemote.Name = "RespawnBall"
	respawnRemote.Parent = settingsFolder
end

local bringBallRemote = settingsFolder:FindFirstChild("BringBall")
if not bringBallRemote then
	bringBallRemote = Instance.new("RemoteEvent")
	bringBallRemote.Name = "BringBall"
	bringBallRemote.Parent = settingsFolder
end

local resetSettingsRemote = settingsFolder:FindFirstChild("ResetSettings")
if not resetSettingsRemote then
	resetSettingsRemote = Instance.new("RemoteEvent")
	resetSettingsRemote.Name = "ResetSettings"
	resetSettingsRemote.Parent = settingsFolder
end

local ballSyncRemote = settingsFolder:FindFirstChild("BallSync")
if not ballSyncRemote then
	ballSyncRemote = Instance.new("UnreliableRemoteEvent")
	ballSyncRemote.Name = "BallSync"
	ballSyncRemote.Parent = settingsFolder
end

local ballStateRemote = settingsFolder:FindFirstChild("BallState")
if not ballStateRemote then
	ballStateRemote = Instance.new("RemoteEvent")
	ballStateRemote.Name = "BallState"
	ballStateRemote.Parent = settingsFolder
end

local parrySoundRemote = settingsFolder:FindFirstChild("ParrySound")
if not parrySoundRemote then
	parrySoundRemote = Instance.new("UnreliableRemoteEvent")
	parrySoundRemote.Name = "ParrySound"
	parrySoundRemote.Parent = settingsFolder
end

local waitingStatusRemote = settingsFolder:FindFirstChild("WaitingStatus")
if not waitingStatusRemote then
	waitingStatusRemote = Instance.new("RemoteEvent")
	waitingStatusRemote.Name = "WaitingStatus"
	waitingStatusRemote.Parent = settingsFolder
end

local aimTargetRemote = settingsFolder:FindFirstChild("AimTarget")
if not aimTargetRemote then
	aimTargetRemote = Instance.new("UnreliableRemoteEvent")
	aimTargetRemote.Name = "AimTarget"
	aimTargetRemote.Parent = settingsFolder
end

local autoParryFlickRemote = settingsFolder:FindFirstChild("AutoParryFlick")
if not autoParryFlickRemote then
	autoParryFlickRemote = Instance.new("UnreliableRemoteEvent")
	autoParryFlickRemote.Name = "AutoParryFlick"
	autoParryFlickRemote.Parent = settingsFolder
end

local getWaitingStatusRemote = settingsFolder:FindFirstChild("GetWaitingStatus")
if not getWaitingStatusRemote then
	getWaitingStatusRemote = Instance.new("RemoteFunction")
	getWaitingStatusRemote.Name = "GetWaitingStatus"
	getWaitingStatusRemote.Parent = settingsFolder
end

local function isWaitingForPlayers()
	local requiredHumans = botProxy and math.max(MIN_PLAYERS_TO_SPAWN - 1, 1) or MIN_PLAYERS_TO_SPAWN
	return #Players:GetPlayers() < requiredHumans
end

local function isWaitingForRealPlayers()
	return #Players:GetPlayers() < MIN_PLAYERS_TO_SPAWN
end

local botActive = true

local function setBotActive(active)
	if not botModel or botActive == active then return end
	botActive = active

	for _, descendant in botModel:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Transparency = active and 0 or 1
			descendant.CanCollide = active
			descendant.CanQuery = active
		elseif descendant:IsA("Decal") then
			descendant.Transparency = active and 0 or 1
		elseif descendant:IsA("BillboardGui") then
			descendant.Enabled = active
		end
	end

end

local function updateBotVisibility()
	if not botModel then return end
	local realPlayerCount = #Players:GetPlayers()
	setBotActive(realPlayerCount < MIN_PLAYERS_TO_SPAWN)
end

local function broadcastWaitingStatus()
	updateBotVisibility()
	waitingStatusRemote:FireAllClients(isWaitingForRealPlayers())
end

getWaitingStatusRemote.OnServerInvoke = function()
	return isWaitingForRealPlayers()
end

getSettingsRemote.OnServerInvoke = function()
	return settings
end

local pingRemote = settingsFolder:FindFirstChild("Ping")
if not pingRemote then
	pingRemote = Instance.new("RemoteFunction")
	pingRemote.Name = "Ping"
	pingRemote.Parent = settingsFolder
end

local getAutoParryStatusRemote = settingsFolder:FindFirstChild("GetAutoParryStatus")
if not getAutoParryStatusRemote then
	getAutoParryStatusRemote = Instance.new("RemoteFunction")
	getAutoParryStatusRemote.Name = "GetAutoParryStatus"
	getAutoParryStatusRemote.Parent = settingsFolder
end

pingRemote.OnServerInvoke = function()
	return true
end

local nextInstanceId = 0
local rng = Random.new()

local baseplateTopY

local function computeBaseplateTopY()
	local best = spawner.Position.Y

	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		local top = baseplate.Position.Y + (baseplate.Size.Y / 2)
		best = math.max(best, top)
	end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {}
	local rayOrigin = spawner.Position + Vector3.new(0, 200, 0)
	local rayResult = Workspace:Raycast(rayOrigin, Vector3.new(0, -1000, 0), rayParams)
	if rayResult then
		best = math.max(best, rayResult.Position.Y)
	end

	return best
end

baseplateTopY = computeBaseplateTopY()

local spawnPointsFolder = Workspace:FindFirstChild("SpawnPoints")

local function getRandomSpawnPosition()
	if not spawnPointsFolder then
		return spawner.Position + Vector3.new(0, 5, 0)
	end
	local points = spawnPointsFolder:GetChildren()
	if #points == 0 then
		return spawner.Position + Vector3.new(0, 5, 0)
	end
	local chosen = points[rng:NextInteger(1, #points)]
	return chosen.Position
end

local function faceCharacterTowards(char, targetPosition)
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local lookAt = Vector3.new(targetPosition.X, hrp.Position.Y, targetPosition.Z)
	if (lookAt - hrp.Position).Magnitude < 0.01 then return end
	hrp.CFrame = CFrame.lookAt(hrp.Position, lookAt)
end

Players.RespawnTime = 0.05

local DEFAULT_WALK_SPEED = 30

local PhysicsService = game:GetService("PhysicsService")
local PLAYER_COLLISION_GROUP = "Players"

local ok = pcall(function()
	PhysicsService:RegisterCollisionGroup(PLAYER_COLLISION_GROUP)
end)
PhysicsService:CollisionGroupSetCollidable(PLAYER_COLLISION_GROUP, PLAYER_COLLISION_GROUP, false)

local function applyCollisionGroupToDescendant(descendant)
	if descendant:IsA("BasePart") then
		descendant.CollisionGroup = PLAYER_COLLISION_GROUP
	end
end

local function applyPlayerCollisionGroup(char)
	for _, descendant in char:GetDescendants() do
		applyCollisionGroupToDescendant(descendant)
	end
	char.DescendantAdded:Connect(applyCollisionGroupToDescendant)
end

if botModel then
	applyPlayerCollisionGroup(botModel)

	local botHead = botModel:FindFirstChild("Head") or botModel:FindFirstChild("HumanoidRootPart")
	if botHead then
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "BotTitle"
		billboard.Size = UDim2.new(0, 160, 0, 40)
		billboard.StudsOffset = Vector3.new(0, 2.2, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = botHead

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Size = UDim2.new(1, 0, 1, 0)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = "BOT"
		titleLabel.TextScaled = true
		titleLabel.FontFace = Font.new("rbxassetid://12187372382", Enum.FontWeight.Regular)
		titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		titleLabel.Parent = billboard

		local titleStroke = Instance.new("UIStroke")
		titleStroke.Thickness = 2
		titleStroke.Color = Color3.fromRGB(0, 0, 0)
		titleStroke.Parent = titleLabel
	end
end

local function applyHumanoidSettings(char)
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.WalkSpeed = DEFAULT_WALK_SPEED
	end
	if char then
		applyPlayerCollisionGroup(char)
	end
end

updateSettingsRemote.OnServerEvent:Connect(function(player, key, value)
	if typeof(value) ~= "number" then return end
	if key == "baseSpeed" then
		settings.baseSpeed = math.clamp(value, 1, 9999)
	elseif key == "maxfBallSpeed" then
		settings.maxBallSpeed = math.clamp(value, 1, math.huge)
	elseif key == "speedIncrease" then
		settings.speedIncrease = math.clamp(value, 0, 9999)
	end
end)

local PARRY_RADIUS = 7	
local PARRY_INPUT_COOLDOWN = 0.15
local PARRY_WINDOW = 1
local WHIFF_COOLDOWN = 0.6
local playerParryWindowEnd = {}
local lastParryAttempt = {}
local parryBlockedUntil = {}
local playerDesiredTarget = {}
local playerFlickDirection = {}

local SHIELD_ICON_ID = "rbxassetid://395920626"
local SHIELD_ICON_OFFSET = 0
local activeShieldIcons = {}

local function closeParryShieldIcon(player)
	local entry = activeShieldIcons[player]
	if not entry then return end
	activeShieldIcons[player] = nil
	if entry.shield.Parent then
		entry.shield:Destroy()
	end
end

local function spawnParryShieldIcon(player)
	closeParryShieldIcon(player)

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local shield = Instance.new("Part")
	shield.Name = "ParryShieldIcon"
	shield.Transparency = 1
	shield.Size = Vector3.new(0.2, 0.2, 0.2)
	shield.Anchored = false
	shield.CanCollide = false
	shield.CanTouch = false
	shield.CanQuery = false
	shield.CastShadow = false
	shield.Massless = true
	shield.CFrame = hrp.CFrame
	shield.Parent = Workspace

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hrp
	weld.Part1 = shield
	weld.Parent = shield

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ParryShieldBillboard"
	billboard.Size = UDim2.new(1.8, 0, 1.8, 0)
	billboard.StudsOffset = Vector3.new(0, SHIELD_ICON_OFFSET, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.Parent = shield

	local icon = Instance.new("ImageLabel")
	icon.BackgroundTransparency = 1
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.new(0.5, 0, 0.5, 0)
	icon.Size = UDim2.new(1, 0, 1, 0)
	icon.Image = SHIELD_ICON_ID
	icon.ImageTransparency = 0
	icon.Parent = billboard

	-- Tied directly to the parry window: fades across exactly PARRY_WINDOW,
	-- and gets closed out early (see closeParryShieldIcon) the instant the
	-- window actually ends, whether that's a timeout or a successful parry.
	local tweenInfo = TweenInfo.new(PARRY_WINDOW, Enum.EasingStyle.Linear)
	TweenService:Create(icon, tweenInfo, {ImageTransparency = 1}):Play()

	local entry = {shield = shield}
	activeShieldIcons[player] = entry

	task.delay(PARRY_WINDOW, function()
		if activeShieldIcons[player] == entry then
			activeShieldIcons[player] = nil
		end
		if shield.Parent then
			shield:Destroy()
		end
	end)
end

-- Curve is simple by design: a parry just snaps the ball's velocity to face
-- wherever the player was looking/flicking at that instant. From there it
-- homes back toward its target automatically (steer rate derived from
-- distance/speed each frame), which is what gives the arc its curved shape.
-- No tuning constants.

local AUTO_PARRY_USERNAMES = {
	"",
	"",
	"lskskson6",
}

local AUTO_PARRY_RADIUS = 5

local autoParryUserIds = {}
local autoParryLookupSet = {}
for _, name in AUTO_PARRY_USERNAMES do
	autoParryLookupSet[name:lower()] = true
end

local function refreshAutoParryForPlayer(plr)
	if autoParryLookupSet[plr.Name:lower()] then
		autoParryUserIds[plr.UserId] = true
	end
end

for _, plr in Players:GetPlayers() do
	refreshAutoParryForPlayer(plr)
end
Players.PlayerAdded:Connect(refreshAutoParryForPlayer)

local function hasAutoParry(plr)
	if plr == botProxy then
		return true
	end
	return plr and autoParryUserIds[plr.UserId] == true
end

getAutoParryStatusRemote.OnServerInvoke = function(requestingPlayer)
	return hasAutoParry(requestingPlayer)
end

local parryAttemptRemote = settingsFolder:FindFirstChild("ParryAttempt")
if not parryAttemptRemote then
	parryAttemptRemote = Instance.new("RemoteEvent")
	parryAttemptRemote.Name = "ParryAttempt"
	parryAttemptRemote.Parent = settingsFolder
end

local FLOOR_SMOOTHING = 14

local KILL_RADIUS = 2

local PARRY_ANIMATION_ID = "rbxassetid://76390801510033"
local parryAnimationTracks = {}

local function getParryAnimationTrack(char)
	local cached = parryAnimationTracks[char]
	if cached and cached.Parent then
		return cached
	end

	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return nil end

	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = hum
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = PARRY_ANIMATION_ID

	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if not ok or not track then return nil end

	parryAnimationTracks[char] = track
	char.Destroying:Connect(function()
		parryAnimationTracks[char] = nil
	end)

	return track
end

local function playParryAnimation(char)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end

	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = hum
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = PARRY_ANIMATION_ID

	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	if not ok or not track then return end

	track:Play(0)
	track.Stopped:Connect(function()
		track:Destroy()
		animation:Destroy()
	end)
end

local function isTargetable(player)
	if not player then return false end
	local char = player.Character
	if not char then return false end
	if not char:FindFirstChild("HumanoidRootPart") then return false end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false end
	return true
end

local function pickRandomTarget(exclude)
	local candidates = {}
	for _, plr in Players:GetPlayers() do
		if plr ~= exclude and isTargetable(plr) then
			table.insert(candidates, plr)
		end
	end
	if botProxy and botActive and botProxy ~= exclude and isTargetable(botProxy) then
		table.insert(candidates, botProxy)
	end
	if #candidates == 0 and exclude and isTargetable(exclude) then
		return exclude
	end
	if #candidates == 0 then
		return nil
	end
	return candidates[rng:NextInteger(1, #candidates)]
end

local function spawnBall(ballId, onDespawn)
	local currentTarget = pickRandomTarget(nil)
	if not currentTarget then
		return nil
	end

	nextInstanceId += 1
	local instanceId = nextInstanceId

	local currentSpeed = settings.baseSpeed

	local function getSpeed()
		return currentSpeed
	end

	local function setSpeed(value)
		currentSpeed = value
	end

	local targetHighlight = Instance.new("Highlight")
	targetHighlight.Name = "BallTargetHighlight" .. tostring(ballId)
	targetHighlight.FillColor = Color3.fromRGB(255, 0, 0)
	targetHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	targetHighlight.FillTransparency = 0.5
	targetHighlight.OutlineTransparency = 0
	targetHighlight.Enabled = true
	targetHighlight.Parent = currentTarget.Character

	local ball = Instance.new("Part")
	ball.Name = "Ball" .. tostring(ballId)
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(BALL_SIZE, BALL_SIZE, BALL_SIZE)
	ball.Color = Color3.fromRGB(120, 120, 120)
	ball.Material = Enum.Material.Neon
	ball.Anchored = true
	ball.CanCollide = false
	ball.CanTouch = true
	ball.CanQuery = false
	ball.Transparency = 0
	ball.CastShadow = false
	ball.Position = spawner.Position + Vector3.new(0, 15, 0)
	ball.Parent = Workspace

	local ballGlow = Instance.new("Part")
	ballGlow.Name = "BallGlow"
	ballGlow.Shape = Enum.PartType.Ball
	ballGlow.Size = Vector3.new(BALL_SIZE * 2, BALL_SIZE * 2, BALL_SIZE * 2)
	ballGlow.Color = ball.Color
	ballGlow.Material = Enum.Material.Neon
	ballGlow.Anchored = false
	ballGlow.CanCollide = false
	ballGlow.CanTouch = false
	ballGlow.CanQuery = false
	ballGlow.CastShadow = false
	ballGlow.Massless = true

	local glowWeld = Instance.new("WeldConstraint")
	glowWeld.Part0 = ball
	glowWeld.Part1 = ballGlow
	glowWeld.Parent = ballGlow

	ballGlow.Transparency = 1
	ballGlow.Parent = ball

	local ballGlowOuter = Instance.new("Part")
	ballGlowOuter.Name = "BallGlowOuter"
	ballGlowOuter.Shape = Enum.PartType.Ball
	ballGlowOuter.Size = Vector3.new(BALL_SIZE * 4.2, BALL_SIZE * 4.2, BALL_SIZE * 4.2)
	ballGlowOuter.Color = ball.Color
	ballGlowOuter.Material = Enum.Material.Neon
	ballGlowOuter.Anchored = false
	ballGlowOuter.CanCollide = false
	ballGlowOuter.CanTouch = false
	ballGlowOuter.CanQuery = false
	ballGlowOuter.CastShadow = false
	ballGlowOuter.Massless = true

	local glowOuterWeld = Instance.new("WeldConstraint")
	glowOuterWeld.Part0 = ball
	glowOuterWeld.Part1 = ballGlowOuter
	glowOuterWeld.Parent = ballGlowOuter

	ballGlowOuter.Transparency = 1
	ballGlowOuter.Parent = ball

	local ballGlowMid = Instance.new("Part")
	ballGlowMid.Name = "BallGlowMid"
	ballGlowMid.Shape = Enum.PartType.Ball
	ballGlowMid.Size = Vector3.new(BALL_SIZE * 2.5, BALL_SIZE * 2.5, BALL_SIZE * 2.5)
	ballGlowMid.Color = ball.Color
	ballGlowMid.Material = Enum.Material.Neon
	ballGlowMid.Anchored = false
	ballGlowMid.CanCollide = false
	ballGlowMid.CanTouch = false
	ballGlowMid.CanQuery = false
	ballGlowMid.CastShadow = false
	ballGlowMid.Massless = true

	local glowMidWeld = Instance.new("WeldConstraint")
	glowMidWeld.Part0 = ball
	glowMidWeld.Part1 = ballGlowMid
	glowMidWeld.Parent = ballGlowMid

	ballGlowMid.Transparency = 1
	ballGlowMid.Parent = ball

	local ballGlowCore = Instance.new("Part")
	ballGlowCore.Name = "BallGlowCore"
	ballGlowCore.Shape = Enum.PartType.Ball
	ballGlowCore.Size = Vector3.new(BALL_SIZE * 1.3, BALL_SIZE * 1.3, BALL_SIZE * 1.3)
	ballGlowCore.Color = Color3.fromRGB(255, 255, 255)
	ballGlowCore.Material = Enum.Material.Neon
	ballGlowCore.Anchored = false
	ballGlowCore.CanCollide = false
	ballGlowCore.CanTouch = false
	ballGlowCore.CanQuery = false
	ballGlowCore.CastShadow = false
	ballGlowCore.Massless = true

	local glowCoreWeld = Instance.new("WeldConstraint")
	glowCoreWeld.Part0 = ball
	glowCoreWeld.Part1 = ballGlowCore
	glowCoreWeld.Parent = ballGlowCore

	ballGlowCore.Transparency = 1
	ballGlowCore.Parent = ball

	local ballOutline = Instance.new("Highlight")
	ballOutline.Name = "BallOutline"
	ballOutline.FillTransparency = 1
	ballOutline.OutlineColor = Color3.fromRGB(255, 255, 255)
	ballOutline.OutlineTransparency = 0
	ballOutline.Parent = ball

	local trailAttachment0 = Instance.new("Attachment")
	trailAttachment0.Name = "TrailAttachment0"
	trailAttachment0.Position = Vector3.new(0, BALL_SIZE / 2, 0)
	trailAttachment0.Parent = ball

	local trailAttachment1 = Instance.new("Attachment")
	trailAttachment1.Name = "TrailAttachment1"
	trailAttachment1.Position = Vector3.new(0, -BALL_SIZE / 2, 0)
	trailAttachment1.Parent = ball

	local trail = Instance.new("Trail")
	trail.Attachment0 = trailAttachment0
	trail.Attachment1 = trailAttachment1
	trail.Lifetime = 0.08
	trail.MinLength = 0
	trail.FaceCamera = true
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1)
	})
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0)
	})
	trail.Parent = ball

	local parryCount = 0
	local homingVelocity = Vector3.zero
	local smoothedFloorY = nil
	local alive = true
	local lastSegStart, lastSegEnd = ball.Position, ball.Position

	local function fireBallState(state)
		if alive then
			state.ballId = ballId
			state.instanceId = instanceId
			state.targetUserId = currentTarget and currentTarget.UserId or nil
			ballStateRemote:FireAllClients(state)
		end
	end

	local function applyTarget(newTarget)
		currentTarget = newTarget
		if currentTarget then
			targetHighlight.Enabled = true
			ball.Color = Color3.fromRGB(255, 0, 0)
			targetHighlight.Parent = currentTarget.Character
			ballGlow.Color = ball.Color
			ballGlow.Transparency = 0
			ballGlowMid.Color = ball.Color
			ballGlowMid.Transparency = 0.2
			ballGlowOuter.Color = ball.Color
			ballGlowOuter.Transparency = 0.45
			ballGlowCore.Transparency = 0
		else
			targetHighlight.Enabled = false
			ball.Color = Color3.fromRGB(120, 120, 120)
			ballGlow.Transparency = 1
			ballGlowMid.Transparency = 1
			ballGlowOuter.Transparency = 1
			ballGlowCore.Transparency = 1
		end
		fireBallState({targetIsPlayer = currentTarget ~= nil, color = ball.Color})
	end

	do
		local initialTarget = currentTarget
		currentTarget = nil
		applyTarget(initialTarget)
	end

	local function doPlayerParry()
		if not alive then return end
		parryCount += 1
		local parriedBy = currentTarget
		if parriedBy then
			lastParryAttempt[parriedBy] = nil
			playerParryWindowEnd[parriedBy] = nil
			parryBlockedUntil[parriedBy] = nil
			closeParryShieldIcon(parriedBy)
		end

		local desired = parriedBy and playerDesiredTarget[parriedBy]
		local hasDirectRedirect = desired and desired ~= parriedBy and isTargetable(desired)
		local flickDirection = parriedBy and playerFlickDirection[parriedBy]

		local newTarget = hasDirectRedirect and desired or pickRandomTarget(parriedBy)
		applyTarget(newTarget)

		setSpeed(getSpeed() + 1)
		if flickDirection then
			-- Snap straight to the direction the player flicked/looked at the moment
			-- of the parry. Homing steer then bends it back toward the target over
			-- time (rate computed automatically per-frame), which is the actual "curve."
			homingVelocity = flickDirection * getSpeed()
		else
			-- No flick (bot, or a plain parry with no camera movement): don't curve at
			-- all -- point straight at the new target instantly. Curving is reserved
			-- for actual flicks; anything else should just aim and go.
			local newTargetChar = newTarget and newTarget.Character
			local newTargetHrp = newTargetChar and newTargetChar:FindFirstChild("HumanoidRootPart")
			if newTargetHrp then
				local toNewTarget = newTargetHrp.Position - ball.Position
				if toNewTarget.Magnitude > 0.001 then
					homingVelocity = toNewTarget.Unit * getSpeed()
				end
			end
		end
		smoothedFloorY = nil

		if parriedBy then
			playerFlickDirection[parriedBy] = nil
		end

		if parriedBy and alive then
			parrySoundRemote:FireAllClients(ballId, parriedBy.UserId)
		end

		local parriedByChar = parriedBy and parriedBy.Character
		local hrpForVFX = parriedByChar and parriedByChar:FindFirstChild("HumanoidRootPart")
		local hitPos = hrpForVFX and (hrpForVFX.Position + hrpForVFX.CFrame.LookVector * 2) or ball.Position
		if parriedByChar then
			StarBurstVFX.PlayHit(parriedByChar, hitPos, nil, nil)
			if parriedBy ~= botProxy then
				playParryAnimation(parriedByChar)
			end
		end
	end

	local function bringBack()
		ball.CFrame = CFrame.new(spawner.Position + Vector3.new(0, 15, 0))
		homingVelocity = Vector3.zero
		smoothedFloorY = nil
		lastSegStart, lastSegEnd = ball.Position, ball.Position
		fireBallState({targetIsPlayer = currentTarget ~= nil, color = ball.Color, teleportTo = ball.Position})
	end

	local function retargetIfCurrentlyTargeting(player)
		if currentTarget == player then
			applyTarget(pickRandomTarget(player))
		end
	end

	local heartbeatConn
	local destroyBall

	heartbeatConn = RunService.Heartbeat:Connect(function(dt)
		if not alive or not ball.Parent then
			heartbeatConn:Disconnect()
			return
		end

		local prevBallPos = ball.Position

		local targetPos
		if currentTarget then
			if not isTargetable(currentTarget) then
				applyTarget(pickRandomTarget(currentTarget))
			else
				local currentHrp = currentTarget.Character:FindFirstChild("HumanoidRootPart")
				if currentHrp then
					targetPos = currentHrp.Position
				end
			end
		end

		if targetPos then
			local toTarget = targetPos - prevBallPos
			local dist = toTarget.Magnitude
			local forward = dist > 0.001 and toTarget.Unit or Vector3.new(0, 0, 1)

			local desiredVelocity = forward * getSpeed()

			-- Steer rate is derived automatically from the ball's own physics: how
			-- long it would take to reach the target at its current speed. Close to
			-- the target it turns sharply, far away it arcs gently -- no manual
			-- tuning constant needed.
			local timeToTarget = math.max(dist / math.max(getSpeed(), 1), 0.05)
			local steerAlpha = 1 - math.exp(-dt / timeToTarget)
			homingVelocity = homingVelocity:Lerp(desiredVelocity, steerAlpha)

			local currentVelocity = homingVelocity
			local nextPos = prevBallPos + currentVelocity * dt

			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			local rayFilter = {ball}
			for _, plr in Players:GetPlayers() do
				if plr.Character then
					table.insert(rayFilter, plr.Character)
				end
			end
			if botModel then
				table.insert(rayFilter, botModel)
			end
			rayParams.FilterDescendantsInstances = rayFilter

			local rayOrigin = Vector3.new(nextPos.X, nextPos.Y + 5, nextPos.Z)
			local rayResult = Workspace:Raycast(rayOrigin, Vector3.new(0, -50, 0), rayParams)
			if rayResult then
				local minY = rayResult.Position.Y + (ball.Size.Y / 2)
				if not smoothedFloorY then
					smoothedFloorY = minY
				end
				local floorAlpha = 1 - math.exp(-FLOOR_SMOOTHING * dt)
				smoothedFloorY = smoothedFloorY + (minY - smoothedFloorY) * floorAlpha
				if nextPos.Y < smoothedFloorY then
					nextPos = Vector3.new(nextPos.X, smoothedFloorY, nextPos.Z)
				end
			else
				smoothedFloorY = nil
			end

			local hardFloorY = baseplateTopY + (ball.Size.Y / 2)
			if nextPos.Y < hardFloorY then
				nextPos = Vector3.new(nextPos.X, hardFloorY, nextPos.Z)
			end

			ball.CFrame = CFrame.new(nextPos)
			lastSegStart = prevBallPos
			lastSegEnd = nextPos

			local velocity = dt > 0 and ((nextPos - prevBallPos) / dt) or Vector3.zero
			local targetUserId = currentTarget and currentTarget.UserId or nil
			ballSyncRemote:FireAllClients(ballId, nextPos, velocity, ball.Size.X, ball.Color, workspace:GetServerTimeNow(), false, instanceId, targetUserId)
		end

		if currentTarget and isTargetable(currentTarget) then
			local currentHrp = currentTarget.Character:FindFirstChild("HumanoidRootPart")
			if currentHrp then
				local segDir = lastSegEnd - lastSegStart
				local segLenSq = segDir:Dot(segDir)
				local closestPoint
				if segLenSq < 0.0001 then
					closestPoint = lastSegEnd
				else
					local t = math.clamp((currentHrp.Position - lastSegStart):Dot(segDir) / segLenSq, 0, 1)
					closestPoint = lastSegStart + segDir * t
				end
				local distToPath = (currentHrp.Position - closestPoint).Magnitude

				local windowEnd = playerParryWindowEnd[currentTarget]
				local windowOpen = windowEnd and os.clock() <= windowEnd

				if hasAutoParry(currentTarget) and distToPath <= AUTO_PARRY_RADIUS then
					playerParryWindowEnd[currentTarget] = nil
					spawnParryShieldIcon(currentTarget)
					doPlayerParry()
				elseif windowOpen and distToPath <= PARRY_RADIUS then
					playerParryWindowEnd[currentTarget] = nil
					doPlayerParry()
				elseif distToPath <= KILL_RADIUS then
					local hum = currentTarget.Character:FindFirstChildOfClass("Humanoid")
					if hum and hum.Health > 0 then
						hum.Health = 0
					end
					destroyBall()
					if onDespawn then
						onDespawn()
					end
					return
				end
			end
		end

		setSpeed(math.min(getSpeed() + settings.speedIncrease * dt, settings.maxBallSpeed))

		ballSpeedRemote:FireAllClients(ballId, getSpeed(), parryCount, instanceId)
	end)

	destroyBall = function()
		if not alive then return end
		alive = false
		if heartbeatConn then
			heartbeatConn:Disconnect()
		end
		ballStateRemote:FireAllClients({ballId = ballId, removed = true, instanceId = instanceId})
		if ball.Parent then
			ball:Destroy()
		end
		if targetHighlight.Parent then
			targetHighlight:Destroy()
		end
	end

	local function getCurrentTarget()
		return currentTarget
	end

	return {
		destroy = destroyBall,
		bringBack = bringBack,
		retargetIfCurrentlyTargeting = retargetIfCurrentlyTargeting,
		getCurrentTarget = getCurrentTarget,
		resetSpeed = function() setSpeed(settings.baseSpeed) end,
	}
end

local BALL_COUNT = 1
local activeBalls = {}
local nextBallId = 0

local function addBallToPool()
	nextBallId += 1
	local ctrl
	ctrl = spawnBall(nextBallId, function()
		for i, c in ipairs(activeBalls) do
			if c == ctrl then
				table.remove(activeBalls, i)
				break
			end
		end
		if not isWaitingForPlayers() then
			addBallToPool()
		end
	end)
	if ctrl then
		table.insert(activeBalls, ctrl)
	end
end

local function destroyAllBalls()
	for _, ctrl in activeBalls do
		ctrl.destroy()
	end
	activeBalls = {}
	nextBallId = 0
end

local function ensureBallsSpawned()
	if isWaitingForPlayers() then return end
	while #activeBalls < BALL_COUNT do
		addBallToPool()
	end
end

local function respawnAndResetBalls()
	destroyAllBalls()
	ensureBallsSpawned()
end

local trackedRealPlayerCount = 0

local function onPlayerAdded(player)
	local priorRealCount = trackedRealPlayerCount
	trackedRealPlayerCount += 1
	if priorRealCount == 1 and trackedRealPlayerCount == 2 then
		broadcastWaitingStatus()
		respawnAndResetBalls()
	else
		broadcastWaitingStatus()
	end
	player.CharacterAdded:Connect(function(char)
		applyHumanoidSettings(char)
		task.wait(0.5)
		applyHumanoidSettings(char)
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = CFrame.new(getRandomSpawnPosition())
		end
		faceCharacterTowards(char, spawner.Position)
		getParryAnimationTrack(char)
		ensureBallsSpawned()
		broadcastWaitingStatus()
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, plr in Players:GetPlayers() do
	onPlayerAdded(plr)
end

Players.PlayerRemoving:Connect(function(player)
	local priorRealCount = trackedRealPlayerCount
	trackedRealPlayerCount = math.max(trackedRealPlayerCount - 1, 0)
	playerParryWindowEnd[player] = nil
	lastParryAttempt[player] = nil
	parryBlockedUntil[player] = nil
	playerDesiredTarget[player] = nil
	playerFlickDirection[player] = nil
	autoParryUserIds[player.UserId] = nil
	for _, ctrl in activeBalls do
		ctrl.retargetIfCurrentlyTargeting(player)
	end
	task.defer(function()
		if isWaitingForPlayers() then
			destroyAllBalls()
			broadcastWaitingStatus()
		elseif priorRealCount == 2 and trackedRealPlayerCount == 1 then
			broadcastWaitingStatus()
			respawnAndResetBalls()
		else
			broadcastWaitingStatus()
		end
	end)
end)

respawnRemote.OnServerEvent:Connect(function(player)
	destroyAllBalls()
	ensureBallsSpawned()
end)

bringBallRemote.OnServerEvent:Connect(function(player)
	for _, ctrl in activeBalls do
		if ctrl.getCurrentTarget() == player then
			ctrl.bringBack()
		end
	end
end)

resetSettingsRemote.OnServerEvent:Connect(function(player)
	for key, value in defaultSettings do
		settings[key] = value
	end
	for _, plr in Players:GetPlayers() do
		applyHumanoidSettings(plr.Character)
	end
	for _, ctrl in activeBalls do
		ctrl.resetSpeed()
	end
	resetSettingsRemote:FireClient(player, settings)
end)

parryAttemptRemote.OnServerEvent:Connect(function(player, desiredTargetPlayer, flickDirection, curveIntensity)
	if hasAutoParry(player) then
		return
	end
	local now = os.clock()
	if lastParryAttempt[player] and now - lastParryAttempt[player] < PARRY_INPUT_COOLDOWN then
		return
	end
	if parryBlockedUntil[player] and now < parryBlockedUntil[player] then
		return
	end

	local existingWindowEnd = playerParryWindowEnd[player]
	if existingWindowEnd and now < existingWindowEnd then
		return
	end

	lastParryAttempt[player] = now

	local thisWindowEnd = now + PARRY_WINDOW
	playerParryWindowEnd[player] = thisWindowEnd
	spawnParryShieldIcon(player)

	if typeof(desiredTargetPlayer) == "Instance" and desiredTargetPlayer:IsA("Player") and desiredTargetPlayer ~= player then
		playerDesiredTarget[player] = desiredTargetPlayer
	else
		playerDesiredTarget[player] = nil
	end

	if typeof(flickDirection) == "Vector3" and flickDirection.Magnitude > 0.001 then
		playerFlickDirection[player] = flickDirection.Unit
	else
		playerFlickDirection[player] = nil
	end

	task.delay(PARRY_WINDOW, function()
		if playerParryWindowEnd[player] == thisWindowEnd then
			playerParryWindowEnd[player] = nil
			parryBlockedUntil[player] = os.clock() + WHIFF_COOLDOWN
		end
	end)
end)

aimTargetRemote.OnServerEvent:Connect(function(player, aimedPlayer)
	if typeof(aimedPlayer) == "Instance" and aimedPlayer:IsA("Player") and aimedPlayer ~= player then
		playerDesiredTarget[player] = aimedPlayer
	else
		playerDesiredTarget[player] = nil
	end
end)

autoParryFlickRemote.OnServerEvent:Connect(function(player, flickDirection)
	if not hasAutoParry(player) then return end
	if typeof(flickDirection) == "Vector3" and flickDirection.Magnitude > 0.001 then
		playerFlickDirection[player] = flickDirection.Unit
	else
		playerFlickDirection[player] = nil
	end
end)
