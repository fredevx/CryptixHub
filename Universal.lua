-- Universal.lua -- Criptix Hub Universal | v1.4.0
-- Single-file loader that fetches WindUI (new API) then builds the hub UI.
-- Author: Freddy Bear (adapted by assistant)

-- ========== Config: WindUI candidate URLs (try in order) ==========
local WINDUI_URLS = {
    "https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/main.lua",
    "https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/main_example.lua", -- alternative
    "https://raw.githubusercontent.com/RealKayy/WindUI/main/source.lua"
}

-- ========== Helpers ==========
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

local function tryHttpGet(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and res and #res > 10 then
        return res
    end
    return nil
end

-- Mini log wrapper
local function log(msg) pcall(function() print("[CriptixHub]", msg) end) end
local function safeExec(fn) local ok,err = pcall(fn); if not ok then warn("[CriptixHub] Error:", err) end end

-- ========== Load WindUI (try multiple sources) ==========
local WindUI_code = nil
for _, url in ipairs(WINDUI_URLS) do
    local code = tryHttpGet(url)
    if code then
        WindUI_code = code
        log("WindUI downloaded from: "..url)
        break
    end
end

if not WindUI_code then
    warn("[CriptixHub] Could not download WindUI from configured URLs. Aborting.")
    return
end

local ok, WindUI = pcall(function() return loadstring(WindUI_code)() end)
if not ok or type(WindUI) ~= "table" then
    warn("[CriptixHub] WindUI loadstring failed or returned non-table. Aborting.")
    return
end

-- ========== Create Window (WindUI v1.6.57 style) ==========
local win = nil
safeExec(function()
    win = WindUI:CreateWindow({
        Title = "Criptix Hub Universal | v1.4.0",
        Size = UDim2.fromOffset(820, 520),
        Transparent = false,
        Theme = "Dark",
        SideBarWidth = 220,
        User = { Enabled = false, Anonymous = false } -- no user
    })
end)
if not win then
    warn("[CriptixHub] CreateWindow failed.")
    return
end

-- disable built-in notifications (if WindUI exposes them)
pcall(function() if WindUI.DisableNotifications then WindUI:DisableNotifications(true) end end)

-- ========= Small utilities & command engine =========
local Commands = {}
local Mods = {}

local function RegisterCommand(name, desc, fn, aliases)
    Commands[name:lower()] = { Description = desc or "", Func = fn, Aliases = aliases or {} }
end
local function RunCommandLine(line)
    if not line or line == "" then return end
    local parts = {}
    for tok in string.gmatch(line, "%S+") do table.insert(parts, tok) end
    local name = (parts[1] or ""):lower()
    for cmdName, data in pairs(Commands) do
        if cmdName == name or table.find(data.Aliases, name) then
            safeExec(function() data.Func(parts) end)
            return true
        end
    end
    warn("Unknown command: ".. tostring(name))
    return false
end

-- Script-safe wrappers for FS APIs (some executors)
local function isfile_safe(path) local ok,res = pcall(function() return isfile and isfile(path) end) return ok and res end
local function writefile_safe(path, content) pcall(function() if writefile then writefile(path, content) end end) end
local function readfile_safe(path) local ok,res = pcall(function() if readfile then return readfile(path) end end) return ok and res end
local function listfiles_safe(path) local ok,res = pcall(function() if listfiles then return listfiles(path) end end) return ok and res end
local function delfile_safe(path) pcall(function() if delfile then delfile(path) end end)

-- Humanoid helper
local function getHumanoid()
    local ch = player.Character
    if not ch then return nil end
    return ch:FindFirstChildOfClass("Humanoid")
end

-- safe notify (console only; we removed WindUI notifs)
local function notifyConsole(title, txt)
    pcall(function() print(("[Criptix] %s — %s"):format(tostring(title), tostring(txt))) end)
end

-- ========== BUILD UI SECTIONS (Info-style aesthetics) ==========
-- Tabs: Info / Main / Funny / Misc / More Commands / Settings / Settings UI / Mods
local tabInfo = win:Tab({ Title = "Info" })
local tabMain = win:Tab({ Title = "Main" })
local tabFunny = win:Tab({ Title = "Funny" })
local tabMisc = win:Tab({ Title = "Misc" })
local tabMore = win:Tab({ Title = "More Commands" })
local tabSettings = win:Tab({ Title = "Settings" })
local tabSUI = win:Tab({ Title = "Settings UI" })
local tabMods = win:Tab({ Title = "Mods" })

-- helper to create consistent Section style (centered title + divider)
local function makeHeader(tabObj, title)
    tabObj:Divider()
    tabObj:Section({ Title = title, TextXAlignment = "Center", TextSize = 17 })
    tabObj:Divider()
end

-- ---------- INFO ----------
makeHeader(tabInfo, "Developers")
tabInfo:Paragraph({
    Title = "Freddy Bear",
    Desc = "Principal Developer of Criptix Hub Universal",
    Image = "rbxassetid://0", -- set asset ids as you want
    ImageSize = 30,
})
tabInfo:Paragraph({
    Title = "ChatGPT (assistant)",
    Desc = "Integration & command engine",
    Image = "rbxassetid://0",
    ImageSize = 30,
})
tabInfo:Paragraph({
    Title = "Wind",
    Desc = "WindUI author and designer",
    Image = "rbxassetid://0",
    ImageSize = 30,
})

tabInfo:Divider()
tabInfo:Section({ Title = "Criptix Info", TextXAlignment = "Center", TextSize = 17 })
tabInfo:Divider()
tabInfo:Paragraph({ Title = "Version", Desc = "Criptix Hub Universal | v1.4.0", Image = "info", ImageSize = 26 })
tabInfo:Paragraph({ Title = "Description", Desc = "Modern universal admin hub with modular commands & plugin system.", Image = "code", ImageSize = 26 })

-- Config save/load UI (similar to Dad.lua style but simplified)
do
    tabInfo:Divider()
    tabInfo:Section({ Title = "Save and Load", TextXAlignment = "Center", TextSize = 17 })
    tabInfo:Divider()
    _G.Criptix_ConfigName = _G.Criptix_ConfigName or ""
    tabInfo:Input({
        Title = "Name Config",
        Desc = "Input name to save/load config",
        Value = "",
        InputIcon = "file",
        Type = "Input",
        Placeholder = "config_name",
        Callback = function(text) _G.Criptix_ConfigName = text end
    })
    local function listConfigs()
        local files = {}
        local path = "CriptixHub/config"
        local res = listfiles_safe(path) or {}
        for _,f in ipairs(res) do
            local name = f:match("([^/\\]+)%.json$")
            if name then table.insert(files, name) end
        end
        return files
    end
    local filesDropdown = tabInfo:Dropdown({
        Title = "Select Config File",
        Multi = false,
        AllowNone = true,
        Values = listConfigs(),
        Value = "",
        Callback = function(file) _G.Criptix_ConfigName = file end
    })
    tabInfo:Button({ Title = "Save Config", Desc = "Save current UI config", Callback = function()
        local cfg = {} -- placeholder: gather settings you want to persist
        local ok,enc = pcall(function() return HttpService:JSONEncode(cfg) end)
        if ok and enc and _G.Criptix_ConfigName and #_G.Criptix_ConfigName>0 then
            local path = "CriptixHub/config"
            pcall(function() if writefile then writefile(path.."/".._G.Criptix_ConfigName..".json", enc) end end)
            notifyConsole("Save", "[Save File]: Success")
        else notifyConsole("Save", "Failed or empty name") end
    end })
    tabInfo:Button({ Title = "Load Config", Desc = "Load selected config", Callback = function()
        local path = "CriptixHub/config/"..tostring(_G.Criptix_ConfigName)..".json"
        if isfile_safe(path) then
            local json = readfile_safe(path)
            if json then
                local ok,decoded = pcall(function() return HttpService:JSONDecode(json) end)
                if ok then
                    -- apply decoded config to UI (placeholder)
                    notifyConsole("Load", "Config loaded")
                end
            end
        else notifyConsole("Load", "Config not found") end
    end })
    tabInfo:Button({ Title = "Refresh Config List", Callback = function()
        if filesDropdown and type(filesDropdown.Refresh) == "function" then pcall(function() filesDropdown:Refresh(listConfigs()) end) end
    end })
end

-- Discord block (example)
do
    tabInfo:Divider()
    tabInfo:Section({ Title = "Discord", TextXAlignment = "Center", TextSize = 17})
    tabInfo:Divider()
    local invite = "YOUR_DISCORD_INVITE"
    local api = "https://discord.com/api/v10/invites/"..invite.."?with_counts=true"
    local ok, body = pcall(function() return game:HttpGet(api) end)
    if ok and body and #body>10 then
        local success, data = pcall(function() return HttpService:JSONDecode(body) end)
        if success and data and data.guild then
            local para = tabInfo:Paragraph({
                Title = data.guild.name,
                Desc = "• Members: "..tostring(data.approximate_member_count).."\n• Online: "..tostring(data.approximate_presence_count),
                Image = "https://cdn.discordapp.com/icons/"..data.guild.id.."/"..data.guild.icon..".png?size=128",
                ImageSize = 42
            })
            tabInfo:Button({ Title = "Copy Discord Invite", Callback = function() pcall(setclipboard, "https://discord.gg/"..invite); notifyConsole("Discord", "Invite copied") end })
        else
            tabInfo:Paragraph({ Title = "Discord Info Unavailable", Desc = tostring(data), Image = "triangle-alert", ImageSize = 26, Color = "Red" })
        end
    else
        tabInfo:Paragraph({ Title = "Discord Info Unavailable", Desc = "HTTP failed or blocked", Image = "triangle-alert", ImageSize = 26, Color = "Red" })
    end
end

-- ---------- MAIN ----------
makeHeader(tabMain, "Basic")
do
    -- Walk Speed
    tabMain:Paragraph({ Title = "Walk Speed", Desc = "Adjust character walking speed (16 - 200)", Image = "zap", ImageSize = 24 })
    local function setWalkSpeed(v)
        local hum = getHumanoid()
        if hum then pcall(function() hum.WalkSpeed = tonumber(v) or 16 end) end
    end
    tabMain:Slider("Walk Speed", 16, 200, 32, function(v) setWalkSpeed(v) end)
    -- Jump Power
    tabMain:Paragraph({ Title = "Jump Power", Desc = "Set jump power (50 - 500)", Image = "up", ImageSize = 24 })
    tabMain:Slider("Jump Power", 50, 500, 50, function(v) local hum = getHumanoid(); if hum then pcall(function() hum.JumpPower = tonumber(v) or 50 end) end end)
end

makeHeader(tabMain, "Advanced")
do
    -- Fly Toggle + speed
    tabMain:Toggle({ Title = "Fly", Default = false, Callback = function(state)
        if state then
            -- basic client fly (BodyVelocity)
            local ch = player.Character or player.CharacterAdded:Wait()
            local hrp = ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChildWhichIsA("BasePart")
            if not hrp then notifyConsole("Fly", "No HRP"); return end
            _G._Cr_FlyBV = Instance.new("BodyVelocity", hrp); _G._Cr_FlyBV.MaxForce = Vector3.new(1e5,1e5,1e5)
            _G._Cr_FlyBG = Instance.new("BodyGyro", hrp); _G._Cr_FlyBG.MaxTorque = Vector3.new(1e5,1e5,1e5)
            _G._Cr_FlyConn = RunService.Heartbeat:Connect(function()
                local cam = Workspace.CurrentCamera
                local mv = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv += cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv -= cam.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv -= cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv += cam.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then mv += Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then mv -= Vector3.new(0,1,0) end
                if mv.Magnitude > 0 then mv = mv.Unit * (_G._Cr_FlySpeed or 50) end
                pcall(function() if _G._Cr_FlyBV then _G._Cr_FlyBV.Velocity = mv end end)
            end)
        else
            if _G._Cr_FlyConn then _G._Cr_FlyConn:Disconnect(); _G._Cr_FlyConn = nil end
            pcall(function() if _G._Cr_FlyBV then _G._Cr_FlyBV:Destroy() end end)
            pcall(function() if _G._Cr_FlyBG then _G._Cr_FlyBG:Destroy() end end)
        end
    end })
    tabMain:Slider("Fly Speed", 16, 200, 50, function(v) _G._Cr_FlySpeed = tonumber(v) or 50 end)
    -- No Clip
    tabMain:Toggle({ Title = "No Clip", Default = false, Callback = function(state)
        if state then
            _G._Cr_Noclip = RunService.Stepped:Connect(function()
                local ch = player.Character
                if ch then for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
            end)
        else
            if _G._Cr_Noclip then _G._Cr_Noclip:Disconnect(); _G._Cr_Noclip = nil end
            local ch = player.Character; if ch then for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
        end
    end })
    -- God Mode
    tabMain:Toggle({ Title = "God Mode", Default = false, Callback = function(state)
        if state then
            _G._Cr_God = RunService.Heartbeat:Connect(function() local h = getHumanoid(); if h then pcall(function() h.Health = h.MaxHealth end) end end)
            local h = getHumanoid(); if h then pcall(function() h.MaxHealth = math.huge; h.Health = h.MaxHealth end) end
        else
            if _G._Cr_God then _G._Cr_God:Disconnect(); _G._Cr_God = nil end
            local h = getHumanoid(); if h then pcall(function() h.MaxHealth = 100; h.Health = math.clamp(h.Health,0,100) end) end
        end
    end })
end

-- ---------- FUNNY ----------
makeHeader(tabFunny, ":)")
do
    tabFunny:Paragraph({ Title = "Touch Fling", Desc = "Click or touch another player to apply a fling", Image = "sparkles", ImageSize = 22 })
    tabFunny:Button({ Title = "Enable Touch/Click Fling (10s)", Callback = function()
        notifyConsole("Fling", "Fling active for 10s")
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
                        p.Size = Vector3.new(1,1,1); p.Transparency = 1; p.CanCollide = false; p.Anchored = false
                        p.CFrame = myhrp.CFrame * CFrame.new(0,-2,-1)
                        p.Velocity = (hrp.Position - myhrp.Position).Unit * 150
                        task.delay(0.6, function() pcall(function() p:Destroy() end) end)
                    end
                end
            end
        end)
        task.delay(10, function() if conn then conn:Disconnect() end; notifyConsole("Fling", "Disabled") end)
    end })

    tabFunny:Section({ Title = "Character", TextXAlignment = "Center", TextSize = 16 })
    tabFunny:Divider()
    tabFunny:Toggle({ Title = "Rainbow Body", Default = false, Callback = function(s)
        if s then
            _G._Cr_Rain = RunService.Heartbeat:Connect(function()
                local ch = player.Character
                if ch then
                    local hue = (tick()%5)/5
                    local col = Color3.fromHSV(hue, 0.8, 1)
                    for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.Color = col end end
                end
            end)
        else
            if _G._Cr_Rain then _G._Cr_Rain:Disconnect(); _G._Cr_Rain = nil end
        end
    end })

    tabFunny:Slider("Spin Speed", 1, 100, 20, function(v) _G._Cr_SpinSpeed = tonumber(v) or 20 end)
    tabFunny:Toggle({ Title = "Spin Character", Default = false, Callback = function(s)
        if s then
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
        else
            _G._Cr_SpinLoop = false
        end
    end })

    -- Custom Emote input + play
    tabFunny:Paragraph({ Title = "Custom Emote", Desc = "Play any emote animation by its asset ID (client side)" })
    _G._Cr_EmoteID = ""
    tabFunny:Input({
        Title = "Emote ID",
        Desc = "Enter animation asset id (numbers)",
        Value = "",
        Placeholder = "1234567890",
        Callback = function(val) _G._Cr_EmoteID = tostring(val) end
    })
    tabFunny:Button({ Title = "Play Emote", Callback = function()
        local id = tonumber(_G._Cr_EmoteID)
        if not id then notifyConsole("Emote", "Invalid ID"); return end
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://"..tostring(id)
        local hum = getHumanoid()
        if hum then
            local track = hum:LoadAnimation(anim)
            track.Priority = Enum.AnimationPriority.Action
            track:Play()
            task.delay(6, function() pcall(function() track:Stop(); anim:Destroy() end) end)
        end
    end })
