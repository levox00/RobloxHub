-- Games/AdoptMe.lua | Adopt Me game module
-- Loaded from the Games tab; runs in the current client.

local function main()
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local pg = player:WaitForChild("PlayerGui")

    -- Cleanup previous instance
    local prev = pg:FindFirstChild("AdoptMeHub")
    if prev then prev:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "AdoptMeHub"
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 998
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = pg

    local card = Instance.new("Frame")
    card.Size = UDim2.fromOffset(320, 200)
    card.Position = UDim2.fromScale(0.5, 0.5)
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    card.BackgroundTransparency = 0.10
    card.BorderSizePixel = 0
    card.Parent = gui
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 20)
    Instance.new("UIStroke", card).Transparency = 0.40

    local t = Instance.new("TextLabel", card)
    t.Size = UDim2.new(1, -32, 0, 30)
    t.Position = UDim2.fromOffset(16, 16)
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.GothamBold
    t.Text = "Adopt Me Tools"
    t.TextColor3 = Color3.fromRGB(20, 20, 30)
    t.TextSize = 18

    local s = Instance.new("TextLabel", card)
    s.Size = UDim2.new(1, -32, 0, 60)
    s.Position = UDim2.fromOffset(16, 50)
    s.BackgroundTransparency = 1
    s.Font = Enum.Font.Gotham
    s.Text = "Skeleton module — placeholder.\nReplace this block with real features."
    s.TextColor3 = Color3.fromRGB(110, 110, 130)
    s.TextSize = 13
    s.TextWrapped = true

    local close = Instance.new("TextButton", card)
    close.Size = UDim2.new(1, -32, 0, 40)
    close.Position = UDim2.fromOffset(16, 140)
    close.BackgroundColor3 = Color3.fromRGB(255, 105, 180)
    close.BackgroundTransparency = 0.10
    close.BorderSizePixel = 0
    close.Font = Enum.Font.GothamBold
    close.Text = "Close"
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
    close.TextSize = 14
    close.AutoButtonColor = false
    Instance.new("UICorner", close).CornerRadius = UDim.new(0, 14)
    close.MouseButton1Click:Connect(function() gui:Destroy() end)

    print("[AdoptMe] module loaded")
end

main()
