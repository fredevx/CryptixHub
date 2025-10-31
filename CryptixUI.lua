-- CriptixUI.lua
-- CriptixUI v1.0.0
-- Reimplementation of WindUI main structure, rebranded to "CriptixHub"
-- Default Title: "CryptixHub {GAME} | v0.0.0"
-- Features:
--  - Window API: Open/Close/Toggle/Destroy
--  - Tab/Section/Divider/Paragraph/Button/Toggle/Slider/Input/Dropdown/Keybind/Colorpicker
--  - Config save/load/delete/refresh (writefile/readfile/listfiles if available)
--  - Discord info fetch + Update/Copy Invite
--  - OpenButtonMain (copied from WindUI main.lua style button)
--  - Themes (Dark default) and runtime theme switching
--  - Animations via TweenService
--  - Touch + mouse friendly controls
-- Notes:
--  - This module returns a table with :CreateWindow() and helpers

-- ===== Services =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- ===== Utilities =====
local function safe_pcall(fn, ...)
    local ok, res = pcall(fn, ...)
    if not ok then
        warn("[CriptixUI] error:", res)
    end
    return ok, res
end

local function cloneTable(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k,v in pairs(t) do out[k] = cloneTable(v) end
    return out
end

local function tween(inst, props, time, style, dir, cb)
    local info = TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    local tw = TweenService:Create(inst, info, props)
    tw:Play()
    if cb then tw.Completed:Connect(cb) end
    return tw
end

local function new(class, props, parent)
    local obj = Instance.new(class)
    if parent then obj.Parent = parent end
    if props then
        for k,v in pairs(props) do
            pcall(function() obj[k] = v end)
        end
    end
    return obj
end

local function clamp(v, a, b)
    v = tonumber(v) or a
    if v < a then return a end
    if v > b then return b end
    return v
end

-- ===== Themes =====
local Themes = {
    Dark = {
        Background = Color3.fromRGB(18,18,18);
        Panel = Color3.fromRGB(26,26,26);
        Accent = Color3.fromRGB(64,160,255);
        Text = Color3.fromRGB(240,240,240);
        Muted = Color3.fromRGB(170,170,180);
    },
    Light = {
        Background = Color3.fromRGB(245,245,245);
        Panel = Color3.fromRGB(230,230,230);
        Accent = Color3.fromRGB(40,120,255);
        Text = Color3.fromRGB(30,30,30);
        Muted = Color3.fromRGB(100,100,100);
    },
    Ocean = {
        Background = Color3.fromRGB(8,16,28);
        Panel = Color3.fromRGB(12,20,36);
        Accent = Color3.fromRGB(80,170,240);
        Text = Color3.fromRGB(230,240,250);
        Muted = Color3.fromRGB(140,160,180);
    },
    Crimson = {
        Background = Color3.fromRGB(30,6,6);
        Panel = Color3.fromRGB(44,8,8);
        Accent = Color3.fromRGB(255,90,80);
        Text = Color3.fromRGB(245,235,230);
        Muted = Color3.fromRGB(170,120,120);
    },
    Emerald = {
        Background = Color3.fromRGB(6,26,18);
        Panel = Color3.fromRGB(10,36,26);
        Accent = Color3.fromRGB(80,220,150);
        Text = Color3.fromRGB(235,245,240);
        Muted = Color3.fromRGB(140,180,160);
    },
    Purple = {
        Background = Color3.fromRGB(18,8,26);
        Panel = Color3.fromRGB(26,12,34);
        Accent = Color3.fromRGB(170,100,255);
        Text = Color3.fromRGB(240,235,250);
        Muted = Color3.fromRGB(150,120,160);
    }
}

-- ===== Config file helpers =====
local MODULE_NAME = "CriptixUI"
local function cfgPath(name)
    if not name or name == "" then name = "default" end
    return MODULE_NAME .. "_" .. tostring(name) .. ".json"
end

local function saveConfig(name, tbl)
    if not writefile then return false end
    local path = cfgPath(name)
    local ok, enc = pcall(function() return HttpService:JSONEncode(tbl) end)
    if not ok then return false end
    pcall(function() writefile(path, enc) end)
    return true
end

local function loadConfig(name)
    if not isfile then return nil end
    local path = cfgPath(name)
    if not isfile(path) then return nil end
    local ok, txt = pcall(function() return readfile(path) end)
    if not ok then return nil end
    local ok2, tbl = pcall(function() return HttpService:JSONDecode(txt) end)
    if not ok2 then return nil end
    return tbl
end

local function listConfigs()
    if not listfiles then return {} end
    local ok, files = pcall(function() return listfiles("") end)
    local out = {}
    if not ok or not files then return out end
    for _,f in ipairs(files) do
        local name = f:match("([^/\\]+)%.json$")
        if name and name:match("^" .. MODULE_NAME .. "_") then
            local clean = name:gsub("^" .. MODULE_NAME .. "_", "")
            table.insert(out, clean)
        end
    end
    return out
end

-- ===== Discord fetch helper =====
local function fetchDiscordInvite(invite)
    if not invite or invite == "" then return nil, "no_invite" end
    local url = ("https://discord.com/api/v10/invites/%s?with_counts=true&with_expiration=true"):format(tostring(invite))
    local ok, body = pcall(function() return game:HttpGet(url) end)
    if not ok or not body then return nil, "http_error" end
    local ok2, data = pcall(function() return HttpService:JSONDecode(body) end)
    if not ok2 or not data then return nil, "parse_error" end
    if data.guild then
        return {
            name = data.guild.name;
            members = data.approximate_member_count;
            online = data.approximate_presence_count;
            id = data.guild.id;
            icon = data.guild.icon;
        }
    end
    return nil, "no_guild"
end

-- ===== Notifications (light) =====
local function notify(screenGui, title, desc, duration)
    if not screenGui then return end
    duration = duration or 3
    -- create notifications container
    local sg = screenGui:FindFirstChild("CriptixNotifications")
    if not sg then
        sg = Instance.new("ScreenGui")
        sg.Name = "CriptixNotifications"
        sg.ResetOnSpawn = false
        sg.Parent = screenGui.Parent -- parent to same PlayerGui/CoreGui
    end
    local frame = new("Frame", {
        Parent = sg;
        Size = UDim2.new(0, 320, 0, 72);
        Position = UDim2.new(1, -10, 0, 10);
        AnchorPoint = Vector2.new(1,0);
        BackgroundColor3 = Themes.Dark.Panel;
        BorderSizePixel = 0;
    })
    new("UICorner", {Parent = frame; CornerRadius = UDim.new(0,8)})
    local t = new("TextLabel", {
        Parent = frame;
        Text = tostring(title or "");
        BackgroundTransparency = 1;
        Font = Enum.Font.SourceSansSemibold;
        TextSize = 15;
        TextColor3 = Themes.Dark.Text;
        Position = UDim2.new(0,8,0,6);
        Size = UDim2.new(1, -16, 0, 20);
        TextXAlignment = Enum.TextXAlignment.Left;
    })
    local d = new("TextLabel", {
        Parent = frame;
        Text = tostring(desc or "");
        BackgroundTransparency = 1;
        Font = Enum.Font.SourceSans;
        TextSize = 13;
        TextColor3 = Themes.Dark.Muted;
        Position = UDim2.new(0,8,0,28);
        Size = UDim2.new(1, -16, 0, 36);
        TextWrapped = true;
        TextXAlignment = Enum.TextXAlignment.Left;
    })
    frame.BackgroundTransparency = 1
    tween(frame, {BackgroundTransparency = 0}, 0.18)
    task.delay(duration, function()
        pcall(function()
            tween(frame, {BackgroundTransparency = 1}, 0.18, nil, nil, function() frame:Destroy() end)
        end)
    end)
end

-- ===== Module table =====
local CriptixUI = {}
CriptixUI.__index = CriptixUI

-- CreateWindow: builds a new window and returns an object with API
function CriptixUI:CreateWindow(opts)
    opts = opts or {}
    local Window = setmetatable({}, CriptixUI)
    Window.Title = opts.Title or ("CryptixHub {GAME} | v0.0.0")
    Window.Size = opts.Size or UDim2.fromOffset(580, 460)
    Window.ThemeName = opts.Theme or "Dark"
    Window.Theme = Themes[Window.ThemeName] or Themes.Dark
    Window.SideWidth = opts.SideWidth or 200
    Window.InternalName = opts.InternalName or "CriptixHub"
    Window.ConfigName = opts.ConfigName or "default"
    Window.Tabs = {}
    Window.User = opts.User or { Enabled = true, Anonymous = true } -- mirrors WindUI behavior
    Window.Notifications = (opts.Notifications == nil) and true or opts.Notifications
    -- ScreenGui (parent to PlayerGui)
    local sg = Instance.new("ScreenGui")
    sg.Name = "CriptixUI_" .. tostring(Window.InternalName)
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    -- prefer CoreGui when possible; but many executors expect PlayerGui - keep PlayerGui
    local parentGui = LocalPlayer:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
    sg.Parent = parentGui
    Window.ScreenGui = sg

    -- Main Frame
    local frame = new("Frame", {
        Parent = sg;
        Name = "MainFrame";
        Size = Window.Size;
        AnchorPoint = Vector2.new(0.5, 0.5);
        Position = UDim2.new(0.5, 0, 0.5, 0);
        BackgroundColor3 = Window.Theme.Background;
        BorderSizePixel = 0;
        Visible = false;
    })
    new("UICorner", {Parent = frame; CornerRadius = UDim.new(0,12)})
    Window.Frame = frame

    -- Top bar
    local top = new("Frame", {Parent = frame; Size = UDim2.new(1,0,0,36); BackgroundTransparency = 1})
    local title = new("TextLabel", {
        Parent = top;
        Text = Window.Title;
        Font = Enum.Font.SourceSansSemibold;
        TextSize = 18;
        TextColor3 = Window.Theme.Text;
        BackgroundTransparency = 1;
        Size = UDim2.new(0.6, 0, 1, 0);
        Position = UDim2.new(0.02, 0, 0, 0);
        TextXAlignment = Enum.TextXAlignment.Left;
    })
    local subtitle = new("TextLabel", {
        Parent = top;
        Text = "Developed by Freddy Bear";
        Font = Enum.Font.SourceSans;
        TextSize = 12;
        TextColor3 = Window.Theme.Muted;
        BackgroundTransparency = 1;
        Size = UDim2.new(0.35, 0, 1, 0);
        Position = UDim2.new(0.62, 0, 0, 0);
        TextXAlignment = Enum.TextXAlignment.Left;
    })
    Window.TitleLabel = title
    Window.SubtitleLabel = subtitle

    -- Close & Min buttons
    local btnClose = new("TextButton", {Parent = top; Size = UDim2.new(0,30,0,24); Position = UDim2.new(1, -38, 0.5, -12); BackgroundTransparency = 1; Text = "✕"; Font = Enum.Font.SourceSansBold; TextSize = 18; TextColor3 = Window.Theme.Text})
    local btnMin = new("TextButton", {Parent = top; Size = UDim2.new(0,30,0,24); Position = UDim2.new(1, -74, 0.5, -12); BackgroundTransparency = 1; Text = "—"; Font = Enum.Font.SourceSansBold; TextSize = 18; TextColor3 = Window.Theme.Text})
    Window.BtnClose = btnClose
    Window.BtnMin = btnMin

    btnClose.MouseButton1Click:Connect(function()
        Window:Close()
        if Window.Notifications then notify(sg, "CriptixUI", "Window closed", 2) end
    end)
    btnMin.MouseButton1Click:Connect(function()
        Window:Toggle()
    end)

    -- Sidebar and Content
    local sidebar = new("Frame", {Parent = frame; Size = UDim2.new(0, Window.SideWidth, 1, -36); Position = UDim2.new(0, 0, 0, 36); BackgroundTransparency = 1})
    local content = new("Frame", {Parent = frame; Size = UDim2.new(1, -Window.SideWidth - 16, 1, -46); Position = UDim2.new(0, Window.SideWidth + 8, 0, 38); BackgroundTransparency = 1})
    new("UIListLayout", {Parent = sidebar; Padding = UDim.new(0,8); FillDirection = Enum.FillDirection.Vertical; HorizontalAlignment = Enum.HorizontalAlignment.Center; VerticalAlignment = Enum.VerticalAlignment.Top})
    Window.Sidebar = sidebar
    Window.Content = content

    -- Tab selection helper
    function Window:SelectTab(tab)
        for _,t in pairs(self.Tabs) do
            pcall(function() t.Frame.Visible = false; t.Button.BackgroundTransparency = 0.8 end)
        end
        if tab and tab.Frame then
            tab.Frame.Visible = true
            tab.Button.BackgroundTransparency = 0.4
            if tab.Frame:IsA("ScrollingFrame") then tab.Frame.CanvasPosition = Vector2.new(0,0) end
        end
    end

    -- Open/Close/Toggle/Destroy
    Window.Visible = false
    function Window:Open()
        if self.Visible then return end
        self.Visible = true
        self.Frame.Visible = true
        self.Frame.BackgroundTransparency = 1
        tween(self.Frame, {BackgroundTransparency = 0}, 0.22)
    end
    function Window:Close()
        if not self.Visible then return end
        self.Visible = false
        tween(self.Frame, {BackgroundTransparency = 1}, 0.18, nil, nil, function() pcall(function() self.Frame.Visible = false end) end)
    end
    function Window:Toggle()
        if self.Visible then self:Close() else self:Open() end
    end
    function Window:Destroy()
        if self.ScreenGui then pcall(function() self.ScreenGui:Destroy() end) end
    end

    -- Theme setter
    function Window:SetTheme(name)
        if not name or not Themes[name] then return end
        self.ThemeName = name
        self.Theme = Themes[name]
        self.Frame.BackgroundColor3 = self.Theme.Background
        self.TitleLabel.TextColor3 = self.Theme.Text
        self.SubtitleLabel.TextColor3 = self.Theme.Muted
        -- apply to sidebar buttons
        for _,t in ipairs(self.Tabs) do
            pcall(function() t.Button.BackgroundColor3 = self.Theme.Panel; t.Button.TextColor3 = self.Theme.Text end)
        end
    end

    -- Config API
    function Window:SaveConfig(name)
        name = name or self.ConfigName or "default"
        local data = {
            Theme = self.ThemeName,
            Transparency = self.Frame.BackgroundTransparency or 0,
            Position = {self.Frame.Position.X.Scale, self.Frame.Position.X.Offset, self.Frame.Position.Y.Scale, self.Frame.Position.Y.Offset}
        }
        return saveConfig(name, data)
    end
    function Window:LoadConfig(name)
        name = name or self.ConfigName or "default"
        local data = loadConfig(name)
        if not data then return false end
        if data.Theme then self:SetTheme(data.Theme) end
        if data.Transparency then self.Frame.BackgroundTransparency = data.Transparency end
        if data.Position and #data.Position >= 4 then
            local xScale, xOff, yScale, yOff = data.Position[1], data.Position[2], data.Position[3], data.Position[4]
            self.Frame.Position = UDim2.new(xScale or 0.5, xOff or 0, yScale or 0.5, yOff or 0)
        end
        return true
    end
    function Window:DeleteConfig(name)
        if not name or not isfile then return false end
        local path = cfgPath(name)
        if not isfile(path) then return false end
        local ok, res = pcall(function() delfile(path) end)
        return ok
    end
    function Window:RefreshConfigList()
        return listConfigs()
    end

    -- Tab factory returns tab object
    function Window:Tab(opts)
        opts = opts or {}
        local tabBtn = new("TextButton", {
            Parent = sidebar;
            Size = UDim2.new(1, -20, 0, 34);
            Text = " " .. tostring(opts.Title or "Tab");
            BackgroundColor3 = self.Theme.Panel;
            BackgroundTransparency = 0.8;
            Font = Enum.Font.SourceSansSemibold;
            TextSize = 15;
            TextColor3 = self.Theme.Text;
        })
        new("UICorner", {Parent = tabBtn; CornerRadius = UDim.new(0,8)})
        local tabFrame = new("ScrollingFrame", {
            Parent = content;
            Size = UDim2.new(1, -10, 1, 0);
            BackgroundTransparency = 1;
            CanvasSize = UDim2.new(0,0,0,0);
            ScrollBarThickness = 6;
            Visible = false;
        })
        new("UIListLayout", {Parent = tabFrame; Padding = UDim.new(0,6); SortOrder = Enum.SortOrder.LayoutOrder})
        new("UIPadding", {Parent = tabFrame; PaddingTop = UDim.new(0,6); PaddingLeft = UDim.new(0,6); PaddingRight = UDim.new(0,6); PaddingBottom = UDim.new(0,6)})

        local tab = { Button = tabBtn, Frame = tabFrame, Sections = {} }
        tabBtn.MouseButton1Click:Connect(function()
            self:SelectTab(tab)
        end)

        function tab:Divider()
            local d = new("Frame", {Parent = self.Frame; Size = UDim2.new(1,0,0,2); BackgroundColor3 = Window.Theme.Panel; BorderSizePixel = 0})
            new("UICorner", {Parent = d; CornerRadius = UDim.new(0,6)})
            return d
        end

        function tab:Section(opts2)
            opts2 = opts2 or {}
            local sec = new("Frame", {Parent = self.Frame; Size = UDim2.new(1,-10,0,60); BackgroundTransparency = 1; LayoutOrder = #self.Sections + 1})
            local title = new("TextLabel", {Parent = sec; Size = UDim2.new(1,0,0,20); Position = UDim2.new(0,0,0,0); BackgroundTransparency = 1; Text = tostring(opts2.Title or ""); Font = Enum.Font.SourceSansSemibold; TextSize = opts2.TextSize or 16; TextColor3 = Window.Theme.Text; TextXAlignment = Enum.TextXAlignment.Center})
            table.insert(self.Sections, sec)
            return sec
        end

        function tab:Paragraph(opts2)
            opts2 = opts2 or {}
            local p = new("Frame", {Parent = self.Frame; Size = UDim2.new(1,-10,0,64); BackgroundTransparency = 1; LayoutOrder = #self.Sections + 1})
            local t = new("TextLabel", {Parent = p; Size = UDim2.new(1,0,0,20); Position = UDim2.new(0,0,0,0); BackgroundTransparency = 1; Text = tostring(opts2.Title or ""); Font = Enum.Font.SourceSansSemibold; TextSize = 14; TextColor3 = Window.Theme.Text; TextXAlignment = Enum.TextXAlignment.Left})
            local d = new("TextLabel", {Parent = p; Size = UDim2.new(1,0,0,40); Position = UDim2.new(0,0,0,20); BackgroundTransparency = 1; Text = tostring(opts2.Desc or ""); Font = Enum.Font.SourceSans; TextSize = 13; TextColor3 = Window.Theme.Muted; TextWrapped = true; TextXAlignment = Enum.TextXAlignment.Left})
            return p
        end

        function tab:Button(opts2)
            opts2 = opts2 or {}
            local b = new("TextButton", {Parent = self.Frame; Size = UDim2.new(0,160,0,34); Text = tostring(opts2.Title or "Button"); Font = Enum.Font.SourceSansSemibold; TextSize = 14; TextColor3 = Window.Theme.Text; BackgroundColor3 = Window.Theme.Panel; BorderSizePixel = 0; LayoutOrder = #self.Sections + 1})
            new("UICorner", {Parent = b; CornerRadius = UDim.new(0,8)})
            b.MouseButton1Click:Connect(function()
                safe_pcall(function() if opts2.Callback then opts2.Callback() end end)
            end)
            return b
        end

        function tab:Toggle(opts2)
            opts2 = opts2 or {}
            local f = new("Frame", {Parent = self.Frame; Size = UDim2.new(0,220,0,28); BackgroundTransparency = 1; LayoutOrder = #self.Sections + 1})
            local lbl = new("TextLabel", {Parent = f; Size = UDim2.new(0,130,1,0); BackgroundTransparency = 1; Text = tostring(opts2.Title or "Toggle"); Font = Enum.Font.SourceSans; TextSize = 14; TextColor3 = Window.Theme.Text})
            local btn = new("TextButton", {Parent = f; Size = UDim2.new(0,60,0,22); Position = UDim2.new(1,-66,0.5,-11); Text = (opts2.Default and "ON" or "OFF"); Font = Enum.Font.SourceSansSemibold; TextSize = 12; TextColor3 = Window.Theme.Text; BackgroundColor3 = (opts2.Default and Color3.fromRGB(60,160,80) or Color3.fromRGB(70,70,70))})
            new("UICorner", {Parent = btn; CornerRadius = UDim.new(0,6)})
            local state = opts2.Default or false
            btn.MouseButton1Click:Connect(function()
                state = not state
                btn.Text = state and "ON" or "OFF"
                btn.BackgroundColor3 = state and Color3.fromRGB(60,160,80) or Color3.fromRGB(70,70,70)
                safe_pcall(function() if opts2.Callback then opts2.Callback(state) end end)
            end)
            return f
        end

        function tab:Slider(title, min, max, default, callback)
            min = tonumber(min) or 0; max = tonumber(max) or 100; default = tonumber(default) or min
            local cont = new("Frame", {Parent = self.Frame; Size = UDim2.new(0,360,0,36); BackgroundTransparency = 1; LayoutOrder = #self.Sections + 1})
            local lbl = new("TextLabel", {Parent = cont; Size = UDim2.new(0,180,1,0); BackgroundTransparency = 1; Text = tostring(title or "Slider"); Font = Enum.Font.SourceSans; TextSize = 14; TextColor3 = Window.Theme.Text})
            local valLbl = new("TextLabel", {Parent = cont; Size = UDim2.new(0,80,1,0); Position = UDim2.new(1,-80,0,0); BackgroundTransparency = 1; Text = tostring(default); Font = Enum.Font.SourceSansSemibold; TextSize = 14; TextColor3 = Window.Theme.Muted})
            local trackBg = new("Frame", {Parent = cont; Size = UDim2.new(0,200,0,10); Position = UDim2.new(0.5,-10,0.5,-5); BackgroundColor3 = Window.Theme.Panel; BorderSizePixel = 0})
            new("UICorner", {Parent = trackBg; CornerRadius = UDim.new(0,6)})
            local fill = new("Frame", {Parent = trackBg; Size = UDim2.new(0,0,1,0); BackgroundColor3 = Window.Theme.Accent; BorderSizePixel = 0})
            new("UICorner", {Parent = fill; CornerRadius = UDim.new(0,6)})
            local thumb = new("ImageButton", {Parent = trackBg; Size = UDim2.new(0,18,0,18); Position = UDim2.new(0, -9, 0.5, -9); BackgroundColor3 = Window.Theme.Accent; AutoButtonColor = false})
            new("UICorner", {Parent = thumb; CornerRadius = UDim.new(1,0)})
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

        function tab:Input(opts2)
            opts2 = opts2 or {}
            local f = new("Frame", {Parent = self.Frame; Size = UDim2.new(0,380,0,36); BackgroundTransparency = 1; LayoutOrder = #self.Sections + 1})
            local lbl = new("TextLabel", {Parent = f; Size = UDim2.new(0,120,1,0); BackgroundTransparency = 1; Text = tostring(opts2.Title or "Input"); Font = Enum.Font.SourceSans; TextColor3 = Window.Theme.Text})
            local box = new("TextBox", {Parent = f; Size = UDim2.new(0,240,0,28); Position = UDim2.new(0,130,0,4); Text = tostring(opts2.Value or ""); PlaceholderText = tostring(opts2.Placeholder or ""); ClearTextOnFocus = false; Font = Enum.Font.SourceSans; TextSize = 14; TextColor3 = Window.Theme.Text; BackgroundColor3 = Window.Theme.Panel; BorderSizePixel = 0})
            new("UICorner", {Parent = box; CornerRadius = UDim.new(0,6)})
            box.FocusLost:Connect(function(enter)
                if enter and opts2.Callback then safe_pcall(function() opts2.Callback(box.Text) end) end
            end)
            return f
        end

        function tab:Dropdown(opts2)
            opts2 = opts2 or {}
            local frame = new("Frame", {Parent = self.Frame; Size = UDim2.new(0,360,0,34); BackgroundTransparency = 1; LayoutOrder = #self.Sections + 1})
            local lbl = new("TextLabel", {Parent = frame; Size = UDim2.new(0,160,1,0); BackgroundTransparency = 1; Text = tostring(opts2.Title or "Dropdown"); Font = Enum.Font.SourceSans; TextColor3 = Window.Theme.Text})
            local btn = new("TextButton", {Parent = frame; Size = UDim2.new(0,170,0,28); Position = UDim2.new(0.45,0,0.1,0); Text = (opts2.Value or (opts2.Values and opts2.Values[1]) or ""); BackgroundColor3 = Window.Theme.Panel; TextColor3 = Window.Theme.Text})
            new("UICorner", {Parent = btn; CornerRadius = UDim.new(0,6)})
            local menu
            btn.MouseButton1Click:Connect(function()
                if menu and menu.Parent then menu:Destroy(); menu = nil; return end
                menu = new("Frame", {Parent = self.Frame; Size = UDim2.new(0,170,0, math.max(28, (#(opts2.Values or {}) * 28))); Position = UDim2.new(btn.Position.X.Scale, btn.Position.X.Offset, btn.Position.Y.Scale, btn.Position.Y.Offset + 34); BackgroundColor3 = Window.Theme.Panel})
                new("UIListLayout", {Parent = menu; Padding = UDim.new(0,2)})
                for i,v in ipairs(opts2.Values or {}) do
                    local it = new("TextButton", {Parent = menu; Size = UDim2.new(1,-8,0,26); Position = UDim2.new(0,4,0,(i-1)*28); Text = tostring(v); BackgroundColor3 = Window.Theme.Panel; TextColor3 = Window.Theme.Text})
                    new("UICorner", {Parent = it; CornerRadius = UDim.new(0,6)})
                    it.MouseButton1Click:Connect(function()
                        btn.Text = tostring(v)
                        safe_pcall(function() if opts2.Callback then opts2.Callback(v) end end)
                        if menu and menu.Parent then menu:Destroy() end
                    end)
                end
            end)
            return frame
        end

        function tab:Keybind(opts2)
            opts2 = opts2 or {}
            local f = new("Frame", {Parent = self.Frame; Size = UDim2.new(0,360,0,36); BackgroundTransparency = 1; LayoutOrder = #self.Sections + 1})
            local lbl = new("TextLabel", {Parent = f; Size = UDim2.new(0,180,1,0); BackgroundTransparency = 1; Text = tostring(opts2.Title or "Keybind"); Font = Enum.Font.SourceSans; TextColor3 = Window.Theme.Text})
            local btn = new("TextButton", {Parent = f; Position = UDim2.new(0.6,0,0.12,0); Size = UDim2.new(0,120,0,28); Text = (opts2.Default and tostring(opts2.Default) or "Set Key"); BackgroundColor3 = Window.Theme.Panel; TextColor3 = Window.Theme.Text})
            new("UICorner", {Parent = btn; CornerRadius = UDim.new(0,6)})
            btn.MouseButton1Click:Connect(function()
                btn.Text = "Press key..."
                local conn
                conn = UserInputService.InputBegan:Connect(function(inp, processed)
                    if processed then return end
                    if inp.UserInputType == Enum.UserInputType.Keyboard then
                        btn.Text = tostring(inp.KeyCode.Name)
                        safe_pcall(function() if opts2.Callback then opts2.Callback(inp.KeyCode) end end)
                        conn:Disconnect()
                    end
                end)
            end)
            return f
        end

        function tab:Colorpicker(opts2)
            opts2 = opts2 or {}
            local f = new("Frame", {Parent = self.Frame; Size = UDim2.new(0,360,0,40); BackgroundTransparency = 1; LayoutOrder = #self.Sections + 1})
            local lbl = new("TextLabel", {Parent = f; Size = UDim2.new(0,160,1,0); BackgroundTransparency = 1; Text = tostring(opts2.Title or "Color"); Font = Enum.Font.SourceSans; TextColor3 = Window.Theme.Text})
            local preview = new("Frame", {Parent = f; Size = UDim2.new(0,36,0,24); Position = UDim2.new(0.6,0,0.12,0); BackgroundColor3 = opts2.Default or Window.Theme.Accent})
            new("UICorner", {Parent = preview; CornerRadius = UDim.new(0,6)})
            local btn = new("TextButton", {Parent = f; Size = UDim2.new(0,120,0,28); Position = UDim2.new(0.75,0,0.12,0); Text = "Pick"; BackgroundColor3 = Window.Theme.Panel; TextColor3 = Window.Theme.Text})
            new("UICorner", {Parent = btn; CornerRadius = UDim.new(0,6)})
            btn.MouseButton1Click:Connect(function()
                local col = Color3.fromHSV(math.random(), 0.8, 0.9)
                preview.BackgroundColor3 = col
                safe_pcall(function() if opts2.Callback then opts2.Callback(col) end end)
            end)
            return f
        end

        table.insert(Window.Tabs, tab)
        return tab
    end

    return Window
end

-- ===== Enable OpenButtonMain (copied structure from WindUI main.lua) =====
function CriptixUI:EnableOpenButton(opts)
    opts = opts or {}
    local label = opts.Label or "CriptixHub"
    local parentGui = LocalPlayer:FindFirstChild("PlayerGui") or game:GetService("CoreGui")

    -- create a ScreenGui for the open button
    local sg = Instance.new("ScreenGui")
    sg.Name = "OpenButtonMain"
    sg.IgnoreGuiInset = true
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = parentGui

    -- Button (as in WindUI main.lua)
    local Button = Instance.new("TextButton")
    Button.Name = "OpenButton"
    Button.AnchorPoint = Vector2.new(0.5, 0.5)
    Button.Position = UDim2.new(1, -70, 1, -70)
    Button.Size = UDim2.new(0, 110, 0, 44)
    Button.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Button.Text = label
    Button.TextColor3 = Color3.fromRGB(255, 255, 255)
    Button.Font = Enum.Font.SourceSansSemibold
    Button.TextSize = 14
    Button.AutoButtonColor = true
    Button.Parent = sg
    Button.Active = true
    Button.Draggable = true

    new("UICorner", {Parent = Button; CornerRadius = UDim.new(0,8)})

    -- Shadow (optional)
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://1316045217"
    Shadow.ImageTransparency = 0.7
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    Shadow.Size = UDim2.new(1, 12, 1, 12)
    Shadow.Position = UDim2.new(0, -6, 0, -6)
    Shadow.ZIndex = 0
    Shadow.Parent = Button

    -- When clicked, toggle the MainFrame of the first created window (if any)
    Button.MouseButton1Click:Connect(function()
        -- find any created MainFrame ScreenGui
        local targetWindowGui = parentGui:FindFirstChildWhichIsA("ScreenGui") -- fallback
        -- try to find CriptixUI_* main guis
        for _,g in ipairs(parentGui:GetChildren()) do
            if g:IsA("ScreenGui") and g.Name:match("^CriptixUI_") then
                targetWindowGui = g
                break
            end
        end
        if targetWindowGui then
            local frame = targetWindowGui:FindFirstChild("MainFrame")
            if frame then
                if frame.Visible then
                    tween(frame, {BackgroundTransparency = 1}, 0.18, nil, nil, function() frame.Visible = false end)
                    Button.Text = label
                else
                    frame.Visible = true
                    frame.BackgroundTransparency = 1
                    tween(frame, {BackgroundTransparency = 0}, 0.22)
                    Button.Text = "✖"
                end
            else
                -- no frame (maybe not created); notify
                safe_pcall(function() notify(parentGui, "CriptixUI", "Main window not loaded", 2) end)
            end
        else
            safe_pcall(function() notify(parentGui, "CriptixUI", "Main window not found", 2) end)
        end
    end)

    -- Save position on mouse leave
    local function savePos()
        if not writefile then return end
        local pos = Button.Position
        local ok, enc = pcall(function() return HttpService:JSONEncode({X = pos.X.Scale, XO = pos.X.Offset, Y = pos.Y.Scale, YO = pos.Y.Offset}) end)
        if ok then
            pcall(function() writefile("CriptixUI_OpenButtonPos.json", enc) end)
        end
    end
    Button.MouseLeave:Connect(savePos)

    -- Try to load saved pos
    if isfile and readfile then
        local path = "CriptixUI_OpenButtonPos.json"
        if isfile(path) then
            local ok, txt = pcall(function() return readfile(path) end)
            if ok and txt then
                local ok2, dec = pcall(function() return HttpService:JSONDecode(txt) end)
                if ok2 and dec then
                    pcall(function()
                        Button.Position = UDim2.new(dec.X or 1, dec.XO or -70, dec.Y or 1, dec.YO or -70)
                    end)
                end
            end
        end
    end

    return sg, Button
end

-- ===== Helper to attach a default Info Tab (with Discord + config tools) =====
function CriptixUI:AttachDefaultInfo(windowObj, inviteCode)
    if not windowObj then return end
    local InfoTab = windowObj:Tab({ Title = "Info" })
    InfoTab:Divider()
    InfoTab:Section({ Title = "Developer", TextSize = 17 })
    InfoTab:Divider()
    InfoTab:Paragraph({ Title = "Freddy Bear (Principal Developer)", Desc = "Creator of CryptixHub" })
    InfoTab:Paragraph({ Title = "Assistant", Desc = "CriptixUI core module" })
    InfoTab:Divider()
    InfoTab:Section({ Title = "Save and Load", TextSize = 17 })
    InfoTab:Divider()

    _G.Criptix_ConfigName = _G.Criptix_ConfigName or ""

    InfoTab:Input({
        Title = "Name Config",
        Placeholder = "config_name",
        Callback = function(txt) _G.Criptix_ConfigName = txt end
    })

    local files = windowObj:RefreshConfigList() or {}
    local filesDropdown = InfoTab:Dropdown({ Title = "Select Config File", Values = files, Callback = function(f) _G.Criptix_ConfigName = f end })

    InfoTab:Button({ Title = "Save Config", Callback = function()
        if not _G.Criptix_ConfigName or _G.Criptix_ConfigName == "" then
            safe_pcall(function() notify(windowObj.ScreenGui, "CriptixUI", "Provide a config name", 2) end)
            return
        end
        local ok = windowObj:SaveConfig(_G.Criptix_ConfigName)
        if ok then safe_pcall(function() notify(windowObj.ScreenGui, "CriptixUI", "Saved config: ".._G.Criptix_ConfigName, 2) end) end
    end })

    InfoTab:Button({ Title = "Load Config", Callback = function()
        if not _G.Criptix_ConfigName or _G.Criptix_ConfigName == "" then
            safe_pcall(function() notify(windowObj.ScreenGui, "CriptixUI", "Provide a config name", 2) end)
            return
        end
        local ok = windowObj:LoadConfig(_G.Criptix_ConfigName)
        if ok then safe_pcall(function() notify(windowObj.ScreenGui, "CriptixUI", "Loaded config: ".._G.Criptix_ConfigName, 2) end) end
    end })

    InfoTab:Button({ Title = "Delete Config", Callback = function()
        if not _G.Criptix_ConfigName or _G.Criptix_ConfigName == "" then
            safe_pcall(function() notify(windowObj.ScreenGui, "CriptixUI", "Provide a config name", 2) end)
            return
        end
        local ok = windowObj:DeleteConfig(_G.Criptix_ConfigName)
        if ok then safe_pcall(function() notify(windowObj.ScreenGui, "CriptixUI", "Deleted: ".._G.Criptix_ConfigName, 2) end) end
    end })

    InfoTab:Button({ Title = "Refresh Config List", Callback = function()
        local list = windowObj:RefreshConfigList()
        filesDropdown = InfoTab:Dropdown({ Title = "Select Config File", Values = list, Callback = function(f) _G.Criptix_ConfigName = f end })
        safe_pcall(function() notify(windowObj.ScreenGui, "CriptixUI", "Config list refreshed", 2) end)
    end })

    InfoTab:Divider()
    InfoTab:Section({ Title = "Discord", TextSize = 17 })
    InfoTab:Divider()

    local invite = inviteCode or ""
    local placeholder = InfoTab:Paragraph({ Title = "Discord", Desc = "Fetching..." })

    InfoTab:Button({ Title = "Update Info", Callback = function()
        spawn(function()
            local res, err = fetchDiscordInvite(invite)
            if res then
                local desc = "• Members: "..tostring(res.members).."\n• Online: "..tostring(res.online)
                InfoTab:Paragraph({ Title = res.name, Desc = desc })
            else
                InfoTab:Paragraph({ Title = "Discord Info Unavailable", Desc = tostring(err) })
            end
        end)
    end })

    InfoTab:Button({ Title = "Copy Discord Invite", Callback = function()
        pcall(function() setclipboard("https://discord.gg/" .. invite) end)
        safe_pcall(function() notify(windowObj.ScreenGui, "CriptixUI", "Invite copied to clipboard", 2) end)
    end })

    spawn(function()
        local res, err = fetchDiscordInvite(invite)
        if res then
            local desc = "• Members: "..tostring(res.members).."\n• Online: "..tostring(res.online)
            InfoTab:Paragraph({ Title = res.name, Desc = desc })
        else
            InfoTab:Paragraph({ Title = "Discord Info Unavailable", Desc = tostring(err) })
        end
    end)
end

-- Return the module
return CriptixUI
