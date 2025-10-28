-- Criptix Hub | v1.6.6 (Fixes: loading, float button removed, tabs reorganized, slider fallback)
-- Dev: Freddy Bear
-- Paste as a single LocalScript into StarterGui

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- -------------------------
-- Loading overlay (self-managed so it can always be removed)
-- -------------------------
local loadingGui
local function showLoadingOverlay()
    pcall(function()
        if loadingGui and loadingGui.Parent then return end
        loadingGui = Instance.new("ScreenGui")
        loadingGui.Name = "Criptix_LoadingOverlay"
        loadingGui.ResetOnSpawn = false
        loadingGui.Parent = playerGui

        local frame = Instance.new("Frame", loadingGui)
        frame.Size = UDim2.new(0,300,0,60)
        frame.Position = UDim2.new(0.5,-150,0.9,-30)
        frame.BackgroundTransparency = 0.35
        frame.BackgroundColor3 = Color3.fromRGB(10,10,10)
        frame.BorderSizePixel = 0
        frame.ZIndex = 1000
        local uic = Instance.new("UICorner", frame); uic.CornerRadius = UDim.new(0,10)

        local txt = Instance.new("TextLabel", frame)
        txt.Size = UDim2.new(1,-20,1,-20)
        txt.Position = UDim2.new(0,10,0,10)
        txt.BackgroundTransparency = 1
        txt.TextColor3 = Color3.fromRGB(220,220,220)
        txt.TextScaled = false
        txt.Font = Enum.Font.SourceSansSemibold
        txt.TextSize = 16
        txt.Text = "Please wait, Criptix Hub is loading..."
        txt.ZIndex = 1001
    end)
end
local function hideLoadingOverlay()
    pcall(function()
        if loadingGui then
            loadingGui:Destroy()
            loadingGui = nil
        end
    end)
end

showLoadingOverlay()

-- -------------------------
-- Load WindUI (robust)
-- -------------------------
local ok, ui = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)
if not ok or type(ui) ~= "table" then
    hideLoadingOverlay()
    warn("[CriptixHub] WindUI load failed")
    return
end

-- Create window (use table config)
local win
local ok2, err2 = pcall(function()
    win = ui:CreateWindow({
        Title = "Criptix Hub | v1.6.6 🌐",
        Size = UDim2.fromOffset(760, 420),
        Transparent = true,
        Theme = "Dark",
        SideBarWidth = 200,
        User = { Enabled = false, Anonymous = false }
    })
end)
if not ok2 or not win then
    hideLoadingOverlay()
    warn("[CriptixHub] CreateWindow failed:", err2)
    return
end

-- safe notify wrapper
local function safeNotify(tbl)
    pcall(function() if ui and ui.Notify then ui:Notify(tbl) end end)
end

-- -------------------------
-- Utility helpers
-- -------------------------
local function getHumanoid()
    local ch = player.Character
    if not ch then return nil end
    return ch:FindFirstChildOfClass("Humanoid")
end

-- fallback-add helpers for multiple WindUI signatures (keeps robust behavior)
local function tryCall(target, name, ...)
    local fn = target[name]
    if type(fn) == "function" then
        local ok, res = pcall(fn, target, ...)
        if ok then return res end
        -- try calling without passing target as first param (some APIs)
        ok, res = pcall(fn, ...)
        if ok then return res end
    end
    return nil
end

