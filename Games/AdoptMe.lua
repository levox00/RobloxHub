-- @name: Adopt Me
-- @description: Auto-Farm Features
-- Loads into PussyHub WindUI window

local Window = getgenv().PussyHub_Window
local WindUI = getgenv().PussyHub_WindUI
if not Window or not WindUI then
	warn("[AdoptMe] Load via PussyHub hub")
	return
end

print("[AdoptMe] Loading features...")

local Tab = Window:Tab({Title = "Adopt Me", Icon = "solar:pet-bold"})
Tab:Section({Title = "Info"})
Tab:Paragraph({Title = "Adopt Me Module", Desc = "Placeholder — features coming soon"})
Tab:Button({Title = "Test Load", Callback = function()
	WindUI:Notify({Title = "AdoptMe", Content = "Module loaded!", Duration = 3})
end})
