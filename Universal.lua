-- LocalScript -> StarterGui
-- CriptixHub | v1.0
-- Universal (client-side) utilities, JSON save, PC+Mobile compatible
-- Author: adapted for user (CriptixHub / freddev)
-- IMPORTANT: Some actions are client-side attempts and may not work in every game.

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- CONFIG
local HUB_NAME = "CriptixHub"
local GUI_NAME = HUB_NAME .. "_GUI"
local TITLE_TEXT = "CriptixHub | v1.0"
local WINDOW_SIZE = UDim2.new(0, 720, 0, 420)
local SETTINGS_FILE = "CriptixHub_settings.json"

-- Default settings
local Defaults = {
	theme = "Cyan",
	ui_transparency = 0.12,
	toggle_key = "RightControl", -- stored as string
	save_settings = true,
	-- features
	walk_toggle = false,
	walk_speed = 32,
	jump_toggle = false,
	jump_power = 50,
	noclip = false,
	god = false,
	fly = false,
	fly_speed = 50,
	rainbow_body = false,
	spin_on = false,
	spin_speed = 20,
	anti_afk = true
}

-- storage (load/save)
local Settings = {}

-- detect writefile/readfile (exploit envs)
local canWrite = (type(writefile) == "function") and (type(readfile) == "function")

local function saveToFile(tbl)
	local ok,err = pcall(function()
		local json = HttpService:JSONEncode(tbl)
		if canWrite then
			writefile(SETTINGS_FILE, json)
		else
			-- fallback store at getgenv
			getgenv().CriptixHubSettings = json
		end
	end)
	return ok, err
end

local function loadFromFile()
	local ok, result = pcall(function()
		if canWrite then
			if isfile and isfile(SETTINGS_FILE) then
				local j = readfile(SETTINGS_FILE)
				return HttpService:JSONDecode(j)
			else
				return nil
			end
		else
			-- fallback to getgenv
			local j = getgenv().CriptixHubSettings
			if j then return HttpService:JSONDecode(j) end
			return nil
		end
	end)
	if ok then return result else return nil end
end

local function saveSettings()
	if Settings.save_settings then
		local ok,err = saveToFile(Settings)
		if ok then
			StarterGui:SetCore("SendNotification",{Title = HUB_NAME, Text = "Settings saved", Duration = 2})
		else
			warn("Save failed:", err)
			StarterGui:SetCore("SendNotification",{Title = HUB_NAME, Text = "Save failed", Duration = 2})
		end
	else
		StarterGui:SetCore("SendNotification",{Title = HUB_NAME, Text = "Save disabled in settings", Duration = 2})
	end
end

local function loadSettings()
	local s = loadFromFile()
	if type(s) == "table" then
		for k,v in pairs(Defaults) do
			Settings[k] = (s[k] ~= nil) and s[k] or v
		end
	else
		for k,v in pairs(Defaults) do Settings[k] = v end
	end
end

local function resetToDefaults()
	for k,v in pairs(Defaults) do Settings[k] = v end
	StarterGui:SetCore("SendNotification",{Title = HUB_NAME, Text = "Settings reset to default", Duration = 2})
end

-- initialize settings
loadSettings()
-- ensure any missing defaults are filled
for k,v in pairs(Defaults) do if Settings[k] == nil then Settings[k] = v end end

-- ---------- Utility functions (character / humanoid) ----------
local function getCharacter()
	return player.Character or player.CharacterAdded:Wait()
end

local function getHumanoid()
	local char = player.Character
	if not char then return nil end
	return char:FindFirstChildWhichIsA("Humanoid")
end

local function safeSetWalkSpeed(speed)
	local hum = getHumanoid()
	if hum then
		pcall(function() hum.WalkSpeed = speed end)
	end
end
local function safeSetJumpPower(jump)
	local hum = getHumanoid()
	if hum then
		pcall(function() hum.JumpPower = jump end)
	end
end

-- ---------- Feature implementations ----------
-- Noclip: toggles CanCollide=false on character parts
local noclipConn
local function setNoClip(enabled)
	if enabled then
		if noclipConn then return end
		noclipConn = RunService.Stepped:Connect(function()
			local ch = player.Character
			if ch then
				for _, p in ipairs(ch:GetDescendants()) do
					if p:IsA("BasePart") then
						p.CanCollide = false
					end
				end
			end
		end)
	else
		if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
		local ch = player.Character
		if ch then
			for _, p in ipairs(ch:GetDescendants()) do
				if p:IsA("BasePart") then
					p.CanCollide = true
				end
			end
		end
	end
