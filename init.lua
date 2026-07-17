-- Mikudes Super Hub | loader entry point
-- Loadstring:
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/levox00/RobloxHub/main/init.lua"))()

local REPO = "https://raw.githubusercontent.com/levox00/RobloxHub/main"
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- ============================================================
-- HTTP helpers (executor-portable)
-- ============================================================
local function httpGet(url)
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

local function copyToClipboard(text)
    pcall(setclipboard, text)
end

local function notify(text, kind)
    kind = kind or "info"
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
    local color = Color3.fromRGB(255, 105, 180)
    if kind == "success" then color = Color3.fromRGB(80, 200, 120)
    elseif kind == "warn" then color = Color3.fromRGB(255, 180, 60)
    elseif kind == "error" then color = Color3.fromRGB(255, 90, 95) end

    local toast = Instance.new("Frame")
    toast.Size = UDim2.fromOffset(280, 44)
    toast.Position = UDim2.new(0.5, 0, 0, 24)
    toast.AnchorPoint = Vector2.new(0.5, 0)
    toast.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    toast.BackgroundTransparency = 0.10
    toast.BorderSizePixel = 0
    toast.Parent = existing
    Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 14)
    local g = Instance.new("UIGradient", toast)
    g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, color), ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 235, 255))})
    g.Rotation = 90
    local s = Instance.new("UIStroke", toast)
    s.Color = Color3.fromRGB(255, 255, 255)
    s.Transparency = 0.40
    s.Thickness = 1

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -28, 1, 0)
    lbl.Position = UDim2.fromOffset(14, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(20, 20, 30)
    lbl.TextSize = 14
    lbl.TextWrapped = true
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = toast

    task.delay(3, function()
        local out = game:GetService("TweenService"):Create(toast, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.fromOffset(280, 0), BackgroundTransparency = 1,
        })
        out:Play(); out.Completed:Wait(); toast:Destroy()
    end)
end

-- ============================================================
-- Fetch auth.json
-- ============================================================
local authRaw = httpGet(REPO .. "/auth.json")
local auth = nil
if authRaw then
    local ok, decoded = pcall(HttpService.JSONDecode, HttpService, authRaw)
    if ok then auth = decoded end
end

if not auth then
    notify("Failed to reach auth server. Check your executor's HTTP.", "error")
    return
end

-- ============================================================
-- Cleanup previous hub
-- ============================================================
local pg = player:WaitForChild("PlayerGui")
local prev = pg:FindFirstChild("MikudesHub")
if prev then prev:Destroy() end

-- ============================================================
-- Discord gate
-- ============================================================
if auth.discord and auth.discord.required then
    -- We can't actually verify Discord membership from inside Roblox.
    -- The hub's design: the gate opens the invite link; user joins; then the key check runs.
    -- The key check is the real protection — Discord is the community step.

    local gate = Instance.new("ScreenGui")
    gate.Name = "MikuGate"
    gate.IgnoreGuiInset = true
    gate.DisplayOrder = 9999
    gate.ResetOnSpawn = false
    gate.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gate.Parent = pg

    local dim = Instance.new("Frame")
    dim.Size = UDim2.new(1, 0, 1, 0)
    dim.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
    dim.BackgroundTransparency = 0.35
    dim.BorderSizePixel = 0
    dim.Parent = gate

    local card = Instance.new("Frame")
    card.Size = UDim2.fromOffset(380, 280)
    card.Position = UDim2.fromScale(0.5, 0.5)
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    card.BackgroundTransparency = 0.10
    card.BorderSizePixel = 0
    card.Parent = gate
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 24)
    local cg = Instance.new("UIGradient", card)
    cg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 230, 245)),
    })
    cg.Rotation = 135
    local cs = Instance.new("UIStroke", card)
    cs.Color = Color3.fromRGB(255, 255, 255)
    cs.Transparency = 0.40
    cs.Thickness = 1.5

    local title = Instance.new("TextLabel", card)
    title.Size = UDim2.new(1, -40, 0, 30)
    title.Position = UDim2.fromOffset(20, 24)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = auth.discord.server_name or "Discord Required"
    title.TextColor3 = Color3.fromRGB(20, 20, 30)
    title.TextSize = 22
    title.TextXAlignment = Enum.TextXAlignment.Left

    local sub = Instance.new("TextLabel", card)
    sub.Size = UDim2.new(1, -40, 0, 60)
    sub.Position = UDim2.fromOffset(20, 60)
    sub.BackgroundTransparency = 1
    sub.Font = Enum.Font.Gotham
    sub.Text = auth.discord.check_message or "Join our Discord before using the hub."
    sub.TextColor3 = Color3.fromRGB(80, 80, 100)
    sub.TextSize = 14
    sub.TextWrapped = true
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.TextYAlignment = Enum.TextYAlignment.Top

    local joinBtn = Instance.new("TextButton", card)
    joinBtn.Size = UDim2.new(1, -40, 0, 48)
    joinBtn.Position = UDim2.fromOffset(20, 140)
    joinBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)  -- Discord blurple
    joinBtn.BackgroundTransparency = 0.10
    joinBtn.BorderSizePixel = 0
    joinBtn.Font = Enum.Font.GothamBold
    joinBtn.Text = "  Join Discord"
    joinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    joinBtn.TextSize = 16
    joinBtn.AutoButtonColor = false
    Instance.new("UICorner", joinBtn).CornerRadius = UDim.new(0, 16)
    Instance.new("UIStroke", joinBtn).Transparency = 0.30

    joinBtn.MouseButton1Click:Connect(function()
        copyToClipboard(auth.discord.invite_url)
        notify("Discord invite copied! Paste in browser.", "success")
        pcall(function() setclipboard(auth.discord.invite_url) end)
    end)

    local haveKeyBtn = Instance.new("TextButton", card)
    haveKeyBtn.Size = UDim2.new(1, -40, 0, 44)
    haveKeyBtn.Position = UDim2.fromOffset(20, 200)
    haveKeyBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    haveKeyBtn.BackgroundTransparency = 0.30
    haveKeyBtn.BorderSizePixel = 0
    haveKeyBtn.Font = Enum.Font.GothamMedium
    haveKeyBtn.Text = "I have a key — continue"
    haveKeyBtn.TextColor3 = Color3.fromRGB(20, 20, 30)
    haveKeyBtn.TextSize = 15
    haveKeyBtn.AutoButtonColor = false
    Instance.new("UICorner", haveKeyBtn).CornerRadius = UDim.new(0, 14)
    Instance.new("UIStroke", haveKeyBtn).Transparency = 0.55

    haveKeyBtn.MouseButton1Click:Connect(function()
        gate:Destroy()
        -- Continue to key check below
        runKeyCheck()
    end)
