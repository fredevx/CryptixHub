-- LocalScript -> StarterGui
-- Criptix Hub | v1.3.1 (WindUI Hotfix)
-- Loads WindUI from remote each time, waits for UI to initialize before creating tabs
-- Ensures WindUI User is disabled (no player data shown)

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

-- Config
local HUB_NAME = "Criptix Hub"
local VERSION = "v1.3.1"
local TITLE = HUB_NAME .. " | " .. VERSION .. " 🌐"
local WINDUI_URL = "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"

-- Persistence
local SETTINGS_FILE = "CriptixHub_v1_3_1_windui.json"
local hasFileApi = (type(writefile) == "function") and (type(readfile) == "function") and (type(isfile) == "function")

local Defaults = {
    theme = "Dark",
    ui_transparency = 0.12,
    toggle_key = "RightControl",
    save_settings = true,
    minimizer_pos = {x = 12, y = 24},

    walk_toggle = false, walk_speed = 32,
    jump_toggle = false, jump_power = 50,
    noclip = false, god = false,
    fly = false, fly_speed = 50,
    rainbow_body = false, spin_on = false, spin_speed = 20,
    anti_afk = true
}
local Settings = {}

-- Save/load helpers
local function loadFromFile()
    local ok, res = pcall(function()
        if hasFileApi then
            if isfile(SETTINGS_FILE) then
                return HttpService:JSONDecode(readfile(SETTINGS_FILE))
            end
            return nil
        else
            if getgenv().CriptixHub_Settings then
                return HttpService:JSONDecode(getgenv().CriptixHub_Settings)
            end
            return nil
        end
    end)
    if ok then return res else return nil end
end

local function saveToFile(tbl)
    local ok,err = pcall(function()
        local j = HttpService:JSONEncode(tbl)
        if hasFileApi then writefile(SETTINGS_FILE, j) else getgenv().CriptixHub_Settings = j end
    end)
    return ok,err
end

local function loadSettings()
    local s = loadFromFile()
    if type(s) == "table" then
        for k,v in pairs(Defaults) do Settings[k] = (s[k] ~= nil) and s[k] or v end
    else
        for k,v in pairs(Defaults) do Settings[k] = v end
    end
end

local function saveSettings()
    if Settings.save_settings then
        local ok,err = saveToFile(Settings)
        if ok then pcall(function() StarterGui:SetCore("SendNotification",{Title=HUB_NAME, Text="Settings saved", Duration=2}) end) else warn("[CriptixHub] Save failed:", err) end
    else
        pcall(function() StarterGui:SetCore("SendNotification",{Title=HUB_NAME, Text="Save disabled", Duration=2}) end)
    end
end

local function resetToDefaults()
    for k,v in pairs(Defaults) do Settings[k] = v end
    pcall(function() StarterGui:SetCore("SendNotification",{Title=HUB_NAME, Text="Defaults applied", Duration=2}) end)
end

-- Init settings
loadSettings()

-- ---------- Gameplay helpers ----------
local function getHumanoid()
    local c = player.Character
    if not c then return nil end
    return c:FindFirstChildWhichIsA("Humanoid")
end

local function safeSetWalkSpeed(s)
    local hum = getHumanoid()
    if hum then pcall(function() hum.WalkSpeed = s end) end
end
local function safeSetJumpPower(j)
    local hum = getHumanoid()
    if hum then pcall(function() hum.JumpPower = j end) end
end

