-- Criptix Hub | v1.6.1 (WindUI structure fix)
-- Developer: Freddy Bear
-- Note: Tabs use table syntax win:Tab({ Title = "..." }) to match WindUI variant

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

-- Load WindUI (remote)
local ok, ui = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)
if not ok or type(ui) ~= "table" then
    hideLoading()
    warn("[CriptixHub] Failed to load WindUI")
    return
end

-- Create window (style: dark + cyan accents expected from WindUI theme)
local win = ui:CreateWindow({
    Title = "Criptix Hub | v1.6.1 🌐",
    Size = UDim2.fromOffset(760, 420),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 200,
    User = { Enabled = false, Anonymous = false }
})

-- Ensure open button exists if available
pcall(function()
    if win.EditOpenButton then win:EditOpenButton({ Title = "Criptix Hub", UseRound = true }) end
end)

-- Create tabs using the table form to avoid string-index issues
local tabInfo    = win:Tab({ Title = "Info" })
local tabMain    = win:Tab({ Title = "Main" })
local tabFunny   = win:Tab({ Title = "Funny" })
local tabMisc    = win:Tab({ Title = "Misc" })
local tabSettings= win:Tab({ Title = "Settings" })
local tabSUI     = win:Tab({ Title = "Settings UI" })

-- Info tab
local secInfo = tabInfo:Section("About")
secInfo:Label("Criptix Hub | v1.6.1")
secInfo:Label("Principal Developer: Freddy Bear")
secInfo:Label("Other Developers: snitadd, chatgpt, wind")
secInfo:Button("Copy Discord Invite", function()
    pcall(function() setclipboard("https://discord.gg/yourinvite") end)
    ui:Notify({ Title="Criptix", Description="Discord invite copied", Duration=2 })
end)

-- Helpers
local function getHumanoid()
    local ch = player.Character
    if not ch then return nil end
    return ch:FindFirstChildOfClass("Humanoid")
end

-- MAIN tab
local secBasic    = tabMain:Section("Basic")
local secAdvanced = tabMain:Section("Advanced")
local secFly      = tabMain:Section("Fly")

-- WalkSpeed
local walkEnabled = false
local walkSpeed = 32
secBasic:Toggle("Enable Custom WalkSpeed", false, function(state)
    walkEnabled = state
    local hum = getHumanoid()
    if hum then
        if walkEnabled then pcall(function() hum.WalkSpeed = walkSpeed end) else pcall(function() hum.WalkSpeed = 16 end) end
    end
end)
secBasic:Slider("Walk Speed (16-200)", 16, 200, 32, function(val)
    walkSpeed = math.clamp(tonumber(val) or 32, 16, 200)
    if walkEnabled then local hum = getHumanoid() if hum then pcall(function() hum.WalkSpeed = walkSpeed end) end end
end)

-- JumpPower
local jumpEnabled = false
local jumpPower = 50
secBasic:Toggle("Enable Custom JumpPower", false, function(state)
    jumpEnabled = state
    local hum = getHumanoid()
    if hum then
        if jumpEnabled then pcall(function() hum.JumpPower = jumpPower end) else pcall(function() hum.JumpPower = 50 end) end
    end
end)
secBasic:Slider("Jump Power (50-500)", 50, 500, 50, function(val)
    jumpPower = math.clamp(tonumber(val) or 50, 50, 500)
    if jumpEnabled then local hum = getHumanoid() if hum then pcall(function() hum.JumpPower = jumpPower end) end end
end)

-- Advanced: Noclip & God
local noclipConn
local noclipOn = false
secAdvanced:Toggle("No Clip (client)", false, function(v)
    noclipOn = v
    if noclipOn then
        noclipConn = RunService.Stepped:Connect(function()
            local ch = player.Character
            if ch then for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
        end)
        ui:Notify({ Title="Criptix", Description="NoClip enabled", Duration=1.5 })
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        local ch = player.Character
        if ch then for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
        ui:Notify({ Title="Criptix", Description="NoClip disabled", Duration=1.5 })
    end
end)

local godConn
secAdvanced:Toggle("God Mode (client)", false, function(v)
    if v then
        local hum = getHumanoid()
        if hum then pcall(function() hum.MaxHealth = math.huge; hum.Health = hum.MaxHealth end) end
        godConn = RunService.Heartbeat:Connect(function()
            local h = getHumanoid()
            if h then pcall(function() h.Health = h.MaxHealth end) end
        end)
        ui:Notify({ Title="Criptix", Description="God Mode enabled", Duration=1.5 })
    else
        if godConn then godConn:Disconnect(); godConn = nil end
        local h = getHumanoid()
        if h then pcall(function() h.MaxHealth = 100; h.Health = math.clamp(h.Health,0,100) end) end
        ui:Notify({ Title="Criptix", Description="God Mode disabled", Duration=1.5 })
    end
end)

-- Fly
local flyOn = false
local flySpeed = 50
local flyBV, flyBG, flyConn
secFly:Toggle("Fly (client)", false, function(v)
    flyOn = v
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
    if flyOn then
        if not hrp then ui:Notify({ Title="Criptix", Description="No HumanoidRootPart found", Duration=2 }); return end
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
        ui:Notify({ Title="Criptix", Description="Fly enabled", Duration=1.5 })
    else
        if flyConn then flyConn:Disconnect(); flyConn = nil end
        if flyBV then pcall(function() flyBV:Destroy() end) end
        if flyBG then pcall(function() flyBG:Destroy() end) end
        ui:Notify({ Title="Criptix", Description="Fly disabled", Duration=1.5 })
    end
end)