end

-- ============================================================
-- Key check
-- ============================================================
function runKeyCheck()
    if not (auth.keys and auth.keys.enabled) then return runHub() end

    local gate2 = Instance.new("ScreenGui")
    gate2.Name = "MikuKey"
    gate2.IgnoreGuiInset = true
    gate2.DisplayOrder = 9999
    gate2.ResetOnSpawn = false
    gate2.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gate2.Parent = pg

    local dim = Instance.new("Frame")
    dim.Size = UDim2.new(1, 0, 1, 0)
    dim.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
    dim.BackgroundTransparency = 0.35
    dim.BorderSizePixel = 0
    dim.Parent = gate2

    local card = Instance.new("Frame")
    card.Size = UDim2.fromOffset(380, 220)
    card.Position = UDim2.fromScale(0.5, 0.5)
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    card.BackgroundTransparency = 0.10
    card.BorderSizePixel = 0
    card.Parent = gate2
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 24)
    local cg = Instance.new("UIGradient", card)
    cg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 230, 245)),
    })
    cg.Rotation = 135
    Instance.new("UIStroke", card).Transparency = 0.40

    local title = Instance.new("TextLabel", card)
    title.Size = UDim2.new(1, -40, 0, 26)
    title.Position = UDim2.fromOffset(20, 22)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = "Enter your key"
    title.TextColor3 = Color3.fromRGB(20, 20, 30)
    title.TextSize = 20
    title.TextXAlignment = Enum.TextXAlignment.Left

    local box = Instance.new("TextBox", card)
    box.Size = UDim2.new(1, -40, 0, 44)
    box.Position = UDim2.fromOffset(20, 60)
    box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    box.BackgroundTransparency = 0.25
    box.BorderSizePixel = 0
    box.Font = Enum.Font.GothamMedium
    box.PlaceholderText = "MikuHub-XXXX-XXXX"
    box.PlaceholderColor3 = Color3.fromRGB(140, 140, 160)
    box.Text = ""
    box.TextColor3 = Color3.fromRGB(20, 20, 30)
    box.TextSize = 14
    box.ClearTextOnFocus = false
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 14)
    Instance.new("UIStroke", box).Transparency = 0.55
    Instance.new("UIPadding", box).PaddingLeft = UDim.new(0, 14)

    local errLbl = Instance.new("TextLabel", card)
    errLbl.Size = UDim2.new(1, -40, 0, 18)
    errLbl.Position = UDim2.fromOffset(20, 112)
    errLbl.BackgroundTransparency = 1
    errLbl.Font = Enum.Font.Gotham
    errLbl.Text = ""
    errLbl.TextColor3 = Color3.fromRGB(255, 90, 95)
    errLbl.TextSize = 13
    errLbl.TextXAlignment = Enum.TextXAlignment.Left

    local submit = Instance.new("TextButton", card)
    submit.Size = UDim2.new(1, -40, 0, 44)
    submit.Position = UDim2.fromOffset(20, 142)
    submit.BackgroundColor3 = Color3.fromRGB(255, 105, 180)
    submit.BackgroundTransparency = 0.10
    submit.BorderSizePixel = 0
    submit.Font = Enum.Font.GothamBold
    submit.Text = "Unlock Hub"
    submit.TextColor3 = Color3.fromRGB(255, 255, 255)
    submit.TextSize = 15
    submit.AutoButtonColor = false
    Instance.new("UICorner", submit).CornerRadius = UDim.new(0, 14)

    local function check()
        local entered = box.Text:gsub("%s+", "")
        local ok = false
        for _, k in ipairs(auth.keys.valid) do
            if entered == k:gsub("%s+", "") then ok = true break end
        end
        if ok then
            if auth.keys.save_to_clipboard then copyToClipboard(entered) end
            notify("Key accepted! Welcome.", "success")
            gate2:Destroy()
            runHub()
        else
            errLbl.Text = auth.keys.wrong_message or "Invalid key."
        end
    end

    submit.MouseButton1Click:Connect(check)
    box.FocusLost:Connect(function(enterPressed) if enterPressed then check() end end)
