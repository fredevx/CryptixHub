--[[
CryptixUI v1.0.0
Rewritten and rebranded from WindUI v1.6.57 (MIT License)
Original Author: Footagesus (WindUI)
Rework & Optimizations: FredevX (Santiago)
License: MIT (derived)
Repository: https://github.com/fredevx/CryptixHub
Default Theme: Dark
--]]

-- Auto-create directory structure for configs and mods
local function EnsureFolder(path)
    if not isfolder then return end
    if not isfolder(path) then
        makefolder(path)
    end
end

local BASE_DIR = "CryptixHub"
local CONFIG_DIR = BASE_DIR .. "/config"

EnsureFolder("CryptixUI")
EnsureFolder(BASE_DIR)
EnsureFolder(CONFIG_DIR)
EnsureFolder(BASE_DIR .. "/mods")

-- Core services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- Utilities and executor compatibility
local function safe_request(req)
    local ok, res = pcall(function()
        if syn and syn.request then return syn.request(req) end
        if request then return request(req) end
        if http_request then return http_request(req) end
        error("No request function available")
    end)
    return ok and res or nil
end

local function sanitize_filename(name)
    name = tostring(name)
    name = name:match("([^/]+)$") or name
    name = name:gsub("%.[^%.]+$","")
    name = name:gsub("[^%w%-_]","_")
    if #name > 50 then name = name:sub(1,50) end
    return name
end

-- File helpers: prefer JSON encode/decode for configs
local function write_json(path, tbl)
    if not writefile then return false, "writefile not available" end
    local ok, encoded = pcall(function() return HttpService:JSONEncode(tbl) end)
    if not ok then return false, "JSONEncode failed" end
    pcall(function() writefile(path, encoded) end)
    return true
end

local function read_json(path)
    if not readfile then return nil, "readfile not available" end
    if not isfile or not isfile(path) then return nil, "file not found" end
    local ok, content = pcall(function() return readfile(path) end)
    if not ok then return nil, "read failed" end
    local ok2, tbl = pcall(function() return HttpService:JSONDecode(content) end)
    if not ok2 then return nil, "JSONDecode failed" end
    return tbl
end

local function delete_file(path)
    if delfile and isfile and isfile(path) then
        pcall(function() delfile(path) end)
        return true
    end
    return false
end

-- Core CryptixUI table
local CryptixUI = {}
CryptixUI.__index = CryptixUI
CryptixUI.Version = "v1.0.0"
CryptixUI.Name = "CryptixUI"
CryptixUI.Theme = "Dark"
CryptixUI.Themes = {
    Dark = {
        WindowBackground = Color3.fromRGB(24,24,24),
        Accent = Color3.fromRGB(57, 136, 235),
        Text = Color3.fromRGB(230,230,230),
        ElementBackground = Color3.fromRGB(40,40,40),
        Hover = Color3.fromRGB(50,50,50),
    },
    Light = {
        WindowBackground = Color3.fromRGB(245,245,245),
        Accent = Color3.fromRGB(57, 136, 235),
        Text = Color3.fromRGB(20,20,20),
        ElementBackground = Color3.fromRGB(230,230,230),
        Hover = Color3.fromRGB(210,210,210),
    }
}

-- Internal signals cleanup list
local _Connections = {}

local function add_connection(conn)
    if conn and conn.Disconnect then
        table.insert(_Connections, conn)
    elseif conn and conn.disconnect then
        table.insert(_Connections, conn)
    else
        table.insert(_Connections, conn)
    end
end

local function disconnect_all()
    for _,c in ipairs(_Connections) do
        pcall(function()
            if type(c) == "RBXScriptConnection" or (type(c)=="table" and c.Disconnect) then
                c:Disconnect()
            elseif type(c)=="table" and c.disconnect then
                c:disconnect()
            end
        end)
    end
    _Connections = {}
end

-- Basic utility: tween
local function tween(instance, time, props, style, dir)
    style = style or Enum.EasingStyle.Quint
    dir = dir or Enum.EasingDirection.Out
    local info = TweenInfo.new(time, style, dir)
    local ok, t = pcall(function() return TweenService:Create(instance, info, props) end)
    if not ok then return nil end
    t:Play()
    return t
