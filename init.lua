-- Mikudes Super Hub | loader entry point (jnkie SDK + Apple Liquid Glass)
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

local function httpGetJson(url)
    local body = httpGet(url)
    if not body then return nil end
    local ok, t = pcall(HttpService.JSONDecode, HttpService, body)
    return ok and t or nil
end

local function copyToClipboard(text)
    pcall(setclipboard, text)
end

-- ============================================================
-- Fetch auth.json (UI + Discord config)
-- ============================================================
local auth = httpGetJson(REPO .. "/auth.json") or {}
auth.discord = auth.discord or { required = false }
auth.ui      = auth.ui or {}
auth.changelog = auth.changelog or {}

local pg = player:WaitForChild("PlayerGui")
local prev = pg:FindFirstChild("MikudesHub")
if prev then prev:Destroy() end
prev = pg:FindFirstChild("MikuGate")
if prev then prev:Destroy() end
prev = pg:FindFirstChild("MikuKey")
if prev then prev:Destroy() end
prev = pg:FindFirstChild("MikuToast")
if prev then prev:Destroy() end

-- ============================================================
-- Notifications
-- ============================================================
local function notify(text, kind, duration)
    kind = kind or "info"
    duration = duration or 3
    local color = Color3.fromRGB(255, 105, 180)
    if kind == "success" then color = Color3.fromRGB(80, 200, 120)
    elseif kind == "warn" then color = Color3.fromRGB(255, 180, 60)
    elseif kind == "error" then color = Color3.fromRGB(255, 90, 95) end

    local existing = pg:FindFirstChild("MikuToast")
    if not existing then
        existing = Instance.new("ScreenGui")
        existing.Name = "MikuToast"
        existing.IgnoreGuiInset = true
        existing.DisplayOrder = 10000
        existing.ResetOnSpawn = false
        existing.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        existing.Parent = pg
    end

    local toast = Instance.new("Frame")
    toast.Size = UDim2.fromOffset(280, 0)
    toast.AutomaticSize = Enum.AutomaticSize.Y
    toast.Position = UDim2.new(0.5, 0, 0, 24)
    toast.AnchorPoint = Vector2.new(0.5, 0)
    toast.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    toast.BackgroundTransparency = 0.10
    toast.BorderSizePixel = 0
    toast.Parent = existing
    Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 14)
    local g = Instance.new("UIGradient", toast)
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 235, 255)),
    })
    g.Rotation = 90
    local s = Instance.new("UIStroke", toast)
    s.Color = Color3.fromRGB(255, 255, 255); s.Transparency = 0.40; s.Thickness = 1

    local lbl = Instance.new("TextLabel", toast)
    lbl.Size = UDim2.new(1, -28, 1, 0)
    lbl.Position = UDim2.fromOffset(14, 0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamMedium
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(20, 20, 30)
    lbl.TextSize = 14
    lbl.TextWrapped = true
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.AutomaticSize = Enum.AutomaticSize.Y

    local pad = Instance.new("UIPadding", toast)
    pad.PaddingTop = UDim.new(0, 10); pad.PaddingBottom = UDim.new(0, 10)

    toast.BackgroundTransparency = 1
    game:GetService("TweenService"):Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.10,
    }):Play()

    task.delay(duration, function()
        local out = game:GetService("TweenService"):Create(toast, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.fromOffset(280, 0),
            BackgroundTransparency = 1,
        })
        out:Play(); out.Completed:Wait(); toast:Destroy()
    end)
end

-- ============================================================
-- Load UI primitives + EdgeFx
-- ============================================================
local UI = loadstring(httpGet(REPO .. "/ui/init.lua"))()
local EdgeFx = loadstring(httpGet(REPO .. "/ui/EdgeFx.lua"))()

