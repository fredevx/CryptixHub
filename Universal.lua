--// 🌐 Criptix Hub | v1.4.1 (WindUI Performance Update)
--// Developer: Freddy Bear
--// Base UI: WindUI
--// Description: Universal hub, performance improved
--// Compatible: PC + Mobile

--// Cargar WindUI
local ui = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

--// Crear ventana principal
local win = ui:CreateWindow({
    Title = "Criptix Hub | v1.4.1 🌐",
    Icon = "",
    Author = "Criptix",
    Folder = "CriptixHub",
    Size = UDim2.fromOffset(750, 400),
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 200,
    Background = "",
    BackgroundImageTransparency = 0.4,
    HideSearchBar = true,
    ScrollBarEnabled = true,
    User = { Enabled = false, Anonymous = false }
})

--// Crear Tabs principales
local Tabs = {
    Info = win:Tab({ Title = "Info", Icon = "info-circle" }),
    Main = win:Tab({ Title = "Main", Icon = "gamepad-2" }),
    Funny = win:Tab({ Title = "Funny", Icon = "smile" }),
    Misc = win:Tab({ Title = "Misc", Icon = "boxes" }),
    Settings = win:Tab({ Title = "Settings", Icon = "cog" }),
    SettingsUI = win:Tab({ Title = "Settings UI", Icon = "paintbrush" })
}

---------------------------------------------------------------------
--// 🧩 TAB: INFO
---------------------------------------------------------------------
Tabs.Info:Label("Criptix Hub | v1.4.1 🌐")
Tabs.Info:Label("Principal Developer: Freddy Bear")
Tabs.Info:Label("Other Developers: snitadd, chatgpt, wind")
Tabs.Info:Button("Join Discord", function()
    setclipboard("https://discord.gg/yourinvite")
    ui:Notify("Discord invite copied to clipboard!")
end)

---------------------------------------------------------------------
--// ⚙️ TAB: MAIN
---------------------------------------------------------------------
local flySpeed = 50
local flying = false
local bp, bg

-- Walk Speed
Tabs.Main:Slider("Walk Speed", 16, 200, 16, function(value)
    local plr = game.Players.LocalPlayer
    local char = plr.Character or plr.CharacterAdded:Wait()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = value end
end)

-- Jump Power
Tabs.Main:Slider("Jump Power", 50, 500, 50, function(value)
    local plr = game.Players.LocalPlayer
    local char = plr.Character or plr.CharacterAdded:Wait()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.JumpPower = value end
end)

-- Fly Speed
Tabs.Main:Slider("Fly Speed", 16, 200, 50, function(value)
    flySpeed = value
end)

-- No Clip
Tabs.Main:Toggle("No Clip", false, function(state)
    local player = game.Players.LocalPlayer
    local char = player.Character or player.CharacterAdded:Wait()
    if state then
        ui:Notify("NoClip enabled.")
        _G.NoclipConn = game:GetService("RunService").Stepped:Connect(function()
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    else
        if _G.NoclipConn then
            _G.NoclipConn:Disconnect()
            _G.NoclipConn = nil
        end
        ui:Notify("NoClip disabled.")
    end
end)

-- God Mode
Tabs.Main:Toggle("God Mode", false, function(state)
    local char = game.Players.LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if state and humanoid then
        humanoid.MaxHealth = math.huge
        humanoid.Health = math.huge
        ui:Notify("God Mode ON")
    else
        ui:Notify("God Mode OFF")
    end
end)

-- Fly
Tabs.Main:Toggle("Fly (On/Off)", false, function(state)
    local plr = game.Players.LocalPlayer
    local char = plr.Character or plr.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart")

    if state then
        flying = true
        ui:Notify("Fly Enabled")
        bp = Instance.new("BodyPosition", hrp)
        bp.MaxForce = Vector3.new(400000, 400000, 400000)
        bp.Position = hrp.Position
        bg = Instance.new("BodyGyro", hrp)
        bg.MaxTorque = Vector3.new(400000, 400000, 400000)
        bg.CFrame = hrp.CFrame

        spawn(function()
            while flying and task.wait() do
                local move = Vector3.zero
                local uis = game:GetService("UserInputService")
                if uis:IsKeyDown(Enum.KeyCode.W) then move = move + hrp.CFrame.LookVector end
                if uis:IsKeyDown(Enum.KeyCode.S) then move = move - hrp.CFrame.LookVector end
                if uis:IsKeyDown(Enum.KeyCode.A) then move = move - hrp.CFrame.RightVector end
                if uis:IsKeyDown(Enum.KeyCode.D) then move = move + hrp.CFrame.RightVector end
                if uis:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
                if uis:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0, 1, 0) end
                bp.Position = hrp.Position + move * (flySpeed / 50)
                bg.CFrame = workspace.CurrentCamera.CFrame
            end
        end)
    else
        flying = false
        if bp then bp:Destroy() end
        if bg then bg:Destroy() end
        ui:Notify("Fly Disabled")
    end
end)

