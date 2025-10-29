-- Criptix Hub Universal | v1.4.0
-- Single-file LocalScript (no external WindUI dependency)
-- Integrated: lightweight WindUI-like engine, Animation Engine, Dock System, Command engine, Mods loader
-- Author: Freddy Bear + assistant
-- Usage: paste into StarterGui as LocalScript or host raw and call with loadstring(HttpGet(...))()

-- ===== Services & basic utilities =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function safe_pcall(fn, ...)
    local ok, res = pcall(fn, ...)
    if not ok then
        warn("[CriptixHub] Error:", res)
    end
    return ok, res
end

local function clamp(v, a, b) v = tonumber(v) or a; if v < a then return a elseif v > b then return b else return v end end
local function deepcopy(t)
    if type(t) ~= "table" then return t end
    local s = {}
    for k,v in pairs(t) do s[deepcopy(k)] = deepcopy(v) end
    return s
end

-- ===== Animation Engine (helper) =====
local Anim = {}
Anim.Tween = function(obj, props, time, style, direction, onComplete)
    local info = TweenInfo.new(time or 0.18, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out)
    local tw = TweenService:Create(obj, info, props)
    tw:Play()
    if onComplete then tw.Completed:Connect(onComplete) end
    return tw
end
Anim.Fade = function(obj, goal, t) Anim.Tween(obj, {BackgroundTransparency = goal}, t or 0.18) end
Anim.Prop = function(obj, propTable, t) Anim.Tween(obj, propTable, t or 0.18) end

-- ===== Lightweight UI engine (WindUI-like minimal) =====
local UI = {}
UI.__index = UI