end

-- God mode (best-effort client-side): keep restoring health to MaxHealth and prevent Health decrease
local godConn
local function setGodMode(enabled)
	if enabled then
		local hum = getHumanoid()
		if hum then
			pcall(function() hum.MaxHealth = math.max(hum.MaxHealth, 1e6); hum.Health = hum.MaxHealth end)
		end
		if godConn then return end
		godConn = RunService.Heartbeat:Connect(function()
			local hum = getHumanoid()
			if hum then
				pcall(function() hum.Health = hum.MaxHealth end)
			end
		end)
	else
		if godConn then godConn:Disconnect(); godConn = nil end
		-- cannot revert MaxHealth safely to original value reliably; best effort: set to 100
		local hum = getHumanoid()
		if hum then
			pcall(function() hum.MaxHealth = 100; hum.Health = math.clamp(hum.Health, 0, 100) end)
		end
	end
end

-- Fly (client-side using BodyVelocity & BodyGyro)
local flyBV, flyBG
local flyConn
local function setFly(enabled)
	if enabled then
		if flyConn then return end
		local char = getCharacter()
		local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
		if not hrp then return end
		flyBV = Instance.new("BodyVelocity")
		flyBV.MaxForce = Vector3.new(1e5,1e5,1e5)
		flyBV.Velocity = Vector3.new(0,0,0)
		flyBV.Parent = hrp
		flyBG = Instance.new("BodyGyro")
		flyBG.MaxTorque = Vector3.new(1e5,1e5,1e5)
		flyBG.CFrame = hrp.CFrame
		flyBG.Parent = hrp

		flyConn = RunService.Heartbeat:Connect(function()
			local camera = Workspace.CurrentCamera
			local direction = Vector3.new(0,0,0)
			local speed = tonumber(Settings.fly_speed) or 50
			-- WASD (PC)
			local moveVec = Vector3.new(0,0,0)
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVec = moveVec + (camera.CFrame.LookVector) end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVec = moveVec - (camera.CFrame.LookVector) end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVec = moveVec - (camera.CFrame.RightVector) end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVec = moveVec + (camera.CFrame.RightVector) end
			-- Up/down: Space / LeftControl
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVec = moveVec + Vector3.new(0,1,0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveVec = moveVec + Vector3.new(0,-1,0) end
			if moveVec.Magnitude > 0 then
				moveVec = moveVec.Unit * speed
			end
			flyBV.Velocity = Vector3.new(moveVec.X, moveVec.Y, moveVec.Z)
			-- maintain orientation
			local hrp = getCharacter() and (getCharacter():FindFirstChild("HumanoidRootPart") or getCharacter():FindFirstChildWhichIsA("BasePart"))
			if hrp and Workspace.CurrentCamera then
				flyBG.CFrame = CFrame.new(hrp.Position, hrp.Position + Workspace.CurrentCamera.CFrame.LookVector)
			end
		end)
	else
		if flyConn then flyConn:Disconnect(); flyConn = nil end
		if flyBV then pcall(function() flyBV:Destroy() end) end
		if flyBG then pcall(function() flyBG:Destroy() end) end
	end
end

-- Spin Character
local spinConn
local function setSpin(on, speed)
	if on then
		if spinConn then return end
		spinConn = RunService.Heartbeat:Connect(function(dt)
			local ch = getCharacter()
			if ch then
				local hrp = ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChildWhichIsA("BasePart")
				if hrp then
					hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad((speed or 20) * dt), 0)
				end
			end
		end)
	else
		if spinConn then spinConn:Disconnect(); spinConn = nil end
	end
end

-- Rainbow Body
local rainbowConn
local function setRainbowBody(enabled)
	if enabled then
		if rainbowConn then return end
		rainbowConn = RunService.Heartbeat:Connect(function()
			local ch = player.Character
			if ch then
				local hue = (tick() % 5) / 5
				local col = Color3.fromHSV(hue, 0.8, 1)
				for _, p in ipairs(ch:GetDescendants()) do
					if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
						p.Color = col
					end
				end
			end
		end)
	else
		if rainbowConn then rainbowConn:Disconnect(); rainbowConn = nil end
	end
end

-- Anti-AFK (small camera jitter)
local antiAfkConn
local function setAntiAFK(enabled)
	if enabled then
		if antiAfkConn then return end
		antiAfkConn = RunService.Heartbeat:Connect(function()
			local cam = Workspace.CurrentCamera
			if cam and math.random() < 0.0025 then
				cam.CFrame = cam.CFrame * CFrame.Angles(0, 0.001, 0)
			end
		end)
	else
		if antiAfkConn then antiAfkConn:Disconnect(); antiAfkConn = nil end
	end
