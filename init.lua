print("[Hub] Starting...")
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
print("[Hub] WindUI loaded")

local REPO_URL = "https://raw.githubusercontent.com/levox00/RobloxHub/main"

print("[Hub] Creating window...")
local success, Window = pcall(function()
	return WindUI:CreateWindow({
		Title = "My Hub",
		Icon = "door-open",
		Folder = "MyHub",
		Size = UDim2.fromOffset(580, 460),
		Theme = "Dark",
		OpenButton = {
			Title = "Open Hub",
			CornerRadius = UDim.new(1, 0),
			StrokeThickness = 3,
			Enabled = true,
			Draggable = true,
			Scale = 0.5,
			Color = ColorSequence.new(
				Color3.fromHex("#30FF6A"),
				Color3.fromHex("#e7ff2f")
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

local MainTab = Window:Tab({
	Title = "Main",
	Icon = "home",
})

MainTab:Button({
	Title = "Start Loading",
	Desc = "Click to run the loading screen",
	Color = Color3.fromHex("#305dff"),
	Callback = function()
		local Loading = Window:Loading({
			Title = "Loading...",
			Desc = "Please wait while the script loads",
			Duration = 3,
		})

		task.wait(3)

		WindUI:Notify({
			Title = "Done!",
			Content = "Loading complete!",
			Duration = 3,
		})
	end,
})

MainTab:Button({
	Title = "Notify Test",
	Desc = "Sends a notification",
	Callback = function()
		WindUI:Notify({
			Title = "Hello",
			Content = "This is a test notification!",
			Duration = 3,
		})
	end,
})

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