end

-- Window object
local Window = {}
Window.__index = Window

function CryptixUI:CreateWindow(title, options)
    options = options or {}
    local win = setmetatable({}, Window)
    win.Title = title or "CryptixHub"
    win.Opened = false
    win.Config = options.Config or {}
    win.Size = options.Size or UDim2.new(0, 800, 0, 520)
    win.Position = options.Position or UDim2.new(0.5, -400, 0.5, -260)
    win.ZIndex = options.ZIndex or 9999
    win.Theme = options.Theme or CryptixUI.Theme
    win._elements = {}
    win._tabs = {}
    win._screen = nil
    win._root = nil
    win._dragging = false
    win._dragStart = nil
    win._dragOrigin = nil
    win:_Create()
    return win
end

function Window:_ApplyTheme()
    local t = CryptixUI.Themes[self.Theme] or CryptixUI.Themes.Dark
    if self._root then
        if self._root:FindFirstChild("WindowBackground") then
            local bg = self._root.WindowBackground
            pcall(function() bg.BackgroundColor3 = t.WindowBackground end)
        end
        if self._root:FindFirstChild("TopbarTitle") then
            local title = self._root.TopbarTitle
            pcall(function() title.TextColor3 = t.Text end)
        end
    end
end

function Window:_Create()
    -- ScreenGui
    local screen = Instance.new("ScreenGui")
    screen.Name = "CryptixUI_" .. sanitize_filename(self.Title)
    screen.ResetOnSpawn = false
    screen.IgnoreGuiInset = true
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screen.Parent = (gethui and gethui()) or (syn and syn.protect_gui and syn.protect_gui(screen) or screen)
    self._screen = screen

    -- Root frame (window)
    local root = Instance.new("Frame")
    root.Name = "CryptixUIRoot"
    root.Size = self.Size
    root.Position = self.Position
    root.AnchorPoint = Vector2.new(0,0)
    root.BackgroundColor3 = (CryptixUI.Themes[self.Theme] or CryptixUI.Themes.Dark).WindowBackground
    root.BorderSizePixel = 0
    root.ClipsDescendants = true
    root.Parent = screen
    self._root = root

    local corner = Instance.new("UICorner", root)
    corner.CornerRadius = UDim.new(0, 12)

    -- Topbar
    local topbar = Instance.new("Frame", root)
    topbar.Name = "Topbar"
    topbar.Size = UDim2.new(1,0,0,46)
    topbar.Position = UDim2.new(0,0,0,0)
    topbar.BackgroundTransparency = 1

    local titleLabel = Instance.new("TextLabel", topbar)
    titleLabel.Name = "TopbarTitle"
    titleLabel.Size = UDim2.new(0, 300, 1, 0)
    titleLabel.Position = UDim2.new(0,12,0,0)
    titleLabel.Text = self.Title
    titleLabel.TextSize = 20
    titleLabel.Font = Enum.Font.GothamSemibold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = (CryptixUI.Themes[self.Theme] or CryptixUI.Themes.Dark).Text

    -- Close / Toggle button
    local closeBtn = Instance.new("ImageButton", topbar)
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 34, 0, 34)
    closeBtn.Position = UDim2.new(1, -44, 0.5, -17)
    closeBtn.AnchorPoint = Vector2.new(0,0)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Image = "rbxassetid://3926305904" -- circle asset; placeholder
    closeBtn.ImageColor3 = (CryptixUI.Themes[self.Theme] or CryptixUI.Themes.Dark).Accent

    closeBtn.MouseButton1Click:Connect(function()
        self:Toggle()
    end)

    -- Content holder and tabs
    local holder = Instance.new("Frame", root)
    holder.Name = "ContentHolder"
    holder.Position = UDim2.new(0,0,0,46)
    holder.Size = UDim2.new(1,0,1,-46)
    holder.BackgroundTransparency = 1
    local holderPadding = Instance.new("UIPadding", holder)
    holderPadding.PaddingLeft = UDim.new(0,12)
    holderPadding.PaddingTop = UDim.new(0,12)
    holderPadding.PaddingRight = UDim.new(0,12)
    holderPadding.PaddingBottom = UDim.new(0,12)

    local tabsFrame = Instance.new("Frame", holder)
    tabsFrame.Name = "Tabs"
    tabsFrame.Size = UDim2.new(0,200,1,0)
    tabsFrame.Position = UDim2.new(0,0,0,0)
    tabsFrame.BackgroundTransparency = 1

    local tabsLayout = Instance.new("UIListLayout", tabsFrame)
    tabsLayout.SortOrder = Enum.SortOrder.Name
    tabsLayout.Padding = UDim.new(0,8)
    tabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    tabsLayout.VerticalAlignment = Enum.VerticalAlignment.Top

    local pagesFrame = Instance.new("Frame", holder)
    pagesFrame.Name = "Pages"
    pagesFrame.Size = UDim2.new(1,-212,1,0)
    pagesFrame.Position = UDim2.new(0,212,0,0)
    pagesFrame.BackgroundTransparency = 1
    pagesFrame.ClipsDescendants = true

    -- Make draggable via topbar
    local dragging = false
    local dragStartPos, startPos
    topbar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStartPos = inp.Position
            startPos = root.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    topbar.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = inp.Position - dragStartPos
            root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- store references
    self._root = root
    self._screen = screen
    self._tabsFrame = tabsFrame
    self._pagesFrame = pagesFrame
    self._holder = holder
    self._titleLabel = titleLabel

    -- default open state false
    root.Visible = false
