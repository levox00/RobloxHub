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

local airJumpEnabled = false

UtilsTab:Toggle({
	Title = "Air Jump",
	Desc = "Jump in mid-air",
	Callback = function(state)
		airJumpEnabled = state
	end,
})

local UIS = game:GetService("UserInputService")

UIS.JumpRequest:Connect(function()
	if not airJumpEnabled then return end
	local ok, char = pcall(function()
		return game.Players.LocalPlayer.Character
	end)
	if ok and char then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.FloorMaterial == Enum.Material.Air then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

local flyEnabled = false
local flySpeed = 50
local flyBV, flyBG

UtilsTab:Slider({
	Title = "Fly Speed",
	Step = 1,
	Value = {
		Min = 10,
		Max = 300,
		Default = 50,
	},
	Callback = function(value)
		flySpeed = value
	end,
})

UtilsTab:Toggle({
	Title = "Fly",
	Desc = "Press E to fly, Q to go down",
	Callback = function(state)
		flyEnabled = state
		local ok, char = pcall(function()
			return game.Players.LocalPlayer.Character
		end)
		if not ok or not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		if state then
			flyBV = Instance.new("BodyVelocity")
			flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
			flyBV.Velocity = Vector3.zero
			flyBV.Parent = hrp

			flyBG = Instance.new("BodyGyro")
			flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
			flyBG.P = 9e4
			flyBG.Parent = hrp
		else
			if flyBV then flyBV:Destroy() flyBV = nil end
			if flyBG then flyBG:Destroy() flyBG = nil end
		end
	end,
})

UIS.InputBegan:Connect(function(input, gpe)
	if gpe or not flyEnabled then return end
	if input.KeyCode == Enum.KeyCode.E then
		local ok, char = pcall(function()
			return game.Players.LocalPlayer.Character
		end)
		if ok and char then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Freefall) end
		end
	end
end)

task.spawn(function()
	while task.wait() do
		if flyEnabled then
			local ok, char = pcall(function()
				return game.Players.LocalPlayer.Character
			end)
			if ok and char then
				local hrp = char:FindFirstChild("HumanoidRootPart")
				local cam = workspace.CurrentCamera
				if hrp and cam and flyBV and flyBG then
					local camCF = cam.CFrame
					local direction = Vector3.zero

					if UIS:IsKeyDown(Enum.KeyCode.W) then
						direction = direction + camCF.LookVector
					end
					if UIS:IsKeyDown(Enum.KeyCode.S) then
						direction = direction - camCF.LookVector
					end
					if UIS:IsKeyDown(Enum.KeyCode.A) then
						direction = direction - camCF.RightVector
					end
					if UIS:IsKeyDown(Enum.KeyCode.D) then
						direction = direction + camCF.RightVector
					end
					if UIS:IsKeyDown(Enum.KeyCode.Space) then
						direction = direction + Vector3.new(0, 1, 0)
					end
					if UIS:IsKeyDown(Enum.KeyCode.Q) then
						direction = direction - Vector3.new(0, 1, 0)
					end

					if direction.Magnitude > 0 then
						direction = direction.Unit
					end

					flyBV.Velocity = direction * flySpeed
					flyBG.CFrame = camCF
				end
			end
		end
	end
end)

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