-- NoClip
local noclipConn
local function setNoClip(enabled)
    if enabled then
        if noclipConn then return end
        noclipConn = RunService.Stepped:Connect(function()
            local ch = player.Character
            if ch then
                for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        local ch = player.Character
        if ch then
            for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end
        end
    end
end

-- God Mode
local godConn
local function setGodMode(enabled)
    if enabled then
        if godConn then return end
        local hum = getHumanoid()
        if hum then pcall(function() hum.MaxHealth = math.max(hum.MaxHealth, 1e6); hum.Health = hum.MaxHealth end) end
        godConn = RunService.Heartbeat:Connect(function()
            local h = getHumanoid()
            if h then pcall(function() h.Health = h.MaxHealth end) end
        end)
    else
        if godConn then godConn:Disconnect(); godConn = nil end
        local h = getHumanoid()
        if h then pcall(function() h.MaxHealth = 100; h.Health = math.clamp(h.Health,0,100) end) end
    end
end

-- Fly
local flyBV, flyBG, flyConn
local function setFly(enabled)
    if enabled then
        if flyConn then return end
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
        if not hrp then return end
        flyBV = Instance.new("BodyVelocity"); flyBV.MaxForce = Vector3.new(1e5,1e5,1e5); flyBV.Parent = hrp
        flyBG = Instance.new("BodyGyro"); flyBG.MaxTorque = Vector3.new(1e5,1e5,1e5); flyBG.Parent = hrp
        flyConn = RunService.Heartbeat:Connect(function()
            local cam = Workspace.CurrentCamera
            if not cam then return end
            local speed = tonumber(Settings.fly_speed) or Defaults.fly_speed
            local mv = Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv = mv + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv = mv - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv = mv - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv = mv + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then mv = mv + Vector3.new(0,-1,0) end
            if mv.Magnitude > 0 then mv = mv.Unit * speed end
            pcall(function() if flyBV then flyBV.Velocity = Vector3.new(mv.X, mv.Y, mv.Z) end end)
            if flyBG and player.Character and Workspace.CurrentCamera then
                local hrp2 = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChildWhichIsA("BasePart")
                if hrp2 then flyBG.CFrame = CFrame.new(hrp2.Position, hrp2.Position + Workspace.CurrentCamera.CFrame.LookVector) end
            end
        end)
    else
        if flyConn then flyConn:Disconnect(); flyConn = nil end
        if flyBV then pcall(function() flyBV:Destroy() end) end
        if flyBG then pcall(function() flyBG:Destroy() end) end
    end
end

-- Spin
local spinConn
local function setSpin(on, speed)
    if on then
        if spinConn then return end
        spinConn = RunService.Heartbeat:Connect(function(dt)
            local ch = player.Character
            if ch then
                local hrp = ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChildWhichIsA("BasePart")
                if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad((speed or 20) * dt), 0) end
            end
        end)
    else
        if spinConn then spinConn:Disconnect(); spinConn = nil end
    end
end

-- Rainbow
local rainbowConn
local function setRainbowBody(enabled)
    if enabled then
        if rainbowConn then return end
        rainbowConn = RunService.Heartbeat:Connect(function()
            local ch = player.Character
            if ch then
                local hue = (tick() % 5) / 5
                local col = Color3.fromHSV(hue, 0.8, 1)
                for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.Color = col end end
            end
        end)
    else
        if rainbowConn then rainbowConn:Disconnect(); rainbowConn = nil end
    end
end

-- Anti AFK
local antiAfkConn
local function setAntiAFK(enabled)
    if enabled then
        if antiAfkConn then return end
        antiAfkConn = RunService.Heartbeat:Connect(function()
            local cam = Workspace.CurrentCamera
            if cam and math.random() < 0.0025 then cam.CFrame = cam.CFrame * CFrame.Angles(0, 0.001, 0) end
        end)
    else
        if antiAfkConn then antiAfkConn:Disconnect(); antiAfkConn = nil end
    end
end

-- FPS Boost
local function doFPSBoost()
    for _,obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then pcall(function() obj.Enabled = false end)
        elseif obj:IsA("Decal") or obj:IsA("Texture") then pcall(function() obj.Transparency = 1 end) end
    end
    local L = game:GetService("Lighting")
    pcall(function()
        L.GlobalShadows = false
        L.EnvironmentDiffuseScale = 0
        L.FogEnd = 1e6
        L.Brightness = math.clamp(L.Brightness - 0.5, 0, 10)
    end)
    pcall(function() StarterGui:SetCore("SendNotification",{Title = HUB_NAME, Text = "FPS Boost applied (client-side)", Duration = 3}) end)
end

local function doRejoin() pcall(function() TeleportService:Teleport(game.PlaceId, player) end) end
local function doServerHop() pcall(function() TeleportService:Teleport(game.PlaceId, player) end) end

-- Fling helpers
local flingPart
local function createFlingPart()
    if flingPart and flingPart.Parent then return end
    flingPart = Instance.new("Part"); flingPart.Size = Vector3.new(1,1,1); flingPart.Transparency = 1; flingPart.Anchored = false; flingPart.CanCollide = false; flingPart.Parent = Workspace
end
local function doFlingOn(targetModel)
    if not targetModel then return end
    local hrp = targetModel:FindFirstChild("HumanoidRootPart") or targetModel:FindFirstChildWhichIsA("BasePart")
    if not hrp then return end
    local myChar = player.Character
    local myHrp = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChildWhichIsA("BasePart"))
    if not myHrp then return end
    createFlingPart()
    for i=1,6 do
        if not flingPart or not flingPart.Parent then break end
        local dir = (hrp.Position - myHrp.Position)
        if dir.Magnitude == 0 then break end
        local unit = dir.Unit
        pcall(function()
            flingPart.CFrame = myHrp.CFrame * CFrame.new(0,-2,-1)
            if flingPart:IsA("BasePart") then flingPart.Velocity = unit * (200 + i*50) end
        end)
        task.wait(0.06)
    end
    pcall(function() flingPart:Destroy() end)
    flingPart = nil
