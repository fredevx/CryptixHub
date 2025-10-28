-- Criptix Hub | v1.6 (WindUI real structure)
-- Functional: Window -> Tab -> Section -> Elements
-- Dev: Freddy Bear

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Persistent loading message
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

-- Load WindUI (official release raw)
local ok, ui = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)
if not ok or type(ui) ~= "table" then
    hideLoading()
    warn("[CriptixHub] Failed to load WindUI")
    return
end

-- Create window
local win = ui:CreateWindow({
    Title = "Criptix Hub | v1.6 🌐",
    Size = UDim2.fromOffset(760, 420),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 200,
    User = { Enabled = false, Anonymous = false }
})

-- Ensure edit/open button exists (some WindUI variants)
pcall(function()
    if win.EditOpenButton then win:EditOpenButton({ Title = "Criptix Hub", UseRound = true }) end
end)

-- Create tabs and sections using WindUI real API
-- Info
local tabInfo = win:Tab("Info")
local secInfo = tabInfo:Section("About")
secInfo:Label("Criptix Hub | v1.6")
secInfo:Label("Principal Developer: Freddy Bear")
secInfo:Label("Other Developers: snitadd, chatgpt, wind")
secInfo:Button("Copy Discord Invite", function()
    pcall(function() setclipboard("https://discord.gg/yourinvite") end)
    ui:Notify({ Title = "Criptix", Description = "Discord invite copied", Duration = 2 })
end)

-- Main
local tabMain = win:Tab("Main")
local secBasic = tabMain:Section("Basic")
local secAdvanced = tabMain:Section("Advanced")
local secFly = tabMain:Section("Fly")

-- Helpers
local function getHumanoid()
    local ch = player.Character
    if not ch then return nil end
    return ch:FindFirstChildOfClass("Humanoid")
end

-- WalkSpeed slider + toggle
local walkEnabled = false
local walkSpeed = 32
secBasic:Toggle("Enable Custom WalkSpeed", false, function(t)
    walkEnabled = t
    if not walkEnabled then
        local hum = getHumanoid()
        if hum then pcall(function() hum.WalkSpeed = 16 end) end
    else
        local hum = getHumanoid()
        if hum then pcall(function() hum.WalkSpeed = walkSpeed end) end
    end
end)
secBasic:Slider("Walk Speed (16-200)", 16, 200, 32, function(val)
    walkSpeed = math.clamp(tonumber(val) or 32, 16, 200)
    if walkEnabled then
        local hum = getHumanoid()
        if hum then pcall(function() hum.WalkSpeed = walkSpeed end) end
    end
end)

-- JumpPower
local jumpEnabled = false
local jumpPower = 50
secBasic:Toggle("Enable Custom JumpPower", false, function(t)
    jumpEnabled = t
    if not jumpEnabled then
        local hum = getHumanoid()
        if hum then pcall(function() hum.JumpPower = 50 end) end
    else
        local hum = getHumanoid()
        if hum then pcall(function() hum.JumpPower = jumpPower end) end
    end
end)
secBasic:Slider("Jump Power (50-500)", 50, 500, 50, function(val)
    jumpPower = math.clamp(tonumber(val) or 50, 50, 500)
    if jumpEnabled then
        local hum = getHumanoid()
        if hum then pcall(function() hum.JumpPower = jumpPower end) end
    end
end)

-- Advanced: noclip & god
local noclipConn
local noclipOn = false
secAdvanced:Toggle("No Clip (client)", false, function(v)
    noclipOn = v
    if noclipOn then
        noclipConn = RunService.Stepped:Connect(function()
            local ch = player.Character
            if ch then
                for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        local ch = player.Character
        if ch then for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
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
    else
        if godConn then godConn:Disconnect(); godConn = nil end
        local h = getHumanoid()
        if h then pcall(function() h.MaxHealth = 100; h.Health = math.clamp(h.Health,0,100) end) end
    end
end)

-- Fly section: toggle and speed
local flyOn = false
local flySpeed = 50
local flyBV, flyBG, flyConn
secFly:Toggle("Fly (client)", false, function(v)
    flyOn = v
    if flyOn then
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
        if not hrp then ui:Notify({Title="Criptix", Description="No HumanoidRootPart found", Duration=2}); return end
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
            if mv.Magnitude > 0 then mv = mv.Unit * (flySpeed) end
            pcall(function() if flyBV then flyBV.Velocity = mv end end)
            if flyBG and player.Character and Workspace.CurrentCamera then
                local hrp2 = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChildWhichIsA("BasePart")
                if hrp2 then flyBG.CFrame = CFrame.new(hrp2.Position, hrp2.Position + Workspace.CurrentCamera.CFrame.LookVector) end
            end
        end)
        ui:Notify({ Title="Criptix", Description="Fly enabled", Duration=2 })
    else
        if flyConn then flyConn:Disconnect(); flyConn = nil end
        if flyBV then pcall(function() flyBV:Destroy() end) end
        if flyBG then pcall(function() flyBG:Destroy() end) end
        ui:Notify({ Title="Criptix", Description="Fly disabled", Duration=2 })
    end
end)

secFly:Slider("Fly Speed (16-200)", 16, 200, 50, function(val)
    flySpeed = math.clamp(tonumber(val) or 50, 16, 200)
end)

-- Funny tab
local tabFunny = win:Tab("Funny")
local secFunnyA = tabFunny:Section(":)")
local secFunnyB = tabFunny:Section("Character")

secFunnyA:Button("Walk on Wall (toggle attempt)", function()
    ui:Notify({ Title="Criptix", Description="Walk on Wall attempted (game-dependent)", Duration=2 })
end)