end

function Window:Open()
    if self._root then
        self._root.Visible = true
        self.Opened = true
        -- play open animation
        local orig = self._root
        orig.Size = UDim2.new(0,0,0,0)
        tween(orig, 0.28, {Size = self.Size})
    end
end

function Window:Close()
    if self._root then
        -- play close animation and hide
        local orig = self._root
        local t = tween(orig, 0.22, {Size = UDim2.new(0,0,0,0)})
        task.delay(0.22, function() if orig then orig.Visible = false end end)
        self.Opened = false
    end
end

function Window:Toggle()
    if self.Opened then self:Close() else self:Open() end
end

function Window:Destroy()
    if self._screen then
        pcall(function() self._screen:Destroy() end)
    end
    disconnect_all()
end

-- Tabs API
function Window:CreateTab(name)
    local tabBtn = Instance.new("TextButton", self._tabsFrame)
    tabBtn.Name = "Tab_" .. sanitize_filename(name)
    tabBtn.Size = UDim2.new(1, -8, 0, 36)
    tabBtn.BackgroundTransparency = 1
    tabBtn.Text = name
    tabBtn.TextSize = 16
    tabBtn.Font = Enum.Font.GothamSemibold
    tabBtn.TextColor3 = (CryptixUI.Themes[self.Theme] or CryptixUI.Themes.Dark).Text
    tabBtn.AutoButtonColor = false

    local page = Instance.new("Frame", self._pagesFrame)
    page.Name = "Page_" .. sanitize_filename(name)
    page.Size = UDim2.new(1,0,1,0)
    page.BackgroundTransparency = 1
    page.Visible = false

    local pageLayout = Instance.new("UIListLayout", page)
    pageLayout.Padding = UDim.new(0,8)
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.VerticalAlignment = Enum.VerticalAlignment.Top

    tabBtn.MouseButton1Click:Connect(function()
        -- hide all pages, show this one
        for _,v in ipairs(self._pagesFrame:GetChildren()) do
            if v:IsA("Frame") then v.Visible = false end
        end
        page.Visible = true
    end)

    -- If first tab, click it
    if #self._tabs == 0 then
        tabBtn:CaptureControl() -- safe call; compatibility
        task.spawn(function() tabBtn.MouseButton1Click:Wait() end)
    end

    table.insert(self._tabs, {Name = name, Button = tabBtn, Page = page})
    return page
end

