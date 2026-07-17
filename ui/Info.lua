-- ui/Info.lua | Info tab: changelog + Discord link + credits
local M = {}

function M.Build(parent, UI, ctx)
    local list = Instance.new("UIListLayout", parent)
    list.Padding = UDim.new(0, 10)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center

    -- Changelog card
    local changelogCard = UI.GlassCard(parent, {Size = UDim2.new(1, 0, 0, 180), Name = "Changelog"})
    changelogCard.LayoutOrder = 1

    UI.Section(changelogCard.Pad, "CHANGELOG", 0)

    local scroll = Instance.new("ScrollingFrame", changelogCard.Pad)
    scroll.Size = UDim2.new(1, 0, 1, -22)
    scroll.Position = UDim2.fromOffset(0, 26)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = UI.Theme.Accent
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local slist = Instance.new("UIListLayout", scroll)
    slist.Padding = UDim.new(0, 8)
    slist.SortOrder = Enum.SortOrder.LayoutOrder

    for i, entry in ipairs(ctx.auth.changelog or {}) do
        local block = Instance.new("Frame", scroll)
        block.Size = UDim2.new(1, -8, 0, 60)
        block.BackgroundTransparency = 1
        block.LayoutOrder = i

        local ver = Instance.new("TextLabel", block)
        ver.Size = UDim2.new(0.4, 0, 0, 18)
        ver.BackgroundTransparency = 1
        ver.Font = Enum.Font.GothamBold
        ver.Text = "v" .. tostring(entry.version)
        ver.TextColor3 = UI.Theme.Accent
        ver.TextSize = 13
        ver.TextXAlignment = Enum.TextXAlignment.Left

        local date = Instance.new("TextLabel", block)
        date.Size = UDim2.new(0.6, 0, 0, 18)
        date.Position = UDim2.new(0.4, 0, 0, 0)
        date.BackgroundTransparency = 1
        date.Font = Enum.Font.Gotham
        date.Text = tostring(entry.date)
        date.TextColor3 = UI.Theme.TextMuted
        date.TextSize = 11
        date.TextXAlignment = Enum.TextXAlignment.Right

        local notes = Instance.new("TextLabel", block)
        notes.Size = UDim2.new(1, 0, 0, 36)
        notes.Position = UDim2.fromOffset(0, 20)
        notes.BackgroundTransparency = 1
        notes.Font = Enum.Font.Gotham
        notes.Text = "- " .. table.concat(entry.notes or {}, "\n- ")
        notes.TextColor3 = UI.Theme.TextSub
        notes.TextSize = 11
        notes.TextWrapped = true
        notes.TextYAlignment = Enum.TextYAlignment.Top
        notes.TextXAlignment = Enum.TextXAlignment.Left
    end

    -- Discord card
    local discordCard = UI.GlassCard(parent, {Size = UDim2.new(1, 0, 0, 110), Name = "DiscordCard"})
    discordCard.LayoutOrder = 2

    UI.Section(discordCard.Pad, "COMMUNITY", 0)

    local dTitle = Instance.new("TextLabel", discordCard.Pad)
    dTitle.Size = UDim2.new(1, 0, 0, 22)
    dTitle.Position = UDim2.fromOffset(0, 22)
    dTitle.BackgroundTransparency = 1
    dTitle.Font = Enum.Font.GothamBold
    dTitle.Text = ctx.auth.discord and ctx.auth.discord.server_name or "Discord"
    dTitle.TextColor3 = UI.Theme.TextPrimary
    dTitle.TextSize = 15
    dTitle.TextXAlignment = Enum.TextXAlignment.Left

    UI.GlassButton(discordCard.Pad, "Copy invite link", function()
        ctx.copyToClipboard(ctx.auth.discord.invite_url)
        UI.Notify("Discord invite copied!", "success")
    end, {Position = UDim2.fromOffset(0, 52), Size = UDim2.new(1, 0, 0, 36), TextSize = 13})

    -- Credits
    local creditsCard = UI.GlassCard(parent, {Size = UDim2.new(1, 0, 0, 70), Name = "Credits"})
    creditsCard.LayoutOrder = 3

    local c1 = Instance.new("TextLabel", creditsCard.Pad)
    c1.Size = UDim2.new(1, 0, 0, 18)
    c1.BackgroundTransparency = 1
    c1.Font = Enum.Font.Gotham
    c1.Text = "Made by levox00"
    c1.TextColor3 = UI.Theme.TextPrimary
    c1.TextSize = 13
    c1.TextXAlignment = Enum.TextXAlignment.Left

    local c2 = Instance.new("TextLabel", creditsCard.Pad)
    c2.Size = UDim2.new(1, 0, 0, 14)
    c2.Position = UDim2.fromOffset(0, 22)
    c2.BackgroundTransparency = 1
    c2.Font = Enum.Font.Gotham
    c2.Text = "Apple Liquid Glass UI — Miku Hub v" .. tostring(ctx.auth.version)
    c2.TextColor3 = UI.Theme.TextMuted
    c2.TextSize = 11
    c2.TextXAlignment = Enum.TextXAlignment.Left
end

return M