-- Touch / Click Fling (activate for 10s)
secFunnyA:Button("Enable Touch Fling (10s)", function()
    ui:Notify({ Title="Criptix", Description="Touch/Click fling active (10s)", Duration=2 })
    local mouse = player:GetMouse()
    local conn
    conn = mouse.Button1Down:Connect(function()
        local t = mouse.Target
        if t then
            local model = t:FindFirstAncestorOfClass("Model")
            if model and model ~= player.Character then
                -- simple fling: set velocity on a temp part
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

-- Character options
secFunnyB:Toggle("Rainbow Body", false, function(v)
    local conn
    if v then
        conn = RunService.Heartbeat:Connect(function()
            local ch = player.Character
            if ch then
                local hue = (tick() % 5) / 5
                local col = Color3.fromHSV(hue, 0.8, 1)
                for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.Color = col end end
            end
        end)
        ui:Notify({ Title="Criptix", Description="Rainbow enabled", Duration=2 })
        -- store to stop later
        player:SetAttribute("Cr_RainbowConn", true)
        _G.__Cr_Rainbow = conn
    else
        if _G.__Cr_Rainbow then _G.__Cr_Rainbow:Disconnect(); _G.__Cr_Rainbow = nil end
        ui:Notify({ Title="Criptix", Description="Rainbow disabled", Duration=2 })
    end
end)

secFunnyB:Slider("Spin Speed (1-100)", 1, 100, 20, function(val)
    _G.Cr_SpinSpeed = math.clamp(tonumber(val) or 20, 1, 100)
end)
secFunnyB:Toggle("Spin Character", false, function(v)
    if v then
        ui:Notify({ Title="Criptix", Description="Spinning on", Duration=2 })
        spawn(function()
            while v do
                local ch = player.Character
                if ch and ch:FindFirstChild("HumanoidRootPart") then
                    ch.HumanoidRootPart.CFrame = ch.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad((_G.Cr_SpinSpeed or 20) * (1/30)), 0)
                end
                task.wait(1/30)
            end
        end)
    else
        ui:Notify({ Title="Criptix", Description="Spinning off", Duration=2 })
    end
end)

-- Misc tab
local tabMisc = win:Tab("Misc")
local secMiscA = tabMisc:Section("For AFK")
local secMiscB = tabMisc:Section("Server")

secMiscA:Toggle("Anti AFK", false, function(v)
    if v then
        local vu = game:GetService("VirtualUser")
        player.Idled:Connect(function()
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end)
        ui:Notify({ Title="Criptix", Description="Anti AFK enabled", Duration=2 })
    else
        ui:Notify({ Title="Criptix", Description="Anti AFK disabled", Duration=2 })
    end
end)

-- Darken Game (previous FPS Boost behavior)
secMiscA:Button("Darken Game", function()
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Texture") or obj:IsA("Decal") then
            pcall(function() obj.Transparency = 1 end)
        end
    end
    ui:Notify({ Title="Criptix", Description="Game darkened (textures hidden)", Duration=2 })
end)

-- New FPS Boost: set parts to SmoothPlastic
secMiscA:Button("FPS Boost", function()
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            pcall(function() obj.Material = Enum.Material.SmoothPlastic end)
        end
    end
    ui:Notify({ Title="Criptix", Description="All parts set to SmoothPlastic", Duration=2 })
end)

secMiscB:Button("Server Hop", function()
    -- best-effort: Teleport to same place (may open matchmaking or fail on studio)
    pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
end)
secMiscB:Button("Rejoin Server", function()
    pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
end)

-- Settings tab
local tabSettings = win:Tab("Settings")
local secSettings = tabSettings:Section("General")
secSettings:Button("Save Settings", function()
    ui:Notify({ Title="Criptix", Description="Settings saved (not implemented file API)", Duration=2 })
end)
secSettings:Button("Load Settings", function()
    ui:Notify({ Title="Criptix", Description="Settings loaded (not implemented file API)", Duration=2 })
end)
secSettings:Button("Reset To Default", function()
    ui:Notify({ Title="Criptix", Description="Defaults applied", Duration=2 })
end)

-- Settings UI
local tabSUI = win:Tab("Settings UI")
local secSUI = tabSUI:Section("Appearance")
secSUI:Dropdown("Change Theme", {"Dark","Light","Ocean","Inferno"}, function(choice)
    if choice and ui.SetTheme then pcall(function() ui:SetTheme(choice) end) end
    ui:Notify({ Title="Criptix", Description="Theme: "..tostring(choice), Duration=2 })
end)
secSUI:Keybind("Toggle UI Keybind", Enum.KeyCode.RightControl, function()
    if win and win.Toggle then pcall(function() win:Toggle() end) end
end)
secSUI:Slider("Transparency (0.0 - 0.8)", 0, 0.8, 0.5, function(v)
    if win and win.SetTransparency then pcall(function() win:SetTransparency(v) end) end
    ui:Notify({ Title="Criptix", Description="Transparency set to "..tostring(v), Duration=1 })
end)

-- Finalize
hideLoading()
ui:Notify({ Title="Criptix", Description="v1.6 loaded successfully", Duration=3 })

-- Reapply features on respawn
player.CharacterAdded:Connect(function()
    task.wait(0.6)
    if walkEnabled then
        local hum = getHumanoid()
        if hum then pcall(function() hum.WalkSpeed = walkSpeed end) end
    end
    if jumpEnabled then
        local hum = getHumanoid()
        if hum then pcall(function() hum.JumpPower = jumpPower end) end
    end
    if noclipOn then
        -- re-enable noclip by reconnecting
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        noclipConn = RunService.Stepped:Connect(function()
            local ch = player.Character
            if ch then for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
        end)
    end
    if flyOn then
        -- simple approach: re-toggle fly to re-create body movers
        -- user can re-enable via toggle manually if needed
    end
end)