end

-- ---------- Load WindUI (remote, always) ----------
local ok, ui = pcall(function()
    return loadstring(game:HttpGet(WINDUI_URL, true))()
end)
if not ok or type(ui) ~= "table" then
    warn("[CriptixHub] Failed to load WindUI from:", WINDUI_URL)
    pcall(function() StarterGui:SetCore("SendNotification",{Title = HUB_NAME, Text = "Failed to load WindUI (HTTP disabled or URL down)", Duration = 4}) end)
    return
end

-- Create window with User disabled
local win = ui:CreateWindow({
    Title = TITLE,
    Icon = "",
    Author = "Criptix",
    Folder = "CriptixHub",
    Size = UDim2.fromOffset(720, 380),
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 200,
    Background = "",
    BackgroundImageTransparency = 0.42,
    HideSearchBar = true,
    ScrollBarEnabled = false,
    User = {
        Enabled = false,    -- NO user data shown
        Anonymous = false
    },
})

-- Ensure WindUI had time to mount internal structures
-- We wait briefly and then check for window readiness
local function waitForWindUIReady(timeout)
    timeout = timeout or 2
    local t0 = tick()
    while tick() - t0 < timeout do
        -- Some WindUI versions expose methods like win.IsReady or ui.IsReady; if not, the short wait helps
        if type(win) == "table" and win.Tab then
            return true
        end
        task.wait(0.05)
    end
    return false
end

-- Wait to avoid "This Tab is empty"
if not waitForWindUIReady(2) then
    -- still proceed but longer wait
    task.wait(0.25)
end

-- Edit open button (small round open button)
win:EditOpenButton({ Title = HUB_NAME, UseRound = true })

-- Short helper
local function clampNum(n,a,b) return math.clamp(tonumber(n) or 0, a, b) end

-- Create Tabs (after WindUI ready)
local Tabs = {}
local success, err = pcall(function()
    Tabs.Main = win:Tab({Title = "Main", Icon = "house"})
    Tabs.Funny = win:Tab({Title = "Funny", Icon = "mood-smile"})
    Tabs.Misc = win:Tab({Title = "Misc", Icon = "sparkles"})
    Tabs.Settings = win:Tab({Title = "Settings", Icon = "cog"})
    Tabs.Info = win:Tab({Title = "Info", Icon = "info-circle"})
    Tabs.SettingsUI = win:Tab({Title = "Settings UI", Icon = "paint"})
end)
if not success then
    warn("[CriptixHub] Failed to create tabs:", err)
    -- try a small delay and retry once
    task.wait(0.2)
    Tabs.Main = win:Tab({Title = "Main", Icon = "house"})
    Tabs.Funny = win:Tab({Title = "Funny", Icon = "mood-smile"})
    Tabs.Misc = win:Tab({Title = "Misc", Icon = "sparkles"})
    Tabs.Settings = win:Tab({Title = "Settings", Icon = "cog"})
    Tabs.Info = win:Tab({Title = "Info", Icon = "info-circle"})
    Tabs.SettingsUI = win:Tab({Title = "Settings UI", Icon = "paint"})
end

-- ---------- Info tab ----------
local Info = Tabs.Info
Info:Label({Title = "Credits"})
Info:Label({Title = "Principal Developer (Freddy Bear)"})
Info:Label({Title = "Other Developers (snitadd, chatgpt, wind)"})
Info:Label({Title = "Discord: paste your invite link here"})
Info:Label({Title = "Version: "..VERSION})

-- ---------- Main tab ----------
local Main = Tabs.Main
Main:Label({Title = "Basic"})
Main:Toggle({
    Title = "Enable Custom WalkSpeed",
    Type = "Toggle",
    Default = Settings.walk_toggle,
    Callback = function(val)
        Settings.walk_toggle = val
        if val then safeSetWalkSpeed(clampNum(Settings.walk_speed, 16, 200)) else safeSetWalkSpeed(16) end
    end
})
Main:Slider({
    Title = "WalkSpeed (16-200)",
    Step = 1,
    Value = {Min = 16, Max = 200, Default = Settings.walk_speed},
    Callback = function(value)
        Settings.walk_speed = clampNum(value, 16, 200)
        if Settings.walk_toggle then safeSetWalkSpeed(Settings.walk_speed) end
    end
})