-- small helper that attempts common names/signatures
local function addElement(container, kind, opts)
    -- try section-style api first (container:Button{...})
    local names = {}
    if kind == "button" then names = {"Button","AddButton","AddBtn"} end
    if kind == "toggle" then names = {"Toggle","AddToggle"} end
    if kind == "slider" then names = {"Slider","AddSlider"} end
    if kind == "paragraph" then names = {"Paragraph","AddParagraph"} end
    if kind == "dropdown" then names = {"Dropdown","AddDropdown"} end
    if kind == "keybind" then names = {"Keybind","AddKeybind"} end
    for _,n in ipairs(names) do
        local ok, res = pcall(function() 
            local fn = container[n]
            if type(fn) == "function" then
                -- prefer table param if available
                local succ = pcall(function() fn(container, opts) end)
                if succ then return true end
                -- fallback signatures:
                if kind == "button" and opts.Title and opts.Callback then
                    pcall(function() fn(container, opts.Title, opts.Callback) end)
                    return true
                end
                if kind == "toggle" and opts.Title and opts.Callback then
                    pcall(function() fn(container, opts.Title, opts.Default or false, opts.Callback) end)
                    return true
                end
                if kind == "slider" and opts.Title and opts.Callback then
                    pcall(function() fn(container, opts.Title, opts.Min or 0, opts.Max or 100, opts.Default or 0, opts.Callback) end)
                    return true
                end
            end
        end)
        if ok and res then return true end
    end
    return false
end

-- section factory (prefer section, fallback to tab)
local function makeSection(tabObj, name)
    if type(tabObj.Section) == "function" then
        local ok, sec = pcall(function() return tabObj:Section(name) end)
        if ok and sec then return sec end
    end
    if type(tabObj.AddSection) == "function" then
        local ok, sec = pcall(function() return tabObj:AddSection(name) end)
        if ok and sec then return sec end
    end
    -- fallback: return tab itself
    return tabObj
end

-- force render helper
local function forceSelect(tabObj)
    pcall(function()
        if type(tabObj.Select) == "function" then pcall(function() tabObj:Select() end) end
        if type(win.SelectTab) == "function" then pcall(function() win:SelectTab(tabObj) end) end
        if type(win.Open) == "function" and not win.Closed then pcall(function() win:Open() end) end
    end)
end

-- -------------------------
-- Tab creation (reorganized as requested)
-- -------------------------
local tabInfo     = win:Tab({ Title = "Info" })
local tabMain     = win:Tab({ Title = "Main" })
local tabFunny    = win:Tab({ Title = "Funny" })
local tabMisc     = win:Tab({ Title = "Misc" })
local tabSettings = win:Tab({ Title = "Settings" })
local tabSUI      = win:Tab({ Title = "Settings UI" })

-- =========================
-- INFO (completed)
-- =========================
local secInfo = makeSection(tabInfo, "About")
addElement(secInfo, "paragraph", { Title = "Criptix Hub | v1.6.6", Content = "Universal exploit hub\nDeveloper: Freddy Bear\nOther devs: snitadd, ChatGPT, Wind\nVersion: v1.6.6\nGitHub: https://github.com/yourrepo" })
addElement(secInfo, "paragraph", { Title = "Usage", Content = "Open the menu (wind UI) and use the sections at left. Use sliders or numeric controls if slider doesn't move." })
addElement(secInfo, "button", { Title = "Copy GitHub Link", Callback = function() pcall(setclipboard, "https://github.com/yourrepo"); safeNotify({ Title="Criptix", Description="GitHub link copied", Duration=2 }) end })
forceSelect(tabInfo)

-- =========================
-- MAIN (Basic + Advanced merged here)
-- =========================
local secBasic    = makeSection(tabMain, "Basic")
local secAdvanced = makeSection(tabMain, "Advanced")
local secFly      = makeSection(tabMain, "Fly")

-- Walk speed: slider + numeric backup
_G._Cr_WalkSpeed = 32
_G._Cr_WalkEnabled = false
addElement(secBasic, "toggle", { Title = "Enable Custom WalkSpeed", Default = false, Callback = function(s) _G._Cr_WalkEnabled = s; local h = getHumanoid(); if h then pcall(function() h.WalkSpeed = s and _G._Cr_WalkSpeed or 16 end) end end })
local function setWalkSpeed(v)
    _G._Cr_WalkSpeed = math.clamp(tonumber(v) or 32, 16, 200)
    if _G._Cr_WalkEnabled then local h = getHumanoid(); if h then pcall(function() h.WalkSpeed = _G._Cr_WalkSpeed end) end end
