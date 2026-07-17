-- Mikudes Super Hub | UI primitives (Apple Liquid Glass style)
-- Used by every panel in the hub. Import via:
--   local UI = loadstring(game:HttpGet(".../ui/init.lua"))()

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer

local UI = {}

-- ============ THEME ============
UI.Theme = {
    Glass       = Color3.fromRGB(255, 255, 255),
    GlassEdge   = Color3.fromRGB(255, 255, 255),
    TintA       = Color3.fromRGB(220, 235, 255),
    TintB       = Color3.fromRGB(255, 240, 250),
    TextPrimary = Color3.fromRGB(20, 20, 30),
    TextSub     = Color3.fromRGB(90, 90, 110),
    TextMuted   = Color3.fromRGB(140, 140, 160),
    Accent      = Color3.fromRGB(255, 105, 180),   -- hot pink
    AccentSoft  = Color3.fromRGB(255, 182, 215),
    Success     = Color3.fromRGB(80, 200, 120),
    Danger      = Color3.fromRGB(255, 90, 95),
    Warn        = Color3.fromRGB(255, 180, 60),

    FontTitle   = Enum.Font.GothamBold,
    FontBody    = Enum.Font.GothamMedium,
    FontLight   = Enum.Font.Gotham,

    Radius      = UDim.new(0, 20),
    RadiusSmall = UDim.new(0, 14),
    RadiusPill  = UDim.new(0, 999),
}

-- ============ HTTP (executor-portable) ============
function UI.HttpGet(url)
    local ok, result = pcall(function()
        if syn and syn.request then
            local r = syn.request({Url = url, Method = "GET"})
            return r and r.Body
        end
        if request then
            local r = request({Url = url, Method = "GET"})
            return r and r.Body
        end
        if http_request then
            local r = http_request({Url = url, Method = "GET"})
            return r and r.Body
        end
        return game:HttpGet(url)
    end)
    return ok and result or nil
end

function UI.JsonDecode(s)
    local ok, t = pcall(HttpService.JSONDecode, HttpService, s)
    return ok and t or nil
end

function UI.CopyToClipboard(text)
    pcall(setclipboard, text)
end

-- ============ GLASS PRIMITIVES ============

-- Glass card (drop-in container with gradient + stroke + soft shadow)
function UI.GlassCard(parent, opts)
    opts = opts or {}
    local size = opts.Size or UDim2.fromOffset(420, 60)
    local pos  = opts.Position or UDim2.fromOffset(20, 0)

    local card = Instance.new("Frame")
    card.Name = opts.Name or "GlassCard"
    card.Size = size
    card.Position = pos
    card.BackgroundColor3 = UI.Theme.Glass
    card.BackgroundTransparency = opts.Transparency or 0.12
    card.BorderSizePixel = 0
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UI.Theme.Radius

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   UI.Theme.Glass),
        ColorSequenceKeypoint.new(0.5, UI.Theme.TintA),
        ColorSequenceKeypoint.new(1,   UI.Theme.TintB),
    })
    grad.Rotation = 135
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0,   0.55),
        NumberSequenceKeypoint.new(0.5, 0.30),
        NumberSequenceKeypoint.new(1,   0.55),
    })
    grad.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Color = UI.Theme.GlassEdge
    stroke.Transparency = 0.40
    stroke.Thickness = 1.2
    stroke.Parent = card

    -- padding container (so children align nicely)
    local pad = Instance.new("Frame")
    pad.Name = "Pad"
    pad.Size = UDim2.new(1, -28, 1, -20)
    pad.Position = UDim2.fromOffset(14, 10)
    pad.BackgroundTransparency = 1
    pad.Parent = card

    card.Pad = pad
    return card
end

-- Glass button (hover/press tween, returns the TextButton)
function UI.GlassButton(parent, text, callback, opts)
    opts = opts or {}
    local size = opts.Size or UDim2.new(1, 0, 0, 44)
    local pos  = opts.Position or UDim2.fromOffset(0, 0)
    local accent = opts.Accent

    local btn = Instance.new("TextButton")
    btn.Name = opts.Name or text
    btn.Size = size
    btn.Position = pos
    btn.BackgroundColor3 = accent or UI.Theme.Glass
    btn.BackgroundTransparency = accent and 0.10 or 0.30
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Font = UI.Theme.FontBody
    btn.Text = text
    btn.TextColor3 = UI.Theme.TextPrimary
    btn.TextSize = opts.TextSize or 15
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UI.Theme.RadiusSmall

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(1, accent or Color3.fromRGB(240,245,255)),
    })
    grad.Rotation = 90
    grad.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = UI.Theme.GlassEdge
    stroke.Transparency = accent and 0.30 or 0.55
    stroke.Thickness = 1
    stroke.Parent = btn

    local rest = btn.BackgroundTransparency
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = math.max(rest - 0.15, 0),
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = rest,
        }):Play()
    end)
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.08), {
            BackgroundTransparency = math.min(rest + 0.25, 1),
        }):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {
            BackgroundTransparency = rest,
        }):Play()
    end)

    if callback then
        btn.MouseButton1Click:Connect(callback)
    end
    return btn
