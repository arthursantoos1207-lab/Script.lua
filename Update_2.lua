-- Services.
local playersService = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")
local starterGui = game:GetService("StarterGui")
local virtualUser = game:GetService("VirtualUser")
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")

local localPlayer = playersService.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Constants.
local BLOCKS = {
	{ name = "LuckyBlock",   remote = "SpawnLuckyBlock",   color = Color3.fromRGB(255, 200, 0) },
	{ name = "SuperBlock",   remote = "SpawnSuperBlock",   color = Color3.fromRGB(255, 100, 0) },
	{ name = "DiamondBlock", remote = "SpawnDiamondBlock", color = Color3.fromRGB(0, 200, 255) },
	{ name = "RainbowBlock", remote = "SpawnRainbowBlock", color = Color3.fromRGB(200, 0, 255) },
	{ name = "GalaxyBlock",  remote = "SpawnGalaxyBlock",  color = Color3.fromRGB(50, 0, 120) },
}

local SPEED_MIN, SPEED_MAX = 16, 500
local JUMP_MIN, JUMP_MAX = 50, 500

-- State.
local flyEnabled = false
local noclipEnabled = false
local infiniteJumpEnabled = false
local flyConnection = nil
local noclipConnection = nil
local flySpeed = 50
local flyBodyVelocity = nil
local flyBodyGyro = nil

-- Animation State (from fly script)
local flightAnimationTrack = nil
local flyingAnimation = Instance.new("Animation")
flyingAnimation.AnimationId = "rbxassetid://3541114300"

-- Anti-AFK.
localPlayer.Idled:Connect(function()
	virtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
	task.wait(1)
	virtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

-- Update character on respawn.
local function setupCharacter(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	rootPart = char:WaitForChild("HumanoidRootPart")
	
	-- Load animation for new character
	flightAnimationTrack = humanoid:LoadAnimation(flyingAnimation)
	flightAnimationTrack.Priority = Enum.AnimationPriority.Action
	flightAnimationTrack.Looped = true
	
	flyEnabled = false
	noclipEnabled = false
end

localPlayer.CharacterAdded:Connect(setupCharacter)
if character then setupCharacter(character) end

-- GUI root.
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LuckyBlockHub"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = game:GetService("CoreGui")

-- Main frame.
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 440)
mainFrame.Position = UDim2.new(0.5, -150, 0.5, -220)
mainFrame.BackgroundColor3 = Color3.fromRGB(13, 13, 20)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 14)

local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = Color3.fromRGB(255, 200, 0)
mainStroke.Thickness = 1.5

-- Title bar.
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 45)
titleBar.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 14)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -50, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "⚡ Lucky Block Hub"
titleLabel.TextColor3 = Color3.fromRGB(13, 13, 20)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -38, 0, 7)
closeBtn.BackgroundColor3 = Color3.fromRGB(13, 13, 20)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 200, 0)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar

Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

closeBtn.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
end)

-- Tab bar.
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -20, 0, 36)
tabBar.Position = UDim2.new(0, 10, 0, 52)
tabBar.BackgroundColor3 = Color3.fromRGB(22, 22, 33)
tabBar.BorderSizePixel = 0
tabBar.Parent = mainFrame

Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 10)

local tabLayout = Instance.new("UIListLayout", tabBar)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 4)

local tabPadding = Instance.new("UIPadding", tabBar)
tabPadding.PaddingLeft = UDim.new(0, 4)
tabPadding.PaddingRight = UDim.new(0, 4)
tabPadding.PaddingTop = UDim.new(0, 4)
tabPadding.PaddingBottom = UDim.new(0, 4)

-- Content area.
local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -20, 1, -102)
contentArea.Position = UDim2.new(0, 10, 0, 96)
contentArea.BackgroundTransparency = 1
contentArea.BorderSizePixel = 0
contentArea.Parent = mainFrame

-- Helper: tab button (divide equally by 3).
local function makeTabBtn(text, order)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.333, -4, 1, 0)
	btn.BackgroundColor3 = Color3.fromRGB(13, 13, 20)
	btn.BorderSizePixel = 0
	btn.Text = text
	btn.TextColor3 = Color3.fromRGB(140, 140, 140)
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamBold
	btn.LayoutOrder = order
	btn.AutoButtonColor = false
	btn.Parent = tabBar

	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
	return btn
end

local tabAutos = makeTabBtn("Autos", 1)
local tabPlayer = makeTabBtn("Player", 2)
local tabExtras = makeTabBtn("Extras", 3)