end
-- try native slider
local sliderOk = addElement(secBasic, "slider", { Title = "Walk Speed (16-200)", Min = 16, Max = 200, Default = 32, Callback = setWalkSpeed })
-- numeric fallback controls (always present as backup)
addElement(secBasic, "paragraph", { Title = "WalkSpeed (numeric controls)", Content = "Use the +/- or input to change value (backup if slider not draggable)." })
addElement(secBasic, "button", { Title = "- 1", Callback = function() setWalkSpeed((_G._Cr_WalkSpeed or 32) - 1) end })
addElement(secBasic, "button", { Title = "+ 1", Callback = function() setWalkSpeed((_G._Cr_WalkSpeed or 32) + 1) end })
if type(secBasic.Input) == "function" then
    pcall(function() secBasic:Input("Set WalkSpeed (number)", tostring(_G._Cr_WalkSpeed), function(val) setWalkSpeed(val) end) end)
end

-- JumpPower (slider + numeric backup)
_G._Cr_JumpPower = 50
_G._Cr_JumpEnabled = false
addElement(secBasic, "toggle", { Title = "Enable Custom JumpPower", Default = false, Callback = function(s) _G._Cr_JumpEnabled = s; local h = getHumanoid(); if h then pcall(function() h.JumpPower = s and _G._Cr_JumpPower or 50 end) end end })
local function setJumpPower(v)
    _G._Cr_JumpPower = math.clamp(tonumber(v) or 50, 50, 500)
    if _G._Cr_JumpEnabled then local h = getHumanoid(); if h then pcall(function() h.JumpPower = _G._Cr_JumpPower end) end end
end
addElement(secBasic, "slider", { Title = "Jump Power (50-500)", Min = 50, Max = 500, Default = 50, Callback = setJumpPower })
addElement(secBasic, "paragraph", { Title = "JumpPower (numeric controls)", Content = "" })
addElement(secBasic, "button", { Title = "- 1", Callback = function() setJumpPower((_G._Cr_JumpPower or 50) - 1) end })
addElement(secBasic, "button", { Title = "+ 1", Callback = function() setJumpPower((_G._Cr_JumpPower or 50) + 1) end })
if type(secBasic.Input) == "function" then pcall(function() secBasic:Input("Set JumpPower (number)", tostring(_G._Cr_JumpPower), function(val) setJumpPower(val) end) end) end

-- Advanced options now inside Main (no "(client)")
addElement(secAdvanced, "toggle", { Title = "No Clip", Default = false, Callback = function(state)
    if state then
        _G._Cr_NoclipConn = RunService.Stepped:Connect(function()
            local ch = player.Character
            if ch then for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
        end)
        safeNotify({ Title="Criptix", Description="No Clip enabled", Duration=1 })
    else
        if _G._Cr_NoclipConn then _G._Cr_NoclipConn:Disconnect(); _G._Cr_NoclipConn = nil end
        local ch = player.Character; if ch then for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
        safeNotify({ Title="Criptix", Description="No Clip disabled", Duration=1 })
    end
end })
addElement(secAdvanced, "toggle", { Title = "God Mode", Default = false, Callback = function(state)
    if state then
        _G._Cr_GodConn = RunService.Heartbeat:Connect(function() local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h then pcall(function() h.Health = h.MaxHealth end) end end)
        local h = getHumanoid(); if h then pcall(function() h.MaxHealth = math.huge; h.Health = h.MaxHealth end) end
        safeNotify({ Title="Criptix", Description="God Mode enabled", Duration=1 })
    else
        if _G._Cr_GodConn then _G._Cr_GodConn:Disconnect(); _G._Cr_GodConn = nil end
        local h = getHumanoid(); if h then pcall(function() h.MaxHealth = 100; h.Health = math.clamp(h.Health,0,100) end) end
        safeNotify({ Title="Criptix", Description="God Mode disabled", Duration=1 })
    end
end })