-- ============================================================
-- jnkie SDK setup
-- ============================================================
local Junkie = loadstring(game:HttpGet("https://jnkie.com/sdk/library.lua"))()
Junkie.service    = (auth.jnkie and auth.jnkie.service)    or "mikudes super hub"
Junkie.identifier = (auth.jnkie and auth.jnkie.identifier) or "1158343"
Junkie.provider   = (auth.jnkie and auth.jnkie.provider)   or "Mikudes Super Hub"

-- Cached key persistence
local KEY_FILE = "mikudes_verified_key.txt"
local function hasFileSystem()
    return pcall(function() return type(writefile) == "function" end)
       and pcall(function() return type(readfile) == "function" end)
       and pcall(function() return type(isfile) == "function" end)
end
local FS_OK = hasFileSystem()

local function loadCachedKey()
    if not FS_OK then return nil end
    local ok, content = pcall(readfile, KEY_FILE)
    return (ok and content and content ~= "" and content) or nil
end

local function saveCachedKey(key)
    if not FS_OK then return end
    pcall(writefile, KEY_FILE, key)
end

local function clearCachedKey()
    if not FS_OK then return end
    pcall(delfile, KEY_FILE)
end

-- ============================================================
-- Discord gate (lightweight — opens invite, sets a flag)
-- ============================================================
local discordDone = not (auth.discord.required)