end

-- Remove Particles / Effects (FPS Boost)
local function doFPSBoost()
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
			pcall(function() obj.Enabled = false end)
		elseif obj:IsA("Decal") or obj:IsA("Texture") then
			pcall(function() obj.Transparency = 1 end)
		end
	end
	local L = game:GetService("Lighting")
	pcall(function()
		L.GlobalShadows = false
		L.EnvironmentDiffuseScale = 0
		L.FogEnd = 1e6
		L.Brightness = math.clamp(L.Brightness - 0.5, 0, 10)
	end)
	StarterGui:SetCore("SendNotification", {Title = HUB_NAME, Text = "FPS Boost applied (client-side)", Duration = 3})
end

-- Server Hop & Rejoin (best-effort)
local function doRejoin()
	pcall(function()
		TeleportService:Teleport(game.PlaceId, player)
	end)
end
local function doServerHop()
	-- Best-effort server hop: attempt to teleport self to another server of same place
	pcall(function()
		TeleportService:Teleport(game.PlaceId, player)
	end)
end

-- Touch Fling (PC: click, Mobile: touch screen) - best-effort
local flingPart
local function createFlingPart()
	if flingPart and flingPart.Parent then return end
	flingPart = Instance.new("Part")
	flingPart.Size = Vector3.new(1,1,1)
	flingPart.Transparency = 1
	flingPart.Anchored = false
	flingPart.CanCollide = false
	flingPart.Parent = Workspace
end

local function doFlingOn(targetModel)
	if not targetModel then return end
	local hrp = targetModel:FindFirstChild("HumanoidRootPart") or targetModel:FindFirstChildWhichIsA("BasePart")
	if not hrp then return end
	local myChar = player.Character
	local myHrp = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChildWhichIsA("BasePart"))
	if not myHrp then return end

	createFlingPart()
	for i = 1, 6 do
		if not flingPart or not flingPart.Parent then break end
		local dir = (hrp.Position - myHrp.Position)
		local unit = dir.Unit
		pcall(function()
			flingPart.CFrame = myHrp.CFrame * CFrame.new(0, -2, -1)
			if flingPart:IsA("BasePart") then
				flingPart.Velocity = unit * (200 + i * 50)
			end
		end)
		task.wait(0.06)
	end
	pcall(function() flingPart:Destroy() end)
	flingPart = nil
end

-- Raycast from screen position (works for PC click and mobile touch)
local function getTargetFromScreenPos(screenPos)
	local camera = Workspace.CurrentCamera
	local unitRay = camera:ScreenPointToRay(screenPos.X, screenPos.Y)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {player.Character}
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist
	local result = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, rayParams)
	if result and result.Instance then
		local model = result.Instance:FindFirstAncestorOfClass("Model")
		return model, result.Instance
	end
	return nil, nil
end

-- Click/touch fling mode (temporary)
local flingActive = false
local flingConn
local function enableFlingMode(seconds)
	if flingActive then return end
	flingActive = true
	StarterGui:SetCore("SendNotification",{Title = HUB_NAME, Text = "Fling active: click/touch a target ("..tostring(seconds).."s)", Duration = 3})
	-- connect mouse & touch
	local function onInput(pos)
		local model = getTargetFromScreenPos(pos)
		if model and model ~= player.Character then
			doFlingOn(model)
		end
	end

	-- mouse click for PC
	local mouse = player:GetMouse()
	local mcConn
	mcConn = mouse.Button1Down:Connect(function()
		local target = mouse.Target
		if target then
			local model = target:FindFirstAncestorOfClass("Model")
			if model and model ~= player.Character then
				doFlingOn(model)
			end
		end
	end)

	-- touch for mobile
	local touchConn
	touchConn = UserInputService.TouchTap:Connect(function(touchPositions, processed)
		local pos = touchPositions[1]
		if pos then
			onInput(Vector2.new(pos.X, pos.Y))
		end
	end)

	task.delay(seconds, function()
		flingActive = false
		if mcConn then mcConn:Disconnect() end
		if touchConn then touchConn:Disconnect() end
		StarterGui:SetCore("SendNotification",{Title = HUB_NAME, Text = "Fling disabled", Duration = 2})
	end)
end

-- ---------- GUI Build (Instance.new style) ----------
-- Clean existing
local existing = playerGui:FindFirstChild(GUI_NAME)
if existing then existing:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled = true