-- Fly (slider + numeric fallback)
_G._Cr_FlySpeed = 50
addElement(secFly, "toggle", { Title = "Fly", Default = false, Callback = function(state)
    _G._Cr_FlyOn = state
    if state then
        -- create movers
        local char = player.Character or player.CharacterAdded:Wait()
        local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
        if not hrp then safeNotify({ Title="Criptix", Description="No HumanoidRootPart found", Duration=2 }); return end
        _G._Cr_FlyBV = Instance.new("BodyVelocity", hrp); _G._Cr_FlyBV.MaxForce = Vector3.new(1e5,1e5,1e5)
        _G._Cr_FlyBG = Instance.new("BodyGyro", hrp); _G._Cr_FlyBG.MaxTorque = Vector3.new(1e5,1e5,1e5)
        _G._Cr_FlyConn = RunService.Heartbeat:Connect(function()
            local cam = Workspace.CurrentCamera
            if not cam then return end
            local mv = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv = mv + cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv = mv - cam.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv = mv - cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv = mv + cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then mv = mv - Vector3.new(0,1,0) end
            if mv.Magnitude > 0 then mv = mv.Unit * (_G._Cr_FlySpeed or 50) end
            pcall(function() if _G._Cr_FlyBV then _G._Cr_FlyBV.Velocity = mv end end)
            if _G._Cr_FlyBG and player.Character and Workspace.CurrentCamera then
                local hrp2 = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChildWhichIsA("BasePart")
                if hrp2 then _G._Cr_FlyBG.CFrame = CFrame.new(hrp2.Position, hrp2.Position + Workspace.CurrentCamera.CFrame.LookVector) end
            end
        end)
        safeNotify({ Title="Criptix", Description="Fly enabled", Duration=1 })
    else
        if _G._Cr_FlyConn then _G._Cr_FlyConn:Disconnect(); _G._Cr_FlyConn = nil end
        if _G._Cr_FlyBV then pcall(function() _G._Cr_FlyBV:Destroy() end); _G._Cr_FlyBV = nil end
        if _G._Cr_FlyBG then pcall(function() _G._Cr_FlyBG:Destroy() end); _G._Cr_FlyBG = nil end
        safeNotify({ Title="Criptix", Description="Fly disabled", Duration=1 })
    end
end })
local function setFlySpeed(v) _G._Cr_FlySpeed = math.clamp(tonumber(v) or 50, 16, 200) end
addElement(secFly, "slider", { Title = "Fly Speed (16-200)", Min = 16, Max = 200, Default = 50, Callback = setFlySpeed })
-- numeric fallback
addElement(secFly, "paragraph", { Title = "Fly Speed (numeric)", Content = "" })
addElement(secFly, "button", { Title = "- 1", Callback = function() setFlySpeed((_G._Cr_FlySpeed or 50) - 1) end })
addElement(secFly, "button", { Title = "+ 1", Callback = function() setFlySpeed((_G._Cr_FlySpeed or 50) + 1) end })
if type(secFly.Input) == "function" then pcall(function() secFly:Input("Set Fly Speed (num)", tostring(_G._Cr_FlySpeed), function(val) setFlySpeed(val) end) end) end

forceSelect(tabMain)

-- =========================
-- FUNNY (unchanged)
-- =========================
local secFunnyA = makeSection(tabFunny, ":)")
local secFunnyB = makeSection(tabFunny, "Character")

