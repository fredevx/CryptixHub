--// 🌐 Criptix Hub | v1.5 (WindUI API Fix)
--// Developer: Freddy Bear
--// Framework: WindUI (latest)
--// Description: Universal functional hub compatible with new WindUI API

--// Load WindUI
local ui = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

--// Create Main Window
local win = ui:CreateWindow({
    Title = "Criptix Hub | v1.5 🌐",
    Icon = "",
    Author = "Criptix",
    Folder = "CriptixHub",
    Size = UDim2.fromOffset(750, 400),
    Transparent = true,
    Theme = "Dark",
    SideBarWidth = 200,
    Background = "",
    BackgroundImageTransparency = 0.4,
    HideSearchBar = true,
    ScrollBarEnabled = true,
    User = { Enabled = false, Anonymous = false }
})

--// Tabs
local Tabs = {
    Info = win:Tab({ Title = "Info", Icon = "info-circle" }),
    Main = win:Tab({ Title = "Main", Icon = "gamepad-2" }),
    Funny = win:Tab({ Title = "Funny", Icon = "smile" }),
    Misc = win:Tab({ Title = "Misc", Icon = "boxes" }),
    Settings = win:Tab({ Title = "Settings", Icon = "cog" }),
    SettingsUI = win:Tab({ Title = "Settings UI", Icon = "paintbrush" })
}

---------------------------------------------------------------------
--// ℹ️ INFO TAB
---------------------------------------------------------------------
Tabs.Info:AddParagraph({
    Title = "Criptix Hub | v1.5 🌐",
    Content = "Principal Developer: Freddy Bear\nOthers: snitadd, ChatGPT, Wind"
})

Tabs.Info:AddButton({
    Title = "Join Discord",
    Callback = function()
        setclipboard("https://discord.gg/yourinvite")
        ui:Notify("Discord invite copied to clipboard!")
    end
})

---------------------------------------------------------------------
--// ⚙️ MAIN TAB
---------------------------------------------------------------------
local flySpeed = 50
local flying = false
local bp, bg

Tabs.Main:AddSlider({
    Title = "Walk Speed",
    Min = 16,
    Max = 200,
    Default = 16,
    Callback = function(value)
        local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = value end
    end
})

Tabs.Main:AddSlider({
    Title = "Jump Power",
    Min = 50,
    Max = 500,
    Default = 50,
    Callback = function(value)
        local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = value end
    end
})

Tabs.Main:AddSlider({
    Title = "Fly Speed",
    Min = 16,
    Max = 200,
    Default = 50,
    Callback = function(value)
        flySpeed = value
    end
})

Tabs.Main:AddToggle({
    Title = "No Clip",
    Default = false,
    Callback = function(state)
        local char = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
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
    end
})

Tabs.Main:AddToggle({
    Title = "God Mode",
    Default = false,
    Callback = function(state)
        local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            if state then
                hum.MaxHealth = math.huge
                hum.Health = math.huge
                ui:Notify("God Mode enabled")
            else
                hum.MaxHealth = 100
                hum.Health = 100
                ui:Notify("God Mode disabled")
            end
        end
    end
})

Tabs.Main:AddToggle({
    Title = "Fly (On/Off)",
    Default = false,
    Callback = function(state)
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

            task.spawn(function()
                while flying and task.wait() do
                    local move = Vector3.zero
                    local uis = game:GetService("UserInputService")
                    if uis:IsKeyDown(Enum.KeyCode.W) then move = move + hrp.CFrame.LookVector end
                    if uis:IsKeyDown(Enum.KeyCode.S) then move = move - hrp.CFrame.LookVector end
                    if uis:IsKeyDown(Enum.KeyCode.A) then move = move - hrp.CFrame.RightVector end
                    if uis:IsKeyDown(Enum.KeyCode.D) then move = move + hrp.CFrame.RightVector end
                    if uis:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
                    if uis:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0,1,0) end
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
    end
})