Main:Toggle({
    Title = "Enable Custom JumpPower",
    Type = "Toggle",
    Default = Settings.jump_toggle,
    Callback = function(val)
        Settings.jump_toggle = val
        if val then safeSetJumpPower(clampNum(Settings.jump_power, 50, 500)) else safeSetJumpPower(50) end
    end
})
Main:Slider({
    Title = "JumpPower (50-500)",
    Step = 1,
    Value = {Min = 50, Max = 500, Default = Settings.jump_power},
    Callback = function(value)
        Settings.jump_power = clampNum(value, 50, 500)
        if Settings.jump_toggle then safeSetJumpPower(Settings.jump_power) end
    end
})

Main:Label({Title = "Advanced"})
Main:Toggle({
    Title = "NoClip (client)",
    Type = "Toggle",
    Default = Settings.noclip,
    Callback = function(v) Settings.noclip = v; setNoClip(v) end
})
Main:Toggle({
    Title = "God Mode (client)",
    Type = "Toggle",
    Default = Settings.god,
    Callback = function(v) Settings.god = v; setGodMode(v) end
})

Main:Label({Title = "Fly"})
Main:Toggle({
    Title = "Fly (client)",
    Type = "Toggle",
    Default = Settings.fly,
    Callback = function(v) Settings.fly = v; setFly(v) end
})
Main:Slider({
    Title = "Fly Speed (16-200)",
    Step = 1,
    Value = {Min = 16, Max = 200, Default = Settings.fly_speed},
    Callback = function(value) Settings.fly_speed = clampNum(value, 16, 200) end
})

-- ---------- Funny tab ----------
local Funny = Tabs.Funny
Funny:Label({Title = ":)"})
Funny:Button({
    Title = "Walk on Wall (attempt)",
    Callback = function() ui:Notify({Title = HUB_NAME, Description = "Walk on Wall attempted (game dependent)", Duration = 2}) end
})
-- Player dropdown + fake kick
local playerNames = {}
for _,pl in ipairs(Players:GetPlayers()) do if pl ~= player then table.insert(playerNames, pl.Name) end end
local dd = Funny:Dropdown({
    Title = "Select Player",
    Multi = false,
    List = playerNames,
    Value = playerNames[1] or "No Players"
})
Funny:Button({
    Title = "Fake Kick Player",
    Callback = function()
        local targetName = dd() or "No Players"
        if targetName == "No Players" then ui:Notify({Title=HUB_NAME, Description="No players available", Duration=2}) return end
        ui:Notify({Title = HUB_NAME, Description = "Fake kicked " .. tostring(targetName), Duration = 2})
    end
})

Funny:Label({Title = "Character"})
Funny:Toggle({
    Title = "Rainbow Body",
    Type = "Toggle",
    Default = Settings.rainbow_body,
    Callback = function(v) Settings.rainbow_body = v; setRainbowBody(v) end
})
Funny:Toggle({
    Title = "Spin Character",
    Type = "Toggle",
    Default = Settings.spin_on,
    Callback = function(v) Settings.spin_on = v; setSpin(v, Settings.spin_speed) end
})
Funny:Slider({
    Title = "Spin Speed (1-100)",
    Step = 1,
    Value = {Min = 1, Max = 100, Default = Settings.spin_speed},
    Callback = function(val) Settings.spin_speed = clampNum(val,1,100); if Settings.spin_on then setSpin(true, Settings.spin_speed) end end
})
Funny:Button({
    Title = "Enable Touch/Click Fling (10s)",
    Callback = function()
        ui:Notify({Title=HUB_NAME, Description="Fling active: click/touch a target (10s)", Duration=3})
        local mouse = player:GetMouse()
        local conn
        conn = mouse.Button1Down:Connect(function()
            local t = mouse.Target
            if t then
                local model = t:FindFirstAncestorOfClass("Model")
                if model and model ~= player.Character then doFlingOn(model) end
            end
        end)
        task.delay(10, function() if conn then conn:Disconnect() end; ui:Notify({Title=HUB_NAME, Description="Fling disabled", Duration=2}) end)
    end
})

