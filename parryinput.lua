local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local settingsFolder = ReplicatedStorage:WaitForChild("BallSettings")
local parryAttemptRemote = settingsFolder:WaitForChild("ParryAttempt")
local parrySoundRemote = settingsFolder:WaitForChild("ParrySound")
local ballStateRemote = settingsFolder:WaitForChild("BallState")
local ballSyncRemote = settingsFolder:WaitForChild("BallSync")
local waitingStatusRemote = settingsFolder:WaitForChild("WaitingStatus")
local getWaitingStatusRemote = settingsFolder:WaitForChild("GetWaitingStatus")
local aimTargetRemote = settingsFolder:WaitForChild("AimTarget")
local getAutoParryStatusRemote = settingsFolder:WaitForChild("GetAutoParryStatus")
local autoParryFlickRemote = settingsFolder:WaitForChild("AutoParryFlick")

local player = Players.LocalPlayer

local isAutoParryPlayer = false
do
	local ok, result = pcall(function()
		return getAutoParryStatusRemote:InvokeServer()
	end)
	if ok then
		isAutoParryPlayer = result == true
	end
end
local CLIENT_DEBOUNCE = 0.1
local lastFire = 0

local PARRY_WINDOW = 1
local WHIFF_COOLDOWN = 0.6

local localWindowEnd = nil
local localBlockedUntil = nil

local overlayCooldownEnd = nil

local cooldownOverlay = nil
local cooldownLabel = nil
local cooldownLabelStroke = nil
local cooldownActive = false

local OVERLAY_SHOWN_TRANSPARENCY = 0.6
local OVERLAY_HIDDEN_TRANSPARENCY = 1
local FADE_TIME = 0.18

local function setCooldownVisible(visible)
	if visible == cooldownActive then return end
	cooldownActive = visible

	local fadeInfo = TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	if cooldownOverlay then
		TweenService:Create(cooldownOverlay, fadeInfo, {
			BackgroundTransparency = visible and OVERLAY_SHOWN_TRANSPARENCY or OVERLAY_HIDDEN_TRANSPARENCY
		}):Play()
	end

	if cooldownLabel then
		TweenService:Create(cooldownLabel, fadeInfo, {
			TextTransparency = visible and 0 or 1
		}):Play()
	end

	if cooldownLabelStroke then
		TweenService:Create(cooldownLabelStroke, fadeInfo, {
			Transparency = visible and 0 or 1
		}):Play()
	end
end

RunService.Heartbeat:Connect(function()
	local now = os.clock()

	if not (localWindowEnd and now < localWindowEnd) and not (localBlockedUntil and now < localBlockedUntil) then
		localWindowEnd = nil
		localBlockedUntil = nil
	end

	if not cooldownOverlay then return end

	if overlayCooldownEnd and now < overlayCooldownEnd then
		setCooldownVisible(true)
		if cooldownLabel then
			cooldownLabel.Text = string.format("%.2f", overlayCooldownEnd - now)
		end
	else
		overlayCooldownEnd = nil
		setCooldownVisible(false)
	end
end)

do
	local function updateListener()
		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if hrp then
			SoundService:SetListener(Enum.ListenerType.ObjectCFrame, hrp)
		end
	end

	player.CharacterAdded:Connect(function()
		task.wait()
		updateListener()
	end)

	if player.Character then
		updateListener()
	end
end

local CURVE_INTENSITY_MIN_SPEED = 20
local CURVE_INTENSITY_MAX_SPEED = 900

local lastLook = nil
local currentAngularSpeed = 0
local currentLookDirection = nil

RunService.Heartbeat:Connect(function(dt)
	local camera = Workspace.CurrentCamera
	if not camera then return end

	local look = camera.CFrame.LookVector
	currentLookDirection = look

	if lastLook and dt > 0 then
		local dot = math.clamp(lastLook:Dot(look), -1, 1)
		local angle = math.deg(math.acos(dot))
		currentAngularSpeed = angle / dt
	end

	lastLook = look
end)

local function getFlickDirection()
	return currentLookDirection
end

local function getCurveIntensity()
	return math.clamp(
		(currentAngularSpeed - CURVE_INTENSITY_MIN_SPEED) / (CURVE_INTENSITY_MAX_SPEED - CURVE_INTENSITY_MIN_SPEED),
		0, 1
	)
end

if isAutoParryPlayer then
	RunService.Heartbeat:Connect(function()
		autoParryFlickRemote:FireServer(getFlickDirection(), getCurveIntensity())
	end)
end

local parrySound = Instance.new("Sound")
parrySound.Name = "ParrySound"
parrySound.SoundId = "rbxassetid://134060321832557"
parrySound.Volume = 1
parrySound.RollOffMode = Enum.RollOffMode.InverseTapered
parrySound.RollOffMinDistance = 8
parrySound.RollOffMaxDistance = 150

