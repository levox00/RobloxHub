-- Games/GrowAGarden2.lua | Grow A Garden 2 module
local function main()
    local Players = game:GetService("Players")
    local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
    local prev = pg:FindFirstChild("GAG2Hub")
    if prev then prev:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "GAG2Hub"
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 998
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = pg

    local card = Instance.new("Frame")
    card.Size = UDim2.fromOffset(320, 220)
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
    t.Text = "Grow A Garden 2"
    t.TextColor3 = Color3.fromRGB(20, 20, 30)
    t.TextSize = 18

    local s = Instance.new("TextLabel", card)
    s.Size = UDim2.new(1, -32, 0, 80)
    s.Position = UDim2.fromOffset(16, 50)
    s.BackgroundTransparency = 1
    s.Font = Enum.Font.Gotham
    s.Text = "Skeleton module — placeholder.\nScanner + sell-helper go here."
    s.TextColor3 = Color3.fromRGB(110, 110, 130)
    s.TextSize = 13
    s.TextWrapped = true

    local close = Instance.new("TextButton", card)
    close.Size = UDim2.new(1, -32, 0, 40)
    close.Position = UDim2.fromOffset(16, 160)
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

    print("[GAG2] module loaded")
end

main()