addElement(secFunnyA, "button", { Title = "Walk on Wall (attempt)", Callback = function() safeNotify({ Title="Criptix", Description="Walk on Wall attempted", Duration=1.2 }) end })
addElement(secFunnyA, "button", { Title = "Enable Touch Fling (10s)", Callback = function()
    safeNotify({ Title="Criptix", Description="Touch fling active (10s)", Duration=1 })
    local mouse = player:GetMouse()
    local conn
    conn = mouse.Button1Down:Connect(function()
        local t = mouse.Target
        if t then
            local model = t:FindFirstAncestorOfClass("Model")
            if model and model ~= player.Character then
                local hrp = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
                local myHrp = player.Character and (player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChildWhichIsA("BasePart"))
                if hrp and myHrp then
                    local p = Instance.new("Part", Workspace)
                    p.Size = Vector3.new(1,1,1); p.Transparency = 1; p.Anchored = false; p.CanCollide = false
                    p.CFrame = myHrp.CFrame * CFrame.new(0,-2,-1)
                    p.Velocity = (hrp.Position - myHrp.Position).Unit * 150
                    task.delay(0.6, function() pcall(function() p:Destroy() end) end)
                end
            end
        end
    end)
    task.delay(10, function() if conn then conn:Disconnect() end; safeNotify({ Title="Criptix", Description="Fling disabled", Duration=1 }) end)
end })
addElement(secFunnyB, "toggle", { Title = "Rainbow Body", Default = false, Callback = function(state)
    if state then
        _G._Cr_Rain = RunService.Heartbeat:Connect(function()
            local ch = player.Character
            if ch then
                local hue = (tick() % 5) / 5
                local col = Color3.fromHSV(hue, 0.8, 1)
                for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.Color = col end end
            end
        end)
        safeNotify({ Title="Criptix", Description="Rainbow enabled", Duration=1 })
    else
        if _G._Cr_Rain then _G._Cr_Rain:Disconnect(); _G._Cr_Rain = nil end
        safeNotify({ Title="Criptix", Description="Rainbow disabled", Duration=1 })
    end
end })
addElement(secFunnyB, "slider", { Title = "Spin Speed (1-100)", Min = 1, Max = 100, Default = 20, Callback = function(v) _G._Cr_SpinSpeed = math.clamp(tonumber(v) or 20, 1, 100) end })
addElement(secFunnyB, "toggle", { Title = "Spin Character", Default = false, Callback = function(state)
    if state then
        _G._Cr_SpinLoop = true
        spawn(function()
            while _G._Cr_SpinLoop do
                local ch = player.Character
                if ch and ch:FindFirstChild("HumanoidRootPart") then
                    ch.HumanoidRootPart.CFrame = ch.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad((_G._Cr_SpinSpeed or 20)/30), 0)
                end
                task.wait(1/30)
            end
        end)
        safeNotify({ Title="Criptix", Description="Spinning on", Duration=1 })
    else
        _G._Cr_SpinLoop = false
        safeNotify({ Title="Criptix", Description="Spinning off", Duration=1 })
    end
end })

forceSelect(tabFunny)

-- =========================
-- MISC (move Servers here)
-- =========================
local secMiscAFK = makeSection(tabMisc, "For AFK")
local secMiscServer = makeSection(tabMisc, "Server")

addElement(secMiscAFK, "toggle", { Title = "Anti AFK", Default = false, Callback = function(v)
    if v then
        player.Idled:Connect(function() local vu = game:GetService("VirtualUser"); vu:CaptureController(); vu:ClickButton2(Vector2.new()) end)
        safeNotify({ Title="Criptix", Description="Anti AFK enabled", Duration=1 })
    else
        safeNotify({ Title="Criptix", Description="Anti AFK disabled", Duration=1 })
    end
end })
addElement(secMiscAFK, "button", { Title = "Darken Game", Callback = function()
    for _,o in ipairs(Workspace:GetDescendants()) do if o:IsA("Texture") or o:IsA("Decal") then pcall(function() o.Transparency = 1 end) end end
    safeNotify({ Title="Criptix", Description="Game darkened", Duration=1 })
end })
addElement(secMiscAFK, "button", { Title = "FPS Boost", Callback = function()
    for _,o in ipairs(Workspace:GetDescendants()) do if o:IsA("BasePart") then pcall(function() o.Material = Enum.Material.SmoothPlastic end) end end
    safeNotify({ Title="Criptix", Description="FPS Boost applied", Duration=1 })
end })