local function playParrySound(sourcePart)
	local sound = parrySound:Clone()
	if sourcePart then
		sound.Parent = sourcePart
	else
		sound.Parent = SoundService
	end
	sound:Play()
	game:GetService("Debris"):AddItem(sound, sound.TimeLength + 1)
end

local function getPlayerSoundSource(userId)
	local otherPlayer = Players:GetPlayerByUserId(userId)
	local char = otherPlayer and otherPlayer.Character
	return char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
end

local TARGETED_COLOR = Color3.fromRGB(255, 0, 0)
local NOT_TARGETED_COLOR = Color3.fromRGB(120, 120, 120)

local function getBallPart(ballId)
	return Workspace:FindFirstChild("Ball" .. tostring(ballId))
end

local function applyLocalBallColor(ballId, targetUserId)
	local ball = getBallPart(ballId)
	if not ball then return end
	if targetUserId == player.UserId then
		ball.Color = TARGETED_COLOR
	else
		ball.Color = NOT_TARGETED_COLOR
	end
end

local function triggerCooldownVisual()
	local now = os.clock()
	local candidateEnd = now + PARRY_WINDOW + WHIFF_COOLDOWN
	overlayCooldownEnd = math.max(overlayCooldownEnd or 0, candidateEnd)
end

parrySoundRemote.OnClientEvent:Connect(function(ballId, parriedByUserId)
	lastFire = 0
	if parriedByUserId == player.UserId then
		if isAutoParryPlayer then
			triggerCooldownVisual()
		else
			localWindowEnd = nil
			localBlockedUntil = nil
			overlayCooldownEnd = nil
		end
	end
	local sourcePart = getPlayerSoundSource(parriedByUserId) or getBallPart(ballId)
	playParrySound(sourcePart)
end)

ballStateRemote.OnClientEvent:Connect(function(state)
	if not state or not state.ballId or state.removed then return end
	applyLocalBallColor(state.ballId, state.targetUserId)
end)

ballSyncRemote.OnClientEvent:Connect(function(ballId, position, velocity, size, color, serverTime, teleported, instanceId, targetUserId)
	applyLocalBallColor(ballId, targetUserId)
end)

local AIM_ASSIST_RADIUS_PIXELS = 999

local function getTargetPlayerAtPos(pointerPos)
	local camera = Workspace.CurrentCamera
	if not camera or not pointerPos then return nil end

	local bestPlayer = nil
	local bestDist = AIM_ASSIST_RADIUS_PIXELS
	for _, otherPlayer in Players:GetPlayers() do
		if otherPlayer ~= player then
			local char = otherPlayer.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hrp and hum and hum.Health > 0 then
				local screenPos, onScreen = camera:WorldToViewportPoint(hrp.Position)
				if onScreen then
					local dist = (Vector2.new(screenPos.X, screenPos.Y) - pointerPos).Magnitude
					if dist < bestDist then
						local rayParams = RaycastParams.new()
						rayParams.FilterType = Enum.RaycastFilterType.Exclude
						rayParams.FilterDescendantsInstances = {player.Character}
						local originPos = camera.CFrame.Position
						local direction = (hrp.Position - originPos)
						local rayResult = Workspace:Raycast(originPos, direction, rayParams)
						local blocked = rayResult and rayResult.Instance
							and not rayResult.Instance:IsDescendantOf(char)
							and (rayResult.Position - originPos).Magnitude < direction.Magnitude - 2
						if not blocked then
							bestDist = dist
							bestPlayer = otherPlayer
						end
					end
				end
			end
		end
	end
	return bestPlayer
end

local function getMouseTargetPlayer()
	local pointerPos = UserInputService:GetMouseLocation()
	return getTargetPlayerAtPos(pointerPos)
end

local function fireParryAttempt(targetPlayer)
	if isAutoParryPlayer then return end

	local now = os.clock()
	if now - lastFire < CLIENT_DEBOUNCE then return end
	if localWindowEnd and now < localWindowEnd then return end
	if localBlockedUntil and now < localBlockedUntil then return end
	lastFire = now
	local flickDirection = getFlickDirection()
	local curveIntensity = getCurveIntensity()
	parryAttemptRemote:FireServer(targetPlayer, flickDirection, curveIntensity)

	local thisWindowEnd = now + PARRY_WINDOW
	localWindowEnd = thisWindowEnd
	overlayCooldownEnd = thisWindowEnd + WHIFF_COOLDOWN
	task.delay(PARRY_WINDOW, function()
		if localWindowEnd == thisWindowEnd then
			localWindowEnd = nil
			localBlockedUntil = os.clock() + WHIFF_COOLDOWN
		end
	end)
end

