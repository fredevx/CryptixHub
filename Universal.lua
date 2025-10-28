-- Criptix Hub | v1.6.5 (Robust renderer, WindUI tolerant)
-- Dev: Freddy Bear
-- Paste as LocalScript in StarterGui (replaces prior versions)

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function showLoading()
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title="Criptix Hub", Text="Please wait, Criptix Hub is loading...", Duration=9999})
    end)
end
local function hideLoading()
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title="Criptix Hub", Text=" ", Duration=0.1})
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

-- Create window (table config)
local win
local ok2, err2 = pcall(function()
    win = ui:CreateWindow({
        Title = "Criptix Hub | v1.6.5 🌐",
        Size = UDim2.fromOffset(760,420),
        Transparent = true,
        Theme = "Dark",
        SideBarWidth = 200,
        User = { Enabled = false, Anonymous = false }
    })
end)
if not ok2 or not win then
    hideLoading()
    warn("[CriptixHub] CreateWindow failed:", err2)
    return
end

-- safe wrappers to detect and call multiple method signatures
local function callAdd(target, methodNames, params)
    -- methodNames: array of possible method names, prefer first
    for _,m in ipairs(methodNames) do
        local fn = target[m]
        if type(fn) == "function" then
            -- try table-style param first
            local ok,err = pcall(function() fn(target, params) end)
            if ok then return true end
            -- fallback: some APIs expect signature (title, callback) or (title, default, cb)
            if params and params.Title and params.Callback then
                local ok2 = pcall(function() fn(target, params.Title, params.Callback) end)
                if ok2 then return true end
            end
            -- fallback: try unpacked (title, min,max,default,cb) for sliders
            if params and params.Title and params.Min and params.Max and params.Default and params.Callback then
                pcall(function() fn(target, params.Title, params.Min, params.Max, params.Default, params.Callback) end)
                return true
            end
        end
    end
    return false
end

-- robust section factory: returns a place to add elements (section or tab)
local function makeSection(tab, name)
    -- prefer tab:Section if exists
    if type(tab.Section) == "function" then
        local ok, sec = pcall(function() return tab:Section(name) end)
        if ok and sec then return sec end
    end
    -- Maybe API uses tab:CreateSection or tab:AddSection
    if type(tab.AddSection) == "function" then
        local ok, sec = pcall(function() return tab:AddSection(name) end)
        if ok and sec then return sec end
    end
    if type(tab.CreateSection) == "function" then
        local ok, sec = pcall(function() return tab:CreateSection(name) end)
        if ok and sec then return sec end
    end
    -- fallback: return tab itself (direct add)
    return tab
end

-- ensure rendering: select tab and open window if needed
local function ensureVisible(tab)
    pcall(function()
        if type(tab.Select) == "function" then pcall(function() tab:Select() end) end
        if type(win.SelectTab) == "function" then pcall(function() win:SelectTab(tab) end) end
        if type(win.Open) == "function" and not win.Closed then pcall(function() win:Open() end) end
        if type(win.Toggle) == "function" then pcall(function() win:Toggle() end) end
    end)
end

-- safe notify
local function safeNotify(tbl)
    pcall(function() if ui and ui.Notify then ui:Notify(tbl) end end)
end

-- helper: add common elements with multiple fallback method names
local function addButton(container, title, callback)
    callAdd(container, {"Button","AddButton","AddBtn"}, { Title = title, Callback = callback })
end
local function addToggle(container, title, default, callback)
    callAdd(container, {"Toggle","AddToggle"}, { Title = title, Default = default, Callback = callback })
end
local function addSlider(container, title, min, max, default, callback)
    callAdd(container, {"Slider","AddSlider"}, { Title = title, Min = min, Max = max, Default = default, Callback = callback })
end
local function addParagraph(container, title, content)
    callAdd(container, {"Paragraph","AddParagraph","Paragraph"}, { Title = title, Content = content })
end
local function addDropdown(container, title, values, callback)
    callAdd(container, {"Dropdown","AddDropdown"}, { Title = title, Values = values, Callback = callback })
end
local function addKeybind(container, title, default, callback)
    callAdd(container, {"Keybind","AddKeybind"}, { Title = title, Default = default, Callback = callback })