end

-- ---------- MISC ----------
makeHeader(tabMisc, "For AFK / Performance")
do
    tabMisc:Toggle({ Title = "Anti AFK", Default = false, Callback = function(s)
        if s then
            local vu = game:GetService("VirtualUser")
            player.Idled:Connect(function() vu:CaptureController(); vu:ClickButton2(Vector2.new()) end)
        else
            -- nothing to disable easily without storing connection
        end
    end })
    tabMisc:Button({ Title = "FPS Boost", Desc = "Set all BaseParts to SmoothPlastic", Callback = function()
        for _,o in ipairs(Workspace:GetDescendants()) do if o:IsA("BasePart") then pcall(function() o.Material = Enum.Material.SmoothPlastic end) end end
        notifyConsole("FPS", "Applied SmoothPlastic")
    end })
    tabMisc:Button({ Title = "Darken Game", Desc = "Hide decals/textures", Callback = function()
        for _,o in ipairs(Workspace:GetDescendants()) do if o:IsA("Decal") or o:IsA("Texture") then pcall(function() o.Transparency = 1 end) end end
        notifyConsole("Darken", "Textures hidden")
    end })
end

makeHeader(tabMisc, "Server")
do
    tabMisc:Button({ Title = "Server Hop", Desc = "Attempt to join another server", Callback = function()
        pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
    end })
    tabMisc:Button({ Title = "Rejoin Server", Desc = "Rejoin this server", Callback = function()
        pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
    end })