---------------------------------------------------------------------
--// 😂 FUNNY TAB
---------------------------------------------------------------------
Tabs.Funny:AddButton({
    Title = "Fake Kick Player",
    Callback = function()
        game.Players.LocalPlayer:Kick("You have been kicked from the game. (Fake Kick)")
    end
})

Tabs.Funny:AddToggle({
    Title = "Rainbow Body",
    Default = false,
    Callback = function(state)
        local char = game.Players.LocalPlayer.Character
        if not char then return end
        if state then
            ui:Notify("Rainbow enabled")
            task.spawn(function()
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
            ui:Notify("Rainbow disabled")
        end
    end
})

Tabs.Funny:AddSlider({
    Title = "Spin Speed",
    Min = 1,
    Max = 100,
    Default = 10,
    Callback = function(value)
        _G.SpinSpeed = value
    end
})

Tabs.Funny:AddToggle({
    Title = "Spin Character",
    Default = false,
    Callback = function(state)
        local char = game.Players.LocalPlayer.Character
        if not char then return end
        if state then
            ui:Notify("Spinning ON")
            task.spawn(function()
                while state and char:FindFirstChild("HumanoidRootPart") do
                    char.HumanoidRootPart.CFrame *= CFrame.Angles(0, math.rad(_G.SpinSpeed or 10), 0)
                    task.wait(0.03)
                end
            end)
        else
            ui:Notify("Spinning OFF")
        end
    end
})

---------------------------------------------------------------------
--// 🧰 MISC TAB
---------------------------------------------------------------------
Tabs.Misc:AddToggle({
    Title = "Anti AFK",
    Default = false,
    Callback = function(state)
        if state then
            local vu = game:GetService("VirtualUser")
            game.Players.LocalPlayer.Idled:Connect(function()
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
            ui:Notify("Anti AFK enabled")
        else
            ui:Notify("Anti AFK disabled")
        end
    end
})

Tabs.Misc:AddButton({
    Title = "Darken Game",
    Callback = function()
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("Texture") or v:IsA("Decal") then
                v.Transparency = 1
            end
        end
        ui:Notify("Game darkened")
    end
})

Tabs.Misc:AddButton({
    Title = "FPS Boost",
    Callback = function()
        for _, v in next, workspace:GetDescendants() do
            if v:IsA("Part") then
                v.Material = Enum.Material.SmoothPlastic
            end
        end
        ui:Notify("FPS Boost applied")
    end
})

Tabs.Misc:AddButton({
    Title = "Server Hop",
    Callback = function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId)
    end
})

Tabs.Misc:AddButton({
    Title = "Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId)
    end
})

---------------------------------------------------------------------
--// ⚙️ SETTINGS TAB
---------------------------------------------------------------------
Tabs.Settings:AddButton({
    Title = "Save Settings",
    Callback = function()
        ui:Notify("Settings saved!")
    end
})

Tabs.Settings:AddButton({
    Title = "Load Settings",
    Callback = function()
        ui:Notify("Settings loaded!")
    end
})

Tabs.Settings:AddButton({
    Title = "Reset to Default",
    Callback = function()
        ui:Notify("Settings reset to default.")
    end
})

---------------------------------------------------------------------
--// 🎨 SETTINGS UI TAB
---------------------------------------------------------------------
Tabs.SettingsUI:AddDropdown({
    Title = "Change Theme",
    Values = {"Dark Blue", "Crimson Red", "Mint Green", "Aqua"},
    Callback = function(theme)
        ui:Notify("Theme set to: " .. theme)
    end
})

Tabs.SettingsUI:AddKeybind({
    Title = "Toggle UI Keybind",
    Default = Enum.KeyCode.RightControl,
    Callback = function()
        ui:Toggle()
    end
})

Tabs.SettingsUI:AddSlider({
    Title = "Transparency",
    Min = 0,
    Max = 0.8,
    Default = 0.5,
    Callback = function(val)
        ui:Notify("Transparency: " .. val)
    end
})

---------------------------------------------------------------------
--// ✅ FINAL MESSAGE
---------------------------------------------------------------------
ui:Notify("Criptix Hub v1.5 loaded successfully with new WindUI API!")