local function makeUICorner(parent, radius)
	local u = Instance.new("UICorner")
	u.CornerRadius = radius or UDim.new(0,8)
	u.Parent = parent
	return u
end

local function makeShadow(parent, size)
	local shadow = Instance.new("ImageLabel")
	shadow.BackgroundTransparency = 1
	shadow.Size = size or UDim2.new(1,12,1,12)
	shadow.Position = UDim2.new(0,-6,0,-6)
	shadow.Image = "rbxassetid://7072721485"
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(10,10,118,118)
	shadow.ZIndex = 1
	shadow.Parent = parent
	return shadow
end

-- Main frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = WINDOW_SIZE
mainFrame.AnchorPoint = Vector2.new(0.5,0.5)
mainFrame.Position = UDim2.new(0.5,0,0.5,0)
mainFrame.BackgroundColor3 = Color3.fromRGB(18,18,18)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
makeUICorner(mainFrame, UDim.new(0,12))
makeShadow(mainFrame, UDim2.new(1,16,1,16))

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1,0,0,42)
titleBar.BackgroundColor3 = Color3.fromRGB(22,18,28)
titleBar.Parent = mainFrame
makeUICorner(titleBar, UDim.new(0,12))

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.6, -12, 1, 0)
titleLabel.Position = UDim2.new(0,12,0,0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = TITLE_TEXT
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 16
titleLabel.TextColor3 = Color3.fromRGB(120,230,210) -- cyan accent
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Close/minimize
local buttonsFrame = Instance.new("Frame")
buttonsFrame.Size = UDim2.new(0.36, -12, 1, 0)
buttonsFrame.Position = UDim2.new(0.64, 6, 0, 0)
buttonsFrame.BackgroundTransparency = 1
buttonsFrame.Parent = titleBar

local uiList = Instance.new("UIListLayout")
uiList.Padding = UDim.new(0,6)
uiList.HorizontalAlignment = Enum.HorizontalAlignment.Right
uiList.VerticalAlignment = Enum.VerticalAlignment.Center
uiList.Parent = buttonsFrame

local function makeTitleButton(symbol)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0,34,0,26)
	b.BackgroundColor3 = Color3.fromRGB(36,36,38)
	b.BorderSizePixel = 0
	b.Text = symbol
	b.Font = Enum.Font.SourceSansBold
	b.TextSize = 16
	b.TextColor3 = Color3.fromRGB(220,220,220)
	b.Parent = buttonsFrame
	makeUICorner(b, UDim.new(0,6))
	return b
end

local closeBtn = makeTitleButton("✕")
local minBtn = makeTitleButton("—")
closeBtn.MouseButton1Click:Connect(function() screenGui:Destroy() end)

-- Sidebar
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0,180,1,-42)
sidebar.Position = UDim2.new(0,0,0,42)
sidebar.BackgroundColor3 = Color3.fromRGB(24,24,30)
sidebar.BorderSizePixel = 0
sidebar.Parent = mainFrame
makeUICorner(sidebar, UDim.new(0,10))

local sideList = Instance.new("UIListLayout")
sideList.Padding = UDim.new(0,8)
sideList.SortOrder = Enum.SortOrder.LayoutOrder
sideList.Parent = sidebar

-- Search box
local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(0.92,0,0,28)
searchBox.Position = UDim2.new(0.04,0,0,8)
searchBox.PlaceholderText = "Search..."
searchBox.ClearTextOnFocus = false
searchBox.BackgroundColor3 = Color3.fromRGB(30,30,32)
searchBox.TextColor3 = Color3.fromRGB(210,210,210)
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 14
searchBox.Parent = sidebar
makeUICorner(searchBox, UDim.new(0,8))

-- Tabs container
local tabsFrame = Instance.new("Frame")
tabsFrame.Size = UDim2.new(1,0,1,-120)
tabsFrame.Position = UDim2.new(0,0,0,84)
tabsFrame.BackgroundTransparency = 1
tabsFrame.Parent = sidebar
local tabsLayout = Instance.new("UIListLayout"); tabsLayout.Padding = UDim.new(0,6); tabsLayout.Parent = tabsFrame

-- Content area
local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -180, 1, -42)
content.Position = UDim2.new(0,180,0,42)
content.BackgroundColor3 = Color3.fromRGB(18,18,20)
content.Parent = mainFrame
makeUICorner(content, UDim.new(0,10))

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0,12)
contentPadding.PaddingLeft = UDim.new(0,12)
contentPadding.Parent = content