-- Helper: scrolling page.
local function makePage()
	local page = Instance.new("ScrollingFrame")
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 3
	page.ScrollBarImageColor3 = Color3.fromRGB(255, 200, 0)
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.Visible = false
	page.Parent = contentArea

	local layout = Instance.new("UIListLayout", page)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 8)

	return page
end

local pageAutos = makePage()
local pagePlayer = makePage()
local pageExtras = makePage()

-- All tabs list for switching.
local tabs = {
	{ page = pageAutos,  btn = tabAutos },
	{ page = pagePlayer, btn = tabPlayer },
	{ page = pageExtras, btn = tabExtras },
}

local function selectTab(targetPage, targetBtn)
	for _, t in ipairs(tabs) do
		t.page.Visible = false
		t.btn.BackgroundColor3 = Color3.fromRGB(13, 13, 20)
		t.btn.TextColor3 = Color3.fromRGB(140, 140, 140)
	end
	targetPage.Visible = true
	targetBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
	targetBtn.TextColor3 = Color3.fromRGB(13, 13, 20)
end

tabAutos.MouseButton1Click:Connect(function() selectTab(pageAutos, tabAutos) end)
tabPlayer.MouseButton1Click:Connect(function() selectTab(pagePlayer, tabPlayer) end)
tabExtras.MouseButton1Click:Connect(function() selectTab(pageExtras, tabExtras) end)

-- =====================
-- AUTOS TAB
-- =====================

local amountRow = Instance.new("Frame")
amountRow.Size = UDim2.new(1, 0, 0, 38)
amountRow.BackgroundColor3 = Color3.fromRGB(22, 22, 33)
amountRow.BorderSizePixel = 0
amountRow.LayoutOrder = 1
amountRow.Parent = pageAutos

Instance.new("UICorner", amountRow).CornerRadius = UDim.new(0, 8)

local amountLabel = Instance.new("TextLabel")
amountLabel.Size = UDim2.new(0.5, 0, 1, 0)
amountLabel.Position = UDim2.new(0, 10, 0, 0)
amountLabel.BackgroundTransparency = 1
amountLabel.Text = "Quantidade:"
amountLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
amountLabel.TextScaled = true
amountLabel.Font = Enum.Font.Gotham
amountLabel.TextXAlignment = Enum.TextXAlignment.Left
amountLabel.Parent = amountRow

local minusAmtBtn = Instance.new("TextButton")
minusAmtBtn.Size = UDim2.new(0, 28, 0, 28)
minusAmtBtn.Position = UDim2.new(0.55, 0, 0.5, -14)
minusAmtBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
minusAmtBtn.BorderSizePixel = 0
minusAmtBtn.Text = "−"
minusAmtBtn.TextColor3 = Color3.fromRGB(255, 200, 0)
minusAmtBtn.TextScaled = true
minusAmtBtn.Font = Enum.Font.GothamBold
minusAmtBtn.Parent = amountRow

Instance.new("UICorner", minusAmtBtn).CornerRadius = UDim.new(0, 6)

local amountBox = Instance.new("TextBox")
amountBox.Size = UDim2.new(0, 48, 0, 28)
amountBox.Position = UDim2.new(0.55, 32, 0.5, -14)
amountBox.BackgroundColor3 = Color3.fromRGB(13, 13, 20)
amountBox.BorderSizePixel = 0
amountBox.Text = "1"
amountBox.TextColor3 = Color3.fromRGB(255, 255, 255)
amountBox.TextScaled = true
amountBox.Font = Enum.Font.GothamBold
amountBox.ClearTextOnFocus = false
amountBox.Parent = amountRow

Instance.new("UICorner", amountBox).CornerRadius = UDim.new(0, 6)

local plusAmtBtn = Instance.new("TextButton")
plusAmtBtn.Size = UDim2.new(0, 28, 0, 28)
plusAmtBtn.Position = UDim2.new(0.55, 84, 0.5, -14)
plusAmtBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
plusAmtBtn.BorderSizePixel = 0
plusAmtBtn.Text = "+"
plusAmtBtn.TextColor3 = Color3.fromRGB(255, 200, 0)
plusAmtBtn.TextScaled = true
plusAmtBtn.Font = Enum.Font.GothamBold
plusAmtBtn.Parent = amountRow

Instance.new("UICorner", plusAmtBtn).CornerRadius = UDim.new(0, 6)

-- CORREÇÃO: Limite de 50 no contador
minusAmtBtn.MouseButton1Click:Connect(function()
	local current = tonumber(amountBox.Text) or 1
	amountBox.Text = tostring(math.clamp(current - 1, 1, 50))
end)