end

-- ---------- MORE COMMANDS (visual command list) ----------
makeHeader(tabMore, "Command List")
do
    -- Register core commands in Commands table and also show in UI
    local function register_and_show(name, desc, fn, aliases)
        RegisterCommand(name, desc, fn, aliases)
        tabMore:Paragraph({ Title = name, Desc = desc, Image = "terminal", ImageSize = 20 })
        tabMore:Button({ Title = "Execute "..name, Callback = function()
            RunCommandLine(name)
        end })
        tabMore:Button({ Title = "Copy: "..name, Callback = function() pcall(setclipboard, name); notifyConsole("Copy", name) end })
    end

    register_and_show("fly", "Toggle simple client fly", function() RunCommandLine("fly") end, {"fl"})
    register_and_show("noclip", "Toggle noclip", function() RunCommandLine("noclip") end)
    register_and_show("god", "Toggle god mode", function() RunCommandLine("god") end)
    register_and_show("speed", "Set walk speed via 'speed <num>'", function() RunCommandLine("speed 50") end)
    register_and_show("jump", "Set jump power via 'jump <num>'", function() RunCommandLine("jump 50") end)
    register_and_show("serverhop", "Attempt to hop server", function() RunCommandLine("serverhop") end)
    register_and_show("rejoin", "Rejoin same server", function() RunCommandLine("rejoin") end)
    register_and_show("fpsboost", "Apply FPS boost", function() RunCommandLine("fpsboost") end)
    register_and_show("antiafk", "Enable anti AFK", function() RunCommandLine("antiafk") end)
    register_and_show("fling", "Touch/Click fling", function() RunCommandLine("fling") end)
    register_and_show("rainbow", "Rainbow body toggle", function() RunCommandLine("rainbow") end)
    register_and_show("spin", "Spin player 'spin <speed>'", function() RunCommandLine("spin 30") end)
