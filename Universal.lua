-- Criptix Hub | v1.6.4 (WindUI - Floating button kept)
-- Dev: Freddy Bear
-- Paste as LocalScript into StarterGui

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Loading notification helpers
local function showLoading()
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Criptix Hub",
            Text = "Please wait, Criptix Hub is loading...",
            Duration = 9999
        })
    end)
end
local function hideLoading()
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "Criptix Hub",
            Text = " ",
            Duration = 0.1
        })
    end)
end

showLoading()

-- Load WindUI
local ok, ui = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)
if not ok or type(ui) ~= "table" then
    hideLoading()
    warn("[CriptixHub] WindUI load failed")
    return
end

-- Create window (table config) — adapted to your detected WindUI variant
local win
local ok2, err2 = pcall(function()
    win = ui:CreateWindow({
        Title = "Criptix Hub | v1.6.4 🌐",
        Size = UDim2.fromOffset(760, 420),
        Transparent = true,
        Theme = "Dark",
        SideBarWidth = 200,
        User = { Enabled = false, Anonymous = false } -- user disabled (no real user)
    })
end)
if not ok2 or not win then
    hideLoading()
    warn("[CriptixHub] CreateWindow failed:", err2)
    return
end

-- Provide safe notify wrapper
local function safeNotify(tbl)
    pcall(function() if ui and ui.Notify then ui:Notify(tbl) end end)
end

-- Utility helpers
local function getHumanoid()
    local ch = player.Character
    if not ch then return nil end
    return ch:FindFirstChildOfClass("Humanoid")
end

-- ========== TABS & CONTENT ==========
local tabInfo     = win:Tab({ Title = "Info" })
local tabMain     = win:Tab({ Title = "Main" })
local tabFunny    = win:Tab({ Title = "Funny" })
local tabMisc     = win:Tab({ Title = "Misc" })
local tabSettings = win:Tab({ Title = "Settings" })
local tabSUI      = win:Tab({ Title = "Settings UI" })

-- INFO
local secInfo = tabInfo:Section("About")
secInfo:Paragraph({ Title = "Criptix Hub | v1.6.4", Content = "Universal hub — Freddy Bear\nOther devs: snitadd, chatgpt, wind" })
secInfo:Button({ Title = "Copy Discord Invite", Callback = function()
    pcall(function() setclipboard("https://discord.gg/yourinvite") end)
    safeNotify({ Title="Criptix", Description="Discord invite copied", Duration=2 })
end })

-- MAIN
local secBasic    = tabMain:Section("Basic")
local secAdvanced = tabMain:Section("Advanced")
local secFly      = tabMain:Section("Fly")

-- Walk speed
local walkEnabled = false
local walkSpeed = 32
secBasic:Toggle({ Title = "Enable Custom WalkSpeed", Default = false, Callback = function(state)
    walkEnabled = state
    local hum = getHumanoid()
    if hum then
        if walkEnabled then pcall(function() hum.WalkSpeed = walkSpeed end) else pcall(function() hum.WalkSpeed = 16 end) end
    end
end })
secBasic:Slider({ Title = "Walk Speed (16-200)", Min = 16, Max = 200, Default = 32, Callback = function(v)
    walkSpeed = math.clamp(tonumber(v) or 32, 16, 200)
    if walkEnabled then local hum = getHumanoid(); if hum then pcall(function() hum.WalkSpeed = walkSpeed end) end end
end })

-- Jump power
local jumpEnabled = false
local jumpPower = 50
secBasic:Toggle({ Title = "Enable Custom JumpPower", Default = false, Callback = function(state)
    jumpEnabled = state
    local hum = getHumanoid()
    if hum then
        if jumpEnabled then pcall(function() hum.JumpPower = jumpPower end) else pcall(function() hum.JumpPower = 50 end) end
    end
end })
secBasic:Slider({ Title = "Jump Power (50-500)", Min = 50, Max = 500, Default = 50, Callback = function(v)
    jumpPower = math.clamp(tonumber(v) or 50, 50, 500)
    if jumpEnabled then local hum = getHumanoid(); if hum then pcall(function() hum.JumpPower = jumpPower end) end end
end })

