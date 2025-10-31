-- Universal.lua
-- CriptixHub Universal | v1.4.1
-- Loads CriptixUI (separate module) and builds the full hub with all tabs & functions.

-- ===== Settings =====
local CRIPTIXUI_RAW = "https://raw.githubusercontent.com/fredevx/CryptixHub/refs/heads/main/CryptixUI.lua"
local DISCORD_INVITE = "GW9E66m8jt"
local UI_TITLE = "CriptixHub Universal | v1.4.1"
local INTERNAL_NAME = "CriptixHubUniversal" -- used by CriptixUI for saving

-- ===== Services =====
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===== Utility helpers =====
local function safe_pcall(fn, ...)
    local ok, res = pcall(fn, ...)
    if not ok then warn("[CriptixHub] error:", res) end
    return ok, res
end

local function try_load_criptixui()
    local ok, res = pcall(function()
        local raw = game:HttpGet(CRIPTIXUI_RAW)
        local func = loadstring(raw)
        assert(type(func) == "function", "loadstring returned non-function")
        return func()
    end)
    if ok and res then
        return res
    else
        warn("[CriptixHub] Failed to load CriptixUI.lua from remote. Error:", res)
        return nil, res
    end
end

-- Load CriptixUI module (remote). If HTTP disabled, user should manually host CriptixUI locally.
local CriptixUI, err = try_load_criptixui()
if not CriptixUI then
    -- Fallback message: create a minimal ScreenGui that tells user to enable HTTP or upload CriptixUI.lua
    local sg = Instance.new("ScreenGui", playerGui)
    sg.Name = "CriptixHub_Fallback"
    sg.ResetOnSpawn = false
    local f = Instance.new("Frame", sg)
    f.Size = UDim2.fromOffset(520,120)
    f.Position = UDim2.new(0.5,-260,0.5,-60)
    f.BackgroundColor3 = Color3.fromRGB(25,25,25)
    f.BorderSizePixel = 0
    local uic = Instance.new("UICorner", f); uic.CornerRadius = UDim.new(0,8)
    local t = Instance.new("TextLabel", f)
    t.Size = UDim2.new(1,-20,1,-20); t.Position = UDim2.new(0,10,0,10)
    t.BackgroundTransparency = 1
    t.TextColor3 = Color3.fromRGB(230,230,230)
    t.TextWrapped = true
    t.Font = Enum.Font.SourceSans
    t.TextSize = 16
    t.Text = "CriptixUI module failed to load.\n\nMake sure HTTP is enabled or upload CriptixUI.lua to your executor. Error:\n"..tostring(err)
    return
end

-- ===== Create Window using CriptixUI =====
local Window = CriptixUI:CreateWindow({
    Title = UI_TITLE,
    Theme = "Dark",
    ConfigName = INTERNAL_NAME,
    Notifications = true
})

-- Enable OpenButtonMain with label "CriptixHub"
local okBtn, openBtnObj = pcall(function()
    return CriptixUI:EnableOpenButton({ Label = "CriptixHub" })
end)

-- Attach default Info tab (Discord + config utils)
CriptixUI:AttachDefaultInfo(Window, DISCORD_INVITE)

-- Create tabs
local MainTab = Window:Tab({ Title = "Main" })
local FunnyTab = Window:Tab({ Title = "Funny" })
local MiscTab = Window:Tab({ Title = "Misc" })
local SettingsTab = Window:Tab({ Title = "Settings" })
local SettingsUITab = Window:Tab({ Title = "Settings UI" })
local ModsTab = Window:Tab({ Title = "Mods" })