plusAmtBtn.MouseButton1Click:Connect(function()
	local current = tonumber(amountBox.Text) or 1
	amountBox.Text = tostring(math.clamp(current + 1, 1, 50))
end)

amountBox.FocusLost:Connect(function()
	local current = tonumber(amountBox.Text) or 1
	amountBox.Text = tostring(math.clamp(current, 1, 50))
end)

for i, data in ipairs(BLOCKS) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 40)
	btn.BackgroundColor3 = data.color
	btn.BorderSizePixel = 0
	btn.Text = data.name
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamBold
	btn.AutoButtonColor = false
	btn.LayoutOrder = i + 1
	btn.Parent = pageAutos

	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

	btn.MouseButton1Click:Connect(function()
		local amount = tonumber(amountBox.Text) or 1
		local remote = replicatedStorage:FindFirstChild(data.remote)
		if not remote then return end
		for _ = 1, amount do
			remote:FireServer()
			task.wait(0.05)
		end
	end)
end

-- =====================
-- PLAYER TAB
-- =====================

local function makeSlider(labelText, minVal, maxVal, defaultVal, step, order, onChanged)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 82)
	container.BackgroundColor3 = Color3.fromRGB(22, 22, 33)
	container.BorderSizePixel = 0
	container.LayoutOrder = order
	container.Parent = pagePlayer

	Instance.new("UICorner", container).CornerRadius = UDim.new(0, 10)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.65, 0, 0, 24)
	label.Position = UDim2.new(0, 10, 0, 8)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = Color3.fromRGB(200, 200, 200)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(0.3, 0, 0, 24)
	valueLabel.Position = UDim2.new(0.68, 0, 0, 8)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = tostring(defaultVal)
	valueLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
	valueLabel.TextScaled = true
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = container

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -20, 0, 10)
	track.Position = UDim2.new(0, 10, 0, 40)
	track.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
	track.BorderSizePixel = 0
	track.Parent = container

	Instance.new("UICorner", track).CornerRadius = UDim.new(0, 5)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
	fill.BorderSizePixel = 0
	fill.Parent = track

	Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 5)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.new(0, 18, 0, 18)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 0.5, 0)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.Parent = track

	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

	local knobStroke = Instance.new("UIStroke", knob)
	knobStroke.Color = Color3.fromRGB(255, 200, 0)
	knobStroke.Thickness = 2

	local minusB = Instance.new("TextButton")
	minusB.Size = UDim2.new(0, 36, 0, 22)
	minusB.Position = UDim2.new(0, 10, 0, 56)
	minusB.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
	minusB.BorderSizePixel = 0
	minusB.Text = "− " .. step
	minusB.TextColor3 = Color3.fromRGB(255, 200, 0)
	minusB.TextScaled = true
	minusB.Font = Enum.Font.GothamBold
	minusB.Parent = container

	Instance.new("UICorner", minusB).CornerRadius = UDim.new(0, 6)

	local plusB = Instance.new("TextButton")
	plusB.Size = UDim2.new(0, 36, 0, 22)
	plusB.Position = UDim2.new(1, -46, 0, 56)
	plusB.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
	plusB.BorderSizePixel = 0
	plusB.Text = "+ " .. step
	plusB.TextColor3 = Color3.fromRGB(255, 200, 0)
	plusB.TextScaled = true
	plusB.Font = Enum.Font.GothamBold
	plusB.Parent = container

	Instance.new("UICorner", plusB).CornerRadius = UDim.new(0, 6)

	local currentVal = defaultVal

	local function updateSlider(val)
		currentVal = math.clamp(math.round(val / step) * step, minVal, maxVal)
		local ratio = (currentVal - minVal) / (maxVal - minVal)
		fill.Size = UDim2.new(ratio, 0, 1, 0)
		knob.Position = UDim2.new(ratio, 0, 0.5, 0)
		valueLabel.Text = tostring(currentVal)
		onChanged(currentVal)
	end

	local dragging = false

	knob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
		end
	end)

	userInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local relX = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		updateSlider(minVal + relX * (maxVal - minVal))
	end)

	userInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	minusB.MouseButton1Click:Connect(function() updateSlider(currentVal - step) end)
	plusB.MouseButton1Click:Connect(function() updateSlider(currentVal + step) end)
end

makeSlider("🏃 Velocidade", SPEED_MIN, SPEED_MAX, 16, 5, 1, function(v)
	humanoid.WalkSpeed = v
end)

makeSlider("🚀 Pulo", JUMP_MIN, JUMP_MAX, 50, 10, 2, function(v)
	humanoid.JumpPower = v
end)