end

-- ============================================================
-- Hub shell (only reached if Discord + key pass)
-- ============================================================
function runHub()
    -- Load UI primitives
    local UI = loadstring(httpGet(REPO .. "/ui/init.lua"))()

    -- Load each tab module
    local Profile   = loadstring(httpGet(REPO .. "/ui/Profile.lua"))()
    local GamesTab  = loadstring(httpGet(REPO .. "/ui/Games.lua"))()
    local InfoTab   = loadstring(httpGet(REPO .. "/ui/Info.lua"))()

    -- Container
    local gui = Instance.new("ScreenGui")
    gui.Name = "MikudesHub"
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = pg

    local PANEL_W = (auth.ui and auth.ui.panel_size and auth.ui.panel_size[1]) or 460
    local PANEL_H = (auth.ui and auth.ui.panel_size and auth.ui.panel_size[2]) or 520

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.fromOffset(PANEL_W, PANEL_H)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    panel.BackgroundTransparency = 0.10
    panel.BorderSizePixel = 0
    panel.ClipsDescendants = true
    panel.Parent = gui
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 24)

    -- Glass gradient
    local pgrad = Instance.new("UIGradient", panel)
    pgrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(220, 235, 255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 240, 250)),
    })
    pgrad.Rotation = 135
    pgrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.55),
        NumberSequenceKeypoint.new(0.5, 0.30),
        NumberSequenceKeypoint.new(1, 0.55),
    })
    Instance.new("UIStroke", panel).Transparency = 0.40

    -- Top reflection sweep
    local hi = Instance.new("Frame")
    hi.Name = "TopReflection"
    hi.Size = UDim2.new(1, -32, 0.45, 0)
    hi.Position = UDim2.fromOffset(16, 0)
    hi.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    hi.BackgroundTransparency = 0.85
    hi.BorderSizePixel = 0
    hi.ZIndex = 2
    hi.Parent = panel
    Instance.new("UICorner", hi).CornerRadius = UDim.new(0, 24)
    local hg = Instance.new("UIGradient", hi)
    hg.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    hg.Rotation = 90

    -- Header bar (title + version + close)
    local header = Instance.new("Frame", panel)
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 64)
    header.BackgroundTransparency = 1
    header.ZIndex = 5

    local hTitle = Instance.new("TextLabel", header)
    hTitle.Size = UDim2.new(1, -120, 0, 26)
    hTitle.Position = UDim2.fromOffset(20, 12)
    hTitle.BackgroundTransparency = 1
    hTitle.Font = Enum.Font.GothamBold
    hTitle.Text = (auth.ui and auth.ui.hub_title) or "Mikudes Super Hub"
    hTitle.TextColor3 = Color3.fromRGB(20, 20, 30)
    hTitle.TextSize = 20
    hTitle.TextXAlignment = Enum.TextXAlignment.Left

    local hSub = Instance.new("TextLabel", header)
    hSub.Size = UDim2.new(1, -120, 0, 16)
    hSub.Position = UDim2.fromOffset(20, 40)
    hSub.BackgroundTransparency = 1
    hSub.Font = Enum.Font.Gotham
    hSub.Text = (auth.ui and auth.ui.hub_subtitle) or ("v" .. tostring(auth.version or "1.0.0"))
    hSub.TextColor3 = Color3.fromRGB(90, 90, 110)
    hSub.TextSize = 12
    hSub.TextXAlignment = Enum.TextXAlignment.Left

    local closeBtn = Instance.new("TextButton", header)
    closeBtn.Size = UDim2.fromOffset(32, 32)
    closeBtn.Position = UDim2.new(1, -44, 0, 16)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 90, 95)
    closeBtn.BackgroundTransparency = 0.20
    closeBtn.BorderSizePixel = 0
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Text = "x"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 16
    closeBtn.AutoButtonColor = false
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 12)

    closeBtn.MouseButton1Click:Connect(function()
        UI.CloseTween(panel, function() gui:Destroy() end)
    end)

    -- Tab bar
    local tabs = (auth.ui and auth.ui.tabs) or {"Profile", "Games", "Info"}
    local tabBar = Instance.new("Frame", panel)
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, -40, 0, 36)
    tabBar.Position = UDim2.fromOffset(20, 72)
    tabBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    tabBar.BackgroundTransparency = 0.45
    tabBar.BorderSizePixel = 0
    Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 14)

    local tabList = Instance.new("UIListLayout", tabBar)
    tabList.FillDirection = Enum.FillDirection.Horizontal
    tabList.Padding = UDim.new(0, 4)
    tabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    tabList.VerticalAlignment = Enum.VerticalAlignment.Center
    tabList.SortOrder = Enum.SortOrder.LayoutOrder

    local UIPadding = Instance.new("UIPadding", tabBar)
    UIPadding.PaddingTop = UDim.new(0, 4); UIPadding.PaddingBottom = UDim.new(0, 4)
    UIPadding.PaddingLeft = UDim.new(0, 4); UIPadding.PaddingRight = UDim.new(0, 4)

    -- Content area
    local content = Instance.new("Frame", panel)
    content.Name = "Content"
    content.Size = UDim2.new(1, -40, 1, -130)
    content.Position = UDim2.fromOffset(20, 116)
    content.BackgroundTransparency = 1
    content.ClipsDescendants = true

    -- Tab content frames
    local tabFrames = {}
    for _, name in ipairs(tabs) do
        local f = Instance.new("Frame", content)
        f.Name = "Tab_" .. name
        f.Size = UDim2.new(1, 0, 1, 0)
        f.BackgroundTransparency = 1
        f.Visible = false
        tabFrames[name] = f
    end

    -- Tab buttons (highlight pill on selected)
    local activeTab = nil
    local function showTab(name)
        for k, f in pairs(tabFrames) do f.Visible = (k == name) end
        for _, child in ipairs(tabBar:GetChildren()) do
            if child:IsA("TextButton") then
                local sel = (child.Name == "TabBtn_" .. name)
                child.BackgroundTransparency = sel and 0.15 or 0.55
                child.TextColor3 = sel and Color3.fromRGB(20, 20, 30) or Color3.fromRGB(110, 110, 130)
            end
        end
        activeTab = name
    end

    for i, name in ipairs(tabs) do
        local btn = Instance.new("TextButton", tabBar)
        btn.Name = "TabBtn_" .. name
        btn.LayoutOrder = i
        btn.Size = UDim2.new(1 / #tabs, -8, 1, 0)
        btn.BackgroundColor3 = (name == (auth.ui and auth.ui.default_tab)) and Color3.fromRGB(255, 105, 180) or Color3.fromRGB(255, 255, 255)
        btn.BackgroundTransparency = 0.55
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.GothamMedium
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(110, 110, 130)
        btn.TextSize = 13
        btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)
        btn.MouseButton1Click:Connect(function() showTab(name) end)
    end

    -- Build each tab's content
    Profile.Build(tabFrames["Profile"], UI, {auth = auth, httpGet = httpGet})
    GamesTab.Build(tabFrames["Games"], UI, {auth = auth, httpGet = httpGet, notify = notify})
    InfoTab.Build(tabFrames["Info"], UI, {auth = auth, httpGet = httpGet, copyToClipboard = copyToClipboard})

    showTab((auth.ui and auth.ui.default_tab) or tabs[1])

    -- Drag
    UI.MakeDraggable(panel, header)

    -- Open animation
    panel.Size = UDim2.fromOffset(0, 0)
    panel.BackgroundTransparency = 1
    game:GetService("TweenService"):Create(panel, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(PANEL_W, PANEL_H),
        BackgroundTransparency = 0.10,
    }):Play()

    notify("Welcome to " .. ((auth.ui and auth.ui.hub_title) or "Mikudes Super Hub"), "success")
end

-- If discord not required, kick off the chain directly
if not (auth.discord and auth.discord.required) then
    runKeyCheck()
end
