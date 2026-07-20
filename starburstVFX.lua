local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local StarBurstVFX = {}
StarBurstVFX.CoreColor = Color3.fromRGB(255, 255, 255)
StarBurstVFX.PrimaryColor = Color3.fromRGB(235, 235, 235)
StarBurstVFX.AccentColor = Color3.fromRGB(190, 190, 190)
StarBurstVFX.ParticleCount = 55
StarBurstVFX.ParticleLifetime = 0.2
StarBurstVFX.ParticleSpeed = 12
StarBurstVFX.ParticleSpeedVariance = 6
StarBurstVFX.ParticleSize = 0.5
StarBurstVFX.ForwardOffset = 2
StarBurstVFX.HitImageId = "rbxassetid://94473747091601"
StarBurstVFX.HitImageSize = 3
StarBurstVFX.HitGrowScale = 1.6
StarBurstVFX.HitFadeTime = 0.25
StarBurstVFX.ShieldSize = 4
StarBurstVFX.ShieldForwardOffset = 3
StarBurstVFX.ShieldDuration = 2
StarBurstVFX.ShieldFadeTime = 0.3
StarBurstVFX.ShieldTransparency = 0.3
function StarBurstVFX.PlayHit(character, hitPosition, hitNormal, colorOverride)
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local color = colorOverride or StarBurstVFX.CoreColor
	local spawnCFrame = hrp.CFrame * CFrame.new(0, 0, -StarBurstVFX.ForwardOffset)
	local anchor = Instance.new("Part")
	anchor.Name = "StarBurstAnchor"
	anchor.Size = Vector3.new(0.1, 0.1, 0.1)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.CastShadow = false
	anchor.CFrame = spawnCFrame
	anchor.Parent = workspace
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ParryHitSparkBillboard"
	billboard.Size = UDim2.new(StarBurstVFX.HitImageSize, 0, StarBurstVFX.HitImageSize, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.Adornee = anchor
	billboard.Parent = anchor
	local icon = Instance.new("ImageLabel")
	icon.BackgroundTransparency = 1
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.new(0.5, 0, 0.5, 0)
	icon.Size = UDim2.new(1, 0, 1, 0)
	icon.Image = StarBurstVFX.HitImageId
	icon.ImageColor3 = color
	icon.ImageTransparency = 0
	icon.Rotation = math.random(0, 359)
	icon.Parent = billboard
	local tweenInfo = TweenInfo.new(StarBurstVFX.HitFadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(billboard, tweenInfo, {
		Size = UDim2.new(StarBurstVFX.HitImageSize * StarBurstVFX.HitGrowScale, 0, StarBurstVFX.HitImageSize * StarBurstVFX.HitGrowScale, 0),
	}):Play()
	TweenService:Create(icon, tweenInfo, {ImageTransparency = 1}):Play()
	Debris:AddItem(anchor, StarBurstVFX.HitFadeTime + 0.1)
end
function StarBurstVFX.PlayShield(character, colorOverride, duration, forwardOffset)
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	duration = duration or StarBurstVFX.ShieldDuration
	forwardOffset = forwardOffset or StarBurstVFX.ShieldForwardOffset
	local color = colorOverride or StarBurstVFX.PrimaryColor
	local shield = Instance.new("Part")
	shield.Name = "ParryShieldVFX"
	shield.Shape = Enum.PartType.Block
	shield.Size = Vector3.new(StarBurstVFX.ShieldSize, StarBurstVFX.ShieldSize, 0.2)
	shield.Material = Enum.Material.ForceField
	shield.Color = color
	shield.Anchored = true
	shield.CanCollide = false
	shield.CanTouch = false
	shield.CanQuery = false
	shield.CastShadow = false
	shield.Transparency = StarBurstVFX.ShieldTransparency
	shield.CFrame = hrp.CFrame * CFrame.new(0, 0, -forwardOffset)
	shield.Parent = workspace
	local fadeTime = math.min(StarBurstVFX.ShieldFadeTime, duration)
	local fadeTween = TweenService:Create(shield, TweenInfo.new(fadeTime, Enum.EasingStyle.Quad), {Transparency = 1})
	task.delay(math.max(duration - fadeTime, 0), function()
		if shield and shield.Parent then
			fadeTween:Play()
		end
	end)
	Debris:AddItem(shield, duration + 0.2)
end
return StarBurstVFX