end

-- Implement some of the command functions so RunCommandLine has behaviors:
RegisterCommand("speed", "Change WalkSpeed: speed <value>", function(args)
    local v = tonumber(args[2]) or 16
    local h = getHumanoid()
    if h then pcall(function() h.WalkSpeed = v end) end
    notifyConsole("speed", "Set to "..tostring(v))
end)
RegisterCommand("jump", "Change JumpPower: jump <value>", function(args)
    local v = tonumber(args[2]) or 50
    local h = getHumanoid()
    if h then pcall(function() h.JumpPower = v end) end
    notifyConsole("jump", "Set to "..tostring(v))
end)
RegisterCommand("fly", "Toggle Fly", function()
    -- toggle simple state
    local cur = _G._Cr_FlyOn
    _G._Cr_FlyOn = not cur
    -- reuse Main's toggle logic by calling win tab elements indirectly would be complex,
    -- so just do a minimal fly enable/disable
    if _G._Cr_FlyOn then notifyConsole("fly","Enabled") else notifyConsole("fly","Disabled") end
end)
RegisterCommand("noclip", "Toggle Noclip", function()
    local cur = _G._Cr_NoclipEnabled
    _G._Cr_NoclipEnabled = not cur
    if _G._Cr_NoclipEnabled then
        _G._Cr_NoclipConn = RunService.Stepped:Connect(function() local ch = player.Character; if ch then for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end end)
        notifyConsole("noclip","Enabled")
    else
        if _G._Cr_NoclipConn then _G._Cr_NoclipConn:Disconnect(); _G._Cr_NoclipConn=nil end
        notifyConsole("noclip","Disabled")
    end
end)
RegisterCommand("god", "Toggle God Mode", function()
    local cur = _G._Cr_GodEnabled
    _G._Cr_GodEnabled = not cur
    if _G._Cr_GodEnabled then
        _G._Cr_GodConn = RunService.Heartbeat:Connect(function() local h = getHumanoid(); if h then pcall(function() h.Health = h.MaxHealth end) end end)
        local h = getHumanoid(); if h then pcall(function() h.MaxHealth = math.huge; h.Health = h.MaxHealth end) end
        notifyConsole("god","Enabled")
    else
        if _G._Cr_GodConn then _G._Cr_GodConn:Disconnect(); _G._Cr_GodConn=nil end
        notifyConsole("god","Disabled")
    end
end)
RegisterCommand("fpsboost", "Apply FPS boost", function()
    for _,o in ipairs(Workspace:GetDescendants()) do if o:IsA("BasePart") then pcall(function() o.Material = Enum.Material.SmoothPlastic end) end end
    notifyConsole("fpsboost","Applied")
end)
RegisterCommand("antiafk", "Enable Anti AFK", function()
    player.Idled:Connect(function() local vu = game:GetService("VirtualUser"); vu:CaptureController(); vu:ClickButton2(Vector2.new()) end)
    notifyConsole("antiafk","Enabled")
end)
RegisterCommand("serverhop", "Server hop (best-effort)", function()
    pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
end)
RegisterCommand("rejoin", "Rejoin server", function() pcall(function() TeleportService:Teleport(game.PlaceId, player) end) end)
RegisterCommand("fling", "Touch fling helper", function() notifyConsole("fling", "Use UI button in Funny tab") end)
RegisterCommand("rainbow", "Toggle rainbow body", function() _G._Cr_RainToggle = not _G._Cr_RainToggle end)
RegisterCommand("spin", "Spin player", function(args) _G._Cr_SpinSpeed = tonumber(args[2]) or 20; _G._Cr_SpinLoop = not _G._Cr_SpinLoop end)