-- Section API (simple container with a header)
function Window:AddSection(page, title)
    local section = Instance.new("Frame", page)
    section.Size = UDim2.new(1,0,0,120)
    section.BackgroundColor3 = (CryptixUI.Themes[self.Theme] or CryptixUI.Themes.Dark).ElementBackground
    section.BorderSizePixel = 0
    local corner = Instance.new("UICorner", section)
    corner.CornerRadius = UDim.new(0,10)

    local header = Instance.new("TextLabel", section)
    header.Size = UDim2.new(1,0,0,32)
    header.Position = UDim2.new(0,0,0,0)
    header.BackgroundTransparency = 1
    header.Text = title or ""
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.TextColor3 = (CryptixUI.Themes[self.Theme] or CryptixUI.Themes.Dark).Text
    header.Font = Enum.Font.GothamSemibold
    header.TextSize = 16
    header.ClipsDescendants = true

    local container = Instance.new("Frame", section)
    container.Size = UDim2.new(1,-12,1,-44)
    container.Position = UDim2.new(0,6,0,36)
    container.BackgroundTransparency = 1
    local vlayout = Instance.new("UIListLayout", container)
    vlayout.SortOrder = Enum.SortOrder.LayoutOrder
    vlayout.Padding = UDim.new(0,8)

    return {Section = section, Container = container}
end

-- Simple components: Button, Toggle, Slider, Input
function Window:CreateButton(container, text, callback)
    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(1,0,0,34)
    btn.AutoButtonColor = false
    btn.Text = text or "Button"
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 15
    btn.TextColor3 = (CryptixUI.Themes[self.Theme] or CryptixUI.Themes.Dark).Text
    btn.BackgroundColor3 = (CryptixUI.Themes[self.Theme] or CryptixUI.Themes.Dark).Accent
    btn.BorderSizePixel = 0
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0,8)
    btn.MouseButton1Click:Connect(function()
        pcall(function() callback() end)
    end)
    return btn
end

function Window:CreateToggle(container, label, default, callback)
    local frame = Instance.new("Frame", container)
    frame.Size = UDim2.new(1,0,0,34)
    frame.BackgroundTransparency = 1
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1,-60,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label or ""
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 15
    lbl.TextColor3 = (CryptixUI.Themes[self.Theme] or CryptixUI.Themes.Dark).Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local toggle = Instance.new("ImageButton", frame)
    toggle.Size = UDim2.new(0,40,0,24)
    toggle.Position = UDim2.new(1,-50,0.5,-12)
    toggle.BackgroundTransparency = 1
    toggle.Image = ""
    local back = Instance.new("Frame", toggle)
    back.Size = UDim2.new(1,0,1,0)
    back.BackgroundColor3 = (default and (CryptixUI.Themes[self.Theme] or CryptixUI.Themes.Dark).Accent) or Color3.fromRGB(80,80,80)
    back.BorderSizePixel = 0
    local corner2 = Instance.new("UICorner", back)
    corner2.CornerRadius = UDim.new(0,12)
    local knob = Instance.new("Frame", toggle)
    knob.Size = UDim2.new(0,14,0,14)
    knob.Position = default and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)
    knob.BackgroundColor3 = Color3.fromRGB(245,245,245)
    knob.BorderSizePixel = 0
    local knobCorner = Instance.new("UICorner", knob)
    knobCorner.CornerRadius = UDim.new(0,8)

    local state = default or false
    toggle.MouseButton1Click:Connect(function()
        state = not state
        back.BackgroundColor3 = state and (CryptixUI.Themes[self.Theme] or CryptixUI.Themes.Dark).Accent or Color3.fromRGB(80,80,80)
        tween(knob, 0.12, {Position = state and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)})
        pcall(function() callback(state) end)
    end)
    return frame, function() return state end, function(v) state = v; back.BackgroundColor3 = state and (CryptixUI.Themes[self.Theme] or CryptixUI.Themes.Dark).Accent or Color3.fromRGB(80,80,80); tween(knob,0.12,{Position = state and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)}) end
end

