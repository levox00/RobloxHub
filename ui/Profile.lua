-- ui/Profile.lua | Profile tab: Roblox user + current game card
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

local M = {}

function M.Build(parent, UI, ctx)
    local list = Instance.new("UIListLayout", parent)
    list.Padding = UDim.new(0, 10)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center

    -- ============ USER CARD ============
    local userCard = UI.GlassCard(parent, {
        Size = UDim2.new(1, 0, 0, 110),
        Name = "UserCard",
    })
    userCard.LayoutOrder = 1

    local avatarRow = Instance.new("Frame", userCard.Pad)
    avatarRow.Size = UDim2.new(1, 0, 0, 64)
    avatarRow.BackgroundTransparency = 1

    local thumb, ok = pcall(function()
        return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
    end)

    local avatar = Instance.new("ImageLabel", avatarRow)
    avatar.Size = UDim2.fromOffset(64, 64)
    avatar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    avatar.BackgroundTransparency = 0.30
    avatar.BorderSizePixel = 0
    if thumb and ok then avatar.Image = thumb end
    Instance.new("UICorner", avatar).CornerRadius = UDim.new(0, 16)

    local nameWrap = Instance.new("Frame", avatarRow)
    nameWrap.Size = UDim2.new(1, -84, 1, 0)
    nameWrap.Position = UDim2.fromOffset(76, 0)
    nameWrap.BackgroundTransparency = 1

    local display = Instance.new("TextLabel", nameWrap)
    display.Size = UDim2.new(1, 0, 0, 22)
    display.BackgroundTransparency = 1
    display.Font = Enum.Font.GothamBold
    display.Text = player.DisplayName
    display.TextColor3 = Color3.fromRGB(20, 20, 30)
    display.TextSize = 17
    display.TextXAlignment = Enum.TextXAlignment.Left

    local username = Instance.new("TextLabel", nameWrap)
    username.Size = UDim2.new(1, 0, 0, 16)
    username.Position = UDim2.fromOffset(0, 24)
    username.BackgroundTransparency = 1
    username.Font = Enum.Font.Gotham
    username.Text = "@" .. player.Name
    username.TextColor3 = Color3.fromRGB(110, 110, 130)
    username.TextSize = 13
    username.TextXAlignment = Enum.TextXAlignment.Left

    local userId = Instance.new("TextLabel", nameWrap)
    userId.Size = UDim2.new(1, 0, 0, 14)
    userId.Position = UDim2.fromOffset(0, 42)
    userId.BackgroundTransparency = 1
    userId.Font = Enum.Font.Gotham
    userId.Text = "ID: " .. tostring(player.UserId)
    userId.TextColor3 = Color3.fromRGB(140, 140, 160)
    userId.TextSize = 11
    userId.TextXAlignment = Enum.TextXAlignment.Left

    local acctAge = Instance.new("TextLabel", nameWrap)
    acctAge.Size = UDim2.new(0.5, 0, 0, 14)
    acctAge.Position = UDim2.new(0.5, 0, 0, 42)
    acctAge.BackgroundTransparency = 1
    acctAge.Font = Enum.Font.Gotham
    acctAge.Text = "Account age: " .. tostring(player.AccountAge) .. " days"
    acctAge.TextColor3 = Color3.fromRGB(140, 140, 160)
    acctAge.TextSize = 11
    acctAge.TextXAlignment = Enum.TextXAlignment.Right

    -- ============ GAME CARD ============
    local gameCard = UI.GlassCard(parent, {
        Size = UDim2.new(1, 0, 0, 130),
        Name = "GameCard",
    })
    gameCard.LayoutOrder = 2

    local gameIcon = Instance.new("ImageLabel", gameCard.Pad)
    gameIcon.Size = UDim2.fromOffset(80, 80)
    gameIcon.Position = UDim2.fromOffset(0, 0)
    gameIcon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    gameIcon.BackgroundTransparency = 0.30
    gameIcon.BorderSizePixel = 0
    pcall(function()
        gameIcon.Image = "rbxthumb://type=GameIcon&id=" .. tostring(game.PlaceId) .. "&w=150&h=150"
    end)
    Instance.new("UICorner", gameIcon).CornerRadius = UDim.new(0, 16)

    local gInfo = Instance.new("Frame", gameCard.Pad)
    gInfo.Size = UDim2.new(1, -96, 1, 0)
    gInfo.Position = UDim2.fromOffset(92, 0)
    gInfo.BackgroundTransparency = 1

    local gName = Instance.new("TextLabel", gInfo)
    gName.Size = UDim2.new(1, 0, 0, 20)
    gName.BackgroundTransparency = 1
    gName.Font = Enum.Font.GothamBold
    gName.Text = "Current game"
    gName.TextColor3 = Color3.fromRGB(20, 20, 30)
    gName.TextSize = 14
    gName.TextXAlignment = Enum.TextXAlignment.Left

    local gPlaceId = Instance.new("TextLabel", gInfo)
    gPlaceId.Size = UDim2.new(1, 0, 0, 16)
    gPlaceId.Position = UDim2.fromOffset(0, 22)
    gPlaceId.BackgroundTransparency = 1
    gPlaceId.Font = Enum.Font.Gotham
    gPlaceId.Text = "Place ID: " .. tostring(game.PlaceId)
    gPlaceId.TextColor3 = Color3.fromRGB(110, 110, 130)
    gPlaceId.TextSize = 12
    gPlaceId.TextXAlignment = Enum.TextXAlignment.Left

    local gJobId = Instance.new("TextLabel", gInfo)
    gJobId.Size = UDim2.new(1, 0, 0, 16)
    gJobId.Position = UDim2.fromOffset(0, 40)
    gJobId.BackgroundTransparency = 1
    gJobId.Font = Enum.Font.Gotham
    gJobId.Text = "Server: " .. tostring(game.JobId):sub(1, 12) .. "..."
    gJobId.TextColor3 = Color3.fromRGB(110, 110, 130)
    gJobId.TextSize = 12
    gJobId.TextXAlignment = Enum.TextXAlignment.Left

    -- Copy invite button (gives the join-script via clipboard)
    local inviteBtn = UI.GlassButton(gInfo, "Copy server invite link", function()
        local link = string.format(
            "Roblox.GameLauncher.joinGameInstance(%d, %q)",
            game.PlaceId, game.JobId
        )
        ctx.copyToClipboard(link)
        UI.Notify("Invite script copied! Paste in browser.", "success")
    end, {Position = UDim2.fromOffset(0, 70), Size = UDim2.new(1, 0, 0, 36), TextSize = 13})

    -- ============ HUB STATS CARD ============
    local statsCard = UI.GlassCard(parent, {
        Size = UDim2.new(1, 0, 0, 70),
        Name = "StatsCard",
    })
    statsCard.LayoutOrder = 3

    local statList = Instance.new("UIListLayout", statsCard.Pad)
    statList.Padding = UDim.new(0, 6)
    statList.FillDirection = Enum.FillDirection.Horizontal
    statList.HorizontalAlignment = Enum.HorizontalAlignment.Left

    local function statPill(label, value)
        local f = Instance.new("Frame")
        f.Size = UDim2.fromOffset(120, 38)
        f.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        f.BackgroundTransparency = 0.30
        f.BorderSizePixel = 0
        f.Parent = statsCard.Pad
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)

        local l = Instance.new("TextLabel", f)
        l.Size = UDim2.new(1, -12, 0, 14)
        l.Position = UDim2.fromOffset(8, 4)
        l.BackgroundTransparency = 1
        l.Font = Enum.Font.Gotham
        l.Text = label
        l.TextColor3 = Color3.fromRGB(110, 110, 130)
        l.TextSize = 10
        l.TextXAlignment = Enum.TextXAlignment.Left

        local v = Instance.new("TextLabel", f)
        v.Size = UDim2.new(1, -12, 0, 18)
        v.Position = UDim2.fromOffset(8, 18)
        v.BackgroundTransparency = 1
        v.Font = Enum.Font.GothamBold
        v.Text = value
        v.TextColor3 = Color3.fromRGB(20, 20, 30)
        v.TextSize = 14
        v.TextXAlignment = Enum.TextXAlignment.Left
        return f
    end

    statPill("Hub version", "v" .. tostring(ctx.auth.version or "1.0.0"))
    statPill("Executor", (identifyexecutor and identifyexecutor()) or "Unknown")
    statPill("Players", tostring(#Players:GetPlayers()))
end

return M