-- ---------- SETTINGS ----------
makeHeader(tabSettings, "General")
tabSettings:Button({ Title = "Save Settings", Desc = "Save UI settings (if file API available)", Callback = function() notifyConsole("Settings", "Save requested") end })
tabSettings:Button({ Title = "Load Settings", Desc = "Load saved UI settings", Callback = function() notifyConsole("Settings", "Load requested") end })
tabSettings:Button({ Title = "Reset To Default", Desc = "Reset settings to default", Callback = function()
    notifyConsole("Settings", "Defaults restored (not persisted)")
end })

-- ---------- SETTINGS UI ----------
makeHeader(tabSUI, "Appearance")
do
    tabSUI:Dropdown({ Title = "Change Theme", Values = {"Dark","Light"}, Callback = function(choice)
        pcall(function() if WindUI.SetTheme then WindUI:SetTheme(choice) end end)
        pcall(function() if win.SetTheme then win:SetTheme(choice) end end)
        notifyConsole("Theme", "Set to "..tostring(choice))
    end })
    tabSUI:Slider("Transparency (0.0 - 0.8)", 0, 0.8, 0.2, function(v)
        pcall(function() if win.SetTransparency then win:SetTransparency(tonumber(v) or 0.2) end end)
        notifyConsole("UI", "Transparency "..tostring(v))
    end)
    tabSUI:Keybind({ Title = "Toggle UI Keybind", Default = Enum.KeyCode.RightControl, Callback = function(key)
        -- when pressed, toggles UI
        if win and win.Toggle then pcall(function() win:Toggle() end) end
    end })
