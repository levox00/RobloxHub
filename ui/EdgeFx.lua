-- ui/EdgeFx.lua | Apple Liquid Glass edge effects
-- Layered edge system: outer glow, top rim, specular hotspot,
-- bottom inner shadow, optional diagonal streak + ambient particles.
--
-- Public API:
--   UI.ApplyEdges(frame, opts)  -> { glow, rim, specular, innerShadow, streak, particles }
--   UI.SweepStreak(edgeBag)     -> play the diagonal light sweep once
--   UI.StartParticles(edgeBag)  -> spawn ambient floating dots

local TweenService = game:GetService("TweenService")

local EdgeFx = {}

local DEFAULTS = {
    cornerRadius   = 24,
    rim            = true,    -- top rim highlight (the white edge that makes glass look glassy)
    specular       = true,    -- bright hotspot on top-left edge
    outerGlow      = true,    -- soft outer rim glow
    innerShadow    = true,    -- dark gradient on bottom edge (depth)
    streak         = true,    -- diagonal light sweep (off until SweepStreak is called)
    particles      = false,   -- ambient floating dots (off by default — heavy)
    rimHeight      = 0.45,    -- how tall the rim is
    specularOffset = UDim2.fromOffset(-12, -12),
    specularSize   = UDim2.fromOffset(160, 80),
    accent         = Color3.fromRGB(255, 255, 255),
}

function EdgeFx.ApplyEdges(parent, opts)
    opts = opts or {}
    for k, v in pairs(DEFAULTS) do opts[k] = opts[k] or v end
    local radius = opts.cornerRadius

    local bag = {}

    -- 1. OUTER GLOW — a slightly larger frame behind with white blur effect
    if opts.outerGlow then
        local glow = Instance.new("Frame")
        glow.Name = "EdgeOuterGlow"
        glow.Size = UDim2.new(1, 8, 1, 8)
        glow.Position = UDim2.fromOffset(-4, -4)
        glow.BackgroundColor3 = opts.accent
        glow.BackgroundTransparency = 0.85
        glow.BorderSizePixel = 0
        glow.ZIndex = (parent.ZIndex or 0) - 1
        glow.Parent = parent
        Instance.new("UICorner", glow).CornerRadius = UDim.new(0, radius + 4)
        bag.glow = glow
    end

    -- 2. RIM HIGHLIGHT — white gradient at top, fading down (the apple signature edge)
    if opts.rim then
        local rim = Instance.new("Frame")
        rim.Name = "EdgeRim"
        rim.Size = UDim2.new(1, 0, opts.rimHeight, 0)
        rim.Position = UDim2.fromOffset(0, 0)
        rim.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        rim.BackgroundTransparency = 0.80
        rim.BorderSizePixel = 0
        rim.ZIndex = (parent.ZIndex or 0) + 1
        rim.Parent = parent
        local rc = Instance.new("UICorner", rim)
        rc.CornerRadius = UDim.new(0, radius)

        local rg = Instance.new("UIGradient", rim)
        rg.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0.00, 0.00),
            NumberSequenceKeypoint.new(0.45, 0.45),
            NumberSequenceKeypoint.new(1.00, 1.00),
        })
        rg.Rotation = 90
        bag.rim = rim
    end

    -- 3. SPECULAR HOTSPOT — bright oval on top-left edge (the wet-glass shine)
    if opts.specular then
        local spec = Instance.new("Frame")
        spec.Name = "EdgeSpecular"
        spec.Size = opts.specularSize
        spec.Position = opts.specularOffset
        spec.AnchorPoint = Vector2.new(0, 0)
        spec.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        spec.BackgroundTransparency = 0.75
        spec.BorderSizePixel = 0
        spec.ZIndex = (parent.ZIndex or 0) + 2
        spec.Parent = parent
        Instance.new("UICorner", spec).CornerRadius = UDim.new(1, 0)

        local sg = Instance.new("UIGradient", spec)
        sg.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0.0, 0.0),
            NumberSequenceKeypoint.new(0.5, 0.5),
            NumberSequenceKeypoint.new(1.0, 1.0),
        })
        sg.Rotation = 35
        bag.specular = spec
    end

    -- 4. INNER SHADOW — dark gradient on bottom edge (depth)
    if opts.innerShadow then
        local sh = Instance.new("Frame")
        sh.Name = "EdgeInnerShadow"
        sh.Size = UDim2.new(1, 0, 0.30, 0)
        sh.Position = UDim2.new(0, 0, 1, 0)
        sh.AnchorPoint = Vector2.new(0, 1)
        sh.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        sh.BackgroundTransparency = 0.85
        sh.BorderSizePixel = 0
        sh.ZIndex = (parent.ZIndex or 0) + 1
        sh.Parent = parent
        local sc = Instance.new("UICorner", sh)
        sc.CornerRadius = UDim.new(0, radius)

        local sg = Instance.new("UIGradient", sh)
        sg.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0.0, 1.0),
            NumberSequenceKeypoint.new(0.5, 0.7),
            NumberSequenceKeypoint.new(1.0, 0.0),
        })
        sg.Rotation = 90
        bag.innerShadow = sh
    end

    -- 5. DIAGONAL LIGHT STREAK — off until triggered
    if opts.streak then
        local streak = Instance.new("Frame")
        streak.Name = "EdgeStreak"
        streak.Size = UDim2.new(1.4, 0, 0.10, 0)
        streak.Position = UDim2.new(-0.2, 0, 0.5, 0)
        streak.AnchorPoint = Vector2.new(0, 0.5)
        streak.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        streak.BackgroundTransparency = 1
        streak.BorderSizePixel = 0
        streak.Rotation = -22
        streak.ZIndex = (parent.ZIndex or 0) + 3
        streak.Parent = parent

        local sg = Instance.new("UIGradient", streak)
        sg.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0.0, 1.0),
            NumberSequenceKeypoint.new(0.4, 0.3),
            NumberSequenceKeypoint.new(0.5, 0.0),
            NumberSequenceKeypoint.new(0.6, 0.3),
            NumberSequenceKeypoint.new(1.0, 1.0),
        })
        bag.streak = streak
    end

    -- 6. AMBIENT PARTICLES (off by default — toggle via opts.particles = true)
    if opts.particles then
        EdgeFx.StartParticles(bag, parent)
    end

    -- Store cleanup + reference back
    bag.parent = parent
    parent._edgeBag = bag

    return bag