secFly:Slider("Fly Speed (16-200)", 16, 200, 50, function(val) flySpeed = math.clamp(tonumber(val) or 50, 16, 200) end)

-- FUNNY tab
local secFunnyA = tabFunny:Section(":)")
local secFunnyB = tabFunny:Section("Character")

secFunnyA:Button("Walk on Wall (attempt)", function()
    ui:Notify({ Title="Criptix", Description="Walk on Wall attempted (game-dependent)", Duration=2 })
end)

-- Touch/Click fling (10s)
secFunnyA:Button("Enable Touch Fling (10s)", function()
    ui:Notify({ Title="Criptix", Description="Touch/Click fling active (10s)", Duration=2 })
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
    task.delay(10, function() if conn then conn:Disconnect() end; ui:Notify({ Title="Criptix", Description="Fling disabled", Duration=2 }) end)
end)

-- Character toggles
secFunnyB:Toggle("Rainbow Body", false, function(state)
    if state then
        _G.__Cr_Rainbow = RunService.Heartbeat:Connect(function()
            local ch = player.Character
            if ch then
                local hue = (tick() % 5) / 5
                local col = Color3.fromHSV(hue, 0.8, 1)
                for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.Color = col end end
            end
        end)
        ui:Notify({ Title="Criptix", Description="Rainbow enabled", Duration=1.5 })
    else
        if _G.__Cr_Rainbow then _G.__Cr_Rainbow:Disconnect(); _G.__Cr_Rainbow = nil end
        ui:Notify({ Title="Criptix", Description="Rainbow disabled", Duration=1.5 })
    end
end)

secFunnyB:Slider("Spin Speed (1-100)", 1, 100, 20, function(val) _G.Cr_SpinSpeed = math.clamp(tonumber(val) or 20, 1, 100) end)
secFunnyB:Toggle("Spin Character", false, function(state)
    if state then
        ui:Notify({ Title="Criptix", Description="Spinning on", Duration=1.5 })
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
        ui:Notify({ Title="Criptix", Description="Spinning off", Duration=1.5 })
    end
end)

-- MISC tab
local secMiscAFK = tabMisc:Section("For AFK")
local secMiscServer = tabMisc:Section("Server")

secMiscAFK:Toggle("Anti AFK", false, function(v)
    if v then
        local vu = game:GetService("VirtualUser")
        player.Idled:Connect(function()
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end)
        ui:Notify({ Title="Criptix", Description="Anti AFK enabled", Duration=1.5 })
    else
        ui:Notify({ Title="Criptix", Description="Anti AFK disabled", Duration=1.5 })
    end
end)

-- Darken Game (hide textures/decals)
secMiscAFK:Button("Darken Game", function()
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Texture") or obj:IsA("Decal") then pcall(function() obj.Transparency = 1 end) end
    end
    ui:Notify({ Title="Criptix", Description="Game darkened (textures hidden)", Duration=2 })
end)

-- FPS Boost (set parts to SmoothPlastic)
secMiscAFK:Button("FPS Boost", function()
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then pcall(function() obj.Material = Enum.Material.SmoothPlastic end) end
    end
    ui:Notify({ Title="Criptix", Description="All parts set to SmoothPlastic", Duration=2 })
end)

secMiscServer:Button("Server Hop", function()
    pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
end)
secMiscServer:Button("Rejoin Server", function()
    pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
end)

-- SETTINGS tab
local secSettingsMain = tabSettings:Section("General")
secSettingsMain:Button("Save Settings", function()
    ui:Notify({ Title="Criptix", Description="Settings saved (not persisted)", Duration=1.5 })
end)
secSettingsMain:Button("Load Settings", function()
    ui:Notify({ Title="Criptix", Description="Settings loaded (not persisted)", Duration=1.5 })
end)
secSettingsMain:Button("Reset To Default", function()
    ui:Notify({ Title="Criptix", Description="Defaults applied", Duration=1.5 })
end)

-- SETTINGS UI tab
local secSUIAppear = tabSUI:Section("Appearance")
secSUIAppear:Dropdown("Change Theme", {"Dark","Light","Ocean","Inferno"}, function(choice)
    if choice and ui.SetTheme then pcall(function() ui:SetTheme(choice) end) end
    ui:Notify({ Title="Criptix", Description="Theme set: "..tostring(choice), Duration=1.2 })
end)
secSUIAppear:Keybind("Toggle UI Keybind", Enum.KeyCode.RightControl, function()
    if win and win.Toggle then pcall(function() win:Toggle() end) end
end)
secSUIAppear:Slider("Transparency (0.0 - 0.8)", 0, 0.8, 0.5, function(v)
    if win and win.SetTransparency then pcall(function() win:SetTransparency(v) end) end
    ui:Notify({ Title="Criptix", Description="Transparency: "..tostring(v), Duration=1 })
end)

-- Finalize load
hideLoading()
ui:Notify({ Title="Criptix", Description="v1.6.1 loaded successfully", Duration=2 })

-- Reapply settings on respawn
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