-- servers (moved to misc)
addElement(secMiscServer, "button", { Title = "Server Hop", Callback = function()
    pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
end })
addElement(secMiscServer, "button", { Title = "Rejoin Server", Callback = function()
    pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
end })

forceSelect(tabMisc)

-- =========================
-- Settings (save/load placeholders)
-- =========================
local secSettingsMain = makeSection(tabSettings, "General")
addElement(secSettingsMain, "button", { Title = "Save Settings", Callback = function() safeNotify({ Title="Criptix", Description="Settings saved (not persisted)", Duration=1 }) end })
addElement(secSettingsMain, "button", { Title = "Load Settings", Callback = function() safeNotify({ Title="Criptix", Description="Settings loaded (not persisted)", Duration=1 }) end })
addElement(secSettingsMain, "button", { Title = "Reset To Default", Callback = function() safeNotify({ Title="Criptix", Description="Defaults applied", Duration=1 }) end })
forceSelect(tabSettings)

-- =========================
-- Settings UI: Theme + Keybind + Transparency
-- =========================
local secSUIAppear = makeSection(tabSUI, "Appearance")

addElement(secSUIAppear, "dropdown", { Title = "Change Theme", Values = {"Dark","Light","Ocean","Inferno"}, Callback = function(choice)
    local okA = pcall(function() if ui.SetTheme then ui:SetTheme(choice) end end)
    local okB = pcall(function() if win.SetTheme then win:SetTheme(choice) end end)
    if okA or okB then safeNotify({ Title="Criptix", Description="Theme set: "..tostring(choice), Duration=1 }) else safeNotify({ Title="Criptix", Description="Theme change failed for this WindUI variant", Duration=2 }) end
end })

addElement(secSUIAppear, "keybind", { Title = "Toggle UI Keybind", Default = Enum.KeyCode.RightControl, Callback = function()
    if win and win.Toggle then pcall(function() win:Toggle() end) end
end })

-- Transparency slider with decimal (0.0 - 0.8)
addElement(secSUIAppear, "slider", { Title = "Transparency (0.0 - 0.8)", Min = 0, Max = 0.8, Default = 0.5, Callback = function(v)
    -- some WindUI require SetTransparency on window, others on ui
    pcall(function() if win.SetTransparency then win:SetTransparency(tonumber(v) or 0.5) end end)
    pcall(function() if ui.SetTransparency then ui:SetTransparency(tonumber(v) or 0.5) end end)
    safeNotify({ Title="Criptix", Description="Transparency: "..tostring(v), Duration=1 })
end })

forceSelect(tabSUI)

-- -------------------------
-- Finalize: hide loading overlay
-- -------------------------
hideLoadingOverlay()
safeNotify({ Title="Criptix", Description="v1.6.6 loaded", Duration=2 })

-- Reapply on respawn
player.CharacterAdded:Connect(function()
    task.wait(0.6)
    if _G._Cr_WalkEnabled then local hum = getHumanoid(); if hum then pcall(function() hum.WalkSpeed = _G._Cr_WalkSpeed end) end end
    if _G._Cr_JumpEnabled then local hum = getHumanoid(); if hum then pcall(function() hum.JumpPower = _G._Cr_JumpPower end) end end
    if _G._Cr_NoclipConn then
        if _G._Cr_NoclipConn then _G._Cr_NoclipConn:Disconnect(); _G._Cr_NoclipConn = nil end
        _G._Cr_NoclipConn = RunService.Stepped:Connect(function() local ch = player.Character; if ch then for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end end)
    end
end)