local function getNearestTargetPlayer()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end

	local bestPlayer = nil
	local bestDist = math.huge
	for _, otherPlayer in Players:GetPlayers() do
		if otherPlayer ~= player then
			local otherChar = otherPlayer.Character
			local otherHrp = otherChar and otherChar:FindFirstChild("HumanoidRootPart")
			local otherHum = otherChar and otherChar:FindFirstChildOfClass("Humanoid")
			if otherHrp and otherHum and otherHum.Health > 0 then
				local dist = (otherHrp.Position - hrp.Position).Magnitude
				if dist < bestDist then
					bestDist = dist
					bestPlayer = otherPlayer
				end
			end
		end
	end
	return bestPlayer
end

local function attemptParry()
	if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then return end
	fireParryAttempt(getMouseTargetPlayer())
end

local function attemptButtonParry()
	if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
		fireParryAttempt(getNearestTargetPlayer())
	else
		attemptParry()
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if isAutoParryPlayer then return end
	if input.KeyCode == Enum.KeyCode.F or input.UserInputType == Enum.UserInputType.MouseButton1 then
		triggerCooldownVisual()
		attemptParry()
	end
end)

local TAP_MAX_MOVEMENT = 18
local TAP_MAX_DURATION = 0.3

local trackedTouches = {}
local lastTouchPos = nil

UserInputService.TouchStarted:Connect(function(touch, gameProcessed)
	if gameProcessed then return end
	local pos = Vector2.new(touch.Position.X, touch.Position.Y)
	trackedTouches[touch] = {startPos = pos, pos = pos, startTime = os.clock()}
	lastTouchPos = pos
end)

UserInputService.TouchMoved:Connect(function(touch, gameProcessed)
	local pos = Vector2.new(touch.Position.X, touch.Position.Y)
	lastTouchPos = pos
	local entry = trackedTouches[touch]
	if not entry then return end
	entry.pos = pos
end)

UserInputService.TouchEnded:Connect(function(touch, gameProcessed)
	local entry = trackedTouches[touch]
	if not entry then return end
	trackedTouches[touch] = nil
	local movement = (entry.pos - entry.startPos).Magnitude
	local duration = os.clock() - entry.startTime
	if movement <= TAP_MAX_MOVEMENT and duration <= TAP_MAX_DURATION then
		if isAutoParryPlayer then return end
		triggerCooldownVisual()
		fireParryAttempt(getTargetPlayerAtPos(entry.pos))
	end
end)

local AIM_REPORT_INTERVAL = 0.1
local lastAimReportTime = 0
local lastReportedAimTarget = nil

local function computeCurrentAimTarget()
	if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
		if lastTouchPos then
			return getTargetPlayerAtPos(lastTouchPos)
		end
		return nil
	end
	return getMouseTargetPlayer()
end

RunService.Heartbeat:Connect(function()
	local now = os.clock()
	if now - lastAimReportTime < AIM_REPORT_INTERVAL then return end
	lastAimReportTime = now

	local aimTarget = computeCurrentAimTarget()
	if aimTarget ~= lastReportedAimTarget then
		lastReportedAimTarget = aimTarget
		aimTargetRemote:FireServer(aimTarget)
	end
end)

do
	local waitingGui = Instance.new("ScreenGui")
	waitingGui.Name = "WaitingStatusGui"
	waitingGui.ResetOnSpawn = false
	waitingGui.IgnoreGuiInset = true
	waitingGui.Parent = player:WaitForChild("PlayerGui")

	local waitingLabel = Instance.new("TextLabel")
	waitingLabel.Name = "WaitingLabel"
	waitingLabel.Size = UDim2.new(0.6, 0, 0.08, 0)
	waitingLabel.Position = UDim2.new(0.5, 0, 0.08, 0)
	waitingLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	waitingLabel.BackgroundTransparency = 1
	waitingLabel.Text = "Waiting for other players.."
	waitingLabel.TextScaled = true
	waitingLabel.FontFace = Font.new("rbxassetid://12187372382", Enum.FontWeight.Regular)
	waitingLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	waitingLabel.Visible = false
	waitingLabel.ZIndex = 10
	waitingLabel.Parent = waitingGui

	local waitingLabelStroke = Instance.new("UIStroke")
	waitingLabelStroke.Thickness = 2
	waitingLabelStroke.Color = Color3.fromRGB(0, 0, 0)
	waitingLabelStroke.Parent = waitingLabel

	local function setWaiting(waiting)
		waitingLabel.Visible = waiting
	end

	waitingStatusRemote.OnClientEvent:Connect(setWaiting)

	task.spawn(function()
		local ok, waiting = pcall(function()
			return getWaitingStatusRemote:InvokeServer()
		end)
		if ok then
			setWaiting(waiting)
		end
	end)
end