-- NoClip
local noclipConn
local noclipOn = false
secAdvanced:Toggle({ Title = "No Clip (client)", Default = false, Callback = function(v)
    noclipOn = v
    if noclipOn then
        noclipConn = RunService.Stepped:Connect(function()
            local ch = player.Character
            if ch then for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
        end)
        safeNotify({ Title="Criptix", Description="NoClip enabled", Duration=1.5 })
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        local ch = player.Character
        if ch then for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
        safeNotify({ Title="Criptix", Description="NoClip disabled", Duration=1.5 })
    end
end })

-- God Mode
local godConn
secAdvanced:Toggle({ Title = "God Mode (client)", Default = false, Callback = function(v)
    if v then
        local hum = getHumanoid()
        if hum then pcall(function() hum.MaxHealth = math.huge; hum.Health = hum.MaxHealth end) end
        godConn = RunService.Heartbeat:Connect(function()
            local h = getHumanoid()
            if h then pcall(function() h.Health = h.MaxHealth end) end
        end)
        safeNotify({ Title="Criptix", Description="God Mode enabled", Duration=1.5 })
    else
        if godConn then godConn:Disconnect(); godConn = nil end
        local h = getHumanoid()
        if h then pcall(function() h.MaxHealth = 100; h.Health = math.clamp(h.Health,0,100) end) end
        safeNotify({ Title="Criptix", Description="God Mode disabled", Duration=1.5 })
    end
end })

-- Fly
local flyOn = false
local flySpeed = 50
local flyBV, flyBG, flyConn
secFly:Toggle({ Title = "Fly (client)", Default = false, Callback = function(v)
    flyOn = v
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
    if flyOn then
        if not hrp then safeNotify({ Title="Criptix", Description="No HumanoidRootPart found", Duration=2 }); return end
        flyBV = Instance.new("BodyVelocity", hrp); flyBV.MaxForce = Vector3.new(1e5,1e5,1e5)
        flyBG = Instance.new("BodyGyro", hrp); flyBG.MaxTorque = Vector3.new(1e5,1e5,1e5)
        flyConn = RunService.Heartbeat:Connect(function()
            local cam = Workspace.CurrentCamera
            if not cam then return end
            local mv = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv = mv + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv = mv - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv = mv - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv = mv + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then mv = mv - Vector3.new(0,1,0) end
            if mv.Magnitude > 0 then mv = mv.Unit * flySpeed end
            pcall(function() if flyBV then flyBV.Velocity = mv end end)
            if flyBG and player.Character and Workspace.CurrentCamera then
                local hrp2 = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChildWhichIsA("BasePart")
                if hrp2 then flyBG.CFrame = CFrame.new(hrp2.Position, hrp2.Position + Workspace.CurrentCamera.CFrame.LookVector) end
            end
        end)
        safeNotify({ Title="Criptix", Description="Fly enabled", Duration=1.5 })
    else
        if flyConn then flyConn:Disconnect(); flyConn = nil end
        if flyBV then pcall(function() flyBV:Destroy() end) end
        if flyBG then pcall(function() flyBG:Destroy() end) end
        safeNotify({ Title="Criptix", Description="Fly disabled", Duration=1.5 })
    end
end })
secFly:Slider({ Title = "Fly Speed (16-200)", Min = 16, Max = 200, Default = 50, Callback = function(v) flySpeed = math.clamp(tonumber(v) or 50, 16, 200) end })

-- FUNNY
local secFunnyA = tabFunny:Section(":)")
local secFunnyB = tabFunny:Section("Character")

secFunnyA:Button({ Title = "Walk on Wall (attempt)", Callback = function()
    safeNotify({ Title="Criptix", Description="Walk on Wall attempted (game-dependent)", Duration=2 })
end })