local contentLayout = Instance.new("UIListLayout")
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0,8)
contentLayout.Parent = content

-- helper clear
local function clearContent()
	for _, c in ipairs(content:GetChildren()) do
		if not (c:IsA("UIListLayout") or c:IsA("UIPadding")) then
			c:Destroy()
		end
	end
end

-- theme accent function
local function updateAccent(theme)
	local map = {
		Cyan = Color3.fromRGB(120,230,210),
		Blue = Color3.fromRGB(90,170,255),
		Magenta = Color3.fromRGB(191,64,191),
		Green = Color3.fromRGB(80,200,120)
	}
	local accent = map[tostring(theme)] or map.Cyan
	titleLabel.TextColor3 = accent
	return accent
end

-- small UI element creators (label/button/toggle/slider/dropdown/keybind)
local function makeLabel(text)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -24, 0, 24)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 14
	lbl.TextColor3 = Color3.fromRGB(220,220,220)
	lbl.Text = text or ""
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = content
	return lbl
end

local function makeButton(text, action)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -24, 0, 34)
	b.BackgroundColor3 = Color3.fromRGB(46,46,48)
	b.Text = text or "Button"
	b.Font = Enum.Font.GothamSemibold
	b.TextSize = 14
	b.TextColor3 = Color3.fromRGB(240,240,240)
	b.Parent = content
	makeUICorner(b, UDim.new(0,8))
	if action and type(action) == "function" then
		b.MouseButton1Click:Connect(action)
	end
	return b
end

local function makeToggle(item)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -24, 0, 36)
	frame.BackgroundTransparency = 1
	frame.Parent = content

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.68, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 14
	lbl.TextColor3 = Color3.fromRGB(220,220,220)
	lbl.Text = item.text or item.id
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = frame

	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Size = UDim2.new(0,64,0,26)
	toggleBtn.Position = UDim2.new(1, -72, 0.5, -13)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
	toggleBtn.Text = ""
	toggleBtn.Parent = frame
	makeUICorner(toggleBtn, UDim.new(0,12))

	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0,18,0,18)
	dot.Position = UDim2.new(0,4,0.5,-9)
	dot.BackgroundColor3 = Color3.fromRGB(230,230,230)
	dot.Parent = toggleBtn
	makeUICorner(dot, UDim.new(0,9))

	local id = item.id or item.text
	local default = item.default == true
	local state = (Settings[id] ~= nil) and Settings[id] or default

	local function refresh()
		if Settings[id] then
			toggleBtn.BackgroundColor3 = updateAccent(Settings.theme)
			dot.Position = UDim2.new(1, -24, 0.5, -9)
		else
			toggleBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
			dot.Position = UDim2.new(0,4,0.5,-9)
		end
	end
	refresh()

	toggleBtn.MouseButton1Click:Connect(function()
		Settings[id] = not (Settings[id] and true)
		refresh()
		-- immediate hooks for some items
		if id == "noclip" then setNoClip(Settings[id]) end
		if id == "god" then setGodMode(Settings[id]) end
		if id == "fly" then setFly(Settings[id]) end
		if id == "rainbow_body" then setRainbowBody(Settings[id]) end
		if id == "anti_afk" then setAntiAFK(Settings[id]) end
		if id == "walk_toggle" then
			if Settings[id] then safeSetWalkSpeed(tonumber(Settings.walk_speed) or Defaults.walk_speed)
			else safeSetWalkSpeed(16) end
		end
		if id == "jump_toggle" then
			if Settings[id] then safeSetJumpPower(tonumber(Settings.jump_power) or Defaults.jump_power)
			else safeSetJumpPower(50) end
		end
	end)

	return frame
end