local function showDiscordGate(onDone)
    local gui = Instance.new("ScreenGui")
    gui.Name = "MikuGate"
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 9999
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = pg

    local dim = Instance.new("Frame", gui)
    dim.Size = UDim2.new(1, 0, 1, 0)
    dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    dim.BackgroundTransparency = 0.30
    dim.BorderSizePixel = 0

    local card = Instance.new("Frame", gui)
    card.Size = UDim2.fromOffset(420, 320)
    card.Position = UDim2.fromScale(0.5, 0.5)
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    card.BackgroundTransparency = 0.10
    card.BorderSizePixel = 0
    card.ClipsDescendants = false
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 28)
    local cg = Instance.new("UIGradient", card)
    cg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(220, 235, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 230, 245)),
    })
    cg.Rotation = 135
    cg.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.55),
        NumberSequenceKeypoint.new(0.5, 0.30),
        NumberSequenceKeypoint.new(1, 0.55),
    })
    Instance.new("UIStroke", card).Transparency = 0.35

    -- Apply liquid glass edges on the gate card
    local cardEdges = EdgeFx.ApplyEdges(card, {
        cornerRadius   = 28,
        rim            = true,
        specular       = true,
        outerGlow      = true,
        innerShadow    = true,
        streak         = true,
        particles      = false,
        specularOffset = UDim2.fromOffset(20, 18),
        specularSize   = UDim2.fromOffset(180, 90),
    })

    -- Header
    local h = Instance.new("TextLabel", card)
    h.Size = UDim2.new(1, -40, 0, 30)
    h.Position = UDim2.fromOffset(20, 22)
    h.BackgroundTransparency = 1
    h.Font = Enum.Font.GothamBold
    h.Text = auth.discord.server_name or "Discord Required"
    h.TextColor3 = Color3.fromRGB(20, 20, 30)
    h.TextSize = 22
    h.TextXAlignment = Enum.TextXAlignment.Left

    local sub = Instance.new("TextLabel", card)
    sub.Size = UDim2.new(1, -40, 0, 50)
    sub.Position = UDim2.fromOffset(20, 60)
    sub.BackgroundTransparency = 1
    sub.Font = Enum.Font.Gotham
    sub.Text = auth.discord.check_message or "Join our Discord before using the hub."
    sub.TextColor3 = Color3.fromRGB(80, 80, 100)
    sub.TextSize = 14
    sub.TextWrapped = true
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.TextYAlignment = Enum.TextYAlignment.Top

    -- Discord icon (white-on-blurple circle)
    local iconFrame = Instance.new("Frame", card)
    iconFrame.Size = UDim2.fromOffset(64, 64)
    iconFrame.Position = UDim2.new(0.5, 0, 0, 110)
    iconFrame.AnchorPoint = Vector2.new(0.5, 0)
    iconFrame.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    iconFrame.BorderSizePixel = 0
    Instance.new("UICorner", iconFrame).CornerRadius = UDim.new(1, 0)

    local iconLabel = Instance.new("TextLabel", iconFrame)
    iconLabel.Size = UDim2.new(1, 0, 1, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.Text = "D"
    iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconLabel.TextSize = 36

    -- Join + Continue buttons (stacked)
    local joinBtn = Instance.new("TextButton", card)
    joinBtn.Size = UDim2.new(1, -40, 0, 48)
    joinBtn.Position = UDim2.fromOffset(20, 198)
    joinBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    joinBtn.BackgroundTransparency = 0.05
    joinBtn.BorderSizePixel = 0
    joinBtn.Font = Enum.Font.GothamBold
    joinBtn.Text = "  Copy Discord invite"
    joinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    joinBtn.TextSize = 15
    joinBtn.AutoButtonColor = false
    Instance.new("UICorner", joinBtn).CornerRadius = UDim.new(0, 16)
    local js = Instance.new("UIStroke", joinBtn)
    js.Color = Color3.fromRGB(255, 255, 255); js.Transparency = 0.30

    -- Apply edge fx on join button (rim only — subtle)
    EdgeFx.ApplyEdges(joinBtn, {
        cornerRadius = 16,
        rim = true, specular = false, outerGlow = false,
        innerShadow = false, streak = true, particles = false,
        rimHeight = 0.7,
    })

    joinBtn.MouseButton1Click:Connect(function()
        copyToClipboard(auth.discord.invite_url or "")
        notify("Discord invite copied to clipboard", "success")
    end)

    local continueBtn = Instance.new("TextButton", card)
    continueBtn.Size = UDim2.new(1, -40, 0, 48)
    continueBtn.Position = UDim2.fromOffset(20, 256)
    continueBtn.BackgroundColor3 = Color3.fromRGB(255, 105, 180)
    continueBtn.BackgroundTransparency = 0.05
    continueBtn.BorderSizePixel = 0
    continueBtn.Font = Enum.Font.GothamBold
    continueBtn.Text = "I joined — continue"
    continueBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    continueBtn.TextSize = 15
    continueBtn.AutoButtonColor = false
    Instance.new("UICorner", continueBtn).CornerRadius = UDim.new(0, 16)
    local cs = Instance.new("UIStroke", continueBtn)
    cs.Color = Color3.fromRGB(255, 255, 255); cs.Transparency = 0.30

    EdgeFx.ApplyEdges(continueBtn, {
        cornerRadius = 16,
        rim = true, specular = false, outerGlow = false,
        innerShadow = false, streak = true, particles = false,
        rimHeight = 0.7,
    })

    local function close()
        if cardEdges then EdgeFx.RemoveEdges(card) end
        gui:Destroy()
        onDone()
    end

    continueBtn.MouseButton1Click:Connect(close)

    -- Sweep the streak on gate open
    task.delay(0.4, function() if cardEdges then EdgeFx.SweepStreak(cardEdges) end end)
end

-- ============================================================
-- Key gate (always-shows-input pattern)
-- - TextBox + Get Link button + Verify button — all visible at once
-- - If a cached key exists, auto-verify on entry
-- ============================================================
local function showKeyGate(onSuccess)
    local gui = Instance.new("ScreenGui")
    gui.Name = "MikuKey"
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 9999
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = pg

    local dim = Instance.new("Frame", gui)
    dim.Size = UDim2.new(1, 0, 1, 0)
    dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    dim.BackgroundTransparency = 0.30
    dim.BorderSizePixel = 0

    local card = Instance.new("Frame", gui)
    card.Size = UDim2.fromOffset(420, 360)
    card.Position = UDim2.fromScale(0.5, 0.5)
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    card.BackgroundTransparency = 0.10
    card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 28)
    local cg = Instance.new("UIGradient", card)
    cg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(220, 235, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 230, 245)),
    })
    cg.Rotation = 135
    cg.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.55),
        NumberSequenceKeypoint.new(0.5, 0.30),
        NumberSequenceKeypoint.new(1, 0.55),
    })
    Instance.new("UIStroke", card).Transparency = 0.35

    -- Edges
    local cardEdges = EdgeFx.ApplyEdges(card, {
        cornerRadius = 28,
        rim = true, specular = true, outerGlow = true,
        innerShadow = true, streak = true, particles = false,
        specularOffset = UDim2.fromOffset(20, 18),
        specularSize = UDim2.fromOffset(180, 90),
    })

    -- Header
    local h = Instance.new("TextLabel", card)
    h.Size = UDim2.new(1, -40, 0, 28)
    h.Position = UDim2.fromOffset(20, 22)
    h.BackgroundTransparency = 1
    h.Font = Enum.Font.GothamBold
    h.Text = "Enter your key"
    h.TextColor3 = Color3.fromRGB(20, 20, 30)
    h.TextSize = 20
    h.TextXAlignment = Enum.TextXAlignment.Left

    local sub = Instance.new("TextLabel", card)
    sub.Size = UDim2.new(1, -40, 0, 36)
    sub.Position = UDim2.fromOffset(20, 56)
    sub.BackgroundTransparency = 1
    sub.Font = Enum.Font.Gotham
    sub.Text = "Paste the key you got from the link below, or load your saved one."
    sub.TextColor3 = Color3.fromRGB(80, 80, 100)
    sub.TextSize = 13
    sub.TextWrapped = true
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.TextYAlignment = Enum.TextYAlignment.Top

    -- Get link button (top — full width)
    local getLinkBtn = Instance.new("TextButton", card)
    getLinkBtn.Name = "GetLink"
    getLinkBtn.Size = UDim2.new(1, -40, 0, 42)
    getLinkBtn.Position = UDim2.fromOffset(20, 100)
    getLinkBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    getLinkBtn.BackgroundTransparency = 0.05
    getLinkBtn.BorderSizePixel = 0
    getLinkBtn.Font = Enum.Font.GothamBold
    getLinkBtn.Text = "  Get key — copy link"
    getLinkBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    getLinkBtn.TextSize = 14
    getLinkBtn.AutoButtonColor = false
    Instance.new("UICorner", getLinkBtn).CornerRadius = UDim.new(0, 14)
    local gls = Instance.new("UIStroke", getLinkBtn)
    gls.Color = Color3.fromRGB(255, 255, 255); gls.Transparency = 0.30

    EdgeFx.ApplyEdges(getLinkBtn, {
        cornerRadius = 14, rim = true, specular = false, outerGlow = false,
        innerShadow = false, streak = true, particles = false, rimHeight = 0.7,
    })

    -- Key input field (always visible — no "I have a key" click required)
    local boxHolder = Instance.new("Frame", card)
    boxHolder.Size = UDim2.new(1, -40, 0, 46)
    boxHolder.Position = UDim2.fromOffset(20, 154)
    boxHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    boxHolder.BackgroundTransparency = 0.20
    boxHolder.BorderSizePixel = 0
    Instance.new("UICorner", boxHolder).CornerRadius = UDim.new(0, 14)
    local boxStroke = Instance.new("UIStroke", boxHolder)
    boxStroke.Color = Color3.fromRGB(255, 255, 255); boxStroke.Transparency = 0.55; boxStroke.Thickness = 1

    local box = Instance.new("TextBox", boxHolder)
    box.Name = "KeyInput"
    box.Size = UDim2.new(1, -16, 1, 0)
    box.Position = UDim2.fromOffset(14, 0)
    box.BackgroundTransparency = 1
    box.Font = Enum.Font.GothamMedium
    box.PlaceholderText = "MikuHub-XXXX-XXXX"
    box.PlaceholderColor3 = Color3.fromRGB(140, 140, 160)
    box.Text = loadCachedKey() or ""
    box.TextColor3 = Color3.fromRGB(20, 20, 30)
    box.TextSize = 14
    box.ClearTextOnFocus = false
    box.TextXAlignment = Enum.TextXAlignment.Left

    -- Focus animation (input stroke glow on focus)
    box.Focused:Connect(function()
        game:GetService("TweenService"):Create(boxStroke, TweenInfo.new(0.18), {
            Color = Color3.fromRGB(255, 105, 180),
            Thickness = 2,
            Transparency = 0,
        }):Play()
    end)
    box.FocusLost:Connect(function()
        game:GetService("TweenService"):Create(boxStroke, TweenInfo.new(0.18), {
            Color = Color3.fromRGB(255, 255, 255),
            Thickness = 1,
            Transparency = 0.55,
        }):Play()
    end)

    -- Verify button (full width, below input)
    local verifyBtn = Instance.new("TextButton", card)
    verifyBtn.Name = "Verify"
    verifyBtn.Size = UDim2.new(1, -40, 0, 48)
    verifyBtn.Position = UDim2.fromOffset(20, 214)
    verifyBtn.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
    verifyBtn.BackgroundTransparency = 0.05
    verifyBtn.BorderSizePixel = 0
    verifyBtn.Font = Enum.Font.GothamBold
    verifyBtn.Text = "Verify key"
    verifyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    verifyBtn.TextSize = 15
    verifyBtn.AutoButtonColor = false
    Instance.new("UICorner", verifyBtn).CornerRadius = UDim.new(0, 16)
    local vs = Instance.new("UIStroke", verifyBtn)
    vs.Color = Color3.fromRGB(255, 255, 255); vs.Transparency = 0.30

    EdgeFx.ApplyEdges(verifyBtn, {
        cornerRadius = 16, rim = true, specular = false, outerGlow = false,
        innerShadow = false, streak = true, particles = false, rimHeight = 0.7,
    })

    -- Status line (errors + status)
    local statusLbl = Instance.new("TextLabel", card)
    statusLbl.Size = UDim2.new(1, -40, 0, 18)
    statusLbl.Position = UDim2.fromOffset(20, 272)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.Text = ""
    statusLbl.TextColor3 = Color3.fromRGB(255, 90, 95)
    statusLbl.TextSize = 13
    statusLbl.TextXAlignment = Enum.TextXAlignment.Left
    statusLbl.TextWrapped = true

    -- Skip-link (small text below)
    local skipLbl = Instance.new("TextLabel", card)
    skipLbl.Size = UDim2.new(1, -40, 0, 14)
    skipLbl.Position = UDim2.fromOffset(20, 296)
    skipLbl.BackgroundTransparency = 1
    skipLbl.Font = Enum.Font.Gotham
    skipLbl.Text = "Don't have a key? Click \"Get key\" above to get one."
    skipLbl.TextColor3 = Color3.fromRGB(140, 140, 160)
    skipLbl.TextSize = 11
    skipLbl.TextXAlignment = Enum.TextXAlignment.Left

    -- Footer (made by)
    local foot = Instance.new("TextLabel", card)
    foot.Size = UDim2.new(1, -40, 0, 16)
    foot.Position = UDim2.fromOffset(20, 326)
    foot.BackgroundTransparency = 1
    foot.Font = Enum.Font.Gotham
    foot.Text = "Powered by jnkie · Mikudes Hub v" .. tostring(auth.version or "1.0.0")
    foot.TextColor3 = Color3.fromRGB(160, 160, 180)
    foot.TextSize = 10
    foot.TextXAlignment = Enum.TextXAlignment.Left

    -- ============== LOGIC ==============
    local function setLoading(isLoading)
        boxHolder.Active = not isLoading
        verifyBtn.Text = isLoading and "Verifying..." or "Verify key"
        getLinkBtn.Active = not isLoading
    end

    local function showError(msg)
        statusLbl.TextColor3 = Color3.fromRGB(255, 90, 95)
        statusLbl.Text = msg
        -- shake the input
        local orig = boxHolder.Position
        for _ = 1, 3 do
            game:GetService("TweenService"):Create(boxHolder, TweenInfo.new(0.05), {
                Position = UDim2.new(orig.X.Scale, orig.X.Offset - 8, orig.Y.Scale, orig.Y.Offset),
            }):Play(); task.wait(0.05)
            game:GetService("TweenService"):Create(boxHolder, TweenInfo.new(0.05), {
                Position = UDim2.new(orig.X.Scale, orig.X.Offset + 8, orig.Y.Scale, orig.Y.Offset),
            }):Play(); task.wait(0.05)
        end
        boxHolder.Position = orig
    end

    local function showSuccess(msg)
        statusLbl.TextColor3 = Color3.fromRGB(80, 200, 120)
        statusLbl.Text = msg
    end

    local function tryVerify()
        local key = box.Text:gsub("%s+", "")
        if key == "" then
            showError("Please paste a key first.")
            return
        end

        setLoading(true)
        statusLbl.Text = ""
        local result = Junkie.check_key(key)
        setLoading(false)

        if result and result.valid then
            saveCachedKey(key)
            showSuccess("Verified! Opening hub...")
            task.wait(0.6)
            if cardEdges then EdgeFx.RemoveEdges(card) end
            gui:Destroy()
            onSuccess(key, result)
        else
            clearCachedKey()
            showError("Invalid or expired key. Get a fresh one via the link above.")
        end
    end

    getLinkBtn.MouseButton1Click:Connect(function()
        local link = Junkie.get_key_link()
        if link then
            copyToClipboard(link)
            notify("Key link copied! Open it in your browser.", "success")
            box:CaptureFocus()
        else
            notify("Could not get key link.", "error")
        end
    end)

    verifyBtn.MouseButton1Click:Connect(tryVerify)
    box.FocusLost:Connect(function(enterPressed) if enterPressed then tryVerify() end end)

    -- Streak on open
    task.delay(0.4, function() if cardEdges then EdgeFx.SweepStreak(cardEdges) end end)

    -- If we loaded a cached key, auto-verify
    if box.Text and box.Text ~= "" then
        task.delay(0.5, tryVerify)
    end