function Window:CreateSlider(container, label, min, max, default, callback)
    local frame = Instance.new("Frame", container)
    frame.Size = UDim2.new(1,0,0,50)
    frame.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1,0,0,18)
    lbl.BackgroundTransparency = 1
    lbl.Text = label or ""
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.TextColor3 = (CryptixUI.Themes[self.Theme] or CryptixUI.Themes.Dark).Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local bar = Instance.new("Frame", frame)
    bar.Size = UDim2.new(1,0,0,10)
    bar.Position = UDim2.new(0,0,1,-24)
    bar.BackgroundColor3 = (CryptixUI.Themes[self.Theme] or CryptixUI.Themes.Dark).Hover
    bar.BorderSizePixel = 0
    local corner = Instance.new("UICorner", bar)
    corner.CornerRadius = UDim.new(0,6)

    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.new(((default or min) - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = (CryptixUI.Themes[self.Theme] or CryptixUI.Themes.Dark).Accent
    fill.BorderSizePixel = 0
    local fillCorner = Instance.new("UICorner", fill)
    fillCorner.CornerRadius = UDim.new(0,6)

    local dragging = false
    local function update(value)
        local clamped = math.clamp(value, min, max)
        local ratio = (clamped - min) / (max - min)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        pcall(function() callback(clamped) end)
    end

    bar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            local conn
            conn = RunService.Heartbeat:Connect(function()
                local mouse = UserInputService:GetMouseLocation()
                local absX = mouse.X - bar.AbsolutePosition.X
                local ratio = math.clamp(absX / bar.AbsoluteSize.X, 0, 1)
                local value = min + ratio * (max - min)
                update(value)
            end)
            add_connection(conn)
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if conn then conn:Disconnect() end
                end
            end)
        end
    end)

    return frame, function() return tonumber(((fill.Size.X.Scale or 0) * (max - min) + min)) end, function(v) update(v) end
end

function Window:CreateInput(container, placeholder, callback)
    local box = Instance.new("TextBox", container)
    box.Size = UDim2.new(1,0,0,34)
    box.ClearTextOnFocus = false
    box.Text = ""
    box.PlaceholderText = placeholder or ""
    box.Font = Enum.Font.Gotham
    box.TextSize = 15
    box.TextColor3 = (CryptixUI.Themes[self.Theme] or CryptixUI.Themes.Dark).Text
    box.BackgroundColor3 = (CryptixUI.Themes[self.Theme] or CryptixUI.Themes.Dark).ElementBackground
    box.BorderSizePixel = 0
    local corner = Instance.new("UICorner", box)
    corner.CornerRadius = UDim.new(0,8)
    box.FocusLost:Connect(function(enter)
        if enter then pcall(function() callback(box.Text) end) end
    end)
    return box
end

-- Config API (JSON-based)
function CryptixUI:SaveConfig(name, data)
    if not writefile then return false, "writefile unavailable" end
    name = sanitize_filename(name or "config")
    local path = CONFIG_DIR .. "/" .. name .. ".json"
    local ok, err = write_json(path, data or {})
    if not ok then return false, err end
    return true
end

function CryptixUI:LoadConfig(name)
    name = sanitize_filename(name or "config")
    local path = CONFIG_DIR .. "/" .. name .. ".json"
    local tbl, err = read_json(path)
    if not tbl then return nil, err end
    return tbl
end

function CryptixUI:DeleteConfig(name)
    name = sanitize_filename(name or "config")
    local path = CONFIG_DIR .. "/" .. name .. ".json"
    return delete_file(path)
end

-- Refresh configs: list files in folder (executor dependent)
function CryptixUI:ListConfigs()
    if not isfolder then return {} end
    local files = {}
    local ok, list = pcall(function()
        return listfiles and listfiles(CONFIG_DIR) or nil
    end)
    if ok and list then
        for _,f in ipairs(list) do
            table.insert(files, f)
        end
    end
    return files
end

-- Expose create window on CryptixUI
function CryptixUI:Create(title, opts)
    return self:CreateWindow(title, opts)
end

-- Minimal notify (disabled by default; only prints)
function CryptixUI:Notify(opts)
    -- opts = {Title=..., Content=..., Duration=...}
    -- Notifications are disabled by default for Hub safety; use print as fallback.
    print(("[CryptixUI Notify] %s: %s"):format(opts and opts.Title or "Notice", opts and opts.Content or ""))
end

-- Expose API
return CryptixUI