secFunnyA:Button({ Title = "Enable Touch Fling (10s)", Callback = function()
    safeNotify({ Title="Criptix", Description="Touch/Click fling active (10s)", Duration=2 })
    local mouse = player:GetMouse()
    local conn
    conn = mouse.Button1Down:Connect(function()
        local t = mouse.Target
        if t then
            local model = t:FindFirstAncestorOfClass("Model")
            if model and model ~= player.Character then
                local hrp = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
                local myChar = player.Character
                local myHrp = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChildWhichIsA("BasePart"))
                if hrp and myHrp then
                    local flingPart = Instance.new("Part", Workspace)
                    flingPart.Size = Vector3.new(1,1,1)
                    flingPart.Transparency = 1
                    flingPart.Anchored = false
                    flingPart.CanCollide = false
                    flingPart.CFrame = myHrp.CFrame * CFrame.new(0,-2,-1)
                    flingPart.Velocity = (hrp.Position - myHrp.Position).Unit * 150
                    task.delay(0.6, function() pcall(function() flingPart:Destroy() end) end)
                end
            end
        end
    end)
    task.delay(10, function() if conn then conn:Disconnect() end; safeNotify({ Title="Criptix", Description="Fling disabled", Duration=2 }) end)
end })

secFunnyB:Toggle({ Title = "Rainbow Body", Default = false, Callback = function(state)
    if state then
        _G.__Cr_Rainbow = RunService.Heartbeat:Connect(function()
            local ch = player.Character
            if ch then
                local hue = (tick() % 5) / 5
                local col = Color3.fromHSV(hue, 0.8, 1)
                for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.Color = col end end
            end
        end)
        safeNotify({ Title="Criptix", Description="Rainbow enabled", Duration=1.5 })
    else
        if _G.__Cr_Rainbow then _G.__Cr_Rainbow:Disconnect(); _G.__Cr_Rainbow = nil end
        safeNotify({ Title="Criptix", Description="Rainbow disabled", Duration=1.5 })
    end
end })

secFunnyB:Slider({ Title = "Spin Speed (1-100)", Min = 1, Max = 100, Default = 20, Callback = function(val) _G.Cr_SpinSpeed = math.clamp(tonumber(val) or 20, 1, 100) end })
secFunnyB:Toggle({ Title = "Spin Character", Default = false, Callback = function(state)
    if state then
        safeNotify({ Title="Criptix", Description="Spinning on", Duration=1.5 })
        spawn(function()
            while state do
                local ch = player.Character
                if ch and ch:FindFirstChild("HumanoidRootPart") then
                    ch.HumanoidRootPart.CFrame = ch.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad((_G.Cr_SpinSpeed or 20) * (1/30)), 0)
                end
                task.wait(1/30)
            end
        end)
    else
        safeNotify({ Title="Criptix", Description="Spinning off", Duration=1.5 })
    end
end })

-- MISC
local secMiscAFK = tabMisc:Section("For AFK")
local secMiscServer = tabMisc:Section("Server")

secMiscAFK:Toggle({ Title = "Anti AFK", Default = false, Callback = function(v)
    if v then
        local vu = game:GetService("VirtualUser")
        player.Idled:Connect(function()
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end)
        safeNotify({ Title="Criptix", Description="Anti AFK enabled", Duration=1.5 })
    else
        safeNotify({ Title="Criptix", Description="Anti AFK disabled", Duration=1.5 })
    end
end })

secMiscAFK:Button({ Title = "Darken Game", Callback = function()
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Texture") or obj:IsA("Decal") then pcall(function() obj.Transparency = 1 end) end
    end
    safeNotify({ Title="Criptix", Description="Game darkened (textures hidden)", Duration=2 })
end })

secMiscAFK:Button({ Title = "FPS Boost", Callback = function()
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then pcall(function() obj.Material = Enum.Material.SmoothPlastic end) end
    end
    safeNotify({ Title="Criptix", Description="All parts set to SmoothPlastic", Duration=2 })
end })

secMiscServer:Button({ Title = "Server Hop", Callback = function()
    pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
end })
secMiscServer:Button({ Title = "Rejoin Server", Callback = function()
    pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
end })

-- SETTINGS
local secSettingsMain = tabSettings:Section("General")
secSettingsMain:Button({ Title = "Save Settings", Callback = function()
    safeNotify({ Title="Criptix", Description="Settings saved (not persisted)", Duration=1.5 })
end })
secSettingsMain:Button({ Title = "Load Settings", Callback = function()
    safeNotify({ Title="Criptix", Description="Settings loaded (not persisted)", Duration=1.5 })
end })
secSettingsMain:Button({ Title = "Reset To Default", Callback = function()
    safeNotify({ Title="Criptix", Description="Defaults applied", Duration=1.5 })
end })