end

-- ============================================================
-- Hub shell (only reached when both gates pass)
-- ============================================================
local function runHub(key)
    local Profile  = loadstring(httpGet(REPO .. "/ui/Profile.lua"))()
    local GamesTab = loadstring(httpGet(REPO .. "/ui/Games.lua"))()
    local InfoTab  = loadstring(httpGet(REPO .. "/ui/Info.lua"))()

    local gui = Instance.new("ScreenGui")
    gui.Name = "MikudesHub"
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = pg

    local PANEL_W = (auth.ui.panel_size and auth.ui.panel_size[1]) or 460
    local PANEL_H = (auth.ui.panel_size and auth.ui.panel_size[2]) or 520

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.Size = UDim2.fromOffset(PANEL_W, PANEL_H)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    panel.BackgroundTransparency = 0.10
    panel.BorderSizePixel = 0
    panel.ClipsDescendants = false
    panel.Parent = gui
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 28)

    -- Big glass gradient on the panel
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

    -- Apply full Apple-style edge effects on the panel
    local panelEdges = EdgeFx.ApplyEdges(panel, {
        cornerRadius   = 28,
        rim            = true,
        specular       = true,
        outerGlow      = true,
        innerShadow    = true,
        streak         = true,
        particles      = false,  -- ambient particles off (heavy); flip to true for floating dots
        specularOffset = UDim2.fromOffset(40, 30),
        specularSize   = UDim2.fromOffset(220, 110),
    })

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
    hTitle.Text = auth.ui.hub_title or "Mikudes Super Hub"
    hTitle.TextColor3 = Color3.fromRGB(20, 20, 30)
    hTitle.TextSize = 20
    hTitle.TextXAlignment = Enum.TextXAlignment.Left

    local hSub = Instance.new("TextLabel", header)
    hSub.Size = UDim2.new(1, -120, 0, 16)
    hSub.Position = UDim2.fromOffset(20, 40)
    hSub.BackgroundTransparency = 1
    hSub.Font = Enum.Font.Gotham
    hSub.Text = (auth.ui.hub_subtitle or "Apple Liquid Glass") .. " · v" .. tostring(auth.version or "1.0.0")
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
        EdgeFx.RemoveEdges(panel)
        UI.CloseTween(panel, function() gui:Destroy() end)
    end)

    -- Tab bar
    local tabs = auth.ui.tabs or {"Profile", "Games", "Info"}
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

    local tabPad = Instance.new("UIPadding", tabBar)
    tabPad.PaddingTop = UDim.new(0, 4); tabPad.PaddingBottom = UDim.new(0, 4)
    tabPad.PaddingLeft = UDim.new(0, 4); tabPad.PaddingRight = UDim.new(0, 4)

    -- Content area
    local content = Instance.new("Frame", panel)
    content.Name = "Content"
    content.Size = UDim2.new(1, -40, 1, -130)
    content.Position = UDim2.fromOffset(20, 116)
    content.BackgroundTransparency = 1
    content.ClipsDescendants = true

    local tabFrames = {}
    for _, name in ipairs(tabs) do
        local f = Instance.new("Frame", content)
        f.Name = "Tab_" .. name
        f.Size = UDim2.new(1, 0, 1, 0)
        f.BackgroundTransparency = 1
        f.Visible = false
        tabFrames[name] = f
    end

    local function showTab(name)
        for k, f in pairs(tabFrames) do f.Visible = (k == name) end
        for _, child in ipairs(tabBar:GetChildren()) do
            if child:IsA("TextButton") then
                local sel = (child.Name == "TabBtn_" .. name)
                child.BackgroundTransparency = sel and 0.15 or 0.55
                child.TextColor3 = sel and Color3.fromRGB(20, 20, 30) or Color3.fromRGB(110, 110, 130)
            end
        end
    end

    for i, name in ipairs(tabs) do
        local btn = Instance.new("TextButton", tabBar)
        btn.Name = "TabBtn_" .. name
        btn.LayoutOrder = i
        btn.Size = UDim2.new(1 / #tabs, -8, 1, 0)
        btn.BackgroundColor3 = (name == (auth.ui.default_tab or tabs[1])) and Color3.fromRGB(255, 105, 180) or Color3.fromRGB(255, 255, 255)
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
    Profile.Build(tabFrames["Profile"], UI, {auth = auth, httpGet = httpGet, copyToClipboard = copyToClipboard})
    GamesTab.Build(tabFrames["Games"], UI, {auth = auth, httpGet = httpGet, notify = notify})
    InfoTab.Build(tabFrames["Info"], UI, {auth = auth, httpGet = httpGet, copyToClipboard = copyToClipboard})

    showTab(auth.ui.default_tab or tabs[1])

    -- Drag
    UI.MakeDraggable(panel, header)

    -- Open animation (scale-in)
    panel.Size = UDim2.fromOffset(0, 0)
    panel.BackgroundTransparency = 1
    game:GetService("TweenService"):Create(panel, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.fromOffset(PANEL_W, PANEL_H),
        BackgroundTransparency = 0.10,
    }):Play()

    -- Sweep the streak once panel opens
    task.delay(0.7, function() if panelEdges then EdgeFx.SweepStreak(panelEdges) end end)

    notify("Welcome to " .. (auth.ui.hub_title or "Mikudes Super Hub"), "success")
end

-- ============================================================
-- Bootstrap flow
-- ============================================================
local function afterDiscord()
    showKeyGate(function(key, result)
        runHub(key)
    end)
end

if auth.discord.required then
    showDiscordGate(afterDiscord)
else
    afterDiscord()
end