function UI:CreateWindow(opts)
    -- opts: Title, Size (UDim2), Transparent (bool), Theme (string), SideBarWidth (number)
    local Win = {}
    Win._opts = opts or {}
    Win._tabs = {}
    Win._visible = false
    Win._theme = opts.Theme or "Dark"
    Win._size = opts.Size or UDim2.fromOffset(800,480)
    Win._side = opts.SideBarWidth or 200

    -- ScreenGui
    local sg = Instance.new("ScreenGui")
    sg.Name = "CriptixHub_SG"
    sg.ResetOnSpawn = false
    sg.Parent = playerGui
    Win._sg = sg

    -- Main frame
    local frame = Instance.new("Frame")
    frame.Name = "Window"
    frame.Size = Win._size
    frame.Position = UDim2.new(0.5, -(Win._size.X.Offset/2), 0.5, -(Win._size.Y.Offset/2))
    frame.AnchorPoint = Vector2.new(0.5,0.5)
    frame.BackgroundColor3 = Color3.fromRGB(18,18,18)
    frame.BorderSizePixel = 0
    frame.Parent = sg
    frame.ZIndex = 2
    Win._frame = frame

    -- UICorner
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0,12)

    -- Topbar
    local top = Instance.new("Frame", frame)
    top.Name = "Top"
    top.Size = UDim2.new(1,0,0,36)
    top.Position = UDim2.new(0,0,0,0)
    top.BackgroundTransparency = 1

    local title = Instance.new("TextLabel", top)
    title.Name = "Title"
    title.Text = opts.Title or "Criptix Hub"
    title.TextColor3 = Color3.fromRGB(240,240,240)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.SFCompactSemibold
    title.TextSize = 18
    title.Size = UDim2.new(0.6,0,1,0)
    title.Position = UDim2.new(0.02,0,0,0)
    title.TextXAlignment = Enum.TextXAlignment.Left

    -- Minimize & Close buttons
    local btnClose = Instance.new("TextButton", top)
    btnClose.Size = UDim2.new(0,30,0,24)
    btnClose.Position = UDim2.new(1,-38,0.5,-12)
    btnClose.AnchorPoint = Vector2.new(0,0)
    btnClose.Text = "✕"
    btnClose.TextColor3 = Color3.fromRGB(220,220,220)
    btnClose.BackgroundTransparency = 1
    btnClose.Font = Enum.Font.SourceSansBold
    btnClose.TextSize = 18

    local btnMin = Instance.new("TextButton", top)
    btnMin.Size = UDim2.new(0,30,0,24)
    btnMin.Position = UDim2.new(1,-74,0.5,-12)
    btnMin.Text = "—"
    btnMin.TextColor3 = Color3.fromRGB(220,220,220)
    btnMin.BackgroundTransparency = 1
    btnMin.Font = Enum.Font.SourceSansBold
    btnMin.TextSize = 18

    -- Sidebar
    local sidebar = Instance.new("Frame", frame)
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, Win._side, 1, -36)
    sidebar.Position = UDim2.new(0,0,0,36)
    sidebar.BackgroundTransparency = 1

    local sideLayout = Instance.new("UIListLayout", sidebar)
    sideLayout.Padding = UDim.new(0,8)
    sideLayout.FillDirection = Enum.FillDirection.Vertical
    sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    sideLayout.VerticalAlignment = Enum.VerticalAlignment.Top

    local content = Instance.new("Frame", frame)
    content.Name = "Content"
    content.Size = UDim2.new(1, -Win._side - 14, 1, -46)
    content.Position = UDim2.new(0, Win._side + 8, 0, 38)
    content.BackgroundTransparency = 1

    local contentLayout = Instance.new("UIListLayout", content)
    contentLayout.Padding = UDim.new(0,6)
    contentLayout.FillDirection = Enum.FillDirection.Vertical
    contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    contentLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- make methods
    function Win:Tab(o)
        -- o.Title
        local tabBtn = Instance.new("TextButton", sidebar)
        tabBtn.Size = UDim2.new(1, -20, 0, 34)
        tabBtn.Text = " "..(o.Title or "Tab")
        tabBtn.TextColor3 = Color3.fromRGB(220,220,220)
        tabBtn.BackgroundTransparency = 0.8
        tabBtn.BackgroundColor3 = Color3.fromRGB(22,22,22)
        tabBtn.Font = Enum.Font.SFCompactSemibold
        tabBtn.TextSize = 15
        local uic = Instance.new("UICorner", tabBtn); uic.CornerRadius = UDim.new(0,8)

        local tabFrame = Instance.new("Frame", content)
        tabFrame.Size = UDim2.new(1,-10,0,300)
        tabFrame.BackgroundTransparency = 1
        tabFrame.LayoutOrder = #Win._tabs + 1
        tabFrame.Visible = false

        local tab = { _btn = tabBtn, _frame = tabFrame, _sections = {} }

        function tab:Select()
            -- hide others
            for _,t in ipairs(Win._tabs) do t._frame.Visible = false end
            tabFrame.Visible = true
            Anim.Prop(tabBtn, {BackgroundTransparency = 0.4}, 0.12)
        end

        tabBtn.MouseButton1Click:Connect(function() tab:Select() end)

        -- API: Divider, Section, Paragraph, Button, Toggle, Slider, Input, Dropdown, Keybind
        function tab:Divider()
            local d = Instance.new("Frame", tabFrame)
            d.Size = UDim2.new(1,0,0,2)
            d.BackgroundColor3 = Color3.fromRGB(40,40,40)
            d.BorderSizePixel = 0
            local uc = Instance.new("UICorner", d); uc.CornerRadius = UDim.new(0,6)
            return d
        end

        function tab:Section(opts)
            opts = opts or {}
            local sec = Instance.new("Frame", tabFrame)
            sec.Size = UDim2.new(1, -10, 0, 80)
            sec.BackgroundTransparency = 1
            local title = Instance.new("TextLabel", sec)
            title.Size = UDim2.new(1,0,0,20)
            title.Position = UDim2.new(0,0,0,0)
            title.BackgroundTransparency = 1
            title.Text = tostring(opts.Title or "")
            title.Font = Enum.Font.SFCompactSemibold
            title.TextColor3 = Color3.fromRGB(220,220,220)
            title.TextSize = opts.TextSize or 16
            title.TextXAlignment = Enum.TextXAlignment.Center
            return sec
        end

        function tab:Paragraph(opts)
            opts = opts or {}
            local p = Instance.new("Frame", tabFrame)
            p.Size = UDim2.new(1,-10,0,64)
            p.BackgroundTransparency = 1
            local t = Instance.new("TextLabel", p)
            t.Size = UDim2.new(1,0,0,20)
            t.Position = UDim2.new(0,0,0,0)
            t.BackgroundTransparency = 1
            t.Text = tostring(opts.Title or "")
            t.Font = Enum.Font.SFCompactSemibold
            t.TextColor3 = Color3.fromRGB(240,240,240)
            t.TextSize = 14
            t.TextXAlignment = Enum.TextXAlignment.Left

            local d = Instance.new("TextLabel", p)
            d.Size = UDim2.new(1,0,0,40)
            d.Position = UDim2.new(0,0,0,20)
            d.BackgroundTransparency = 1
            d.Text = tostring(opts.Desc or "")
            d.Font = Enum.Font.SourceSans
            d.TextColor3 = Color3.fromRGB(200,200,200)
            d.TextSize = 13
            d.TextWrapped = true
            d.TextXAlignment = Enum.TextXAlignment.Left
            return p
        end

        function tab:Button(opts)
            local btn = Instance.new("TextButton", tabFrame)
            btn.Size = UDim2.new(0,160,0,34)
            btn.Text = tostring(opts.Title or "Button")
            btn.Font = Enum.Font.SFCompactSemibold
            btn.TextSize = 14
            btn.TextColor3 = Color3.fromRGB(240,240,240)
            btn.BackgroundColor3 = Color3.fromRGB(28,28,28)
            btn.BorderSizePixel = 0
            local u = Instance.new("UICorner", btn); u.CornerRadius = UDim.new(0,8)
            if opts.Desc then
                btn.ToolTip = opts.Desc
            end
            btn.MouseButton1Click:Connect(function()
                safe_pcall(function() if opts.Callback then opts.Callback() end end)
            end)
            return btn
        end

        function tab:Toggle(opts)
            local frame = Instance.new("Frame", tabFrame)
            frame.Size = UDim2.new(0,180,0,28)
            frame.BackgroundTransparency = 1
            local label = Instance.new("TextLabel", frame)
            label.Size = UDim2.new(0,110,1,0)
            label.Position = UDim2.new(0,0,0,0)
            label.BackgroundTransparency = 1
            label.Text = tostring(opts.Title or "Toggle")
            label.Font = Enum.Font.SourceSans
            label.TextSize = 14
            label.TextColor3 = Color3.fromRGB(220,220,220)
            local btn = Instance.new("TextButton", frame)
            btn.Size = UDim2.new(0,48,0,20)
            btn.Position = UDim2.new(1,-50,0.5,-10)
            btn.Text = opts.Default and "ON" or "OFF"
            btn.Font = Enum.Font.SFCompactSemibold
            btn.TextSize = 12
            btn.BackgroundColor3 = opts.Default and Color3.fromRGB(60,160,80) or Color3.fromRGB(70,70,70)
            btn.TextColor3 = Color3.fromRGB(240,240,240)
            local state = opts.Default or false
            btn.MouseButton1Click:Connect(function()
                state = not state
                btn.Text = state and "ON" or "OFF"
                btn.BackgroundColor3 = state and Color3.fromRGB(60,160,80) or Color3.fromRGB(70,70,70)
                safe_pcall(function() if opts.Callback then opts.Callback(state) end end)
            end)
            return frame
        end

        function tab:Slider(title, min, max, default, callback)
            -- slider with value label and +/- fallback
            min = tonumber(min) or 0; max = tonumber(max) or 100; default = tonumber(default) or min
            local container = Instance.new("Frame", tabFrame)
            container.Size = UDim2.new(0,360,0,36)
            container.BackgroundTransparency = 1
            local lbl = Instance.new("TextLabel", container)
            lbl.Size = UDim2.new(0,180,1,0)
            lbl.Position = UDim2.new(0,0,0,0)
            lbl.BackgroundTransparency = 1
            lbl.Text = tostring(title or "Slider")
            lbl.Font = Enum.Font.SourceSans
            lbl.TextSize = 14
            lbl.TextColor3 = Color3.fromRGB(220,220,220)
            local valLbl = Instance.new("TextLabel", container)
            valLbl.Size = UDim2.new(0,80,1,0)
            valLbl.Position = UDim2.new(1,-80,0,0)
            valLbl.BackgroundTransparency = 1
            valLbl.Text = tostring(default)
            valLbl.Font = Enum.Font.SFCompactSemibold
            valLbl.TextSize = 14
            valLbl.TextColor3 = Color3.fromRGB(200,200,200)
            -- plus/minus buttons
            local minus = Instance.new("TextButton", container)
            minus.Size = UDim2.new(0,26,0,26); minus.Position = UDim2.new(0.55,-40,0.5,-13)
            minus.Text = "-" minus.Font = Enum.Font.SourceSansBold minus.TextSize = 18 minus.BackgroundColor3 = Color3.fromRGB(50,50,50) minus.TextColor3 = Color3.fromRGB(240,240,240)
            local plus = Instance.new("TextButton", container)
            plus.Size = UDim2.new(0,26,0,26); plus.Position = UDim2.new(0.55,-10,0.5,-13)
            plus.Text = "+" plus.Font = Enum.Font.SourceSansBold plus.TextSize = 18 plus.BackgroundColor3 = Color3.fromRGB(50,50,50) plus.TextColor3 = Color3.fromRGB(240,240,240)
            -- value handling
            local value = tonumber(default)
            local function setVal(v)
                v = clamp(v, min, max)
                value = v
                valLbl.Text = tostring(math.floor((v*100))/100)
                safe_pcall(function() if callback then callback(v) end end)
            end
            minus.MouseButton1Click:Connect(function() setVal(value - 1) end)
            plus.MouseButton1Click:Connect(function() setVal(value + 1) end)
            -- allow clicking on left/right area to set approximate value
            container.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    local pos = input.Position
                    local absPos = container.AbsolutePosition
                    local rel = (pos.X - absPos.X) / container.AbsoluteSize.X
                    local v = min + (max - min) * rel
                    setVal(v)
                end
            end)
            setVal(default)
            return container
        end

        function tab:Input(opts)
            opts = opts or {}
            local f = Instance.new("Frame", tabFrame)
            f.Size = UDim2.new(0,380,0,36)
            f.BackgroundTransparency = 1
            local lbl = Instance.new("TextLabel", f)
            lbl.Size = UDim2.new(0,120,1,0); lbl.BackgroundTransparency = 1; lbl.Text = tostring(opts.Title or "Input"); lbl.Font = Enum.Font.SourceSans; lbl.TextColor3 = Color3.fromRGB(220,220,220)
            local box = Instance.new("TextBox", f)
            box.Size = UDim2.new(0,240,0,28); box.Position = UDim2.new(0,130,0,4)
            box.Text = tostring(opts.Value or "")
            box.PlaceholderText = tostring(opts.Placeholder or "")
            box.ClearTextOnFocus = false
            box.Font = Enum.Font.SourceSans
            box.TextSize = 14
            box.TextColor3 = Color3.fromRGB(240,240,240)
            box.BackgroundColor3 = Color3.fromRGB(26,26,26)
            box.BorderSizePixel = 0
            local uc = Instance.new("UICorner", box); uc.CornerRadius = UDim.new(0,6)
            box.FocusLost:Connect(function(enter)
                if enter and opts.Callback then safe_pcall(function() opts.Callback(box.Text) end) end
            end)
            return f
        end

        function tab:Dropdown(opts)
            opts = opts or {}
            local frame = Instance.new("Frame", tabFrame)
            frame.Size = UDim2.new(0,360,0,34); frame.BackgroundTransparency = 1
            local lbl = Instance.new("TextLabel", frame)
            lbl.Size = UDim2.new(0,160,1,0); lbl.BackgroundTransparency = 1; lbl.Text = tostring(opts.Title or "Dropdown"); lbl.Font = Enum.Font.SourceSans; lbl.TextColor3 = Color3.fromRGB(220,220,220)
            local btn = Instance.new("TextButton", frame)
            btn.Size = UDim2.new(0,170,0,28); btn.Position = UDim2.new(0.45,0,0.1,0)
            btn.Text = (opts.Value or (opts.Values and opts.Values[1]) or "")
            btn.BackgroundColor3 = Color3.fromRGB(26,26,26); btn.TextColor3 = Color3.fromRGB(240,240,240)
            local menu
            btn.MouseButton1Click:Connect(function()
                if menu and menu.Parent then menu:Destroy(); menu = nil; return end
                menu = Instance.new("Frame", frame.Parent)
                menu.Position = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset, frame.Position.Y.Scale + 0.05, frame.Position.Y.Offset + 34)
                menu.Size = UDim2.new(0,170,0, math.max(28, (#(opts.Values or {}) * 28)))
                menu.BackgroundColor3 = Color3.fromRGB(26,26,26)
                local lay = Instance.new("UIListLayout", menu); lay.Padding = UDim.new(0,2)
                for i,v in ipairs(opts.Values or {}) do
                    local it = Instance.new("TextButton", menu)
                    it.Size = UDim2.new(1, -8, 0, 26)
                    it.Position = UDim2.new(0,4,0, (i-1)*28)
                    it.Text = tostring(v)
                    it.BackgroundColor3 = Color3.fromRGB(30,30,30)
                    it.TextColor3 = Color3.fromRGB(240,240,240)
                    it.MouseButton1Click:Connect(function()
                        btn.Text = tostring(v)
                        safe_pcall(function() if opts.Callback then opts.Callback(v) end end)
                        if menu and menu.Parent then menu:Destroy(); menu = nil end
                    end)
                end
            end)
            return frame
        end

        function tab:Keybind(opts)
            opts = opts or {}
            local f = Instance.new("Frame", tabFrame); f.Size = UDim2.new(0,360,0,36); f.BackgroundTransparency = 1
            local lbl = Instance.new("TextLabel", f); lbl.Size = UDim2.new(0,180,1,0); lbl.BackgroundTransparency = 1; lbl.Text = tostring(opts.Title or "Keybind"); lbl.Font = Enum.Font.SourceSans; lbl.TextColor3 = Color3.fromRGB(220,220,220)
            local btn = Instance.new("TextButton", f); btn.Position = UDim2.new(0.6,0,0.12,0); btn.Size = UDim2.new(0,120,0,28); btn.Text = tostring(opts.Default and tostring(opts.Default) or "Set Key")
            btn.MouseButton1Click:Connect(function()
                btn.Text = "Press key..."
                local conn
                conn = UserInputService.InputBegan:Connect(function(inp, processed)
                    if processed then return end
                    if inp.UserInputType == Enum.UserInputType.Keyboard then
                        btn.Text = tostring(inp.KeyCode.Name)
                        if opts.Callback then safe_pcall(function() opts.Callback(inp.KeyCode) end) end
                        conn:Disconnect()
                    end
                end)
            end)
            return f
        end

        table.insert(Win._tabs, tab)
        return tab
    end

    function Win:Toggle()
        self._visible = not self._visible
        self._frame.Visible = self._visible
        -- simple fade
        if self._visible then Anim.Prop(self._frame, {Position = UDim2.new(0.5, -(self._size.X.Offset/2), 0.5, -(self._size.Y.Offset/2))}, 0.18) end
    end

    function Win:SetTheme(name)
        self._theme = name
        -- minimal theme mapping
        if name == "Dark" then
            self._frame.BackgroundColor3 = Color3.fromRGB(18,18,18)
        elseif name == "Light" then
            self._frame.BackgroundColor3 = Color3.fromRGB(240,240,240)
        elseif name == "Criptix" then
            self._frame.BackgroundColor3 = Color3.fromRGB(15,15,20)
        else
            self._frame.BackgroundColor3 = Color3.fromRGB(18,18,18)
        end
    end

    -- close & minimize behavior
    btnClose.MouseButton1Click:Connect(function()
        safe_pcall(function() sg:Destroy() end)
    end)
    btnMin.MouseButton1Click:Connect(function()
        Win:Toggle()
    end)

    return Win
end

-- ===== Create the window and tabs =====
local win = UI:CreateWindow({ Title = "Criptix Hub Universal | v1.4.0", Size = UDim2.fromOffset(880,520), Theme = "Dark", SideBarWidth = 200 })
local tabInfo = win:Tab({ Title = "Info" })
local tabMain = win:Tab({ Title = "Main" })
local tabFunny = win:Tab({ Title = "Funny" })
local tabMisc = win:Tab({ Title = "Misc" })
local tabMore = win:Tab({ Title = "More Commands" })
local tabSettings = win:Tab({ Title = "Settings" })
local tabSUI = win:Tab({ Title = "Settings UI" })
local tabMods = win:Tab({ Title = "Mods" })

-- ===== Dock System (floating button) =====
do
    local sg = Instance.new("ScreenGui"); sg.Name = "CriptixDock"; sg.ResetOnSpawn = false; sg.Parent = playerGui
    local frame = Instance.new("Frame", sg)
    frame.Name = "Dock"
    frame.Size = UDim2.fromOffset(60,60)
    frame.Position = UDim2.new(0.9,0,0.08,0)
    frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
    frame.BorderSizePixel = 0
    frame.AnchorPoint = Vector2.new(0,0)
    local uc = Instance.new("UICorner", frame); uc.CornerRadius = UDim.new(0,14)
    local txt = Instance.new("TextLabel", frame)
    txt.Size = UDim2.new(1,0,1,0); txt.BackgroundTransparency = 1; txt.Text = "🌐"; txt.Font = Enum.Font.Cartoon; txt.TextSize = 28; txt.TextColor3 = Color3.fromRGB(180,220,255)
    -- draggable
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    -- click to toggle window
    frame.MouseButton1Click = nil -- some executors require actual button
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1,0,1,0); btn.BackgroundTransparency = 1; btn.Text = ""; btn.AutoButtonColor = false
    btn.MouseButton1Click:Connect(function() if win and win.Toggle then pcall(function() win:Toggle() end) end end)
end

-- ===== Command engine & Mods table =====
local Commands = {}
local Mods = {}

local function RegisterCommand(name, desc, fn, aliases)
    name = tostring(name):lower()
    Commands[name] = { Desc = desc or "", Fn = fn, Aliases = aliases or {} }
end

local function RunCommandLine(line)
    if not line or line == "" then return false end
    local parts = {}
    for w in string.gmatch(line, "%S+") do table.insert(parts, w) end
    local cmd = (parts[1] or ""):lower()
    for k,v in pairs(Commands) do
        if k == cmd or (v.Aliases and table.find(v.Aliases, cmd)) then
            safe_pcall(function() v.Fn(parts) end)
            return true
        end
    end
    warn("[Criptix] Unknown command:", cmd)
    return false
end

-- ===== Build Info Tab (based on Dad.lua style) =====
do
    tabInfo:Divider()
    tabInfo:Section({ Title = "Developers", TextXAlignment = "Center", TextSize = 17 })
    tabInfo:Divider()
    tabInfo:Paragraph({ Title = "Freddy Bear", Desc = "Principal Developer of Criptix Hub Universal", Image = "", ImageSize = 30 })
    tabInfo:Paragraph({ Title = "ChatGPT", Desc = "Assistant & Integration", Image = "", ImageSize = 30 })
    tabInfo:Paragraph({ Title = "Wind", Desc = "WindUI engine & design", Image = "", ImageSize = 30 })

    tabInfo:Divider()
    tabInfo:Section({ Title = "Criptix Info", TextXAlignment = "Center", TextSize = 17 })
    tabInfo:Divider()
    tabInfo:Paragraph({ Title = "Version", Desc = "Criptix Hub Universal | v1.4.0", Image = "info", ImageSize = 26 })
    tabInfo:Paragraph({ Title = "Description", Desc = "Modern universal admin hub with modular commands & plugin system.", Image = "code", ImageSize = 26 })

    -- Save/load area (simple)
    tabInfo:Divider()
    tabInfo:Section({ Title = "Save and Load", TextXAlignment = "Center", TextSize = 17 })
    tabInfo:Divider()
    _G.Criptix_ConfigName = _G.Criptix_ConfigName or ""
    tabInfo:Input({ Title = "Name Config", Desc = "Input name to save/load config", Value = "", Placeholder = "config_name", Callback = function(text) _G.Criptix_ConfigName = text end })
    local filesDropdown = tabInfo:Dropdown({ Title = "Select Config File", Multi = false, AllowNone = true, Values = {}, Value = "", Callback = function(file) _G.Criptix_ConfigName = file end })

    tabInfo:Button({ Title = "Save Config", Desc = "Save current UI config", Callback = function()
        local cfg = {} -- collect some settings
        cfg.Theme = win._theme
        cfg.Version = "v1.4.0"
        local ok, enc = pcall(function() return HttpService:JSONEncode(cfg) end)
        if ok and enc and _G.Criptix_ConfigName and #_G.Criptix_ConfigName>0 then
            local path = "CriptixHub_config_" .. _G.Criptix_ConfigName .. ".json"
            if writefile then
                pcall(function() writefile(path, enc) end)
                warn("[Criptix] Config saved:", path)
            else
                warn("[Criptix] writefile not available in this executor.")
            end
        else warn("[Criptix] Save failed.") end
    end })

    tabInfo:Button({ Title = "Load Config", Desc = "Load selected config", Callback = function()
        local path = "CriptixHub_config_" .. tostring(_G.Criptix_ConfigName) .. ".json"
        if isfile and isfile(path) then
            local json = readfile(path)
            local ok, decoded = pcall(function() return HttpService:JSONDecode(json) end)
            if ok and decoded then
                if decoded.Theme and win.SetTheme then win:SetTheme(decoded.Theme) end
                warn("[Criptix] Config loaded:", path)
            end
        else warn("[Criptix] Config file not found:", path) end
    end })

    tabInfo:Button({ Title = "Refresh Config List", Callback = function()
        if filesDropdown and type(filesDropdown.Refresh) == "function" then
            local list = {}
            if listfiles then
                for _,f in ipairs(listfiles("CriptixHub")) do
                    local s = f:match("([^/\\]+)%.json$")
                    if s then table.insert(list, s) end
                end
            end
            pcall(function() filesDropdown:Refresh(list) end)
        end
    end })

    -- Discord block (simple try-get)
    tabInfo:Divider()
    tabInfo:Section({ Title = "Discord", TextXAlignment = "Center", TextSize = 17 })
    tabInfo:Divider()
    local invite = "YOUR_DISCORD_INVITE"
    local ok, body = pcall(function() return game:HttpGet("https://discord.com/api/v10/invites/"..invite.."?with_counts=true") end)
    if ok and body and #body>10 then
        local s, d = pcall(function() return HttpService:JSONDecode(body) end)
        if s and d and d.guild then
            local para = tabInfo:Paragraph({ Title = d.guild.name, Desc = "• Members: "..tostring(d.approximate_member_count).."\n• Online: "..tostring(d.approximate_presence_count), Image = "https://cdn.discordapp.com/icons/"..d.guild.id.."/"..d.guild.icon..".png?size=128", ImageSize = 42 })
            tabInfo:Button({ Title = "Copy Discord Invite", Callback = function() pcall(setclipboard, "https://discord.gg/"..invite) end })
        else
            tabInfo:Paragraph({ Title = "Discord Info Unavailable", Desc = tostring(d), Image = "triangle-alert", ImageSize = 26, Color = "Red" })
        end
    else
        tabInfo:Paragraph({ Title = "Discord Info Unavailable", Desc = "HTTP blocked or invite invalid", Image = "triangle-alert", ImageSize = 26, Color = "Red" })
    end
end

-- ===== Build Main Tab =====
do
    tabMain:Divider()
    tabMain:Section({ Title = "Basic", TextXAlignment = "Center", TextSize = 17 })
    tabMain:Divider()
    -- Walk Speed
    local function setWalk(v) local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h then pcall(function() h.WalkSpeed = tonumber(v) or 16 end) end end
    tabMain:Paragraph({ Title = "Walk Speed", Desc = "Adjust walking speed (16-200)" })
    tabMain:Slider("Walk Speed", 16, 200, 32, function(v) setWalk(v) end)
    -- Jump Power
    tabMain:Paragraph({ Title = "Jump Power", Desc = "Adjust jump power (50-500)" })
    tabMain:Slider("Jump Power", 50, 500, 50, function(v) local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h then pcall(function() h.JumpPower = tonumber(v) or 50 end) end end)

    tabMain:Divider()
    tabMain:Section({ Title = "Advanced", TextXAlignment = "Center", TextSize = 17 })
    tabMain:Divider()
    -- Fly toggle & speed
    _G._Cr_FlySpeed = 50
    tabMain:Toggle({ Title = "Fly", Default = false, Callback = function(s)
        _G._Cr_FlyOn = s
        if s then
            local ch = player.Character or player.CharacterAdded:Wait()
            local hrp = ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChildWhichIsA("BasePart")
            if not hrp then return end
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

    tabMain:Toggle({ Title = "No Clip", Default = false, Callback = function(s)
        _G._Cr_Noclip = s
        if s then
            _G._Cr_NoclipConn = RunService.Stepped:Connect(function()
                local ch = player.Character; if ch then for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
            end)
        else
            if _G._Cr_NoclipConn then _G._Cr_NoclipConn:Disconnect(); _G._Cr_NoclipConn = nil end
            local ch = player.Character; if ch then for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
        end
    end })

    tabMain:Toggle({ Title = "God Mode", Default = false, Callback = function(s)
        _G._Cr_God = s
        if s then
            _G._Cr_GodConn = RunService.Heartbeat:Connect(function() local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h then pcall(function() h.Health = h.MaxHealth end) end end)
            local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h then pcall(function() h.MaxHealth = math.huge; h.Health = h.MaxHealth end) end
        else
            if _G._Cr_GodConn then _G._Cr_GodConn:Disconnect(); _G._Cr_GodConn = nil end
            local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h then pcall(function() h.MaxHealth = 100; h.Health = math.clamp(h.Health,0,100) end) end
        end
    end })
end

-- ===== Funny Tab =====
do
    tabFunny:Divider()
    tabFunny:Section({ Title = ":)", TextXAlignment = "Center", TextSize = 17 })
    tabFunny:Divider()
    tabFunny:Paragraph({ Title = "Touch Fling", Desc = "Click/touch a player to fling (10s window)." })
    tabFunny:Button({ Title = "Enable Touch Fling (10s)", Callback = function()
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
    end })

    tabFunny:Section({ Title = "Character", TextXAlignment = "Center", TextSize = 16 })
    tabFunny:Divider()
    tabFunny:Toggle({ Title = "Rainbow Body", Default = false, Callback = function(s)
        if s then
            _G._Cr_RainConn = RunService.Heartbeat:Connect(function()
                local ch = player.Character
                if ch then local hue = (tick()%5)/5; local col = Color3.fromHSV(hue,0.8,1); for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then p.Color = col end end end
            end)
        else
            if _G._Cr_RainConn then _G._Cr_RainConn:Disconnect(); _G._Cr_RainConn = nil end
        end
    end })

    tabFunny:Slider("Spin Speed", 1, 100, 20, function(v) _G._Cr_SpinSpeed = tonumber(v) or 20 end)
    tabFunny:Toggle({ Title = "Spin Character", Default = false, Callback = function(s)
        if s then
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
    end })

    tabFunny:Paragraph({ Title = "Custom Emote", Desc = "Play any animation by ID (client-side)" })
    _G._Cr_EmoteID = ""
    tabFunny:Input({ Title = "Emote ID", Desc = "Animation ID", Value = "", Placeholder = "123456789", Callback = function(v) _G._Cr_EmoteID = tostring(v) end })
    tabFunny:Button({ Title = "Play Emote", Callback = function()
        local id = tonumber(_G._Cr_EmoteID)
        if not id then warn("[Criptix] Invalid emote ID") return end
        local anim = Instance.new("Animation"); anim.AnimationId = "rbxassetid://"..tostring(id)
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            local track = hum:LoadAnimation(anim); track.Priority = Enum.AnimationPriority.Action; track:Play()
            task.delay(6, function() pcall(function() track:Stop(); anim:Destroy() end) end)
        end
    end })
end

-- ===== Misc Tab =====
do
    tabMisc:Divider()
    tabMisc:Section({ Title = "For AFK", TextXAlignment = "Center", TextSize = 17 })
    tabMisc:Divider()
    tabMisc:Toggle({ Title = "Anti AFK", Default = false, Callback = function(s)
        if s then player.Idled:Connect(function() local vu = game:GetService("VirtualUser"); vu:CaptureController(); vu:ClickButton2(Vector2.new()) end) end
    end })
    tabMisc:Button({ Title = "FPS Boost", Desc = "Set BaseParts to SmoothPlastic", Callback = function()
        for _,o in ipairs(Workspace:GetDescendants()) do if o:IsA("BasePart") then pcall(function() o.Material = Enum.Material.SmoothPlastic end) end end
    end })
    tabMisc:Button({ Title = "Darken Game", Desc = "Hide decals/textures", Callback = function()
        for _,o in ipairs(Workspace:GetDescendants()) do if o:IsA("Decal") or o:IsA("Texture") then pcall(function() o.Transparency = 1 end) end end
    end })

    tabMisc:Divider()
    tabMisc:Section({ Title = "Server", TextXAlignment = "Center", TextSize = 17 })
    tabMisc:Divider()
    tabMisc:Button({ Title = "Server Hop", Desc = "Hop server (best-effort)", Callback = function() pcall(function() TeleportService:Teleport(game.PlaceId, player) end) end })
    tabMisc:Button({ Title = "Rejoin Server", Desc = "Rejoin same server", Callback = function() pcall(function() TeleportService:Teleport(game.PlaceId, player) end) end })
end

-- ===== More Commands Tab (visual list) =====
do
    tabMore:Divider()
    tabMore:Section({ Title = "Commands", TextXAlignment = "Center", TextSize = 17 })
    tabMore:Divider()
    local function addCommandEntry(name, desc, ex)
        tabMore:Paragraph({ Title = name, Desc = desc })
        tabMore:Button({ Title = "Execute: "..ex, Callback = function() RunCommandLine(ex) end })
        tabMore:Button({ Title = "Copy: "..ex, Callback = function() pcall(setclipboard, ex) end })
    end

    addCommandEntry("speed", "Set walk speed: speed <num>", "speed 50")
    addCommandEntry("jump", "Set jump power: jump <num>", "jump 50")
    addCommandEntry("fly", "Toggle fly", "fly")
    addCommandEntry("noclip", "Toggle noclip", "noclip")
    addCommandEntry("god", "Toggle god", "god")
    addCommandEntry("fpsboost", "Apply FPS boost", "fpsboost")
    addCommandEntry("antiafk", "Toggle anti afk", "antiafk")
    addCommandEntry("serverhop", "Server hop", "serverhop")
    addCommandEntry("rejoin", "Rejoin", "rejoin")
    addCommandEntry("fling", "Touch fling", "fling")
    addCommandEntry("rainbow", "Rainbow body", "rainbow")
    addCommandEntry("spin", "Spin player", "spin 30")
end

-- ===== Register core command functions =====
RegisterCommand("speed", "Change WalkSpeed", function(args)
    local v = tonumber(args[2]) or 16
    local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if h then pcall(function() h.WalkSpeed = v end) end
    warn("[Criptix] speed ->", v)
end, {"ws"})

RegisterCommand("jump", "Change JumpPower", function(args)
    local v = tonumber(args[2]) or 50
    local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if h then pcall(function() h.JumpPower = v end) end
    warn("[Criptix] jump ->", v)
end, {"jp"})

RegisterCommand("fly", "Toggle fly", function()
    local cur = _G._Cr_FlyOn
    _G._Cr_FlyOn = not cur
    warn("[Criptix] fly toggled:", _G._Cr_FlyOn)
end)

RegisterCommand("noclip", "Toggle noclip", function()
    local cur = _G._Cr_NoclipEnabled
    _G._Cr_NoclipEnabled = not cur
    if _G._Cr_NoclipEnabled then
        _G._Cr_NoclipConn = RunService.Stepped:Connect(function() local ch = player.Character; if ch then for _,p in ipairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end end)
    else
        if _G._Cr_NoclipConn then _G._Cr_NoclipConn:Disconnect(); _G._Cr_NoclipConn = nil end
    end
end)

RegisterCommand("god", "Toggle god mode", function()
    local cur = _G._Cr_GodEnabled
    _G._Cr_GodEnabled = not cur
    if _G._Cr_GodEnabled then
        _G._Cr_GodConn = RunService.Heartbeat:Connect(function() local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h then pcall(function() h.Health = h.MaxHealth end) end end)
    else
        if _G._Cr_GodConn then _G._Cr_GodConn:Disconnect(); _G._Cr_GodConn = nil end
    end
end)

RegisterCommand("fpsboost", "Apply FPS boost", function() for _,o in ipairs(Workspace:GetDescendants()) do if o:IsA("BasePart") then pcall(function() o.Material = Enum.Material.SmoothPlastic end) end end end)
RegisterCommand("antiafk", "Enable anti AFK", function() player.Idled:Connect(function() local vu = game:GetService("VirtualUser"); vu:CaptureController(); vu:ClickButton2(Vector2.new()) end) end)
RegisterCommand("serverhop", "Server hop", function() pcall(function() TeleportService:Teleport(game.PlaceId, player) end) end)
RegisterCommand("rejoin", "Rejoin", function() pcall(function() TeleportService:Teleport(game.PlaceId, player) end) end)
RegisterCommand("fling", "Client fling helper", function() warn("Use the Funny tab fling button for interactive fling") end)
RegisterCommand("rainbow", "Toggle Rainbow", function() _G._Cr_RainToggle = not _G._Cr_RainToggle end)
RegisterCommand("spin", "Spin player", function(args) _G._Cr_SpinSpeed = tonumber(args[2]) or 20; _G._Cr_SpinLoop = not _G._Cr_SpinLoop end)

-- ===== Settings tab =====
do
    tabSettings:Divider(); tabSettings:Section({ Title = "General", TextXAlignment = "Center", TextSize = 17 }); tabSettings:Divider()
    tabSettings:Button({ Title = "Save Settings", Desc = "Save UI settings (if allowed)", Callback = function() warn("[Criptix] Save requested") end })
    tabSettings:Button({ Title = "Load Settings", Desc = "Load UI settings (if present)", Callback = function() warn("[Criptix] Load requested") end })
    tabSettings:Button({ Title = "Reset To Default", Desc = "Restore defaults", Callback = function() win:SetTheme("Dark"); win:Toggle() end })
end

-- ===== Settings UI tab =====
do
    tabSUI:Divider(); tabSUI:Section({ Title = "Appearance", TextXAlignment = "Center", TextSize = 17 }); tabSUI:Divider()
    tabSUI:Dropdown({ Title = "Change Theme", Values = {"Dark","Light","Criptix","Inferno","Emerald","Ocean"}, Callback = function(ch)
        if win.SetTheme then pcall(function() win:SetTheme(ch) end) end
    end })
    tabSUI:Slider("Transparency (0.0 - 0.8)", 0, 0.8, 0.2, function(v)
        if win and win._frame then win._frame.BackgroundTransparency = tonumber(v) or 0 end
    end)
    tabSUI:Keybind({ Title = "Toggle UI Keybind", Default = Enum.KeyCode.RightControl, Callback = function(key)
        -- binds: when key pressed, toggle UI
        local conn
        conn = UserInputService.InputBegan:Connect(function(inp, processed)
            if processed then return end
            if inp.KeyCode == key then if win.Toggle then pcall(function() win:Toggle() end) end end
        end)
    end })
end

-- ===== Mods Tab (plugin loader) =====
do
    tabMods:Divider(); tabMods:Section({ Title = "Plugin Manager", TextXAlignment = "Center", TextSize = 17 }); tabMods:Divider()
    _G.Criptix_ModURL = ""
    tabMods:Input({ Title = "Mod URL", Desc = "Raw script url", Value = "", Placeholder = "https://...", Callback = function(v) _G.Criptix_ModURL = tostring(v) end })
    tabMods:Button({ Title = "Load Mod", Callback = function()
        local url = tostring(_G.Criptix_ModURL or "")
        if url == "" then warn("[Criptix] No URL") return end
        local ok, body = pcall(function() return game:HttpGet(url) end)
        if not ok or not body then warn("[Criptix] HTTP GET failed") return end
        local ok2, res = pcall(function() return loadstring(body)() end)
        if ok2 then warn("[Criptix] Mod loaded:", url) else warn("[Criptix] Mod error:", res) end
    end })
    tabMods:Button({ Title = "Unload All Mods", Callback = function() Mods = {}; warn("[Criptix] Mods cleared") end })
end

-- ===== Finalize: show the window =====
pcall(function() if win and win.Toggle then win:Toggle() end end)

warn("[Criptix] v1.4.0 loaded (Dock + Animation Engine enabled).")

-- End of file