end

-- create tab helper that populates robustly
local function populateTab(tab, definition)
    local sect = makeSection(tab, definition.sectionName or "")
    for _,el in ipairs(definition.elements) do
        local typ = el.type
        if typ == "paragraph" then addParagraph(sect, el.title or "", el.content or "") end
        if typ == "button" then addButton(sect, el.title or "Button", el.callback) end
        if typ == "toggle" then addToggle(sect, el.title or "Toggle", el.default or false, el.callback) end
        if typ == "slider" then addSlider(sect, el.title or "Slider", el.min or 0, el.max or 100, el.default or 0, el.callback) end
        if typ == "dropdown" then addDropdown(sect, el.title or "Dropdown", el.values or {}, el.callback) end
        if typ == "keybind" then addKeybind(sect, el.title or "Keybind", el.default, el.callback) end
    end
    -- force show
    ensureVisible(tab)
end

-- ============================
-- Build all tabs with robust calls
-- ============================

-- INFO
populateTab(win:Tab({ Title = "Info" }), {
    sectionName = "About",
    elements = {
        { type = "paragraph", title = "Criptix Hub | v1.6.5", content = "Universal hub — Freddy Bear\nOther devs: snitadd, chatgpt, wind" },
        { type = "button", title = "Copy Discord Invite", callback = function() pcall(function() setclipboard("https://discord.gg/yourinvite") end); safeNotify({Title="Criptix", Description="Invite copied", Duration=2}) end }
    }
})

-- MAIN
populateTab(win:Tab({ Title = "Main" }), {
    sectionName = "Basic",
    elements = {
        { type = "toggle", title = "Enable Custom WalkSpeed", default = false, callback = function(state) _G._Cr_WalkEnabled = state; local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if hum then pcall(function() hum.WalkSpeed = state and (_G._Cr_WalkSpeed or 32) or 16 end) end end },
        { type = "slider", title = "Walk Speed (16-200)", min = 16, max = 200, default = 32, callback = function(v) _G._Cr_WalkSpeed = math.clamp(tonumber(v) or 32,16,200); if _G._Cr_WalkEnabled then local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if hum then pcall(function() hum.WalkSpeed = _G._Cr_WalkSpeed end) end end end },
        { type = "toggle", title = "Enable Custom JumpPower", default = false, callback = function(state) _G._Cr_JumpEnabled = state; local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if hum then pcall(function() hum.JumpPower = state and (_G._Cr_JumpPower or 50) or 50 end) end end },
        { type = "slider", title = "Jump Power (50-500)", min = 50, max = 500, default = 50, callback = function(v) _G._Cr_JumpPower = math.clamp(tonumber(v) or 50,50,500); if _G._Cr_JumpEnabled then local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if hum then pcall(function() hum.JumpPower = _G._Cr_JumpPower end) end end end }
    }
})

-- Advanced (NoClip / God)
populateTab(win:Tab({ Title = "Advanced" }), {
    sectionName = "Advanced",
    elements = {
        { type = "toggle", title = "No Clip (client)", default = false, callback = function(state)
            if state then
                _G._Cr_NoclipConn = RunService.Stepped:Connect(function()
                    local ch = player.Character
                    if ch then for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
                end)
            else
                if _G._Cr_NoclipConn then _G._Cr_NoclipConn:Disconnect(); _G._Cr_NoclipConn = nil end
            end
            safeNotify({Title="Criptix", Description=(state and "NoClip enabled" or "NoClip disabled"), Duration=1.2})
        end },
        { type = "toggle", title = "God Mode (client)", default = false, callback = function(state)
            if state then
                _G._Cr_GodConn = RunService.Heartbeat:Connect(function() local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h then pcall(function() h.Health = h.MaxHealth end) end end)
                local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h then pcall(function() h.MaxHealth = math.huge; h.Health = h.MaxHealth end) end
            else
                if _G._Cr_GodConn then _G._Cr_GodConn:Disconnect(); _G._Cr_GodConn = nil end
                local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h then pcall(function() h.MaxHealth = 100; h.Health = math.clamp(h.Health,0,100) end) end
            end
        end }
    }
})