end

-- Pill label (status badges, chips)
function UI.Pill(parent, text, color, opts)
    opts = opts or {}
    local lbl = Instance.new("TextLabel")
    lbl.Name = opts.Name or text
    lbl.Size = opts.Size or UDim2.fromOffset(80, 22)
    lbl.Position = opts.Position or UDim2.fromOffset(0, 0)
    lbl.BackgroundColor3 = color or UI.Theme.AccentSoft
    lbl.BackgroundTransparency = 0.25
    lbl.BorderSizePixel = 0
    lbl.Font = UI.Theme.FontLight
    lbl.Text = "  " .. text .. "  "
    lbl.TextColor3 = UI.Theme.TextPrimary
    lbl.TextSize = 12
    lbl.Parent = parent
    Instance.new("UICorner", lbl).CornerRadius = UI.Theme.RadiusPill
    Instance.new("UIStroke", lbl).Transparency = 0.6
    return lbl
end

-- Section header
function UI.Section(parent, text, yOffset)
    local h = Instance.new("TextLabel")
    h.Name = "Section_" .. text
    h.Size = UDim2.new(1, 0, 0, 18)
    h.Position = UDim2.fromOffset(0, yOffset or 0)
    h.BackgroundTransparency = 1
    h.Font = UI.Theme.FontBody
    h.Text = text
    h.TextColor3 = UI.Theme.TextSub
    h.TextSize = 12
    h.TextXAlignment = Enum.TextXAlignment.Left
    h.Parent = parent
    return h
end

-- Toggle row (label + switch)
function UI.Toggle(parent, label, default, callback, yOffset)
    local row = Instance.new("Frame")
    row.Name = "Toggle_" .. label
    row.Size = UDim2.new(1, 0, 0, 36)
    row.Position = UDim2.fromOffset(0, yOffset or 0)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = UI.Theme.FontBody
    lbl.Text = label
    lbl.TextColor3 = UI.Theme.TextPrimary
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local switch = Instance.new("TextButton")
    switch.Name = "Switch"
    switch.Size = UDim2.fromOffset(46, 24)
    switch.Position = UDim2.new(1, -50, 0.5, -12)
    switch.BackgroundColor3 = default and UI.Theme.Success or Color3.fromRGB(200, 200, 210)
    switch.BackgroundTransparency = 0.25
    switch.BorderSizePixel = 0
    switch.Text = ""
    switch.AutoButtonColor = false
    switch.Parent = row
    Instance.new("UICorner", switch).CornerRadius = UI.Theme.RadiusPill

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(18, 18)
    knob.Position = default and UDim2.fromOffset(24, 3) or UDim2.fromOffset(4, 3)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = switch
    Instance.new("UICorner", knob).CornerRadius = UI.Theme.RadiusPill

    local state = default and true or false
    switch.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(switch, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundColor3 = state and UI.Theme.Success or Color3.fromRGB(200, 200, 210),
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = state and UDim2.fromOffset(24, 3) or UDim2.fromOffset(4, 3),
        }):Play()
        if callback then callback(state) end
    end)

    return row, function() return state end
end

-- Slider row
function UI.Slider(parent, label, min, max, default, callback, yOffset)
    local row = Instance.new("Frame")
    row.Name = "Slider_" .. label
    row.Size = UDim2.new(1, 0, 0, 44)
    row.Position = UDim2.fromOffset(0, yOffset or 0)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.7, 0, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Font = UI.Theme.FontBody
    lbl.Text = label
    lbl.TextColor3 = UI.Theme.TextPrimary
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0.3, -8, 0, 18)
    valLbl.Position = UDim2.new(0.7, 8, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Font = UI.Theme.FontBody
    valLbl.Text = tostring(default)
    valLbl.TextColor3 = UI.Theme.Accent
    valLbl.TextSize = 14
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, 0, 0, 6)
    track.Position = UDim2.new(0, 0, 0, 30)
    track.BackgroundColor3 = Color3.fromRGB(220, 220, 230)
    track.BackgroundTransparency = 0.30
    track.BorderSizePixel = 0
    track.Parent = row
    Instance.new("UICorner", track).CornerRadius = UI.Theme.RadiusPill

    local function setVisual(v)
        local pct = math.clamp((v - min) / (max - min), 0, 1)
        local fill = track:FindFirstChild("Fill")
        if not fill then
            fill = Instance.new("Frame")
            fill.Name = "Fill"
            fill.BackgroundColor3 = UI.Theme.Accent
            fill.BackgroundTransparency = 0.10
            fill.BorderSizePixel = 0
            fill.Parent = track
            Instance.new("UICorner", fill).CornerRadius = UI.Theme.RadiusPill
        end
        fill.Size = UDim2.new(pct, 0, 1, 0)
        valLbl.Text = (v == math.floor(v)) and tostring(math.floor(v)) or string.format("%.2f", v)
    end
    setVisual(default)

    local dragging = false
    local function update(input)
        local absX = track.AbsolutePosition.X
        local sizeX = track.AbsoluteSize.X
        local rel = math.clamp((input.Position.X - absX) / sizeX, 0, 1)
        local v = min + (max - min) * rel
        setVisual(v)
        if callback then callback(v) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input)
        end
    end)
    track.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)

    return row, function() return default end
