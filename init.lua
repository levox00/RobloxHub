print("[Hub] Starting...")
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
print("[Hub] WindUI loaded")

WindUI:AddTheme({
	Name = "Moon",
	Accent = Color3.fromHex("#0c1445"),
	Dialog = Color3.fromHex("#070d33"),
	Outline = Color3.fromHex("#b0c4de"),
	Text = Color3.fromHex("#dce4f0"),
	Placeholder = Color3.fromHex("#6878a0"),
	Background = Color3.fromHex("#050a1a"),
	Button = Color3.fromHex("#1a2a5e"),
	Icon = Color3.fromHex("#8fa8cc"),
	Toggle = Color3.fromHex("#6fa8dc"),
	Slider = Color3.fromHex("#5b8ec9"),
	Checkbox = Color3.fromHex("#6fa8dc"),
	PanelBackground = Color3.fromHex("#0e1a3a"),
	PanelBackgroundTransparency = 0.1,
	SliderIcon = Color3.fromHex("#7b9ec9"),
	Primary = Color3.fromHex("#4a7ab5"),
	LabelBackground = Color3.fromHex("#080e28"),
	LabelBackgroundTransparency = 0.5,
	ElementBackground = Color3.fromHex("#0f1c40"),
	ElementBackgroundTransparency = 0,
})

local REPO_URL = "https://raw.githubusercontent.com/levox00/RobloxHub/main"

print("[Hub] Creating window...")
local success, Window = pcall(function()
	return WindUI:CreateWindow({
		Title = "My Hub",
		Icon = "door-open",
		Folder = "MyHub",
		Size = UDim2.fromOffset(580, 460),
		Theme = "Moon",
		OpenButton = {
			Title = "Open Hub",
			CornerRadius = UDim.new(1, 0),
			StrokeThickness = 3,
			Enabled = true,
			Draggable = true,
			Scale = 0.5,
		Color = ColorSequence.new(
			Color3.fromHex("#4a7ab5"),
			Color3.fromHex("#8fa8cc")
		),
		},
	})
end)

if not success then
	warn("[Hub] CreateWindow FAILED:", Window)
	return
end

print("[Hub] Window created!")

pcall(function()
	Window:DisableTopbarButtons({ "Minimize" })
end)

local UtilsTab = Window:Tab({
	Title = "Utils",
	Icon = "solar:settings-bold",
})

local wsEnabled = false
local wsSpeed = 16

UtilsTab:Slider({
	Title = "WalkSpeed",
	Step = 1,
	Value = {
		Min = 16,
		Max = 500,
		Default = 16,
	},
	Callback = function(value)
		wsSpeed = value
	end,
})

UtilsTab:Toggle({
	Title = "Enable WalkSpeed",
	Callback = function(state)
		wsEnabled = state
	end,
})

task.spawn(function()
	while task.wait(0.1) do
		local ok, char = pcall(function()
			return game.Players.LocalPlayer.Character
		end)
		if ok and char then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid then
				if wsEnabled then
					humanoid.WalkSpeed = wsSpeed
				else
					humanoid.WalkSpeed = 16
				end
			end
		end
	end
end)

local HubsTab = Window:Tab({
	Title = "Hubs",
	Icon = "solar:folder-with-files-bold",
})

local cacheBuster = "?v=" .. math.random(1, 999999)

local loadSuccess, scriptsList = pcall(function()
	return loadstring(game:HttpGet(REPO_URL .. "/loadstrings.lua" .. cacheBuster))()
end)

if loadSuccess and scriptsList then
	for _, scriptEntry in ipairs(scriptsList) do
		HubsTab:Button({
			Title = scriptEntry.Name,
			Justify = "Center",
			Callback = function()
				local ok, err = pcall(function()
					loadstring(game:HttpGet(scriptEntry.Url .. cacheBuster))()
				end)
				if ok then
					WindUI:Notify({
						Title = scriptEntry.Name,
						Content = "Loaded successfully!",
						Duration = 3,
					})
				else
					WindUI:Notify({
						Title = "Error",
						Content = "Failed to load: " .. tostring(err),
						Duration = 5,
					})
				end
			end,
		})
	end
else
	HubsTab:Button({
		Title = "No scripts found",
		Desc = "Add scripts to loadstrings.lua",
		Locked = true,
	})
end