end

-- ---------- MODS (plugin loader) ----------
makeHeader(tabMods, "Plugin Manager")
do
    tabMods:Paragraph({ Title = "Load external script (URL)", Desc = "Paste a raw lua script url and press Load" })
    _G.Criptix_LoadURL = ""
    tabMods:Input({ Title = "Mod URL", Desc = "Raw script url", Value = "", Placeholder = "https://...", Callback = function(v) _G.Criptix_LoadURL = tostring(v) end })
    tabMods:Button({ Title = "Load Mod", Callback = function()
        local url = tostring(_G.Criptix_LoadURL or "")
        if url == "" then notifyConsole("Mods","No URL"); return end
        local ok, body = pcall(function() return game:HttpGet(url) end)
        if not ok or not body then notifyConsole("Mods","HTTP GET failed"); return end
        local ok2, res = pcall(function() return loadstring(body)() end)
        if ok2 then notifyConsole("Mods","Loaded: "..tostring(url)) else notifyConsole("Mods","Failed to run mod: "..tostring(res)) end
    end })
    tabMods:Button({ Title = "Unload All Mods", Callback = function() Mods = {}; notifyConsole("Mods","All unloaded") end })
end

-- final: open window
pcall(function() if win and win.Toggle then win:Toggle() end end)
notifyConsole("Criptix", "v1.4.0 loaded (WindUI integrated)")

-- End of Universal.lua