makeSlider("🛸 Fly Speed", 10, 300, 50, 10, 3, function(v)
	flySpeed = v
end)

-- =====================
-- EXTRAS TAB (Toggles)
-- =====================

local function makeToggle(text, icon, order, onToggle)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 44)
	row.BackgroundColor3 = Color3.fromRGB(22, 22, 33)
	row.BorderSizePixel = 0
	row.LayoutOrder = order
	row.Parent = pageExtras

	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -80, 1, 0)
	label.Position = UDim2.new(0, 44, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(200, 200, 200)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(0, 34, 0, 34)
	iconLabel.Position = UDim2.new(0, 5, 0, 5)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = icon
	iconLabel.TextScaled = true
	iconLabel.Parent = row

	local toggleBg = Instance.new("Frame")
	toggleBg.Size = UDim2.new(0, 44, 0, 24)
	toggleBg.Position = UDim2.new(1, -54, 0.5, -12)
	toggleBg.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	toggleBg.BorderSizePixel = 0
	toggleBg.Parent = row

	Instance.new("UICorner", toggleBg).CornerRadius = UDim.new(1, 0)

	local circle = Instance.new("Frame")
	circle.Size = UDim2.new(0, 20, 0, 20)
	circle.Position = UDim2.new(0, 3, 0.5, -10)
	circle.BackgroundColor3 = Color3.fromRGB(140, 140, 140)
	circle.BorderSizePixel = 0
	circle.Parent = toggleBg

	Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

	local enabled = false

	local function setToggle(state)
		enabled = state
		if enabled then
			circle:TweenPosition(UDim2.new(1, -23, 0.5, -10), "Out", "Quart", 0.2, true)
			toggleBg.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
			circle.BackgroundColor3 = Color3.fromRGB(13, 13, 20)
		else
			circle:TweenPosition(UDim2.new(0, 3, 0.5, -10), "Out", "Quart", 0.2, true)
			toggleBg.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
			circle.BackgroundColor3 = Color3.fromRGB(140, 140, 140)
		end
		onToggle(enabled)
	end

	local clickDetect = Instance.new("TextButton")
	clickDetect.Size = UDim2.new(1, 0, 1, 0)
	clickDetect.BackgroundTransparency = 1
	clickDetect.Text = ""
	clickDetect.Parent = row

	clickDetect.MouseButton1Click:Connect(function()
		setToggle(not enabled)
	end)
end

-- =====================
-- FLY SYSTEM (Mobile Analog & Infinite Yield Style)
-- =====================

local function startFly()
	if not rootPart then return end
	
	-- Play animation
	if flightAnimationTrack then
		flightAnimationTrack:Play()
	end
	
	humanoid.PlatformStand = true
	
	flyBodyVelocity = Instance.new("BodyVelocity")
	flyBodyVelocity.Velocity = Vector3.zero
	flyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	flyBodyVelocity.Parent = rootPart

	flyBodyGyro = Instance.new("BodyGyro")
	flyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
	flyBodyGyro.P = 1e4
	flyBodyGyro.Parent = rootPart

	flyConnection = runService.RenderStepped:Connect(function()
		if not flyEnabled or not rootPart then return end
		local cam = workspace.CurrentCamera
		
		-- Use humanoid.MoveDirection to support Mobile Thumbstick automatically
		local moveDir = humanoid.MoveDirection
		local velocity = Vector3.zero
		
		if moveDir.Magnitude > 0 then
			-- Infinite Yield style: move in the direction the camera is facing
			-- This allows going up/down by looking up/down while moving
			velocity = cam.CFrame:VectorToWorldSpace(Vector3.new(
				(userInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (userInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0),
				0,
				(userInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0) - (userInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
			))
			
			-- If on mobile, moveDir is already calculated from the thumbstick
			if velocity.Magnitude == 0 and moveDir.Magnitude > 0 then
				velocity = moveDir
			end
			
			-- Add vertical control for keyboard (Space/Shift)
			if userInputService:IsKeyDown(Enum.KeyCode.Space) then
				velocity = velocity + Vector3.new(0, 1, 0)
			elseif userInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
				velocity = velocity - Vector3.new(0, 1, 0)
			end
			
			-- Combine with camera direction for full 3D flight (Infinite Yield Style)
			-- If moving forward, go where camera points
			if moveDir.Magnitude > 0 then
				local camLook = cam.CFrame.LookVector
				-- Simple approach: use the move vector but scaled by speed
				flyBodyVelocity.Velocity = veloci