end

-- Play a one-shot diagonal light sweep across the surface
function EdgeFx.SweepStreak(bag)
    if not bag or not bag.streak then return end
    local streak = bag.streak
    streak.BackgroundTransparency = 0.55
    streak.Position = UDim2.new(-0.4, 0, 0.5, 0)
    TweenService:Create(streak, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(1.0, 0, 0.5, 0),
        BackgroundTransparency = 1,
    }):Play()
end

-- Spawn ambient floating dots inside the parent
function EdgeFx.StartParticles(bag, parent)
    if not parent or not parent.Parent then return end
    local bag = bag or {}
    bag._particleTask = task.spawn(function()
        while parent and parent.Parent do
            local p = Instance.new("Frame")
            p.Name = "EdgeParticle"
            local sz = math.random(2, 4)
            p.Size = UDim2.fromOffset(sz, sz)
            p.Position = UDim2.new(math.random() * 0.9 + 0.05, 0, 1, 0)
            p.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            p.BackgroundTransparency = 0.55
            p.BorderSizePixel = 0
            p.ZIndex = (parent.ZIndex or 0) + 4
            p.Parent = parent
            Instance.new("UICorner", p).CornerRadius = UDim.new(1, 0)

            local drift = (math.random() - 0.5) * 60
            TweenService:Create(p, TweenInfo.new(math.random(8, 14), Enum.EasingStyle.Linear), {
                Position = UDim2.new(p.Position.X.Scale, drift, -0.05, 0),
                BackgroundTransparency = 1,
            }):Play()
            task.delay(math.random(8, 14), function() p:Destroy() end)
            task.wait(math.random(3, 6))
        end
    end)
end

-- Remove all edges from a frame
function EdgeFx.RemoveEdges(parent)
    local bag = parent and parent._edgeBag
    if not bag then return end
    for _, name in ipairs({"glow", "rim", "specular", "innerShadow", "streak"}) do
        local f = bag[name]
        if f then pcall(function() f:Destroy() end) end
    end
    parent._edgeBag = nil
end

return EdgeFx