-- ---------- Misc tab ----------
local Misc = Tabs.Misc
Misc:Label({Title = "For AFK"})
Misc:Toggle({
    Title = "Anti AFK",
    Type = "Toggle",
    Default = Settings.anti_afk,
    Callback = function(v) Settings.anti_afk = v; setAntiAFK(v) end
})
Misc:Button({
    Title = "FPS Boost (client-side)",
    Callback = function() doFPSBoost() end
})
Misc:Label({Title = "Server"})
Misc:Button({
    Title = "Server Hop (attempt)",
    Callback = function() doServerHop() end
})
Misc:Button({
    Title = "Rejoin Server",
    Callback = function() doRejoin() end
})

-- ---------- Settings tab ----------
local SettingsTab = Tabs.Settings
SettingsTab:Button({
    Title = "Save Settings",
    Callback = function() saveSettings() end
})
SettingsTab:Button({
    Title = "Load Settings",
    Callback = function()
        loadSettings()
        if Settings.walk_toggle then safeSetWalkSpeed(Settings.walk_speed) else safeSetWalkSpeed(16) end
        if Settings.jump_toggle then safeSetJumpPower(Settings.jump_power) else safeSetJumpPower(50) end
        setNoClip(Settings.noclip)
        setGodMode(Settings.god)
        setFly(Settings.fly)
        setRainbowBody(Settings.rainbow_body)
        setSpin(Settings.spin_on, Settings.spin_speed)
        setAntiAFK(Settings.anti_afk)
        ui:Notify({Title = HUB_NAME, Description = "Settings loaded", Duration = 2})
    end
})
SettingsTab:Button({
    Title = "Reset To Default",
    Callback = function()
        resetToDefaults()
        ui:Notify({Title = HUB_NAME, Description = "Defaults applied", Duration = 2})
    end
})

-- ---------- Settings UI tab ----------
local SUI = Tabs.SettingsUI
SUI:Dropdown({
    Title = "Change Theme",
    Multi = false,
    List = {"Dark","Light","Ocean","Inferno","Toxic","Royal","Cybergold"},
    Callback = function(choice)
        if choice then ui:SetTheme(choice) end
        Settings.theme = choice or Defaults.theme
    end
})
SUI:Button({
    Title = "Set Toggle Key (press then press a key)",
    Callback = function()
        ui:Notify({Title=HUB_NAME, Description="Press a keyboard key to set toggle", Duration=3})
        local conn
        conn = UserInputService.InputBegan:Connect(function(inp, processed)
            if processed then return end
            if inp.UserInputType == Enum.UserInputType.Keyboard then
                Settings.toggle_key = inp.KeyCode.Name
                ui:Notify({Title=HUB_NAME, Description="Toggle key set to "..inp.KeyCode.Name, Duration=2})
                conn:Disconnect()
            end
        end)
    end
})
SUI:Slider({
    Title = "Transparency (0.0 - 0.8)",
    Step = 0.1,
    Value = {Min = 0.0, Max = 0.8, Default = Settings.ui_transparency},
    Callback = function(val)
        Settings.ui_transparency = tonumber(val) or Defaults.ui_transparency
        if win and win.SetTransparency then pcall(function() win:SetTransparency(Settings.ui_transparency) end) end
    end
})

-- ---------- Toggle key wiring ----------
local function getToggleKeyEnum(name)
    for _,k in ipairs(Enum.KeyCode:GetEnumItems()) do if k.Name == tostring(name) then return k end end
    return Enum.KeyCode.RightControl
end
local toggleKeyEnum = getToggleKeyEnum(Settings.toggle_key or Defaults.toggle_key)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == toggleKeyEnum then
        if win and win.Toggle then pcall(function() win:Toggle() end) end
    end
end)
spawn(function()
    while true do
        local ek = getToggleKeyEnum(Settings.toggle_key or Defaults.toggle_key)
        if ek ~= toggleKeyEnum then toggleKeyEnum = ek end
        task.wait(1)
    end
end)

-- ---------- Apply persisted features ----------
if Settings.walk_toggle then safeSetWalkSpeed(Settings.walk_speed) end
if Settings.jump_toggle then safeSetJumpPower(Settings.jump_power) end
setNoClip(Settings.noclip)
setGodMode(Settings.god)
setFly(Settings.fly)
setRainbowBody(Settings.rainbow_body)
setSpin(Settings.spin_on, Settings.spin_speed)
setAntiAFK(Settings.anti_afk)

-- Reapply on respawn
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

-- Save on close
game:BindToClose(function()
    if Settings.save_settings then pcall(function() saveSettings() end) end
end)

-- Final notify: everything initialized
ui:Notify({Title = HUB_NAME, Description = "Criptix Hub started", Duration = 3})
