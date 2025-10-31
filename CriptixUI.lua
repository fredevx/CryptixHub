-- CriptixUI.lua
-- CriptixUI v1.2.0 -- A custom WindUI-like framework for CriptixHub
-- Author: Freddy Bear (design) + assistant (implementation)
-- Features:
--   - Window: Open/Close/Toggle/Destroy
--   - Tab, Section, Divider, Paragraph, Button, Toggle, Slider, Input, Dropdown, Keybind, Colorpicker
--   - Notifications system
--   - Theme manager (many themes)
--   - OpenButtonMain (floating open button, draggable, saves position)
--   - Config save/load/delete/refresh (uses writefile/readfile/listfiles if available)
--   - Discord fetch/Update Info (safe pcall, fallback when HTTP disabled)
--   - Touch + mouse friendly sliders and keybinds
--   - Designed to be embedded in Universal.lua and be offline-friendly

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CriptixUI = {}
CriptixUI.__index = CriptixUI

-- utilities
local function safe_pcall(fn, ...)
    local ok, res = pcall(fn, ...)
    if not ok then warn("[CriptixUI] error:", res) end
    return ok, res
end

local function clamp(n, a, b)
    n = tonumber(n) or a
    if n < a then return a end
    if n > b then return b end
    return n
end

local function deepcopy(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k,v in pairs(t) do out[deepcopy(k)] = deepcopy(v) end
    return out
end

local function tween(obj, props, t, style, dir, cb)
    local info = TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    local tw = TweenService:Create(obj, info, props)
    tw:Play()
    if cb then tw.Completed:Connect(cb) end
    return tw
end

local function new(instClass, props, parent)
    local inst = Instance.new(instClass)
    if parent then inst.Parent = parent end
    if props then
        for k,v in pairs(props) do
            pcall(function() inst[k] = v end)
        end
    end
    return inst
end

-- themes
local Themes = {
    Dark = {
        Background = Color3.fromRGB(18,18,18),
        Panel = Color3.fromRGB(28,28,30),
        Accent = Color3.fromRGB(70,150,255),
        Text = Color3.fromRGB(240,240,240),
        Muted = Color3.fromRGB(170,170,180)
    },
    Light = {
        Background = Color3.fromRGB(244,244,244),
        Panel = Color3.fromRGB(225,225,230),
        Accent = Color3.fromRGB(40,120,255),
        Text = Color3.fromRGB(20,20,20),
        Muted = Color3.fromRGB(100,100,110)
    },
    Ocean = {
        Background = Color3.fromRGB(8,18,30),
        Panel = Color3.fromRGB(10,22,36),
        Accent = Color3.fromRGB(80,170,255),
        Text = Color3.fromRGB(230,240,250),
        Muted = Color3.fromRGB(140,160,180)
    },
    Crimson = {
        Background = Color3.fromRGB(30,6,6),
        Panel = Color3.fromRGB(44,8,8),
        Accent = Color3.fromRGB(255,90,80),
        Text = Color3.fromRGB(245,235,230),
        Muted = Color3.fromRGB(170,120,120)
    },
    Emerald = {
        Background = Color3.fromRGB(6,26,18),
        Panel = Color3.fromRGB(10,36,26),
        Accent = Color3.fromRGB(80,220,150),
        Text = Color3.fromRGB(235,245,240),
        Muted = Color3.fromRGB(140,180,160)
    },
    Purple = {
        Background = Color3.fromRGB(18,8,26),
        Panel = Color3.fromRGB(26,12,34),
        Accent = Color3.fromRGB(170,100,255),
        Text = Color3.fromRGB(240,235,250),
        Muted = Color3.fromRGB(150,120,160)
    }
}

-- internal default config
local INTERNAL_NAME = "CriptixHubUniversal"
local CONFIG_ROOT = "CriptixUI" -- used for file naming: CriptixUI_<name>.json
local defaultWindowConfig = {
    Theme = "Dark",
    Transparency = 0,
    Position = {0.5, 0, 0.5, 0}
}

-- file helpers
local function composeConfigPath(name)
    if not name or name == "" then name = INTERNAL_NAME end
    return (CONFIG_ROOT .. "_" .. name .. ".json")
end

local function saveConfigFile(name, tbl)
    if not writefile then return false end
    local path = composeConfigPath(name)
    local ok, enc = pcall(function() return HttpService:JSONEncode(tbl) end)
    if not ok then return false end
    pcall(function() writefile(path, enc) end)
    return true
end

local function loadConfigFile(name)
    if not isfile then return nil end
    local path = composeConfigPath(name)
    if not isfile(path) then return nil end
    local ok, txt = pcall(function() return readfile(path) end)
    if not ok or not txt then return nil end
    local ok2, dec = pcall(function() return HttpService:JSONDecode(txt) end)
    if not ok2 then return nil end
    return dec
end

local function listConfigFiles()
    if not listfiles then return {} end
    local out = {}
    local ok, files = pcall(function() return listfiles("") end)
    if not ok or not files then return out end
    for _,f in ipairs(files) do
        local name = f:match("([^/\\]+)%.json$")
        if name and name:match("^" .. CONFIG_ROOT .. "_") then
            local clean = name:gsub("^" .. CONFIG_ROOT .. "_", "")
            table.insert(out, clean)
        end
    end
    return out
end

-- Discord fetch helper
local function fetchDiscordInvite(inviteCode)
    if not inviteCode or inviteCode == "" then return nil, "no_invite" end
    local url = "https://discord.com/api/v10/invites/" .. inviteCode .. "?with_counts=true&with_expiration=true"
    local ok, body = pcall(function() return game:HttpGet(url) end)
    if not ok or not body then return nil, "http_error" end
    local ok2, data = pcall(function() return HttpService:JSONDecode(body) end)
    if not ok2 or not data then return nil, "parse_error" end
    if data.guild then
        return {
            name = data.guild.name,
            members = data.approximate_member_count,
            online = data.approximate_presence_count,
            id = data.guild.id,
            icon = data.guild.icon
        }
    end
    return nil, "no_guild"
end

-- Notification helper (simple)
local function notify(parentGui, title, desc, duration)
    duration = duration or 4
    if not parentGui then return end
    local sg = parentGui:FindFirstChild("CriptixNotifications")
    if not sg then sg = Instance.new("ScreenGui"); sg.Name = "CriptixNotifications"; sg.ResetOnSpawn = false; sg.Parent = parentGui end
    local frame = new("Frame", {Parent = sg, Size = UDim2.fromOffset(300, 72), Position = UDim2.new(1, -10, 0, 10), AnchorPoint = Vector2.new(1,0), BackgroundColor3 = Themes.Dark.Panel, BorderSizePixel = 0})
    new("UICorner", {Parent = frame, CornerRadius = UDim.new(0,10)})
    local t = new("TextLabel", {Parent = frame, Text = title, Font = Enum.Font.SourceSansSemibold, TextSize = 15, TextColor3 = Themes.Dark.Text, BackgroundTransparency = 1, Position = UDim2.new(0,8,0,6), Size = UDim2.new(1,-16,0,20)})
    local d = new("TextLabel", {Parent = frame, Text = desc, Font = Enum.Font.SourceSans, TextSize = 13, TextColor3 = Themes.Dark.Muted, BackgroundTransparency = 1, Position = UDim2.new(0,8,0,28), Size = UDim2.new(1,-16,0,36), TextWrapped = true})
    frame.BackgroundTransparency = 1
    tween(frame, {BackgroundTransparency = 0}, 0.18)
    task.delay(duration, function() tween(frame, {BackgroundTransparency = 1}, 0.18, nil, nil, function() pcall(function() frame:Destroy() end) end) end)
end

-- Core: Create a Window object
function CriptixUI:CreateWindow(opts)
    opts = opts or {}
    local win = setmetatable({}, CriptixUI)
    win.Title = opts.Title or ("CriptixHub Universal | v1.4.1")
    win.InternalName = opts.InternalName or INTERNAL_NAME
    win.Size = opts.Size or UDim2.fromOffset(880, 520)
    win.ThemeName = opts.Theme or defaultWindowConfig.Theme
    win.Theme = Themes[win.ThemeName] or Themes.Dark
    win.SideWidth = opts.SideWidth or 200
    win.ConfigName = opts.ConfigName or win.InternalName
    win.Tabs = {}
    win.User = { Enabled = true, Anonymous = false } -- default: not anonymous (we'll allow override)
    win.Notifications = opts.Notifications or false

    -- ScreenGui
    local sg = new("ScreenGui", {Name = "CriptixUI_" .. tostring(win.InternalName), ResetOnSpawn = false}, playerGui)
    win.ScreenGui = sg

    -- main frame
    local frame = new("Frame", {
        Name = "MainFrame",
        Parent = sg,
        Size = win.Size,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundColor3 = win.Theme.Background,
        BorderSizePixel = 0,
        Visible = false
    })
    new("UICorner", {Parent = frame, CornerRadius = UDim.new(0, 12)})
    win.Frame = frame

    -- topbar (title + subtitle)
    local top = new("Frame", {Parent = frame, Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1})
    win.Top = top
    local title = new("TextLabel", {Parent = top, Text = win.Title, Font = Enum.Font.SourceSansSemibold, TextSize = 18, TextColor3 = win.Theme.Text, BackgroundTransparency = 1, Size = UDim2.new(0.6,0,1,0), Position = UDim2.new(0.02,0,0,0), TextXAlignment = Enum.TextXAlignment.Left})
    win.TitleLabel = title
    local subtitle = new("TextLabel", {Parent = top, Text = "Developed by Freddy Bear", Font = Enum.Font.SourceSans, TextSize = 12, TextColor3 = win.Theme.Muted, BackgroundTransparency = 1, Size = UDim2.new(0.35,0,1,0), Position = UDim2.new(0.62,0,0,0), TextXAlignment = Enum.TextXAlignment.Left})
    win.Subtitle = subtitle

    -- controls (close/min)
    local btnClose = new("TextButton", {Parent = top, Size = UDim2.new(0,30,0,24), Position = UDim2.new(1,-38,0.5,-12), BackgroundTransparency = 1, Text = "✕", Font = Enum.Font.SourceSansBold, TextSize = 18, TextColor3 = win.Theme.Text})
    local btnMin = new("TextButton", {Parent = top, Size = UDim2.new(0,30,0,24), Position = UDim2.new(1,-74,0.5,-12), BackgroundTransparency = 1, Text = "—", Font = Enum.Font.SourceSansBold, TextSize = 18, TextColor3 = win.Theme.Text})
    win.BtnClose = btnClose; win.BtnMin = btnMin

    -- sidebar & content
    local sidebar = new("Frame", {Parent = frame, Size = UDim2.new(0, win.SideWidth, 1, -36), Position = UDim2.new(0,0,0,36), BackgroundTransparency = 1})
    win.Sidebar = sidebar
    local content = new("Frame", {Parent = frame, Size = UDim2.new(1, -win.SideWidth - 16, 1, -46), Position = UDim2.new(0, win.SideWidth + 8, 0, 38), BackgroundTransparency = 1})
    win.Content = content

    new("UIListLayout", {Parent = sidebar, Padding = UDim.new(0,8), FillDirection = Enum.FillDirection.Vertical, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Top})

    -- internal helper to show selected tab
    function win:SelectTab(tabObj)
        for _,t in ipairs(self.Tabs) do
            t.Frame.Visible = false
            t.Button.BackgroundTransparency = 0.8
        end
        if tabObj and tabObj.Frame then
            tabObj.Frame.Visible = true
            tabObj.Button.BackgroundTransparency = 0.4
            -- scroll to top
            if tabObj.Frame:IsA("ScrollingFrame") then tabObj.Frame.CanvasPosition = Vector2.new(0,0) end
        end
    end

    -- show/hide with tween (fade)
    win.Visible = false
    function win:Open()
        if self.Visible then return end
        self.Visible = true
        self.Frame.Visible = true
        self.Frame.BackgroundTransparency = 1
        tween(self.Frame, {BackgroundTransparency = 0}, 0.22)
    end
    function win:Close()
        if not self.Visible then return end
        self.Visible = false
        tween(self.Frame, {BackgroundTransparency = 1}, 0.18, nil, nil, function() pcall(function() self.Frame.Visible = false end) end)
    end
    function win:Toggle()
        if self.Visible then self:Close() else self:Open() end
    end
    function win:Destroy()
        if self.ScreenGui then pcall(function() self.ScreenGui:Destroy() end) end
    end

    -- Set theme
    function win:SetTheme(name)
        if not name or not Themes[name] then return end
        self.ThemeName = name
        self.Theme = Themes[name]
        self.Frame.BackgroundColor3 = self.Theme.Background
        self.TitleLabel.TextColor3 = self.Theme.Text
        self.Subtitle.TextColor3 = self.Theme.Muted
        for _,t in ipairs(self.Tabs) do
            pcall(function() t.Button.TextColor3 = self.Theme.Text end)
        end
    end

    -- Save/Load/Delete/Refresh config API
    function win:SaveConfig(name)
        name = name or self.ConfigName or INTERNAL_NAME
        local data = {
            Theme = self.ThemeName,
            Transparency = self.Frame.BackgroundTransparency or 0,
            Position = {self.Frame.Position.X.Scale, self.Frame.Position.X.Offset, self.Frame.Position.Y.Scale, self.Frame.Position.Y.Offset}
        }
        return saveConfigFile(name, data)
    end

    function win:LoadConfig(name)
        name = name or self.ConfigName or INTERNAL_NAME
        local data = loadConfigFile(name)
        if not data then return false end
        if data.Theme then self:SetTheme(data.Theme) end
        if data.Transparency then self.Frame.BackgroundTransparency = data.Transparency end
        if data.Position and #data.Position >= 4 then
            local xScale = data.Position[1] or 0.5
            local xOffset = data.Position[2] or 0
            local yScale = data.Position[3] or 0.5
            local yOffset = data.Position[4] or 0
            self.Frame.Position = UDim2.new(xScale, xOffset, yScale, yOffset)
        end
        return true
    end

    function win:DeleteConfig(name)
        if not name or name == "" or not os then return false end
        if not isfile then return false end
        local path = composeConfigPath(name)
        if not isfile(path) then return false end
        local ok, res = pcall(function() delfile(path) end)
        return ok
    end

    function win:RefreshConfigList()
        return listConfigFiles()
    end

    -- tab factory
    function win:Tab(opts)
        opts = opts or {}
        local tabBtn = new("TextButton", {Parent = sidebar, Size = UDim2.new(1, -20, 0, 34), Text = " "..tostring(opts.Title or "Tab"), BackgroundColor3 = win.Theme.Panel, BackgroundTransparency = 0.8, Font = Enum.Font.SourceSansSemibold, TextSize = 15, TextColor3 = win.Theme.Text})
        new("UICorner", {Parent = tabBtn, CornerRadius = UDim.new(0,8)})
        local tabFrame = new("ScrollingFrame", {Parent = content, Size = UDim2.new(1,-10,1,0), BackgroundTransparency = 1, CanvasSize = UDim2.new(0,0,0,0), ScrollBarThickness = 6, Visible = false})
        new("UIListLayout", {Parent = tabFrame, Padding = UDim.new(0,6), SortOrder = Enum.SortOrder.LayoutOrder})
        new("UIPadding", {Parent = tabFrame, PaddingTop = UDim.new(0,6), PaddingLeft = UDim.new(0,6), PaddingRight = UDim.new(0,6), PaddingBottom = UDim.new(0,6)})

        local tab = { Button = tabBtn, Frame = tabFrame, Sections = {} }
        tabBtn.MouseButton1Click:Connect(function()
            win:SelectTab(tab)
        end)

        -- Divider
        function tab:Divider()
            local d = new("Frame", {Parent = self.Frame, Size = UDim2.new(1,0,0,2), BackgroundColor3 = win.Theme.Panel, BorderSizePixel = 0})
            new("UICorner", {Parent = d, CornerRadius = UDim.new(0,6)})
            return d
        end

        -- Section
        function tab:Section(opts)
            opts = opts or {}
            local sec = new("Frame", {Parent = self.Frame, Size = UDim2.new(1,-10,0,60), BackgroundTransparency = 1, LayoutOrder = #self.Sections + 1})
            local title = new("TextLabel", {Parent = sec, Size = UDim2.new(1,0,0,20), Position = UDim2.new(0,0,0,0), BackgroundTransparency = 1, Text = tostring(opts.Title or ""), Font = Enum.Font.SourceSansSemibold, TextSize = opts.TextSize or 16, TextColor3 = win.Theme.Text, TextXAlignment = Enum.TextXAlignment.Center})
            table.insert(self.Sections, sec)
            return sec
        end

        -- Paragraph
        function tab:Paragraph(opts)
            opts = opts or {}
            local p = new("Frame", {Parent = self.Frame, Size = UDim2.new(1,-10,0,64), BackgroundTransparency = 1, LayoutOrder = #self.Sections + 1})
            local t = new("TextLabel", {Parent = p, Size = UDim2.new(1,0,0,20), Position = UDim2.new(0,0,0,0), BackgroundTransparency = 1, Text = tostring(opts.Title or ""), Font = Enum.Font.SourceSansSemibold, TextSize = 14, TextColor3 = win.Theme.Text, TextXAlignment = Enum.TextXAlignment.Left})
            local d = new("TextLabel", {Parent = p, Size = UDim2.new(1,0,0,40), Position = UDim2.new(0,0,0,20), BackgroundTransparency = 1, Text = tostring(opts.Desc or ""), Font = Enum.Font.SourceSans, TextSize = 13, TextColor3 = win.Theme.Muted, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left})
            return p
        end

        -- Button
        function tab:Button(opts)
            opts = opts or {}
            local btn = new("TextButton", {Parent = self.Frame, Size = UDim2.new(0,160,0,34), Text = tostring(opts.Title or "Button"), Font = Enum.Font.SourceSansSemibold, TextSize = 14, TextColor3 = win.Theme.Text, BackgroundColor3 = win.Theme.Panel, BorderSizePixel = 0, LayoutOrder = #self.Sections + 1})
            new("UICorner", {Parent = btn, CornerRadius = UDim.new(0,8)})
            if opts.Desc then btn.ToolTip = opts.Desc end
            btn.MouseButton1Click:Connect(function()
                safe_pcall(function() if opts.Callback then opts.Callback() end end)
            end)
            return btn
        end

        -- Toggle
        function tab:Toggle(opts)
            opts = opts or {}
            local f = new("Frame", {Parent = self.Frame, Size = UDim2.new(0,220,0,28), BackgroundTransparency = 1, LayoutOrder = #self.Sections + 1})
            local lbl = new("TextLabel", {Parent = f, Size = UDim2.new(0,130,1,0), BackgroundTransparency = 1, Text = tostring(opts.Title or "Toggle"), Font = Enum.Font.SourceSans, TextSize = 14, TextColor3 = win.Theme.Text})
            local btn = new("TextButton", {Parent = f, Size = UDim2.new(0,60,0,22), Position = UDim2.new(1,-66,0.5,-11), Text = (opts.Default and "ON" or "OFF"), Font = Enum.Font.SourceSansSemibold, TextSize = 12, TextColor3 = win.Theme.Text, BackgroundColor3 = (opts.Default and Color3.fromRGB(60,160,80) or Color3.fromRGB(70,70,70))})
            new("UICorner", {Parent = btn, CornerRadius = UDim.new(0,6)})
            local state = opts.Default or false
            btn.MouseButton1Click:Connect(function()
                state = not state
                btn.Text = state and "ON" or "OFF"
                btn.BackgroundColor3 = state and Color3.fromRGB(60,160,80) or Color3.fromRGB(70,70,70)
                safe_pcall(function() if opts.Callback then opts.Callback(state) end end)
            end)
            return f
        end

        -- Slider (draggable + touch friendly)
        function tab:Slider(title, min, max, default, callback)
            min = tonumber(min) or 0; max = tonumber(max) or 100; default = tonumber(default) or min
            local cont = new("Frame", {Parent = self.Frame, Size = UDim2.new(0,360,0,36), BackgroundTransparency = 1, LayoutOrder = #self.Sections + 1})
            local lbl = new("TextLabel", {Parent = cont, Size = UDim2.new(0,180,1,0), BackgroundTransparency = 1, Text = tostring(title or "Slider"), Font = Enum.Font.SourceSans, TextSize = 14, TextColor3 = win.Theme.Text})
            local valLbl = new("TextLabel", {Parent = cont, Size = UDim2.new(0,80,1,0), Position = UDim2.new(1,-80,0,0), BackgroundTransparency = 1, Text = tostring(default), Font = Enum.Font.SourceSansSemibold, TextSize = 14, TextColor3 = win.Theme.Muted})
            local trackBg = new("Frame", {Parent = cont, Size = UDim2.new(0,200,0,10), Position = UDim2.new(0.5,-10,0.5,-5), BackgroundColor3 = win.Theme.Panel, BorderSizePixel = 0})
            new("UICorner", {Parent = trackBg, CornerRadius = UDim.new(0,6)})
            local fill = new("Frame", {Parent = trackBg, Size = UDim2.new(0,0,1,0), BackgroundColor3 = win.Theme.Accent, BorderSizePixel = 0})
            new("UICorner", {Parent = fill, CornerRadius = UDim.new(0,6)})
            local thumb = new("ImageButton", {Parent = trackBg, Size = UDim2.new(0,18,0,18), Position = UDim2.new(0, -9, 0.5, -9), BackgroundColor3 = win.Theme.Accent, AutoButtonColor = false})
            new("UICorner", {Parent = thumb, CornerRadius = UDim.new(1,0)})
            thumb.ZIndex = trackBg.ZIndex + 1

            local value = default
            local function update(v)
                v = clamp(v, min, max)
                local ratio = (v - min) / math.max(0.0001, (max - min))
                fill.Size = UDim2.new(ratio, 0, 1, 0)
                thumb.Position = UDim2.new(ratio, -9, 0.5, -9)
                valLbl.Text = tostring(math.floor((v*100))/100)
                value = v
                safe_pcall(function() if callback then callback(v) end end)
            end

            local dragging = false
            local function posToValue(pos)
                local abs = trackBg.AbsolutePosition
                local size = trackBg.AbsoluteSize
                local rel = clamp((pos.X - abs.X) / math.max(1, size.X), 0, 1)
                return min + (max - min) * rel
            end

            thumb.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then dragging = true end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                    local v = posToValue(inp.Position)
                    update(v)
                end
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if dragging and (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) then dragging = false end
            end)
            trackBg.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    local v = posToValue(inp.Position)
                    update(v)
                end
            end)

            update(default)
            return cont
        end

        -- Input
        function tab:Input(opts)
            opts = opts or {}
            local f = new("Frame", {Parent = self.Frame, Size = UDim2.new(0,380,0,36), BackgroundTransparency = 1, LayoutOrder = #self.Sections + 1})
            local lbl = new("TextLabel", {Parent = f, Size = UDim2.new(0,120,1,0), BackgroundTransparency = 1, Text = tostring(opts.Title or "Input"), Font = Enum.Font.SourceSans, TextColor3 = win.Theme.Text})
            local box = new("TextBox", {Parent = f, Size = UDim2.new(0,240,0,28), Position = UDim2.new(0,130,0,4), Text = tostring(opts.Value or ""), PlaceholderText = tostring(opts.Placeholder or ""), ClearTextOnFocus = false, Font = Enum.Font.SourceSans, TextSize = 14, TextColor3 = win.Theme.Text, BackgroundColor3 = win.Theme.Panel, BorderSizePixel = 0})
            new("UICorner", {Parent = box, CornerRadius = UDim.new(0,6)})
            box.FocusLost:Connect(function(enter)
                if enter and opts.Callback then safe_pcall(function() opts.Callback(box.Text) end) end
            end)
            return f
        end

        -- Dropdown
        function tab:Dropdown(opts)
            opts = opts or {}
            local frame = new("Frame", {Parent = self.Frame, Size = UDim2.new(0,360,0,34), BackgroundTransparency = 1, LayoutOrder = #self.Sections + 1})
            local lbl = new("TextLabel", {Parent = frame, Size = UDim2.new(0,160,1,0), BackgroundTransparency = 1, Text = tostring(opts.Title or "Dropdown"), Font = Enum.Font.SourceSans, TextColor3 = win.Theme.Text})
            local btn = new("TextButton", {Parent = frame, Size = UDim2.new(0,170,0,28), Position = UDim2.new(0.45,0,0.1,0), Text = (opts.Value or (opts.Values and opts.Values[1]) or ""), BackgroundColor3 = win.Theme.Panel, TextColor3 = win.Theme.Text})
            new("UICorner", {Parent = btn, CornerRadius = UDim.new(0,6)})
            local menu
            btn.MouseButton1Click:Connect(function()
                if menu and menu.Parent then menu:Destroy(); menu = nil; return end
                menu = new("Frame", {Parent = self.Frame, Size = UDim2.new(0,170,0, math.max(28, (#(opts.Values or {}) * 28))), Position = UDim2.new(btn.Position.X.Scale, btn.Position.X.Offset, btn.Position.Y.Scale, btn.Position.Y.Offset + 34), BackgroundColor3 = win.Theme.Panel})
                new("UIListLayout", {Parent = menu, Padding = UDim.new(0,2)})
                for i,v in ipairs(opts.Values or {}) do
                    local it = new("TextButton", {Parent = menu, Size = UDim2.new(1,-8,0,26), Position = UDim2.new(0,4,0,(i-1)*28), Text = tostring(v), BackgroundColor3 = win.Theme.Panel, TextColor3 = win.Theme.Text})
                    new("UICorner", {Parent = it, CornerRadius = UDim.new(0,6)})
                    it.MouseButton1Click:Connect(function()
                        btn.Text = tostring(v)
                        safe_pcall(function() if opts.Callback then opts.Callback(v) end end)
                        if menu and menu.Parent then menu:Destroy() end
                    end)
                end
            end)
            return frame
        end

        -- Keybind
        function tab:Keybind(opts)
            opts = opts or {}
            local f = new("Frame", {Parent = self.Frame, Size = UDim2.new(0,360,0,36), BackgroundTransparency = 1, LayoutOrder = #self.Sections + 1})
            local lbl = new("TextLabel", {Parent = f, Size = UDim2.new(0,180,1,0), BackgroundTransparency = 1, Text = tostring(opts.Title or "Keybind"), Font = Enum.Font.SourceSans, TextColor3 = win.Theme.Text})
            local btn = new("TextButton", {Parent = f, Position = UDim2.new(0.6,0,0.12,0), Size = UDim2.new(0,120,0,28), Text = (opts.Default and tostring(opts.Default) or "Set Key"), BackgroundColor3 = win.Theme.Panel, TextColor3 = win.Theme.Text})
            new("UICorner", {Parent = btn, CornerRadius = UDim.new(0,6)})
            btn.MouseButton1Click:Connect(function()
                btn.Text = "Press key..."
                local conn
                conn = UserInputService.InputBegan:Connect(function(inp, processed)
                    if processed then return end
                    if inp.UserInputType == Enum.UserInputType.Keyboard then
                        btn.Text = tostring(inp.KeyCode.Name)
                        safe_pcall(function() if opts.Callback then opts.Callback(inp.KeyCode) end end)
                        conn:Disconnect()
                    end
                end)
            end)
            return f
        end

        -- Colorpicker (basic)
        function tab:Colorpicker(opts)
            opts = opts or {}
            local f = new("Frame", {Parent = self.Frame, Size = UDim2.new(0,360,0,40), BackgroundTransparency = 1, LayoutOrder = #self.Sections + 1})
            local lbl = new("TextLabel", {Parent = f, Size = UDim2.new(0,160,1,0), BackgroundTransparency = 1, Text = tostring(opts.Title or "Color"), Font = Enum.Font.SourceSans, TextColor3 = win.Theme.Text})
            local preview = new("Frame", {Parent = f, Size = UDim2.new(0,36,0,24), Position = UDim2.new(0.6,0,0.12,0), BackgroundColor3 = opts.Default or win.Theme.Accent})
            new("UICorner", {Parent = preview, CornerRadius = UDim.new(0,6)})
            local btn = new("TextButton", {Parent = f, Size = UDim2.new(0,120,0,28), Position = UDim2.new(0.75,0,0.12,0), Text = "Pick", BackgroundColor3 = win.Theme.Panel, TextColor3 = win.Theme.Text})
            new("UICorner", {Parent = btn, CornerRadius = UDim.new(0,6)})
            btn.MouseButton1Click:Connect(function()
                -- simple color cycle for demo; implement proper picker UI if needed
                local col = Color3.fromHSV(math.random(), 0.8, 0.9)
                preview.BackgroundColor3 = col
                safe_pcall(function() if opts.Callback then opts.Callback(col) end end)
            end)
            return f
        end

        table.insert(win.Tabs, tab)
        return tab
    end

    -- Finish init
    return win
end

-- OpenButtonMain (original-style floating button, configurable)
function CriptixUI:EnableOpenButton(opts)
    opts = opts or {}
    local label = opts.Label or "CriptixHub"
    local anchor = opts.Anchor or UDim2.new(1, -70, 1, -70)
    local parentGui = playerGui

    local sg = new("ScreenGui", {Name = "CriptixUI_OpenButton", ResetOnSpawn = false}, parentGui)
    local btn = new("TextButton", {Parent = sg, Name = "OpenButtonMain", Size = UDim2.new(0, 110, 0, 44), Position = anchor, BackgroundColor3 = (Themes.Dark and Themes.Dark.Panel or Color3.fromRGB(30,30,30)), Text = label, Font = Enum.Font.SourceSansSemibold, TextSize = 14, TextColor3 = (Themes.Dark and Themes.Dark.Text or Color3.new(1,1,1))})
    new("UICorner", {Parent = btn, CornerRadius = UDim.new(0,8)})
    btn.Active = true
    btn.Draggable = true

    local function savePos()
        if not writefile then return end
        local pos = btn.Position
        local path = ("CriptixUI_OpenButtonPos.json")
        pcall(function() writefile(path, HttpService:JSONEncode({XScale = pos.X.Scale, XOffset = pos.X.Offset, YScale = pos.Y.Scale, YOffset = pos.Y.Offset})) end)
    end
    local function loadPos()
        if not isfile then return end
        local path = ("CriptixUI_OpenButtonPos.json")
        if not isfile(path) then return end
        local ok, txt = pcall(function() return readfile(path) end)
        if not ok or not txt then return end
        local ok2, dec = pcall(function() return HttpService:JSONDecode(txt) end)
        if not ok2 then return end
        pcall(function()
            btn.Position = UDim2.new(dec.XScale or 1, dec.XOffset or -70, dec.YScale or 1, dec.YOffset or -70)
        end)
    end
    loadPos()

    -- toggles the window if present
    btn.MouseButton1Click:Connect(function()
        -- find main window ScreenGui
        local main = playerGui:FindFirstChild("CriptixUI_" .. INTERNAL_NAME)
        if main and main:FindFirstChild("MainFrame") then
            local frame = main.MainFrame
            -- toggle visibility via frame's parent object created by CreateWindow:Open/Close will handle fade when used directly,
            -- here we just toggle visible property and basic fade for compatibility
            if frame.Visible then
                tween(frame, {BackgroundTransparency = 1}, 0.18, nil, nil, function() frame.Visible = false end)
                btn.Text = label
            else
                frame.Visible = true
                frame.BackgroundTransparency = 1
                tween(frame, {BackgroundTransparency = 0}, 0.22)
                btn.Text = "✖"
            end
        else
            -- no main window found
            notify(playerGui, "CriptixUI", "Main window not loaded", 3)
        end
    end)

    btn.MouseLeave:Connect(savePos)
    return sg, btn
end

-- Helper to insert a prebuilt Info tab with Discord and config utils (Dad.lua style)
function CriptixUI:AttachDefaultInfo(win, inviteCode)
    if not win then return end
    local InfoTab = win:Tab({Title = "Info"})
    InfoTab:Divider()
    InfoTab:Section({Title = "Developer", TextSize = 17})
    InfoTab:Divider()
    InfoTab:Paragraph({Title = "Freddy Bear (Principal Developer)", Desc = "Creator of Criptix Hub Universal"})
    InfoTab:Paragraph({Title = "Assistant", Desc = "CriptixUI by assistant"})
    InfoTab:Divider()
    InfoTab:Section({Title = "Save and Load", TextSize = 17})
    InfoTab:Divider()

    -- config name input
    _G.Criptix_ConfigName = _G.Criptix_ConfigName or ""
    InfoTab:Input({Title = "Name Config", Placeholder = "config_name", Callback = function(txt) _G.Criptix_ConfigName = txt end})

    local files = win:RefreshConfigList() or {}
    local filesDropdown = InfoTab:Dropdown({Title = "Select Config File", Values = files, Callback = function(f) _G.Criptix_ConfigName = f end})

    InfoTab:Button({Title = "Save Config", Callback = function()
        if not _G.Criptix_ConfigName or _G.Criptix_ConfigName == "" then notify(playerGui, "CriptixUI", "Provide a config name", 3); return end
        local ok = win:SaveConfig(_G.Criptix_ConfigName)
        if ok then notify(playerGui, "CriptixUI", "Saved config: ".._G.Criptix_ConfigName, 3) else notify(playerGui, "CriptixUI", "Save failed (no writefile)", 3) end
    end})

    InfoTab:Button({Title = "Load Config", Callback = function()
        if not _G.Criptix_ConfigName or _G.Criptix_ConfigName == "" then notify(playerGui, "CriptixUI", "Provide a config name", 3); return end
        local ok = win:LoadConfig(_G.Criptix_ConfigName)
        if ok then notify(playerGui, "CriptixUI", "Loaded config: ".._G.Criptix_ConfigName, 3) else notify(playerGui, "CriptixUI", "Load failed", 3) end
    end})

    InfoTab:Button({Title = "Delete Config", Callback = function()
        if not _G.Criptix_ConfigName or _G.Criptix_ConfigName == "" then notify(playerGui, "CriptixUI", "Provide a config name", 3); return end
        local ok = win:DeleteConfig(_G.Criptix_ConfigName)
        if ok then notify(playerGui, "CriptixUI", "Deleted config: ".._G.Criptix_ConfigName, 3) else notify(playerGui, "CriptixUI", "Delete failed", 3) end
    end})

    InfoTab:Button({Title = "Refresh Config List", Callback = function()
        local list = win:RefreshConfigList()
        filesDropdown = InfoTab:Dropdown({Title = "Select Config File", Values = list, Callback = function(f) _G.Criptix_ConfigName = f end})
        notify(playerGui, "CriptixUI", "Config list refreshed", 2)
    end})

    InfoTab:Divider()
    InfoTab:Section({Title = "Discord", TextSize = 17})
    InfoTab:Divider()

    local invite = inviteCode or ""
    local placeholder = InfoTab:Paragraph({Title = "Discord", Desc = "Fetching..."})

    -- create update button and copy button
    InfoTab:Button({Title = "Update Info", Callback = function()
        spawn(function()
            local res, err = fetchDiscordInvite(invite)
            if res then
                local desc = "• Members: "..tostring(res.members).."\n• Online: "..tostring(res.online)
                InfoTab:Paragraph({Title = res.name, Desc = desc})
            else
                InfoTab:Paragraph({Title = "Discord Info Unavailable", Desc = tostring(err)})
            end
        end)
    end})

    InfoTab:Button({Title = "Copy Discord Invite", Callback = function()
        pcall(function() setclipboard("https://discord.gg/" .. invite) end)
        notify(playerGui, "CriptixUI", "Invite copied to clipboard", 2)
    end})

    -- initial fetch (non-blocking)
    spawn(function()
        local res, err = fetchDiscordInvite(invite)
        if res then
            local desc = "• Members: "..tostring(res.members).."\n• Online: "..tostring(res.online)
            InfoTab:Paragraph({Title = res.name, Desc = desc})
        else
            InfoTab:Paragraph({Title = "Discord Info Unavailable", Desc = tostring(err)})
        end
    end)
end

-- Return module
return CriptixUI
