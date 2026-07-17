-- Games/keyboardEscape.lua | Universal: force-leave the current game
-- Press the button to teleport to a private server-less hop.
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local player = Players.LocalPlayer

local function main()
    local pg = player:WaitForChild("PlayerGui")
    local prev = pg:FindFirstChild("KeyboardEscape")
    if prev then prev:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "KeyboardEscape"
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 998
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = pg

    local card = Instance.new("Frame")
    card.Size = UDim2.fromOffset(280, 130)
    card.Position = UDim2.fromOffset(40, 40)
    card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    card.BackgroundTransparency = 0.10
    card.BorderSizePixel = 0
    card.Parent = gui
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 18)
    Instance.new("UIStroke", card).Transparency = 0.40

    local t = Instance.new("TextLabel", card)
    t.Size = UDim2.new(1, -32, 0, 22)
    t.Position = UDim2.fromOffset(16, 14)
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.GothamBold
    t.Text = "Keyboard Escape"
    t.TextColor3 = Color3.fromRGB(20, 20, 30)
    t.TextSize = 15

    local s = Instance.new("TextLabel", card)
    s.Size = UDim2.new(1, -32, 0, 28)
    s.Position = UDim2.fromOffset(16, 40)
    s.BackgroundTransparency = 1
    s.Font = Enum.Font.Gotham
    s.Text = "Force-leave to a fresh server."
    s.TextColor3 = Color3.fromRGB(110, 110, 130)
    s.TextSize = 12

    local btn = Instance.new("TextButton", card)
    btn.Size = UDim2.new(1, -32, 0, 38)
    btn.Position = UDim2.fromOffset(16, 78)
    btn.BackgroundColor3 = Color3.fromRGB(255, 90, 95)
    btn.BackgroundTransparency = 0.10
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.Text = "Rejoin server"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)

    btn.MouseButton1Click:Connect(function()
        pcall(function()
            TeleportService:Teleport(game.PlaceId, player)
        end)
    end)

    print("[KeyboardEscape] module loaded")
end

main()
