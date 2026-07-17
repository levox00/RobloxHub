-- @name: Blox Fruits
-- Standalone WindUI window. Loaded via loadstrings.lua.

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

WindUI:AddTheme({
	Name = "BloxFruits",
	Accent = Color3.fromHex("#ef4444"),
	Dialog = Color3.fromHex("#070d33"),
	Outline = Color3.fromHex("#b0c4de"),
	Text = Color3.fromHex("#dce4f0"),
	Placeholder = Color3.fromHex("#6878a0"),
	Background = Color3.fromHex("#050a1a"),
	Button = Color3.fromHex("#1a2a5e"),
	Icon = Color3.fromHex("#8fa8cc"),
	Toggle = Color3.fromHex("#ef4444"),
	Slider = Color3.fromHex("#5b8ec9"),
	Primary = Color3.fromHex("#ef4444"),
})

local Window = WindUI:CreateWindow({
	Title = "Blox Fruits",
	Icon = "solar:sword-bold",
	Folder = "BloxFruits",
	Size = UDim2.fromOffset(440, 360),
	Theme = "BloxFruits",
	OpenButton = { Title = "Blox Fruits", CornerRadius = UDim.new(1, 0), StrokeThickness = 3, Enabled = true, Draggable = true, Scale = 0.5, Color = ColorSequence.new(Color3.fromHex("#ef4444"), Color3.fromHex("#7b2ff7")) },
})
if not Window then return end

local Tab = Window:Tab({Title = "Main", Icon = "solar:sword-bold"})
Tab:Section({Title = "Features"})
Tab:Paragraph({Title = "Blox Fruits Module", Desc = "Coming soon!"})
Tab:Button({Title = "Test", Callback = function()
	WindUI:Notify({Title = "BloxFruits", Content = "Module ready!", Duration = 3})
end})
print("[BloxFruits] Loaded")