-- =========================
-- Main Tab
-- =========================
do
    MainTab:Divider()
    MainTab:Section({ Title = "Basic", TextSize = 17 })
    MainTab:Divider()

    -- Walk Speed slider (16 - 200)
    local function setWalkSpeed(v)
        local ch = player.Character
        if not ch then return end
        local hum = ch:FindFirstChildOfClass("Humanoid")
        if hum then
            safe_pcall(function() hum.WalkSpeed = tonumber(v) or 16 end)
        end
    end
    MainTab:Paragraph({ Title = "Walk Speed", Desc = "Set player walk speed (16 - 200). Value shown next to slider." })
    MainTab:Slider("Walk Speed", 16, 200, 16, setWalkSpeed)

    -- Jump Power slider (50 - 500)
    local function setJumpPower(v)
        local ch = player.Character
        if not ch then return end
        local hum = ch:FindFirstChildOfClass("Humanoid")
        if hum then
            safe_pcall(function() hum.JumpPower = tonumber(v) or 50 end)
        end
    end
    MainTab:Paragraph({ Title = "Jump Power", Desc = "Set player jump power (50 - 500)." })
    MainTab:Slider("Jump Power", 50, 500, 50, setJumpPower)

    MainTab:Divider()
    MainTab:Section({ Title = "Advanced", TextSize = 17 })
    MainTab:Divider()

    -- NoClip toggle (client-side, sets CanCollide false for character parts)
    MainTab:Toggle({ Title = "No Clip", Default = false, Callback = function(enable)
        if enable then
            _G.Cr_NoclipConn = RunService.Stepped:Connect(function()
                local ch = player.Character
                if ch then
                    for _,p in ipairs(ch:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = false end
                    end
                end
            end)
            Window:Notify("NoClip", "Enabled (client)", "check", 3)
        else
            if _G.Cr_NoclipConn then _G.Cr_NoclipConn:Disconnect(); _G.Cr_NoclipConn = nil end
            local ch = player.Character
            if ch then
                for _,p in ipairs(ch:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = true end
                end
            end
            Window:Notify("NoClip", "Disabled", "check", 2)
        end
    end })

    -- God Mode toggle (client-enforced)
    MainTab:Toggle({ Title = "God Mode", Default = false, Callback = function(enable)
        if enable then
            _G.Cr_GodConn = RunService.Heartbeat:Connect(function()
                local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    pcall(function()
                        hum.Health = hum.MaxHealth
                    end)
                end
            end)
            Window:Notify("God Mode", "Enabled (client)", "check", 3)
        else
            if _G.Cr_GodConn then _G.Cr_GodConn:Disconnect(); _G.Cr_GodConn = nil end
            Window:Notify("God Mode", "Disabled", "check", 2)
        end
    end })

    -- Fly (client)
    _G.Cr_FlySpeed = 50
    MainTab:Toggle({ Title = "Fly (client)", Default = false, Callback = function(enable)
        if enable then
            local ch = player.Character or player.CharacterAdded:Wait()
            local hrp = ch:FindFirstChild("HumanoidRootPart")
            if not hrp then Window:Notify("Fly", "No HumanoidRootPart", "warn", 3); return end
            _G.Cr_FlyBV = Instance.new("BodyVelocity", hrp)
            _G.Cr_FlyBV.MaxForce = Vector3.new(1e5,1e5,1e5)
            _G.Cr_FlyBG = Instance.new("BodyGyro", hrp)
            _G.Cr_FlyBG.MaxTorque = Vector3.new(1e5,1e5,1e5)
            _G.Cr_FlyEnable = true
            _G.Cr_FlyConn = RunService.Heartbeat:Connect(function()
                local cam = Workspace.CurrentCamera
                local mv = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv = mv + cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv = mv - cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv = mv - cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv = mv + cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then mv = mv - Vector3.new(0,1,0) end
                if mv.Magnitude > 0 then mv = mv.Unit * (_G.Cr_FlySpeed or 50) end
                pcall(function()
                    if _G.Cr_FlyBV then _G.Cr_FlyBV.Velocity = mv end
                end)
            end)
            Window:Notify("Fly", "Enabled (client)", "check", 3)
        else
            _G.Cr_FlyEnable = false
            if _G.Cr_FlyConn then _G.Cr_FlyConn:Disconnect(); _G.Cr_FlyConn = nil end
            pcall(function() if _G.Cr_FlyBV then _G.Cr_FlyBV:Destroy() end end)
            pcall(function() if _G.Cr_FlyBG then _G.Cr_FlyBG:Destroy() end end)
            Window:Notify("Fly", "Disabled", "check", 2)
        end
    end })
    MainTab:Slider("Fly Speed", 16, 200, 50, function(v) _G.Cr_FlySpeed = tonumber(v) or 50 end)
end

-- =========================
-- Funny Tab
-- =========================
do
    FunnyTab:Divider()
    FunnyTab:Section({ Title = ":)", TextSize = 17 })
    FunnyTab:Divider()

    FunnyTab:Button({ Title = "Touch Fling (10s)", Callback = function()
        local mouse = player:GetMouse()
        local conn
        conn = mouse.Button1Down:Connect(function()
            local t = mouse.Target
            if t then
                local model = t:FindFirstAncestorOfClass("Model")
                if model and model ~= player.Character then
                    local hrp = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
                    local myhrp = player.Character and (player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChildWhichIsA("BasePart"))
                    if hrp and myhrp then
                        local p = Instance.new("Part", Workspace)
                        p.Size = Vector3.new(1,1,1); p.Transparency = 1; p.Anchored = false; p.CanCollide = false
                        p.CFrame = myhrp.CFrame * CFrame.new(0,-2,-1)
                        p.Velocity = (hrp.Position - myhrp.Position).Unit * 150
                        task.delay(0.6, function() pcall(function() p:Destroy() end) end)
                    end
                end
            end
        end)
        task.delay(10, function() if conn then conn:Disconnect() end end)
        Window:Notify("Touch Fling", "Enabled for 10s", "check", 3)
    end })

    FunnyTab:Section({ Title = "Character", TextSize = 16 })
    FunnyTab:Divider()

    -- Walk on Wall (simulated by setting PlatformStand and BodyGyro) - client effect
    FunnyTab:Toggle({ Title = "Walk on Wall", Default = false, Callback = function(enable)
        if enable then
            _G.Cr_WallConn = RunService.Heartbeat:Connect(function()
                local ch = player.Character
                if ch and ch:FindFirstChild("HumanoidRootPart") then
                    -- emulate sticking by slightly modifying platform stand/friction (client-only)
                    pcall(function()
                        for _,part in ipairs(ch:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.Friction = 0
                            end
                        end
                    end)
                end
            end)
            Window:Notify("Walk on Wall", "Enabled (client)", "check", 2)
        else
            if _G.Cr_WallConn then _G.Cr_WallConn:Disconnect(); _G.Cr_WallConn = nil end
            Window:Notify("Walk on Wall", "Disabled", "check", 2)
        end
    end })

    -- Fake Kick Player: creates a local "You were kicked" popup for the selected player (non-destructive)
    local function getPlayerNamesList()
        local out = {}
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl ~= player then table.insert(out, pl.Name) end
        end
        if #out == 0 then table.insert(out, "No players") end
        return out
    end

    local selectedFakeKick = nil
    FunnyTab:Dropdown({ Title = "Select Player (Fake Kick)", Values = getPlayerNamesList(), Callback = function(v) selectedFakeKick = v end })
    FunnyTab:Button({ Title = "Fake Kick (local)", Callback = function()
        if not selectedFakeKick or selectedFakeKick == "No players" then Window:Notify("Fake Kick", "No player selected", "warn", 2); return end
        -- Show local notification simulating that player was kicked (non-harmful)
        Window:Notify("Fake Kick", selectedFakeKick.." was (locally) kicked (simulation)", "check", 3)
    end })

    -- Rainbow Body
    FunnyTab:Toggle({ Title = "Rainbow Body", Default = false, Callback = function(enable)
        if enable then
            _G.Cr_RainConn = RunService.Heartbeat:Connect(function()
                local ch = player.Character
                if ch then
                    local hue = (tick()%5)/5
                    local col = Color3.fromHSV(hue, 0.8, 1)
                    for _,p in pairs(ch:GetDescendants()) do
                        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                            p.Color = col
                        end
                    end
                end
            end)
            Window:Notify("Rainbow Body", "Enabled", "check", 2)
        else
            if _G.Cr_RainConn then _G.Cr_RainConn:Disconnect(); _G.Cr_RainConn = nil end
            Window:Notify("Rainbow Body", "Disabled", "check", 2)
        end
    end })

    -- Spin Character (slider + toggle)
    _G.Cr_SpinSpeed = 20
    FunnyTab:Slider("Spin Speed", 1, 100, 20, function(v) _G.Cr_SpinSpeed = tonumber(v) or 20 end)
    FunnyTab:Toggle({ Title = "Spin Character", Default = false, Callback = function(enable)
        if enable then
            _G.Cr_SpinLoop = true
            spawn(function()
                while _G.Cr_SpinLoop do
                    local ch = player.Character
                    if ch and ch:FindFirstChild("HumanoidRootPart") then
                        ch.HumanoidRootPart.CFrame = ch.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad((_G.Cr_SpinSpeed or 20)/30), 0)
                    end
                    task.wait(1/30)
                end
            end)
            Window:Notify("Spin", "Enabled", "check", 2)
        else
            _G.Cr_SpinLoop = false
            Window:Notify("Spin", "Disabled", "check", 2)
        end
    end })

    -- Emote by ID
    _G.Cr_EmoteID = nil
    FunnyTab:Input({ Title = "Emote ID", Placeholder = "123456789", Callback = function(txt) _G.Cr_EmoteID = txt end })
    FunnyTab:Button({ Title = "Play Emote", Callback = function()
        local id = tonumber(_G.Cr_EmoteID)
        if not id then Window:Notify("Emote", "Invalid ID", "warn", 2); return end
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://"..tostring(id)
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            local track = hum:LoadAnimation(anim)
            track.Priority = Enum.AnimationPriority.Action
            track:Play()
            task.delay(8, function() pcall(function() track:Stop(); anim:Destroy() end) end)
        end
    end })
end

-- =========================
-- Misc Tab
-- =========================
do
    MiscTab:Divider()
    MiscTab:Section({ Title = "For AFK", TextSize = 17 })
    MiscTab:Divider()

    -- Anti AFK
    MiscTab:Toggle({ Title = "Anti AFK", Default = false, Callback = function(enable)
        if enable then
            _G.Cr_AFKConn = player.Idled:Connect(function()
                local vu = game:GetService("VirtualUser")
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
            Window:Notify("Anti AFK", "Enabled", "check", 2)
        else
            if _G.Cr_AFKConn then _G.Cr_AFKConn:Disconnect(); _G.Cr_AFKConn = nil end
            Window:Notify("Anti AFK", "Disabled", "check", 2)
        end
    end })

    -- FPS Boost (client-side: change materials, disable particle emitters)
    MiscTab:Button({ Title = "FPS Boost", Desc = "Set BaseParts to SmoothPlastic and disable particles", Callback = function()
        for _,v in ipairs(Workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                safe_pcall(function() v.Material = Enum.Material.SmoothPlastic end)
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
                safe_pcall(function() v.Enabled = false end)
            end
        end
        Window:Notify("FPS Boost", "Applied (client-side)", "check", 3)
    end })

    -- Darken Game (hide decals/textures)
    MiscTab:Button({ Title = "Darken Game", Desc = "Hide decals and textures", Callback = function()
        for _,o in ipairs(Workspace:GetDescendants()) do
            if o:IsA("Decal") or o:IsA("Texture") then
                safe_pcall(function() o.Transparency = 1 end)
            end
        end
        Window:Notify("Darken Game", "Applied", "check", 2)
    end })

    MiscTab:Divider()
    MiscTab:Section({ Title = "Server", TextSize = 17 })
    MiscTab:Divider()

    -- Server Hop (best-effort using TeleportService; may require HTTP to fetch servers — using basic teleport as fallback)
    MiscTab:Button({ Title = "Server Hop", Callback = function()
        local ok, err = pcall(function()
            TeleportService:Teleport(game.PlaceId, player)
        end)
        if ok then Window:Notify("Server Hop", "Attempting to teleport...", "check", 3) else Window:Notify("Server Hop", "Failed: "..tostring(err), "warn", 3) end
    end })

    MiscTab:Button({ Title = "Rejoin Server", Callback = function()
        local ok, err = pcall(function()
            TeleportService:Teleport(game.PlaceId, player)
        end)
        if ok then Window:Notify("Rejoin", "Rejoining...", "check", 2) else Window:Notify("Rejoin", "Failed: "..tostring(err), "warn", 3) end
    end })
end

-- =========================
-- Settings Tab
-- =========================
do
    SettingsTab:Divider(); SettingsTab:Section({ Title = "General", TextSize = 17 }); SettingsTab:Divider()

    SettingsTab:Button({ Title = "Save Settings", Callback = function()
        local ok = Window:SaveConfig(Window.ConfigName)
        if ok then Window:Notify("Settings", "Saved", "check", 2) else Window:Notify("Settings", "Save failed (writefile?)", "warn", 3) end
    end })

    SettingsTab:Button({ Title = "Load Settings", Callback = function()
        local ok = Window:LoadConfig(Window.ConfigName)
        if ok then Window:Notify("Settings", "Loaded", "check", 2) else Window:Notify("Settings", "Load failed", "warn", 3) end
    end })

    SettingsTab:Button({ Title = "Reset To Default", Callback = function()
        Window:SetTheme("Dark")
        Window.Frame.BackgroundTransparency = 0
        Window:Notify("Settings", "Reset to defaults", "check", 2)
    end })
end

-- =========================
-- Settings UI Tab
-- =========================
do
    SettingsUITab:Divider(); SettingsUITab:Section({ Title = "Appearance", TextSize = 17 }); SettingsUITab:Divider()

    -- Theme dropdown (all available themes from CriptixUI module)
    local themeList = {"Dark","Light","Ocean","Crimson","Emerald","Purple"}
    SettingsUITab:Dropdown({ Title = "Change Theme", Values = themeList, Callback = function(choice)
        Window:SetTheme(choice)
    end })

    -- Transparency slider (0 - 0.8) with decimals
    SettingsUITab:Slider("Transparency (0.0 - 0.8)", 0, 0.8, 0, function(v)
        local val = tonumber(v) or 0
        if val > 0.8 then val = 0.8 end
        Window.Frame.BackgroundTransparency = val
    end)

    -- Toggle UI Keybind: press to capture the key to toggle UI
    SettingsUITab:Keybind({ Title = "Toggle UI Keybind", Default = Enum.KeyCode.RightControl, Callback = function(key)
        -- Unbind previous binds by creation of new connection
        if _G.Cr_ToggleConn then _G.Cr_ToggleConn:Disconnect(); _G.Cr_ToggleConn = nil end
        _G.Cr_ToggleConn = UserInputService.InputBegan:Connect(function(inp, processed)
            if processed then return end
            if inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode == key then
                Window:Toggle()
            end
        end)
        Window:Notify("Keybind", "Toggle bound to "..tostring(key), "check", 2)
    end })
end

-- =========================
-- Mods Tab
-- =========================
do
    ModsTab:Divider(); ModsTab:Section({ Title = "Mods / Plugin Manager", TextSize = 17 }); ModsTab:Divider()

    _G.Cr_ModURL = ""
    ModsTab:Input({ Title = "Mod URL", Placeholder = "raw script url", Callback = function(v) _G.Cr_ModURL = tostring(v) end })
    ModsTab:Button({ Title = "Load Mod", Callback = function()
        local url = tostring(_G.Cr_ModURL or "")
        if url == "" then Window:Notify("Mods", "No URL specified", "warn", 2); return end
        local ok, body = pcall(function() return game:HttpGet(url) end)
        if not ok or not body then Window:Notify("Mods", "HTTP GET failed", "warn", 3); return end
        local ok2, res = pcall(function() return loadstring(body)() end)
        if ok2 then Window:Notify("Mods", "Mod loaded", "check", 2) else Window:Notify("Mods", "Mod error", "warn", 3) end
    end })
    ModsTab:Button({ Title = "Unload All Mods", Callback = function()
        -- For simplicity, just signal and let loaded mods manage unloading
        _G.CriptixLoadedMods = {}
        Window:Notify("Mods", "Marked mods as unloaded", "check", 2)
    end })
end

-- =========================
-- Finalize: create sidebar players dropdown refresh where needed
-- (refresh player lists for Fake Kick dropdown)
-- =========================
do
    -- helper to refresh player list in Funny tab (fake kick)
    local function refreshPlayerDropdown()
        local names = {}
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl ~= player then table.insert(names, pl.Name) end
        end
        if #names == 0 then names = {"No players"} end
        -- naive: recreate dropdown by adding a new one at end (CriptixUI's Dropdown API doesn't expose update)
        FamousDropdown = FunnyTab:Dropdown({ Title = "Select Player (Fake Kick)", Values = names, Callback = function(v) _G.Cr_FakeKickTarget = v end })
    end

    -- refresh on player join/leave
    Players.PlayerAdded:Connect(function() refreshPlayerDropdown() end)
    Players.PlayerRemoving:Connect(function() refreshPlayerDropdown() end)
    -- initial populate
    refreshPlayerDropdown()
end

-- =========================
-- Open UI (we rely on OpenButtonMain; do not auto-open)
-- =========================
Window:Notify("CriptixHub", "Loaded v1.4.1", "check", 3)
warn("[CriptixHub] CriptixUI loaded and Universal initialized (v1.4.1)")

-- If OpenButton failed to create, open UI directly
if not okBtn then
    Window:Open()
else
    -- Otherwise we keep UI closed and let the button toggle; but we open first tab selected
    if #Window.Tabs > 0 then
        Window:SelectTab(Window.Tabs[1])
    end
end

-- Save window state when closing or position changes (best-effort)
-- Hook to store position on mouse release
local mainGui = playerGui:FindFirstChild("CriptixUI_"..INTERNAL_NAME)
if mainGui and mainGui:FindFirstChild("MainFrame") then
    local mf = mainGui.MainFrame
    -- store position on InputEnded for drag-like interactions
    mf.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            pcall(function() Window:SaveConfig(Window.ConfigName) end)
        end
    end)
end

-- All done.