end

-- Text input row
function UI.Input(parent, placeholder, default, yOffset)
    local box = Instance.new("TextBox")
    box.Name = "Input"
    box.Size = UDim2.new(1, 0, 0, 38)
    box.Position = UDim2.fromOffset(0, yOffset or 0)
    box.BackgroundColor3 = UI.Theme.Glass
    box.BackgroundTransparency = 0.25
    box.BorderSizePixel = 0
    box.Font = UI.Theme.FontBody
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = UI.Theme.TextMuted
    box.Text = default or ""
    box.TextColor3 = UI.Theme.TextPrimary
    box.TextSize = 14
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false
    box.Parent = parent
    Instance.new("UIPadding", box).PaddingLeft = UDim.new(0, 14)
    Instance.new("UICorner", box).CornerRadius = UI.Theme.RadiusSmall
    local s = Instance.new("UIStroke", box)
    s.Color = UI.Theme.GlassEdge
    s.Transparency = 0.55
    s.Thickness = 1
    return box
end

-- Toast notification (top-center, auto-fade)
function UI.Notify(text, kind, duration)
    kind = kind or "info"
    duration = duration or 3
    local color = UI.Theme.Accent
    if kind == "success" then color = UI.Theme.Success
    elseif kind == "warn" then color = UI.Theme.Warn
    elseif kind == "error" then color = UI.Theme.Danger end

    local gui = player:FindFirstChild("PlayerGui")
    if not gui then return end
    local existing = gui:FindFirstChild("MikuToast")
    if not existing then
        existing = Instance.new("ScreenGui")
        existing.Name = "MikuToast"
        existing.IgnoreGuiInset = true
        existing.DisplayOrder = 10000
        existing.ResetOnSpawn = false
        existing.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        existing.Parent = gui
    end

    local toast = Instance.new("Frame")
    toast.Size = UDim2.fromOffset(280, 0)
    toast.AutomaticSize = Enum.AutomaticSize.Y
    toast.Position = UDim2.new(0.5, 0, 0, 24)
    toast.AnchorPoint = Vector2.new(0.5, 0)
    toast.BackgroundColor3 = UI.Theme.Glass
    toast.BackgroundTransparency = 0.10
    toast.BorderSizePixel = 0
    toast.ClipsDescendants = true
    toast.Parent = existing
    Instance.new("UICorner", toast).CornerRadius = UI.Theme.RadiusSmall
    local g = Instance.new("UIGradient", toast)
    g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, color), ColorSequenceKeypoint.new(1, UI.Theme.TintA)})
    g.Rotation = 90
    local s = Instance.new("UIStroke", toast)
    s.Color = UI.Theme.GlassEdge
    s.Transparency = 0.40
    s.Thickness = 1

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -28, 1, 0)
    lbl.Position = UDim2.fromOffset(14, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = UI.Theme.FontBody
    lbl.Text = text
    lbl.TextColor3 = UI.Theme.TextPrimary
    lbl.TextSize = 14
    lbl.TextWrapped = true
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.Parent = toast
    Instance.new("UIPadding", toast).PaddingTop = UDim.new(0, 10)
    Instance.new("UIPadding", toast).PaddingBottom = UDim.new(0, 10)

    toast.Size = UDim2.fromOffset(280, 0)
    toast.BackgroundTransparency = 1
    TweenService:Create(toast, TweenInfo.new(0.30, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(280, 44),
        BackgroundTransparency = 0.10,
    }):Play()

    task.delay(duration, function()
        local out = TweenService:Create(toast, TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.fromOffset(280, 0),
            BackgroundTransparency = 1,
        })
        out:Play()
        out.Completed:Wait()
        toast:Destroy()
    end)
end

-- Drag handler (call on the panel frame)
function UI.MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Open/close tween helpers
function UI.OpenTween(frame, targetSize, duration)
    frame.Size = UDim2.fromOffset(0, 0)
    frame.BackgroundTransparency = 1
    TweenService:Create(frame, TweenInfo.new(duration or 0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = targetSize,
        BackgroundTransparency = 0.15,
    }):Play()
end

function UI.CloseTween(frame, onDone)
    local t = TweenService:Create(frame, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
        Size = UDim2.fromOffset(0, 0),
        BackgroundTransparency = 1,
    })
    t:Play()
    t.Completed:Connect(function()
        if onDone then onDone() end
        frame:Destroy()
    end)
end

return UI