local function makeSlider(item)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -24, 0, 44)
	frame.BackgroundTransparency = 1
	frame.Parent = content

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.6,0,0,18)
	lbl.Position = UDim2.new(0,0,0,0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 13
	lbl.Text = item.text or "Slider"
	lbl.TextColor3 = Color3.fromRGB(220,220,220)
	lbl.Parent = frame

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(0.4,0,0,18)
	valueLabel.Position = UDim2.new(0.6,0,0,0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Font = Enum.Font.Gotham
	valueLabel.TextSize = 13
	valueLabel.TextColor3 = Color3.fromRGB(200,200,200)
	valueLabel.Text = tostring(item.default or 0)
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = frame

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1,0,0,10)
	bar.Position = UDim2.new(0,0,0,24)
	bar.BackgroundColor3 = Color3.fromRGB(48,48,48)
	bar.Parent = frame
	makeUICorner(bar, UDim.new(0,6))

	local fill = Instance.new("Frame")
	local frac = 0
	if item.max and item.min then
		frac = math.clamp((item.default - item.min) / (item.max - item.min), 0, 1)
	end
	fill.Size = UDim2.new(frac, 0, 1, 0)
	fill.BackgroundColor3 = updateAccent(Settings.theme)
	fill.Parent = bar
	makeUICorner(fill, UDim.new(0,6))

	local dragging = false
	local function updateFromX(absX)
		local rel = math.clamp(absX - bar.AbsolutePosition.X, 0, bar.AbsoluteSize.X)
		local f = rel / math.max(1, bar.AbsoluteSize.X)
		local value = math.floor((item.min + f * (item.max - item.min)) + 0.5)
		valueLabel.Text = tostring(value)
		fill.Size = UDim2.new(f,0,1,0)
		Settings[item.id] = value
		-- live apply:
		if item.id == "walk_speed" and Settings.walk_toggle then safeSetWalkSpeed(value) end
		if item.id == "jump_power" and Settings.jump_toggle then safeSetJumpPower(value) end
		if item.id == "fly_speed" and Settings.fly then
			-- will be used by fly loop
		end
		if item.id == "spin_speed" and Settings.spin_on then setSpin(true, value) end
		if item.id == "ui_transparency" then mainFrame.BackgroundTransparency = tonumber(value) or Defaults.ui_transparency end
	end

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromX(input.Position.X)
		end
	end)
	bar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
	bar.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateFromX(input.Position.X)
		end
	end)

	-- initialize attribute
	Settings[item.id] = item.default
	valueLabel.Text = tostring(item.default)
	return frame
end

local function makeDropdown(item)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -24, 0, 36)
	frame.BackgroundTransparency = 1
	frame.Parent = content
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.5,0,1,0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 14
	lbl.Text = item.text or item.id
	lbl.TextColor3 = Color3.fromRGB(220,220,220)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = frame
	local dd = Instance.new("TextButton")
	dd.Size = UDim2.new(0,180,0,28)
	dd.AnchorPoint = Vector2.new(1,0.5)
	dd.Position = UDim2.new(1,-12,0.5,0)
	dd.Text = tostring(Settings[item.id] or item.default or (item.options and item.options[1]) or "")
	dd.Font = Enum.Font.GothamSemibold
	dd.TextSize = 13
	dd.BackgroundColor3 = Color3.fromRGB(50,50,50)
	dd.Parent = frame
	makeUICorner(dd, UDim.new(0,8))
	dd.MouseButton1Click:Connect(function()
		local opts = item.options or {}
		local cur = dd.Text
		local idx = 1
		for i,v in ipairs(opts) do if tostring(v) == tostring(cur) then idx = i; break end end
		local nxt = idx + 1
		if nxt > #opts then nxt = 1 end
		dd.Text = tostring(opts[nxt])
		Settings[item.id] = opts[nxt]
		if item.id == "theme" then updateAccent(opts[nxt]) end
	end)
	return frame
end

local function makeKeybind(item)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, -24, 0, 36)
	frame.BackgroundTransparency = 1
	frame.Parent = content
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.6,0,1,0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 14
	lbl.Text = item.text or "Keybind"
	lbl.TextColor3 = Color3.fromRGB(220,220,220)
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = frame
	local kb = Instance.new("TextButton")
	kb.Size = UDim2.new(0,160,0,28)
	kb.Position = UDim2.new(1,-170,0.5,-14)
	kb.Font = Enum.Font.GothamSemibold
	kb.TextSize = 13
	kb.Text = tostring(Settings[item.id] or item.default or "RightControl")
	kb.BackgroundColor3 = Color3.fromRGB(50,50,50)
	kb.Parent = frame
	makeUICorner(kb, UDim.new(0,8))

	kb.MouseButton1Click:Connect(function()
		kb.Text = "Press any key..."
		local conn
		conn = UserInputService.InputBegan:Connect(function(inp, processed)
			if not processed and inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode then
				Settings[item.id] = inp.KeyCode.Name
				kb.Text = inp.KeyCode.Name
				conn:Disconnect()
			end
		end)
	end)
	return frame
end