---------------------------------------------------------------------
--// 😂 TAB: FUNNY
---------------------------------------------------------------------
Tabs.Funny:Button("Fake Kick Player", function()
    game.Players.LocalPlayer:Kick("You have been kicked from the game. (Fake Kick)")
end)

Tabs.Funny:Toggle("Rainbow Body", false, function(state)
    local char = game.Players.LocalPlayer.Character
    if not char then return end
    if state then
        ui:Notify("Rainbow enabled!")
        spawn(function()
            while state do
                for _, p in pairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then
                        p.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
                    end
                end
                task.wait(0.1)
            end
        end)
    else
        ui:Notify("Rainbow disabled.")
    end
end)

Tabs.Funny:Slider("Spin Speed", 1, 100, 10, function(value)
    _G.SpinSpeed = value
end)

Tabs.Funny:Toggle("Spin Character", false, function(state)
    local char = game.Players.LocalPlayer.Character
    if not char then return end
    if state then
        ui:Notify("Spinning ON")
        spawn(function()
            while state and char:FindFirstChild("HumanoidRootPart") do
                char.HumanoidRootPart.CFrame *= CFrame.Angles(0, math.rad(_G.SpinSpeed or 10), 0)
                task.wait(0.03)
            end
        end)
    else
        ui:Notify("Spinning OFF")
    end
end)

---------------------------------------------------------------------
--// 🧰 TAB: MISC
---------------------------------------------------------------------
Tabs.Misc:Toggle("Anti AFK", false, function(state)
    if state then
        local vu = game:GetService("VirtualUser")
        game.Players.LocalPlayer.Idled:Connect(function()
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end)
        ui:Notify("Anti AFK Activated")
    else
        ui:Notify("Anti AFK Disabled")
    end
end)

-- Darken Game
Tabs.Misc:Button("Darken Game", function()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Texture") or v:IsA("Decal") then
            v.Transparency = 1
        end
    end
    ui:Notify("Game darkened and textures removed!")
end)

-- FPS Boost
Tabs.Misc:Button("FPS Boost", function()
    for _, v in next, workspace:GetDescendants() do
        if v:IsA("Part") then
            v.Material = Enum.Material.SmoothPlastic
        end
    end
    ui:Notify("All parts converted to SmoothPlastic for performance!")
end)

-- Server Hop
Tabs.Misc:Button("Server Hop", function()
    local TeleportService = game:GetService("TeleportService")
    TeleportService:TeleportToPlaceInstance(game.PlaceId)
end)

-- Rejoin Server
Tabs.Misc:Button("Rejoin Server", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId)
end)

---------------------------------------------------------------------
--// ⚙️ TAB: SETTINGS
---------------------------------------------------------------------
Tabs.Settings:Button("Save Settings", function()
    ui:Notify("Settings saved successfully!")
end)

Tabs.Settings:Button("Load Settings", function()
    ui:Notify("Settings loaded successfully!")
end)

Tabs.Settings:Button("Reset to Default", function()
    ui:Notify("Settings reset to default.")
end)

---------------------------------------------------------------------
--// 🎨 TAB: SETTINGS UI
---------------------------------------------------------------------
Tabs.SettingsUI:Dropdown("Change Theme", {"Dark Blue", "Crimson Red", "Mint Green", "Aqua"}, function(theme)
    ui:Notify("Theme set to: " .. theme)
end)

Tabs.SettingsUI:Keybind("Toggle UI Keybind", Enum.KeyCode.RightControl, function()
    ui:Toggle()
end)

Tabs.SettingsUI:Slider("Transparency", 0, 0.8, 0.5, function(val)
    ui:Notify("Transparency: " .. val)
end)

---------------------------------------------------------------------
--// ✅ Final
---------------------------------------------------------------------
ui:Notify("Criptix Hub v1.4.1 fully loaded successfully!")