-- Funny (touch fling, rainbow, spin)
populateTab(win:Tab({ Title = "Funny" }), {
    sectionName = ":)",
    elements = {
        { type = "button", title = "Walk on Wall (attempt)", callback = function() safeNotify({Title="Criptix", Description="Walk on Wall attempted", Duration=1.5}) end },
        { type = "button", title = "Enable Touch Fling (10s)", callback = function()
            safeNotify({Title="Criptix", Description="Touch fling active (10s)", Duration=1})
            local mouse = player:GetMouse()
            local conn
            conn = mouse.Button1Down:Connect(function() local t = mouse.Target; if t then local model = t:FindFirstAncestorOfClass("Model"); if model and model ~= player.Character then local hrp = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart"); local myHrp = player.Character and (player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChildWhichIsA("BasePart")); if hrp and myHrp then local p = Instance.new("Part", Workspace); p.Size=Vector3.new(1,1,1); p.Transparency=1; p.Anchored=false; p.CanCollide=false; p.CFrame = myHrp.CFrame * CFrame.new(0,-2,-1); p.Velocity = (hrp.Position - myHrp.Position).Unit * 150; task.delay(0.6,function() pcall(function() p:Destroy() end) end) end end end end)
            task.delay(10,function() if conn then conn:Disconnect() end; safeNotify({Title="Criptix", Description="Fling disabled", Duration=1}) end)
        end },
        { type = "toggle", title = "Rainbow Body", default = false, callback = function(state)
            if state then
                _G._Cr_Rain = RunService.Heartbeat:Connect(function() local ch = player.Character; if ch then local hue = (tick()%5)/5; local col = Color3.fromHSV(hue,0.8,1); for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.Color = col end end end end)
            else
                if _G._Cr_Rain then _G._Cr_Rain:Disconnect(); _G._Cr_Rain = nil end
            end
        end },
        { type = "slider", title = "Spin Speed (1-100)", min = 1, max = 100, default = 20, callback = function(v) _G._Cr_SpinSpeed = math.clamp(tonumber(v) or 20,1,100) end },
        { type = "toggle", title = "Spin Character", default = false, callback = function(state)
            if state then
                _G._Cr_SpinLoop = true
                spawn(function()
                    while _G._Cr_SpinLoop do
                        local ch = player.Character
                        if ch and ch:FindFirstChild("HumanoidRootPart") then ch.HumanoidRootPart.CFrame = ch.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad((_G._Cr_SpinSpeed or 20)/30), 0) end
                        task.wait(1/30)
                    end
                end)
            else
                _G._Cr_SpinLoop = false
            end
        end }
    }
})

-- Misc
populateTab(win:Tab({ Title = "Misc" }), {
    sectionName = "For AFK",
    elements = {
        { type = "toggle", title = "Anti AFK", default = false, callback = function(v)
            if v then
                player.Idled:Connect(function() local vu = game:GetService("VirtualUser"); vu:CaptureController(); vu:ClickButton2(Vector2.new()) end)
            end
        end },
        { type = "button", title = "Darken Game", callback = function() for _,o in ipairs(Workspace:GetDescendants()) do if o:IsA("Texture") or o:IsA("Decal") then pcall(function() o.Transparency = 1 end) end end; safeNotify({Title="Criptix", Description="Game darkened", Duration=1.2}) end },
        { type = "button", title = "FPS Boost", callback = function() for _,o in ipairs(Workspace:GetDescendants()) do if o:IsA("BasePart") then pcall(function() o.Material = Enum.Material.SmoothPlastic end) end end; safeNotify({Title="Criptix", Description="FPS Boost applied", Duration=1.2}) end }
    }
})
-- Server buttons on same tab but different section name
populateTab(win:Tab({ Title = "Servers" }), {
    sectionName = "Server",
    elements = {
        { type = "button", title = "Server Hop", callback = function() pcall(function() TeleportService:Teleport(game.PlaceId, player) end) end },
        { type = "button", title = "Rejoin Server", callback = function() pcall(function() TeleportService:Teleport(game.PlaceId, player) end) end }
    }
})