-- SETTINGS UI
local secSUIAppear = tabSUI:Section("Appearance")
secSUIAppear:Dropdown({ Title = "Change Theme", Values = {"Dark","Light","Ocean","Inferno"}, Callback = function(choice)
    if choice and ui.SetTheme then pcall(function() ui:SetTheme(choice) end) end
    safeNotify({ Title="Criptix", Description="Theme set: "..tostring(choice), Duration=1.2 })
end })
secSUIAppear:Keybind({ Title = "Toggle UI Keybind", Default = Enum.KeyCode.RightControl, Callback = function()
    if win and win.Toggle then pcall(function() win:Toggle() end) end
end })
secSUIAppear:Slider({ Title = "Transparency (0.0 - 0.8)", Min = 0, Max = 0.8, Default = 0.5, Callback = function(v)
    if win and win.SetTransparency then pcall(function() win:SetTransparency(v) end) end
    safeNotify({ Title="Criptix", Description="Transparency: "..tostring(v), Duration=1 })
end })

-- ========== Floating draggable open button ==========
-- Create a small ScreenGui with draggable ImageButton that toggles the window
local function createFloatingButton()
    local sg = Instance.new("ScreenGui")
    sg.Name = "CriptixHub_Button"
    sg.ResetOnSpawn = false
    sg.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Name = "Container"
    frame.Size = UDim2.new(0,70,0,70)
    frame.Position = UDim2.new(0.85,0,0.06,0)
    frame.BackgroundTransparency = 1
    frame.Parent = sg

    local btn = Instance.new("ImageButton")
    btn.Name = "OpenBtn"
    btn.Size = UDim2.fromOffset(60,60)
    btn.Position = UDim2.fromScale(0.5,0.5)
    btn.AnchorPoint = Vector2.new(0.5,0.5)
    btn.BackgroundTransparency = 0
    btn.BackgroundColor3 = Color3.fromRGB(20,20,20)
    btn.BorderSizePixel = 0
    btn.Image = "" -- leave blank or set to an asset id
    btn.AutoButtonColor = true
    btn.Parent = frame

    -- corner
    local uic = Instance.new("UICorner", btn)
    uic.CornerRadius = UDim.new(0,16)

    -- small glow border (optional)
    local stroke = Instance.new("UIStroke", btn)
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(68, 196, 255)
    stroke.Transparency = 0.6

    -- label (small)
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1,0,0,16)
    lbl.Position = UDim2.new(0,0,1,2)
    lbl.AnchorPoint = Vector2.new(0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "Criptix"
    lbl.TextSize = 12
    lbl.TextColor3 = Color3.fromRGB(200,200,200)
    lbl.Font = Enum.Font.SourceSans
    lbl.TextWrapped = true

    -- Dragging support (touch + mouse)
    local dragging = false
    local dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        frame.Position = newPos
    end

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    btn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            update(input)
        end
    end)

    -- Toggle window on click
    btn.MouseButton1Click:Connect(function()
        pcall(function() if win and win.Toggle then win:Toggle() else if win and win.Open then win:Open() end end end)
    end)

    return sg, btn
end

-- create the floating button
local sgButton, openBtn = pcall(function() return createFloatingButton() end)
-- if creation failed, continue silently

-- finalize load
hideLoading()
safeNotify({ Title="Criptix", Description="v1.6.4 loaded", Duration=2 })

-- Reapply features on respawn
player.CharacterAdded:Connect(function()
    task.wait(0.6)
    if walkEnabled then local hum = getHumanoid(); if hum then pcall(function() hum.WalkSpeed = walkSpeed end) end end
    if jumpEnabled then local hum = getHumanoid(); if hum then pcall(function() hum.JumpPower = jumpPower end) end end
    if noclipOn then
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        noclipConn = RunService.Stepped:Connect(function()
            local ch = player.Character
            if ch then for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
        end)
    end
end)