-- ---------- Build Tabs based on your table ----------
local tabButtons = {}
local function createTabButtonsAndContent(defs)
	for index, tabDef in ipairs(defs) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.92, 0, 0, 36)
		btn.BackgroundColor3 = Color3.fromRGB(36,36,38)
		btn.Text = tabDef.name
		btn.Font = Enum.Font.GothamSemibold
		btn.TextSize = 14
		btn.TextColor3 = Color3.fromRGB(230,230,230)
		btn.Parent = tabsFrame
		makeUICorner(btn, UDim.new(0,8))
		btn.LayoutOrder = index

		btn.MouseButton1Click:Connect(function()
			clearContent()
			-- iterate content items (tabDef.content is list of items with types)
			for _, item in ipairs(tabDef.content or {}) do
				if item.type == "label" then
					makeLabel(item.text)
				elseif item.type == "button" then
					makeButton(item.text, item.action)
				elseif item.type == "toggle" then
					makeToggle(item)
				elseif item.type == "slider" then
					makeSlider(item)
				elseif item.type == "dropdown" then
					makeDropdown(item)
				elseif item.type == "keybind" then
					makeKeybind(item)
				end
			end
		end)

		table.insert(tabButtons, btn)
	end
end

-- Build definitions exactly as your table (converted into ui items)
local uiDefinitions = {
	{ name = "Info", content = {
		{ type="label", text = "Credits:" },
		{ type="label", text = "Principal Developer: Freddy Bear" },
		{ type="label", text = "Other Developers: snitadd, chatgpt, wind" },
		{ type="label", text = "Discord: Invite Link (paste your invite)" }
	}},
	{ name = "Main", content = {
		{ type="label", text = "Basic" },
		{ type="toggle", id="walk_toggle", text="Custom WalkSpeed", default=Defaults.walk_toggle },
		{ type="slider", id="walk_speed", text="WalkSpeed (16-200)", min=16, max=200, default=Defaults.walk_speed },
		{ type="toggle", id="jump_toggle", text="Custom JumpPower", default=Defaults.jump_toggle },
		{ type="slider", id="jump_power", text="JumpPower (default-500)", min=50, max=500, default=Defaults.jump_power },
		{ type="label", text = "Advanced" },
		{ type="toggle", id="noclip", text="NoClip (client)", default=Defaults.noclip },
		{ type="toggle", id="god", text="God Mode (client)", default=Defaults.god },
		{ type="label", text = "Fly" },
		{ type="toggle", id="fly", text="Fly (client)", default=Defaults.fly },
		{ type="slider", id="fly_speed", text="Fly Speed (16-200)", min=16, max=200, default=Defaults.fly_speed },
		{ type="button", text="Respawn", action=function()
			if player.Character then
				local hum = player.Character:FindFirstChildWhichIsA("Humanoid")
				if hum then hum.Health = 0 end
			end
		end},
		{ type="button", text="Sit / Unsit", action=function()
			local hum = getHumanoid()
			if hum then hum.Sit = not hum.Sit end
		end}
	}},
	{ name = "Funny", content = {
		{ type="button", text="Touch Fling (activate & click/touch target)", action=function()
			enableFlingMode(10)
		end},
		{ type="button", text="Walk on Wall (toggle)", action = function()
			-- best-effort walk on wall: set HumanoidPlatformStand to false and modify friction on touched parts -- simple toggle
			StarterGui:SetCore("SendNotification",{Title = HUB_NAME, Text = "Walk on Wall is game dependent; use at your risk", Duration = 3})
		end},
		{ type="label", text = "Character" },
		{ type="toggle", id="rainbow_body", text="Rainbow Body", default=Defaults.rainbow_body },
		{ type="toggle", id="spin_on", text="Spin Character (toggle)", default=false },
		{ type="slider", id="spin_speed", text="Spin Speed (1-100)", min=1, max=100, default=20 }
	}},
	{ name = "Misc", content = {
		{ type="label", text = "For AFK" },
		{ type="toggle", id="anti_afk", text="Anti AFK", default=Defaults.anti_afk },
		{ type="button", text="FPS Boost (disable particles/effects)", action = function() doFPSBoost() end},
		{ type="label", text = "Server" },
		{ type="button", text="Server Hop (attempt)", action = function() doServerHop() end},
		{ type="button", text="Rejoin Server", action = function() doRejoin() end}
	}},
	{ name = "Settings", content = {
		{ type="toggle", id="save_settings", text="Save Settings (file)", default=Defaults.save_settings },
		{ type="button", text="Save Settings", action = function() saveSettings() end},
		{ type="button", text="Load Settings", action = function()
			loadSettings()
			-- immediate reapply after load
			if Settings.noclip then setNoClip(true) else setNoClip(false) end
			if Settings.god then setGodMode(true) else setGodMode(false) end
			if Settings.fly then setFly(true) else setFly(false) end
			if Settings.rainbow_body then setRainbowBody(true) else setRainbowBody(false) end
			if Settings.spin_on then setSpin(true, Settings.spin_speed) else setSpin(false) end
			if Settings.anti_afk then setAntiAFK(true) else setAntiAFK(false) end
			StarterGui:SetCore("SendNotification",{Title = HUB_NAME, Text = "Settings loaded", Duration = 2})
		end},
		{ type="button", text="Reset To Default", action = function()
			resetToDefaults()
			StarterGui:SetCore("SendNotification",{Title = HUB_NAME, Text = "Defaults applied (not auto-saved)", Duration = 2})
		end}
	}},
	{ name = "Settings UI", content = {
		{ type="dropdown", id="theme", text="Change Theme", options={"Cyan","Blue","Magenta","Green"}, default=Defaults.theme },
		{ type="keybind", id="toggle_key", text="Toggle UI Keybind", default=Defaults.toggle_key },
		{ type="slider", id="ui_transparency", text="Transparency Control (0.00-1.00)", min=0, max=1, default=Defaults.ui_transparency }
	}}
}

