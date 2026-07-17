-- @name: Adopt Me
-- Standalone WindUI window. Loaded via loadstrings.lua.

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

WindUI:AddTheme({
	Name = "AdoptMe",
	Accent = Color3.fromHex("#ec4899"),
	Dialog = Color3.fromHex("#070d33"),
	Outline = Color3.fromHex("#b0c4de"),
	Text = Color3.fromHex("#dce4f0"),
	Placeholder = Color3.fromHex("#6878a0"),
	Background = Color3.fromHex("#050a1a"),
	Button = Color3.fromHex("#1a2a5e"),
	Icon = Color3.fromHex("#8fa8cc"),
	Toggle = Color3.fromHex("#ec4899"),
	Slider = Color3.fromHex("#5b8ec9"),
	Primary = Color3.fromHex("#ec4899"),
})

local Window = WindUI:CreateWindow({
	Title = "Adopt Me",
	Icon = "solar:pet-bold",
	Folder = "AdoptMe",
	Size = UDim2.fromOffset(440, 360),
	Theme = "AdoptMe",
	OpenButton = { Title = "Adopt Me", CornerRadius = UDim.new(1, 0), StrokeThickness = 3, Enabled = true, Draggable = true, Scale = 0.5, Color = ColorSequence.new(Color3.fromHex("#ec4899"), Color3.fromHex("#7b2ff7")) },
})
if not Window then return end

local Tab = Window:Tab({Title = "Main", Icon = "solar:pet-bold"})
Tab:Section({Title = "Features"})
Tab:Paragraph({Title = "Adopt Me Module", Desc = "Coming soon!"})
Tab:Button({Title = "Test", Callback = function()
	WindUI:Notify({Title = "AdoptMe", Content = "Module ready!", Duration = 3})
end})
print("[AdoptMe] Loaded")