do
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ParryButtonGui"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = player:WaitForChild("PlayerGui")

	local containerSize = UserInputService.TouchEnabled and 58 or 72
	local containerBottomOffset = UserInputService.TouchEnabled and 60 or 110

	local buttonContainer = Instance.new("Frame")
	buttonContainer.Name = "ParryButtonContainer"
	buttonContainer.Size = UDim2.new(0, containerSize, 0, containerSize)
	buttonContainer.Position = UDim2.new(0.5, 0, 1, -containerBottomOffset)
	buttonContainer.AnchorPoint = Vector2.new(0.5, 0)
	buttonContainer.BackgroundTransparency = 1
	buttonContainer.Parent = screenGui

	local blockLabel = Instance.new("TextLabel")
	blockLabel.Name = "BlockLabel"
	blockLabel.Size = UDim2.new(1, 0, 0.5, 0)
	blockLabel.Position = UDim2.new(0.5, 0, -0.27, 0)
	blockLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	blockLabel.BackgroundTransparency = 1
	blockLabel.Text = "BLOCK"
	blockLabel.TextScaled = true
	blockLabel.FontFace = Font.new("rbxassetid://12187372382", Enum.FontWeight.Regular)
	blockLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	blockLabel.ZIndex = 4
	blockLabel.Parent = buttonContainer

	local blockStroke = Instance.new("UIStroke")
	blockStroke.Thickness = 2
	blockStroke.Color = Color3.fromRGB(0, 0, 0)
	blockStroke.Parent = blockLabel

	local parryButton = Instance.new("ImageButton")
	parryButton.Name = "ParryButton"
	parryButton.Size = UDim2.new(1, 0, 1, 0)
	parryButton.Position = UDim2.new(0.5, 0, 0.5, 0)
	parryButton.AnchorPoint = Vector2.new(0.5, 0.5)
	parryButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	parryButton.BackgroundTransparency = 1
	parryButton.Image = "rbxassetid://395920626"
	parryButton.ScaleType = Enum.ScaleType.Fit
	parryButton.AutoButtonColor = false
	parryButton.BorderSizePixel = 0
	parryButton.ZIndex = 2
	parryButton.ClipsDescendants = true
	parryButton.Parent = buttonContainer

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 16)
	buttonCorner.Parent = parryButton

	local buttonGradient = Instance.new("UIGradient")
	buttonGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 90, 90)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
	})
	buttonGradient.Rotation = 90
	buttonGradient.Parent = parryButton

	local buttonStroke = Instance.new("UIStroke")
	buttonStroke.Thickness = 2
	buttonStroke.Color = Color3.fromRGB(255, 255, 255)
	buttonStroke.Transparency = 0.4
	buttonStroke.Parent = parryButton

	local darkOverlay = Instance.new("Frame")
	darkOverlay.Name = "CooldownOverlay"
	darkOverlay.Size = UDim2.new(1, 0, 1, 0)
	darkOverlay.Position = UDim2.new(0, 0, 0, 0)
	darkOverlay.AnchorPoint = Vector2.new(0, 0)
	darkOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	darkOverlay.BackgroundTransparency = 1
	darkOverlay.BorderSizePixel = 0
	darkOverlay.ZIndex = 3
	darkOverlay.Visible = true
	darkOverlay.Parent = parryButton

	local darkOverlayCorner = Instance.new("UICorner")
	darkOverlayCorner.CornerRadius = UDim.new(0, 16)
	darkOverlayCorner.Parent = darkOverlay

	cooldownOverlay = darkOverlay

	local cooldownText = Instance.new("TextLabel")
	cooldownText.Name = "CooldownLabel"
	cooldownText.Size = UDim2.new(0.5, 0, 0.5, 0)
	cooldownText.Position = UDim2.new(0.5, 0, 0.5, 0)
	cooldownText.AnchorPoint = Vector2.new(0.5, 0.5)
	cooldownText.BackgroundTransparency = 1
	cooldownText.FontFace = Font.new("rbxassetid://12187372382", Enum.FontWeight.Regular)
	cooldownText.TextScaled = true
	cooldownText.TextColor3 = Color3.fromRGB(255, 255, 255)
	cooldownText.TextTransparency = 1
	cooldownText.Text = ""
	cooldownText.Visible = true
	cooldownText.ZIndex = 4
	cooldownText.Parent = parryButton

	local cooldownTextStroke = Instance.new("UIStroke")
	cooldownTextStroke.Thickness = 1.5
	cooldownTextStroke.Color = Color3.fromRGB(0, 0, 0)
	cooldownTextStroke.Transparency = 1
	cooldownTextStroke.Parent = cooldownText

	cooldownLabel = cooldownText
	cooldownLabelStroke = cooldownTextStroke

	parryButton.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if isAutoParryPlayer then return end
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			triggerCooldownVisual()
			attemptButtonParry()
		end
	end)
end