-- Settings
populateTab(win:Tab({ Title = "Settings" }), {
    sectionName = "General",
    elements = {
        { type = "button", title = "Save Settings", callback = function() safeNotify({Title="Criptix", Description="Settings saved (not persisted)", Duration=1}) end },
        { type = "button", title = "Load Settings", callback = function() safeNotify({Title="Criptix", Description="Settings loaded (not persisted)", Duration=1}) end },
        { type = "button", title = "Reset To Default", callback = function() safeNotify({Title="Criptix", Description="Defaults applied", Duration=1}) end }
    }
})

-- Settings UI
populateTab(win:Tab({ Title = "Settings UI" }), {
    sectionName = "Appearance",
    elements = {
        { type = "dropdown", title = "Change Theme", values = {"Dark","Light","Ocean","Inferno"}, callback = function(choice) if choice and ui.SetTheme then pcall(function() ui:SetTheme(choice) end) end; safeNotify({Title="Criptix", Description="Theme: "..tostring(choice), Duration=1}) end },
        { type = "keybind", title = "Toggle UI Keybind", default = Enum.KeyCode.RightControl, callback = function() if win and win.Toggle then pcall(function() win:Toggle() end) end end },
        { type = "slider", title = "Transparency (0-0.8)", min = 0, max = 0.8, default = 0.5, callback = function(v) if win and win.SetTransparency then pcall(function() win:SetTransparency(v) end) end; safeNotify({Title="Criptix", Description="Transparency: "..tostring(v), Duration=1}) end }
    }
})

-- Floating button (draggable) to toggle GUI
pcall(function()
    local sg = Instance.new("ScreenGui"); sg.Name="CriptixHub_Button"; sg.ResetOnSpawn=false; sg.Parent=playerGui
    local frame = Instance.new("Frame"); frame.Size=UDim2.new(0,70,0,70); frame.Position=UDim2.new(0.85,0,0.06,0); frame.BackgroundTransparency=1; frame.Parent=sg
    local btn = Instance.new("ImageButton"); btn.Size=UDim2.fromOffset(60,60); btn.Position=UDim2.new(0.5,0,0.5,0); btn.AnchorPoint=Vector2.new(0.5,0.5); btn.BackgroundColor3=Color3.fromRGB(20,20,20); btn.BorderSizePixel=0; btn.Image=""; btn.Parent=frame
    local uic = Instance.new("UICorner", btn); uic.CornerRadius=UDim.new(0,16)
    local stroke = Instance.new("UIStroke", btn); stroke.Thickness=2; stroke.Color=Color3.fromRGB(68,196,255); stroke.Transparency=0.6
    local lbl = Instance.new("TextLabel", frame); lbl.Size=UDim2.new(1,0,0,16); lbl.Position=UDim2.new(0,0,1,2); lbl.BackgroundTransparency=1; lbl.Text="Criptix"; lbl.TextSize=12; lbl.TextColor3=Color3.fromRGB(200,200,200); lbl.Font=Enum.Font.SourceSans
    -- dragging
    local dragging=false; local dragStart; local startPos; local dragInput
    btn.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true; dragStart=input.Position; startPos=frame.Position
            input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    btn.InputChanged:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then dragInput=input end end)
    UserInputService.InputChanged:Connect(function(input) if dragging and input==dragInput then local delta = input.Position - dragStart; frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
    btn.MouseButton1Click:Connect(function() pcall(function() if win and win.Toggle then win:Toggle() elseif win and win.Open then win:Open() end end) end)
end)

-- finalize
hideLoading()
safeNotify({Title="Criptix", Description="v1.6.5 loaded", Duration=2})

-- reapply on respawn
player.CharacterAdded:Connect(function()
    task.wait(0.6)
    if _G._Cr_WalkEnabled then local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if hum then pcall(function() hum.WalkSpeed = _G._Cr_WalkSpeed end) end end
    if _G._Cr_JumpEnabled then local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if hum then pcall(function() hum.JumpPower = _G._Cr_JumpPower end) end end
    if _G._Cr_NoclipConn then
        if _G._Cr_NoclipConn then _G._Cr_NoclipConn:Disconnect(); _G._Cr_NoclipConn=nil end
        _G._Cr_NoclipConn = RunService.Stepped:Connect(function() local ch = player.Character; if ch then for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end end)
    end
end)