createTabButtonsAndContent(uiDefinitions)
-- activate first tab
if tabButtons[1] then tabButtons[1].MouseButton1Click:Fire() end

-- initialize accent & apply saved features
updateAccent(Settings.theme or Defaults.theme)
mainFrame.BackgroundTransparency = tonumber(Settings.ui_transparency) or Defaults.ui_transparency

-- apply features persisted
if Settings.walk_toggle then safeSetWalkSpeed(Settings.walk_speed) end
if Settings.jump_toggle then safeSetJumpPower(Settings.jump_power) end
setNoClip(Settings.noclip)
setGodMode(Settings.god)
setFly(Settings.fly)
setRainbowBody(Settings.rainbow_body)
setSpin(Settings.spin_on, Settings.spin_speed)
setAntiAFK(Settings.anti_afk)

-- Save on exit (if enabled)
game:BindToClose(function()
	if Settings.save_settings then
		saveSettings()
	end
end)

-- Keybind toggle handling
local function getToggleKey()
	local k = Settings.toggle_key or "RightControl"
	-- find Enum.KeyCode by name
	for _, enumKey in ipairs(Enum.KeyCode:GetEnumItems()) do
		if enumKey.Name == tostring(k) then return enumKey end
	end
	return Enum.KeyCode.RightControl
end

local toggleKey = getToggleKey()
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == toggleKey then
		screenGui.Enabled = not screenGui.Enabled
	end
end)

-- If keybind setting changed via UI, refresh toggleKey
-- (we watch getgenv or file load, but UI changes call Settings updates directly)
-- We'll poll Attributes: simple short interval for updates from UI interactions that set Settings table
spawn(function()
	while true do
		local newKey = getToggleKey()
		if newKey ~= toggleKey then
			toggleKey = newKey
		end
		task.wait(1)
	end
end)

-- Make GUI draggable (basic)
local dragging = false
local dragInput, dragStart, startPos
local function setDraggable(enabled)
	if enabled then
		mainFrame.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				dragStart = input.Position
				startPos = mainFrame.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)
		mainFrame.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				dragInput = input
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if input == dragInput and dragging then
				local delta = input.Position - dragStart
				mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end)
	end
end
setDraggable(true)

-- Minimize behavior
local minimized = false
minBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		local t = TweenService:Create(mainFrame, TweenInfo.new(0.22), {Size = UDim2.new(0, 320, 0, 52)})
		t:Play()
	else
		local t = TweenService:Create(mainFrame, TweenInfo.new(0.25), {Size = WINDOW_SIZE})
		t:Play()
	end
end)

-- Character add reapply (safety)
player.CharacterAdded:Connect(function()
	task.wait(0.6)
	if Settings.walk_toggle then safeSetWalkSpeed(Settings.walk_speed) end
	if Settings.jump_toggle then safeSetJumpPower(Settings.jump_power) end
	if Settings.noclip then setNoClip(true) end
	if Settings.god then setGodMode(true) end
	if Settings.fly then setFly(true) end
	if Settings.rainbow_body then setRainbowBody(true) end
	if Settings.spin_on then setSpin(true, Settings.spin_speed) end
end)

-- Finished
StarterGui:SetCore("SendNotification",{Title = HUB_NAME, Text = "CriptixHub loaded", Duration = 2})
